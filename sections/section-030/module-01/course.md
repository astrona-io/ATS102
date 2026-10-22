# Sign Artifacts With Cosign And Enforce Signatures

The tag `release/podinfo:6.15.0` points at one image today. Anyone with push rights to the project can push another image with the same tag tomorrow, and every pull after that gets the new one. Nothing in the tag tells you whether the image is the one your build pipeline produced.

A **digital signature** solves this. The builder signs the artifact's **digest**, the SHA-256 hash that identifies its exact content, with a private key. Anyone with the matching public key can check the signature, and a changed artifact has a different digest that the signature does not cover. **Cosign**, from the Sigstore project, is the most common tool for signing container images, and Harbor understands its signatures.

This module teaches you to sign with Cosign and to make Harbor enforce signatures. Keep one sentence in mind: **a signature covers a digest, not a tag, and Harbor only enforces signatures when the project tells it to.**

The module has three parts. **Signatures, Accessories And Where Notary Went** explains how Harbor stores signatures and why Docker Content Trust is gone. **Signing And Verifying With Cosign** creates a key pair, signs a release and verifies it. **Making A Project Refuse Unsigned Artifacts** turns on enforcement and reads Harbor's refusal. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain how Harbor stores a signature as an accessory of the signed artifact.
- Say what replaced Notary v1 and Docker Content Trust in Harbor, and since which version.
- Create a Cosign key pair and keep the private key safe with a password.
- Sign an artifact by its digest without the public transparency log, and verify the signature.
- Make a project refuse every artifact without a Cosign signature.
- Read Harbor's refusal of an unsigned pull and explain why a signer can still pull it.

## Before you start

You need to know what an image, a tag and a digest are, and you will use `curl` and `jq` against a REST API.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `cosign` 3.1.4, `regctl`, the `harbor` command-line tool, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds these artifacts, and none is signed:

| Project | Repository | Tag | What it is |
| --- | --- | --- | --- |
| `release` | `podinfo` | `6.15.0` | The current release of the `podinfo` web application, `linux/amd64` only |
| `release` | `podinfo` | `6.14.1-rc` | A release candidate that must never reach production, `linux/amd64` only |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
