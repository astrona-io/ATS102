# Generating, Downloading And Reading An SBOM

An SBOM only helps if it exists for every image and you can read it when you need it. This part asks Harbor for an SBOM of one image, downloads the SPDX document, and answers real questions from it with `jq`. Then it turns on SBOM generation on push, so that every new image gets one without anyone asking.

## Ask Harbor for an SBOM

Harbor generates an SBOM with the same machinery it uses for vulnerability scans. You send a `POST` to the artifact's `scan` endpoint, and the body says which kind of scan you want: `{"scan_type": "sbom"}`. Without a body, the same endpoint starts a vulnerability scan.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define the helper and ask for an SBOM of `podinfo:6.15.0`:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/projects/inventory/repositories/podinfo/artifacts/6.15.0/scan" -d '{"scan_type":"sbom"}'
```

The request returns at once with no body. As with a scan, `core` hands the work to `jobservice`, which asks the Trivy adapter for the SBOM and stores it as an accessory. Follow the status in the SBOM overview:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.15.0?with_sbom_overview=true" \
  | jq '.sbom_overview | {scan_status, sbom_digest, start_time, end_time}'
```

`scan_status` reads `Running` first and then `Success`. At that point `sbom_digest` holds the digest of the new SBOM accessory. That digest is how you reach the document.

## Download the SPDX document

The SBOM accessory is an OCI artifact in the same repository, so any OCI client can fetch it by its digest. `regctl artifact get` downloads the content of an artifact, and `-m` picks the layer by its media type, here `application/spdx+json`. Save the digest in a variable first, then download the document to a file:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
SBOM_DIGEST=$(api "$API/projects/inventory/repositories/podinfo/artifacts/6.15.0?with_sbom_overview=true" | jq -r '.sbom_overview.sbom_digest')
regctl artifact get -m application/spdx+json "harbor.localtest.me:8443/inventory/podinfo@$SBOM_DIGEST" > podinfo-6.15.0.spdx.json
```

The file `podinfo-6.15.0.spdx.json` now holds the whole SPDX document. Look at its header first:

```sh
jq '{spdxVersion, name, created: .creationInfo.created, creators: .creationInfo.creators, packages: (.packages | length)}' podinfo-6.15.0.spdx.json
```

`spdxVersion` names the SPDX version, `creators` names the Trivy version that wrote it, and `packages` counts the entries. The count includes Alpine packages from the base image and Go modules compiled into the `podinfo` binary.

## Answer questions from the SBOM

Now use the document the way you would during an incident. List every package with its version, as one line each, sorted by name:

```sh
jq -r '.packages[] | select(.versionInfo != null) | [.name, .versionInfo] | @tsv' podinfo-6.15.0.spdx.json | sort
```

The list names each package once, with the version that is in the image. To answer the question from the start of this module, whether the image contains a given library, filter by name. For example, to find any package whose name contains `zlib` or `ssl`:

```sh
jq -r '.packages[] | select(.name | test("zlib|ssl")) | [.name, .versionInfo] | @tsv' podinfo-6.15.0.spdx.json
```

The answer comes from the file alone. No scan ran, and no database was consulted: the SBOM records what was in the image when it was built, and that never changes.

## Generate SBOMs on push

Generating SBOMs by hand has the same problem as scanning by hand: nobody remembers. The project setting `auto_sbom_generation` makes Harbor generate one for every artifact pushed to the project. The `harbor` command-line tool v0.0.27 has no flag for it, so set it through the REST API with a `PUT` of the project's metadata:

```sh
api -X PUT "$API/projects/inventory" -d '{"metadata":{"auto_sbom_generation":"true"}}'
api "$API/projects/inventory" | jq .metadata
```

The metadata now includes `"auto_sbom_generation": "true"`. Push a new artifact to test it, copying `podinfo:6.14.1` for one platform, and do not ask for anything:

```sh
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:6.14.1
api "$API/projects/inventory/repositories/podinfo/artifacts/6.14.1?with_sbom_overview=true" \
  | jq '{push_time, sbom: (.sbom_overview | {scan_status, start_time})}'
```

The SBOM job started seconds after `push_time`, without a request from you. That gap proves the generation was triggered by the push. Like scan on push, the setting does nothing for artifacts that were already there: `6.0.0` still has no SBOM until you ask for one.

You can now generate an SBOM, follow its status, download the SPDX document by its digest, and answer real questions from it. You can also make a project generate SBOMs on push, and prove that it did. The open question for a release process is how to combine this with scanning, so that every artifact has both.

## Common pitfalls

> [!WARNING]
> - **Sending the `scan` request without a body.** That starts a vulnerability scan. An SBOM needs `{"scan_type":"sbom"}`.
> - **Downloading the image instead of the SBOM.** Use the `sbom_digest` from the SBOM overview, not the image digest.
> - **Looking for an `auto_sbom` flag in the `harbor` command-line tool.** v0.0.27 has none; set `auto_sbom_generation` through the REST API.
> - **Expecting old artifacts to get SBOMs on push.** Generate those once by hand.

## Your mission: Generate An SBOM For Every Pushed Artifact

You can now generate and read SBOMs, by hand and on push. The graded lab gives you the project `inventory` without any SBOM and asks you to turn on generation on push, push `podinfo:6.14.1` so that it gets an SBOM on its own, and give `6.15.0` an SBOM by hand.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-020-01
astrona start ats-102-playground-020-01
```
