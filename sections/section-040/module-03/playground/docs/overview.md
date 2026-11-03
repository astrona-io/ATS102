# Overview: Retention Policies (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, seeds three tags, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `cosign`, `regctl`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`inventory`** with `inventory/podinfo` at `6.0.0`, `6.14.1` and `6.15.0`, pushed in that order.

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

- List the tags with their push times.
- Create a policy that keeps the two newest pushes, dry run it, and read the tasks.
- Run it for real and check the survivors.
- Change K to 1 and push a new tag with `regctl image copy`, then dry run again.
- Add a second rule with the template `always` for the pattern `6.0.*` and see that the old tag survives.
- Add an immutable tag rule and run retention again.
