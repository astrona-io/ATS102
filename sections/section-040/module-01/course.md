# Stop Vulnerable Artifacts From Being Pulled

The vulnerability report of `inventory/podinfo:6.0.0` lists several High and Critical findings. Anyone can still pull it, and any cluster can still run it. A report on its own refuses nothing.

Harbor can refuse it for you. The project setting **"Prevent vulnerable images from running"** makes Harbor check the report on every pull and refuse any artifact with vulnerabilities at or above a chosen **severity**. Because a cluster pulls images from the registry, a refusal at the registry stops the image from running anywhere.

This module teaches that setting and its exceptions. Keep one sentence in mind: **the policy acts on the report, so an artifact is only as blocked as its report says, and every exception must be narrow and must expire.**

The module has two parts. **Preventing Vulnerable Images From Running** turns the policy on, reads Harbor's refusal, and explains the cases that surprise people: unscanned artifacts, image indexes and exempt pulls. **CVE Allowlists With An Expiry** adds exceptions at system and project level and builds a narrow allowlist from a report. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Turn on vulnerability prevention for a project with a severity threshold.
- Read Harbor's refusal of a vulnerable or unscanned artifact.
- Explain why an image index passes the check and which pulls are exempt.
- Explain how a project chooses between the system allowlist and its own.
- Write a project CVE allowlist that covers exactly the reviewed findings of one artifact, with an expiry.
- Predict from a report whether a pull will be allowed or refused.

## Before you start

You need to know what an image, a tag, a digest and a vulnerability report are. You will call a REST API with `curl`, read JSON with `jq`, and work out a Unix timestamp with `date`.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `regctl`, the `harbor` command-line tool, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds these artifacts, both scanned:

| Project | Repository | Tag | What it is |
| --- | --- | --- | --- |
| `inventory` | `podinfo` | `6.0.0` | An old release of the `podinfo` web application, `linux/amd64` only, with High and Critical findings |
| `inventory` | `podinfo` | `6.15.0` | A recent release, `linux/amd64` only |

Vulnerability prevention is off, and no CVE allowlist exists.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
