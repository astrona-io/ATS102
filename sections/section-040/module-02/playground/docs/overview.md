# Overview: Robot Accounts And Immutable Tags (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies an artifact into it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `regctl`, `cosign`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`inventory`** with `inventory/podinfo:6.15.0`, `linux/amd64` only. It has no robot account and no tag immutability rule.
- The project **`warmup`**, with one scanned artifact, so that the Trivy database is already downloaded.

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

Robot names contain a `$`. Put them in single quotes, for example `'robot$inventory+ci-pull'`.

## Practice tasks

- Create a pull-only robot with a duration of 14 days. Read it back and compare `creation_time` and `expires_at`.
- Sign in to the registry with the robot using `regctl registry login`, and pull a digest. Try to push, and read the refusal.
- Request a token for a repository the robot has no access to, and print the HTTP status.
- Refresh the secret with a `PATCH`, and check that the old secret no longer works.
- Create a system-level robot with the namespace `*`, and compare its listing with a project robot.
- Create an immutability rule for `6.*`. Try to overwrite `6.15.0` with another image, compare the digests, and push a tag outside the pattern.
- Disable the rule, overwrite the tag, and then enable it again.
- Save the gate script from the reading, scan `6.15.0`, and run it. Run it right after the scan starts and read the exit code.
