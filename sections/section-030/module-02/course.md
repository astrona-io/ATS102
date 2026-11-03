# Signature Annotations, Attestations And Key Rotation

One signature says that someone holding a key vouched for a digest. It does not say who, why, or what was checked. Real release processes need more: the build system signs, then the security team approves, and a reader of the registry wants to see both. Keys also age, leak and change hands, so a signing process needs a plan for replacing them.

This module goes beyond the first signature. A **signature** is a statement, made with a private key, about one digest. An **annotation** is a key and value pair that the signer adds to the signature, such as `approved-by=security`. An **attestation** is a signed statement about an artifact that carries data, such as a build record or a test result, instead of only vouching for the digest. **Key rotation** is replacing a signing key with a new one. Keep one sentence in mind: **a signature proves who signed a digest, and an annotation or attestation says what they claim about it.**

The module has four parts. **What A Signature Proves** shows what is stored and what a check really tells you. **Annotations And More Than One Signer** adds a second signature and a claim, and a graded lab follows it. **Attestations** signs a statement with data and reads it back. **Keys, Keyless Signing And Rotation** covers key hygiene and the replacement of a key.

## Learning objectives

After this module you can:

- Show with `cosign tree` which signatures and attestations an artifact has.
- Explain what a successful `cosign verify` proves and what it does not.
- Add an annotation to a signature and require it when verifying.
- Put two signatures from two keys on one artifact and verify each one.
- Sign an attestation with a predicate, and verify it and read its content.
- Describe keyless signing, and say why this course signs with keys.
- Rotate a signing key without a gap in verification.

## Before you start

You need the basics of `cosign sign` and `cosign verify` with a key pair, and you need to know that Harbor stores a signature as an accessory.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `cosign` 3.1.4, `regctl`, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds the project `release` with `release/podinfo:6.14.1` and `release/podinfo:6.15.0`, both signed with the build key. The build key pair is in `/root/build` in the workstation. A second pair for the security team is in `/root/security`. The key passwords are `build-signing-password` and `security-signing-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
