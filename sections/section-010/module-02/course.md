# Configure Trivy And Read Findings In Depth

A default Harbor scans every artifact with one scanner and one set of Trivy settings. A real team soon asks more. Which scanner does a project use? Why does the report list a flaw that has no fix? What do the severity and the score of a finding mean? And what does a scan that never finishes look like?

A **scanner registration** is the entry in Harbor that tells `core` where a scanner lives and how to call it. The **Trivy adapter** is the Harbor component, the `trivy` pod, that runs Trivy for Harbor and reads its own settings from environment variables. This module covers both, and then shows how to read the details of a finding and how to follow a scan that is stuck. Keep one sentence in mind: **a report only shows what the scanner was set up to look for, so know the settings before you trust the numbers.**

The module has four parts. **Scanner Registrations And The Project Scanner** lists the scanners, registers one and chooses the scanner of a project. **Configuring The Trivy Adapter** changes the adapter settings and sees the effect in a report. **Severity, CVSS Scores And Fixed Versions** reads the fields of a finding. **Scan States, Stopping A Scan And The Scan Log** follows a scan from start to end. A graded lab follows the second part.

## Learning objectives

After this module you can:

- List the scanner registrations, and say which one is the system default and which one a project uses.
- Register a scanner by its URL and assign it to one project.
- Name the environment variables that control the Trivy adapter and change one on the `harbor-trivy` StatefulSet.
- Explain why a report that ignores unfixed vulnerabilities has fewer findings.
- Read the severity, the CVSS score, the package, the installed version and the fixed version of a finding with `jq`.
- Name the states of a scan, stop a running scan and read its log.

## Before you start

You need Kubernetes basics and `kubectl`. You need to know what a vulnerability scan is and how to read JSON with `jq`. A scan report is a list of CVEs (Common Vulnerabilities and Exposures, public identifiers for known security flaws).

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds the `harbor` command-line tool, `regctl`, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds these artifacts:

| Project | Repository | Tags | What it is |
| --- | --- | --- | --- |
| `inventory` | `podinfo` | `6.0.0` | An old release of the `podinfo` web application, copied for `linux/amd64` only |
| `inventory` | `podinfo` | `6.15.0` | A recent release, also `linux/amd64` only |

Neither artifact has been scanned. The playground scanned one artifact in a project called `warmup`, so the Trivy database is already downloaded and your first scan does not have to wait for it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
