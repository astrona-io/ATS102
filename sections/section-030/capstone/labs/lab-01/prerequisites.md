# Prerequisites

Before starting this lab you should be able to:

- Sign and verify an artifact with Cosign and a key pair.
- Find the digest of a tag with `regctl image digest`.
- Change a project setting with the `harbor` CLI or the Harbor API.

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
