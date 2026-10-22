# Overview: Generate And Read Software Bills Of Materials (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies some artifacts into it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`. Its Trivy adapter generates SBOMs as well as vulnerability reports.
- The **workstation** pod in the namespace `workstation`, with `regctl`, the `harbor` command-line tool, `cosign`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`inventory`** with `podinfo:6.0.0` and `podinfo:6.15.0`, both `linux/amd64` only and both without an SBOM. Automatic SBOM generation is off.
- The project **`warmup`**, scanned once so that the Trivy database is already downloaded.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell. `api` calls the Harbor REST API as `admin`. `get_sbom` downloads the SPDX document of one tag in `inventory/podinfo` to the file `<tag>.spdx.json`.

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
get_sbom() {
  regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345 >/dev/null 2>&1
  sbom_digest=$(api "$API/projects/inventory/repositories/podinfo/artifacts/$1?with_sbom_overview=true" | jq -r '.sbom_overview.sbom_digest')
  regctl artifact get -m application/spdx+json "harbor.localtest.me:8443/inventory/podinfo@$sbom_digest" > "$1.spdx.json"
}
```

Use them like this: `get_sbom 6.15.0`, then `jq '.packages | length' 6.15.0.spdx.json`.

## Practice tasks

- Generate SBOMs for both tags and compare the number of packages. Which packages appear in `6.0.0` but not in `6.15.0`?
- List the license of each package (`licenseConcluded` or `licenseDeclared`) and count how many packages use each license.
- Find the package URL of every Alpine package in the `externalRefs` of the SPDX document.
- Generate an SBOM for an artifact twice and look at `sbom_digest` and the accessories each time. Does Harbor keep two SBOMs?
- Delete `inventory/podinfo:6.0.0` after it has an SBOM, and check whether its SBOM accessory is still in the repository.
