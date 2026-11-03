# Overview: Signature Annotations, Attestations And Key Rotation (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies some artifacts into it, signs them, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `cosign` 3.1.4, `regctl`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`release`** with `release/podinfo:6.14.1` and `release/podinfo:6.15.0`, both `linux/amd64` only and both signed with the build key.
- Two key pairs in the workstation:

  | Directory | Password | Use |
  | --- | --- | --- |
  | `/root/build` | `build-signing-password` | The key that signed the releases |
  | `/root/security` | `security-signing-password` | An unused key for the security team |

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
```

Sign without the public log in this cluster: add `--use-signing-config=false --tlog-upload=false` to `cosign sign` and `cosign attest`, and `--insecure-ignore-tlog=true` to the verify commands.

## Practice tasks

- Run `cosign tree` on both releases and compare it with the accessories that the Harbor API lists.
- Verify `6.15.0` with the build key and read the digest from the output. Compare it with `regctl image digest`.
- Sign `6.14.1` with the build key and two annotations. Verify with `-a` for each, and with a wrong value to see the refusal.
- Sign `6.15.0` with the security key and the annotation `approved-by=security`, and verify both signatures.
- Attach a custom attestation with a test result, verify it with `--type custom`, and decode the payload.
- Make a new key pair, sign with it, and verify with the old and the new public key.
- Delete one signature accessory through the API and check which verification fails.
