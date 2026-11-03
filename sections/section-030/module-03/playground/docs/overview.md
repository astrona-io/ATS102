# Overview: Sign And Verify With Notation (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies an artifact into it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `notation` 1.3.2, `cosign`, `regctl`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`release`** with `release/podinfo:6.15.0`, `linux/amd64` only and unsigned.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
notation login -u admin -p Harbor12345 harbor.localtest.me:8443
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
```

## Practice tasks

- Print `notation version`, and list the keys and certificates before you create any.
- Generate a test certificate, sign the release by digest, and run `notation ls` and `notation inspect`.
- Read the accessories of the release through the API and find the type.
- Write a trust policy, import it, and verify. Change the trust store name, import it again, and read the failure.
- Try each verification level, and sign a second copy of the image with another certificate to see the trusted identities in action.
- Create a project, turn on `enable_content_trust`, and request a manifest with a bearer token. Read the `412`, sign the artifact, and request it again.
