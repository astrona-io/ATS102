# Generate And Read Software Bills Of Materials

A new flaw is announced in a common compression library. Your manager asks a simple question: which of our images contain it? With vulnerability reports alone, you wait for every artifact to be scanned again against tomorrow's database. With a list of what each image contains, you search the lists you already have.

That list is a **Software Bill of Materials (SBOM)**: a document that names every package inside an artifact, with its version, and often its license and origin. Harbor can produce one for any image through its Trivy adapter and keep it next to the image. This module teaches you to do that.

Keep one sentence in mind: **a vulnerability report is a judgement that goes out of date, and an SBOM is an inventory that does not.** The packages in an image never change after it is built, so its SBOM stays true for as long as the image exists.

The module has two parts. **What An SBOM Is And How Harbor Stores It** explains the SPDX format and Harbor's accessories. **Generating, Downloading And Reading An SBOM** generates one, downloads it, reads its packages, and turns on generation on push. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain what an SBOM is and how it differs from a vulnerability report.
- Name the main fields of an SPDX document.
- Explain how Harbor stores an SBOM as an accessory of its subject artifact.
- Generate an SBOM through the Harbor REST API and follow its status.
- Download an SBOM with `regctl` and list its packages with `jq`.
- Turn on automatic SBOM generation for a project and prove it worked on push.

## Before you start

You need to know what an image, a tag and a digest are, and you will call a REST API with `curl` and read JSON with `jq`.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `regctl`, the `harbor` command-line tool, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds these artifacts, and none has an SBOM yet:

| Project | Repository | Tags | What it is |
| --- | --- | --- | --- |
| `inventory` | `podinfo` | `6.0.0` | An old release of the `podinfo` web application, `linux/amd64` only |
| `inventory` | `podinfo` | `6.15.0` | A recent release, `linux/amd64` only |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
