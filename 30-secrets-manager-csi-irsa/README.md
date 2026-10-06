# Moving Hard-Coded Credentials into Secrets Manager (CSI Driver + IRSA)

## Problem

The organisation-wide secret scanning (see [24-supply-chain-security](../24-supply-chain-security))
found database connection strings and API keys written directly into Kubernetes
manifests. Scanning finds the problem; it doesn't fix it. Each service needed its
credentials moved out of Git without breaking it.

## The pattern

For each service, the same five pieces:

1. **A secret in AWS Secrets Manager**, one per environment, holding the values.
2. **A scoped IAM policy** that can read only that service's secrets (matched by name
   prefix), attached to...
3. **An IRSA role bound to the service's Kubernetes service account**, so the pod
   gets AWS access with no stored keys.
4. **A SecretProviderClass** that mounts the secret into the pod as a file.
5. **The Deployment** with the hard-coded variable deleted, and a service account and
   volume mount added. The application loads the mounted file at start-up through
   the dotenv loader it already used — only the path changes.

Applied across **three services** — two with production and sandbox environments,
one holding three separate credentials per environment.

## The gotcha: CI applied only the files it knew about

After the first migration, the pod didn't get its secret. The deploy workflow listed
**specific manifests** to apply, so it never applied the new SecretProviderClass. The
fix was to apply the **whole manifests folder**, so a new file can't be silently
skipped again.

## How I verified each one

Not "the workflow went green":

- the pod is `1/1 Running` with no restarts,
- the IRSA token is projected into the pod,
- the secret file is mounted and has the expected size,
- the application logs show a successful database connection and real data loading,
- the health endpoint answers.

One environment's database was unreachable from the cluster before the change as well
as after. I recorded that explicitly, with the evidence, so the migration wasn't
blamed for a pre-existing problem.

## What this does not fix

Moving a leaked credential into Secrets Manager stops it being committed again. It
**does not invalidate the value that is already in Git history.** Each one still needs
rotating, and some can't be rotated like a password (an API key has to be regenerated
at the provider, and if two environments share it, both secrets change together).
That rotation is separate work, and it needs its own owner.

## What this demonstrates

Turning a scanner finding into a repeatable remediation, least-privilege IAM per
service, keyless AWS access from pods, and being precise about what a fix does and
does not achieve.

**Tech:** AWS Secrets Manager, Secrets Store CSI Driver, IRSA, EKS, Kustomize, GitHub
Actions
