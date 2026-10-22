# Prerequisites

Before starting this lab you should be able to:

- Open a shell in a pod with `kubectl exec`.
- Call a REST API with `curl` and read JSON with `jq`.
- Copy an image with `regctl image copy`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Harbor 2.15.4** at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod with `harbor`, `cosign`, `regctl`, `oras`, `curl` and `jq`, which trusts Harbor's certificate. Open a shell in it with `kubectl -n workstation exec -it deploy/workstation -- sh`.
- The projects and artifacts the task describes.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Harbor, so leave your changes in place.
- Change one setting at a time and check the result before the next change.
- The first scan of a new environment downloads the Trivy database and takes a few minutes. Wait for it instead of starting the scan again.
