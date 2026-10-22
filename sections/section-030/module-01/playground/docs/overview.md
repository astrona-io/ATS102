# Overview: Sign Artifacts With Cosign And Enforce Signatures (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies some artifacts into it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `cosign` 3.1.4, `regctl`, the `harbor` command-line tool, `oras`, `curl` and `jq`. It trusts Harbor's certificate. Files you create in it, such as a key pair in `/root`, are lost when the pod restarts.
- The project **`release`** with two unsigned artifacts, both `linux/amd64` only:

  | Artifact | What it is |
  | --- | --- |
  | `release/podinfo:6.15.0` | The current release |
  | `release/podinfo:6.14.1-rc` | A release candidate |

- Signature enforcement is off for `release`.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell. `api` calls the Harbor REST API as `admin`. `accessories` lists the accessory types of one tag in `release/podinfo`. `try_pull` pulls one tag's manifest with `regctl` and says whether Harbor allowed it.

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
accessories() { api "$API/projects/release/repositories/podinfo/artifacts/$1/accessories" | jq -r '.[].type'; }
try_pull() {
  regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345 >/dev/null 2>&1
  regctl manifest get "harbor.localtest.me:8443/release/podinfo:$1" > /dev/null && echo "$1: allowed"
}
```

Use them like this: `accessories 6.15.0`, `try_pull 6.14.1-rc`.

## Practice tasks

- Create a key pair in `/root`, sign `6.15.0` by its digest, and verify it with `cosign verify --key cosign.pub --insecure-ignore-tlog=true`.
- Turn on Cosign enforcement, then run `try_pull` for both tags and read Harbor's message for the refused one.
- Make a second key pair in `/root/other`, sign `6.14.1-rc` with it, and verify it with the first public key. What does Harbor's enforcement say about it, and what does `cosign verify` say?
- Push a new image to the tag `6.15.0` (for example `podinfo:6.14.1` with `regctl image copy --platform linux/amd64`) and pull it. Is the tag still signed?
- Turn on Notation enforcement as well with `harbor project config update release --enable-content-trust true`, pull the signed release, and explain the result.
