#!/usr/bin/env bash
#
# backup-example.sh
# -----------------------------------------------------------------------------
# Representative MongoDB backup script (genericized).
#
# Flow: fetch credentials from Secrets Manager -> mongodump -> zip -> upload to
# S3 -> clean up local files -> email an HTML report via SES.
#
# All identifiers below are placeholders.
# -----------------------------------------------------------------------------

set -euo pipefail

AWS_REGION="ap-south-1"
SECRET_ID="mongodb/backup/config"          # holds host/user/pass/bucket/smtp
INSTANCE_NAME="ExampleInstance"
DB_NAME="example-db"
EXCLUDE_COLLECTIONS=("very_large_collection")   # backed up separately/weekly

BACKUP_DIR="/root/mongodb-backup"
LOG_FILE="/var/log/mongodb-backup-${INSTANCE_NAME}-${DB_NAME}.log"
CURRENT_MONTH="$(date +%Y-%m-%B)"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"

# --- pull all secrets in one call; nothing hardcoded -------------------------
SECRET="$(aws secretsmanager get-secret-value --region "$AWS_REGION" \
          --secret-id "$SECRET_ID" --query SecretString --output text)"
MONGO_HOST="$(echo "$SECRET" | jq -r '.host')"
MONGO_USER="$(echo "$SECRET" | jq -r '.user')"
MONGO_PASS="$(echo "$SECRET" | jq -r '.pass')"
MONGO_AUTH_DB="$(echo "$SECRET" | jq -r '.auth_db')"
S3_BUCKET="$(echo "$SECRET" | jq -r '.s3_bucket')"
SMTP_HOST="$(echo "$SECRET" | jq -r '.smtp_host')"
SMTP_USER="$(echo "$SECRET" | jq -r '.smtp_user')"
SMTP_PASS="$(echo "$SECRET" | jq -r '.smtp_pass')"
MAIL_FROM="$(echo "$SECRET" | jq -r '.email_from')"
MAIL_TO="$(echo "$SECRET" | jq -r '.email_to')"

export AWS_DEFAULT_REGION="$AWS_REGION"
mkdir -p "$BACKUP_DIR"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"; }

send_report() {
  # $1 subject, $2 html body — sent via SES SMTP
  python3 - "$1" "$2" <<'PY' || log "WARN: email send failed"
import sys, smtplib, os
from email.mime.text import MIMEText
subject, body = sys.argv[1], sys.argv[2]
msg = MIMEText(body, "html")
msg["Subject"], msg["From"], msg["To"] = subject, os.environ["MAIL_FROM"], os.environ["MAIL_TO"]
s = smtplib.SMTP(os.environ["SMTP_HOST"], 587); s.starttls()
s.login(os.environ["SMTP_USER"], os.environ["SMTP_PASS"])
s.sendmail(os.environ["MAIL_FROM"], os.environ["MAIL_TO"].split(","), msg.as_string()); s.quit()
PY
}
export MAIL_FROM MAIL_TO SMTP_HOST SMTP_USER SMTP_PASS

on_error() {
  log "ERROR: backup failed"
  send_report "FAILED: ${INSTANCE_NAME}/${DB_NAME} backup" \
              "<p>Backup failed at ${STAMP}. Check ${LOG_FILE}.</p>"
  rm -rf "${BACKUP_DIR:?}/${DB_NAME}_${STAMP}"* || true
  exit 1
}
trap on_error ERR

# --- build exclude args ------------------------------------------------------
EXCLUDES=()
for c in "${EXCLUDE_COLLECTIONS[@]}"; do EXCLUDES+=(--excludeCollection "$c"); done

# --- dump --------------------------------------------------------------------
DUMP_PATH="${BACKUP_DIR}/${DB_NAME}_${STAMP}"
log "Dumping ${DB_NAME} from ${MONGO_HOST}"
mongodump --host "$MONGO_HOST" --port 27017 \
  --username "$MONGO_USER" --password "$MONGO_PASS" \
  --authenticationDatabase "$MONGO_AUTH_DB" \
  --db "$DB_NAME" "${EXCLUDES[@]}" \
  --out "$DUMP_PATH"

# --- compress ----------------------------------------------------------------
ZIP_PATH="${DUMP_PATH}.zip"
( cd "$BACKUP_DIR" && zip -r -q "$(basename "$ZIP_PATH")" "$(basename "$DUMP_PATH")" )
SIZE="$(du -h "$ZIP_PATH" | cut -f1)"
log "Compressed -> ${SIZE}"

# --- upload ------------------------------------------------------------------
S3_KEY="${CURRENT_MONTH}/${INSTANCE_NAME}/${DB_NAME}/$(basename "$ZIP_PATH")"
aws s3 cp "$ZIP_PATH" "s3://${S3_BUCKET}/${S3_KEY}" --only-show-errors
log "Uploaded to s3://${S3_BUCKET}/${S3_KEY}"

# --- clean up + report -------------------------------------------------------
rm -rf "$DUMP_PATH" "$ZIP_PATH"
send_report "SUCCESS: ${INSTANCE_NAME}/${DB_NAME} backup" \
  "<p>Backup of <b>${DB_NAME}</b> completed at ${STAMP}.<br>Size: ${SIZE}<br>Location: s3://${S3_BUCKET}/${S3_KEY}</p>"
log "Done"
