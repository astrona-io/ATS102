# Sign And Verify With Notation

Cosign is not the only signing tool that Harbor understands. **Notation** is the command-line tool of the Notary Project, a CNCF project. It signs container images with X.509 certificates, and it checks signatures against a trust policy that you write down. Harbor stores a Notation signature as an accessory of the signed artifact, the same way it stores a Cosign signature, and it can refuse artifacts that have no Notation signature.

The two tools answer the same question, "who vouched for this digest", in different ways. Cosign checks a signature against a public key that you pass on the command line. Notation checks it against a **trust policy**, a JSON file that says which certificates you trust, for which repositories, and how strictly to check. Keep one sentence in mind: **with Notation, the trust policy decides what a valid signature is, not the person who runs the command.**

The module has four parts. **Notation And Cosign Side By Side** compares the models. **Keys, Certificates And Signing** creates a test certificate and signs a release. **Trust Policies And Verification** writes the policy and verifies, and a graded lab follows it. **Enforcing Notation Signatures In Harbor** turns on the project setting and reads the refusal.

## Learning objectives

After this module you can:

- Say how a Notation signature differs from a Cosign signature in what it uses and where the trust decision lives.
- Create a test key and certificate, and sign an artifact by its digest with `notation sign`.
- List and inspect the signatures of an artifact with `notation ls` and `notation inspect`.
- Write a trust policy with a trust store, trusted identities and a verification level.
- Verify an artifact with `notation verify`, and explain why a missing policy makes verification fail.
- Turn on Notation enforcement for a Harbor project and read the refusal of an unsigned pull.

## Before you start

You need to know what a digest is and what an accessory is in Harbor. You will use `curl` and `jq` against a REST API.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `notation` 1.3.2, `cosign`, `regctl`, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds the project `release` with `release/podinfo:6.15.0`, `linux/amd64` only and unsigned.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
