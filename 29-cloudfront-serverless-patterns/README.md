# CloudFront in Front of Serverless Apps — Four Traps and Their Fixes

## Context

The pattern is common: one domain, a static single-page app in a private S3 bucket,
and an API on API Gateway or a Lambda Function URL, both behind CloudFront. It looks
simple. Four things in it fail in ways that point to the wrong cause, and each cost
real debugging time before it was understood. This is the runbook I wrote from them.

## Trap 1 — Lambda Function URL + OAC returns 403 with no logs

**Symptom.** Static files work. Every call to the Function URL origin returns 403, and
**no CloudWatch log group appears** — the request never reaches the function. Invoking
the function directly works.

**Cause.** For Function URLs created after October 2025, the resource policy must
grant **both** `lambda:InvokeFunctionUrl` **and** `lambda:InvokeFunction`. Older
examples show only the first. It is documented only in an update to an AWS blog post.
Setting the URL's auth type to NONE does *not* help, because OAC still signs the
request and the policy is still evaluated.

**Fix.** Add the second grant, scoped to the distribution. It takes effect immediately.

## Trap 2 — "Unauthorized: No token provided" that isn't authentication

**Symptom.** Every sign-in returns 401.

**Cause.** CloudFront forwards the full path, so `/api/auth/login` reaches API Gateway
with `/api` still on it. It misses the `/auth/{proxy+}` route and falls into the
greedy `/{proxy+}` route — the *wrong Lambda*, which wants a token.

**Fix.** A **viewer-request CloudFront Function** that strips `/api`, attached to the
`/api/*` behaviour **only**. It must be **published to LIVE** — a function left in
development attaches without error and silently does nothing. One function per
application, so a change for one cannot affect another.

## Trap 3 — the Authorization header disappears

**Cause.** With no origin request policy, CloudFront does not forward the header, so
authenticated calls fail with the same 401. The obvious fix, forwarding *all* viewer
headers, makes API Gateway return **403**, because the Host header is forwarded too.

**Fix.** The managed policy that forwards everything **except the Host header**,
with caching disabled on API behaviours.

Telling traps 2 and 3 apart: if an endpoint that needs **no** auth also fails, it is
the path prefix; if only authenticated calls fail, it is the header. Both can be
present at once.

## Trap 4 — deep links return an error

**Cause.** A single-page app routes in the browser. A direct visit to `/login` asks S3
for a file that does not exist.

**Fix.** A viewer-request function on the *default* behaviour (never on `/api/*`)
that sends extensionless paths back to the app.

## A diagnostic that saves hours

Call the API endpoint **directly, bypassing CloudFront**. If that works and the
CloudFront path does not, the fault is routing or headers, not your auth code.

## What this demonstrates

Debugging across layers where the error message points at the wrong one, reading
platform behaviour carefully, and writing it down so the next application takes
minutes, not days.

**Tech:** CloudFront (OAC, Functions, origin request policies), S3, API Gateway,
Lambda Function URLs, IAM resource policies
