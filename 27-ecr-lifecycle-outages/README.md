# ECR Lifecycle Policy Outages — Three Production Incidents

## Problem

Two production services went down on separate days with the same symptom:
`ImagePullBackOff`. The images they were trying to pull no longer existed.

## Investigation

CloudTrail showed a **lifecycle policy** had been added to the container
repositories with the tag prefix `app-` and the rule "keep only the 3 newest images".
That prefix matches **both** production images (`app-{sha}`) and development images
(`app-dev-{sha}`).

When three development images were pushed, the policy counted them against the same
limit of three — and expired the **production** images to make room. The services
only failed later, when Karpenter moved a pod and it tried to pull an image that was
gone. The same policy was present on **ten repositories**.

## Recovery

Each service was brought back by triggering a fresh build, which pushed a new
production image. That restored service but not the cause.

## The fix that didn't work

My first fix split the policy into two rules — one for development tags, one for
production. It failed. Tag-pattern rules do **not** exclude images already matched by
another rule, so the production rule still caught development tags, and a second
service went down.

## The fix that did

I removed the production rule from all ten repositories. The final policy:

- keeps the 3 newest **development** images,
- expires untagged layers after a day,
- has **no production rule**, so production images are never touched.

I verified that every repository still held its production images afterwards.

## Trade-off I accepted

With no production rule, production images accumulate. That is the safe default for a
cost programme that must never delete a live image. A proper retention rule needs the
two kinds of image to be distinguishable by tag scheme, not by prefix.

## The third incident

An earlier outage had the same root: a repository removed during a cost audit.
AgentCore runtimes are invisible to inventories that only look at the cluster, so the
repository looked unused. The corrective process requires **programmatic
verification across the runtime, Lambda and container services before any deletion**.

## What this demonstrates

Tracing a production failure back through CloudTrail to a cost-saving change,
recognising that a plausible fix was wrong, and designing clean-up rules so a saving
can never take down something live.

**Tech:** Amazon ECR, lifecycle policies, CloudTrail, Karpenter, Kubernetes
