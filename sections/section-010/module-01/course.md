# Scan Artifacts For Vulnerabilities With Trivy

You push `podinfo:6.0.0` to Harbor and the push succeeds. Harbor stores it, lists it, and serves it to anyone with access. Nothing tells you that this image was built years ago and that some of the packages inside it have known security flaws.

A **vulnerability** is a known security flaw in a software package. Each one has a public identifier in the Common Vulnerabilities and Exposures (CVE) list, for example `CVE-2023-1234`. A **vulnerability scanner** looks inside an artifact, lists its packages, and compares their versions with a database of known CVEs. Harbor comes with one already connected: **Trivy**.

This module teaches you to use it. Keep one sentence in mind: **Harbor does not scan anything until something asks it to, and a scan is only as current as the database it used.** You ask by hand, on push or on a schedule, and you read the answer in the report.

The module has three parts. **How Harbor Scans Artifacts With Trivy** follows one scan request through Harbor's components and explains the Trivy database. **Scanning An Artifact And Reading The Report** starts a scan from the command line and reads the result through the REST API. **Scan On Push And Scheduled Scans** makes Harbor scan without being asked. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the Harbor components that take part in a scan and say what each one does.
- Explain what the Trivy database is and why a new Harbor needs internet for its first scan.
- Start a scan with the `harbor` command-line tool and with the REST API.
- Read the summary of a vulnerability report and list the High and Critical CVEs with `jq`.
- Turn on scan on push for a project and set a daily scan of every artifact.
- Prove that an artifact was scanned on push and not by hand.

## Before you start

You need Kubernetes basics and `kubectl`, and you need to know what an image, a tag, a digest and a registry are. You will call a REST API with `curl` and read JSON with `jq`.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds the `harbor` command-line tool, `regctl`, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds these artifacts:

| Project | Repository | Tags | What it is |
| --- | --- | --- | --- |
| `inventory` | `podinfo` | `6.0.0` | An old release of the `podinfo` web application, copied for `linux/amd64` only |
| `inventory` | `podinfo` | `6.15.0` | A recent release, also `linux/amd64` only |

Neither artifact has been scanned. The playground also scanned one artifact in a project called `warmup`, so the Trivy database is already downloaded and your first scan does not have to wait for it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
