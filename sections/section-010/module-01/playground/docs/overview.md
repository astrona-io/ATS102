# Overview: Scan Artifacts For Vulnerabilities With Trivy (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies some artifacts into it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`. Its built-in Trivy adapter, the `trivy` component, is the default scanner.
- The **workstation** pod in the namespace `workstation`, with the `harbor` command-line tool, `regctl`, `cosign`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`inventory`** with two artifacts that nobody has scanned:

  | Artifact | What it is |
  | --- | --- |
  | `inventory/podinfo:6.0.0` | An old release of the `podinfo` web application, `linux/amd64` only, with many known vulnerabilities |
  | `inventory/podinfo:6.15.0` | A recent release, `linux/amd64` only |

- The project **`warmup`**, with one scanned artifact. The playground scanned it so that the Trivy database is already downloaded.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell. `api` calls the Harbor REST API as `admin`. `scan_summary` prints the scan status and the count per severity of one tag in `inventory/podinfo`.

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
scan_summary() {
  api "$API/projects/inventory/repositories/podinfo/artifacts/$1?with_scan_overview=true" \
    | jq -c '[.scan_overview[]? | {scan_status, summary: .summary.summary}]'
}
```

Use them like this: `scan_summary 6.0.0`. Sign the `harbor` tool in once per workstation pod with `harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin`.

## Practice tasks

- Scan `6.15.0` with `harbor artifact scan start inventory/podinfo/6.15.0` and follow `scan_summary 6.15.0` until it reads `Success`.
- List the packages behind the High findings of `6.0.0`, each package once, with `jq` and `unique`.
- On your machine, scale the Trivy adapter down with `kubectl -n harbor scale statefulset harbor-trivy --replicas=0`, start a scan, and watch the `trivy` entry of `curl -s https://harbor.localtest.me:8443/api/v2.0/health` in the workstation. Predict the final `scan_status`, then scale it back to `1`.
- Turn on scan on push for `inventory`, copy `podinfo:6.14.1` in with `regctl image copy --platform linux/amd64`, and compare `push_time` with the scan's `start_time`.
- Copy `podinfo:6.14.1` into `inventory` without `--platform` as the tag `6.14.1-all`. Look at the artifact's `type` and `references` in the API, and find out where Harbor puts the scan reports of an image index.
