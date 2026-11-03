# Read And Use The Content Of An SBOM

An SBOM that nobody reads protects nothing. The value of the document is in the questions it answers: which packages are in this image, under which license, and which of my images contain the package that a new advisory names? Those questions need more than a list of names. They need you to know how an SPDX document is built.

A **Software Bill of Materials (SBOM)** is a list of the software packages inside an artifact. **SPDX** (Software Package Data Exchange) is the format in which Harbor writes it, as a JSON file. This module takes the document apart, reads packages, versions, licenses and package URLs from it, searches several artifacts for one package, and explains how the SBOM accessory is stored and replaced. Keep one sentence in mind: **an SBOM records what is in an artifact, so it answers questions about content, and a vulnerability report answers questions about risk.**

The module has four parts. **The Structure Of An SPDX Document** names the fields and the relationships. **Packages, Versions, Licenses And Package URLs** reads them with `jq`. **Find A Package Across Artifacts** answers the question that an advisory raises, and a graded lab follows it. **The Life Of An SBOM Accessory** covers regeneration, status, copying and deletion.

## Learning objectives

After this module you can:

- Name the top-level fields of an SPDX document and say what each one holds.
- Explain how the relationships connect the artifact, the operating system and the packages.
- List the packages, versions, licenses and package URLs of an SBOM with `jq`.
- Decide from the SBOMs of several artifacts which ones contain a given package.
- Record the result in Harbor as a label on each artifact.
- Say what happens to an SBOM when you regenerate it, copy the artifact or delete the artifact.

## Before you start

You need Kubernetes basics and `kubectl`, and you need to read JSON with `jq`. You need to know that Harbor stores an SBOM next to an artifact as an accessory, an artifact that belongs to another artifact.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `regctl`, `curl`, `jq` and the other client tools, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds these artifacts:

| Project | Repository | Tags | What it is |
| --- | --- | --- | --- |
| `audit` | `podinfo` | `6.15.0` | A release of the `podinfo` web application, `linux/amd64` only |
| `audit` | `alpine` | `3.20` | The Alpine Linux base image, `linux/amd64` only |

Neither artifact has an SBOM yet, and the project does not generate them on push.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
