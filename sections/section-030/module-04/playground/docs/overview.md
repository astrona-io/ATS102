# Overview: Replicate Signed Artifacts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, seeds a signed artifact, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `cosign`, `regctl`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`staging`** with `staging/podinfo:6.15.0`, signed with the Cosign key pair in `/root/build` (password `build-signing-password`) and carrying an SBOM.
- The empty project **`prod`**.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
```

## Practice tasks

- List the accessories of the source artifact and note the digest.
- Create the endpoint and the rule `staging-to-prod`, run it, and wait for `Succeed`.
- Compare the digests, list the accessories in `prod`, and verify the signature there.
- Change the filter to a tag that does not exist, run again, and read the total.
- Turn override off and run twice. Compare the task results.
- Turn on a signature requirement in `prod` before running, copy an unsigned artifact, and read the task log.
- Create a rule with a scheduled trigger and read the trigger back.
