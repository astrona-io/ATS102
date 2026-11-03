# Scanner Registrations And The Project Scanner

Harbor does not have a scanner built into `core`. It calls a scanner over HTTP, and it learns where that scanner is from a list of registrations. This part shows that list, explains what one entry holds, registers a second entry and moves one project to it. It matters because every report in Harbor comes from one registration, and a project with the wrong one gets no report or a different one.

## What a registration holds

A scanner registration is one row in Harbor's database. It holds a name, a URL, the way Harbor signs in to the scanner, and two flags: `is_default` and `disabled`. Harbor talks to the scanner with the **Scanner Adapter API**, a small REST interface that every Harbor scanner must offer. The adapter answers `GET /api/v1/metadata` with its name, vendor, version and the report types it can produce. It accepts scan requests on `POST /api/v1/scan` and returns reports on `GET /api/v1/scan/{id}/report`.

Exactly one registration is the **system default**. A project that has no scanner of its own uses the default. Harbor installed with Helm already has one registration, `Trivy`, whose URL is the Service `http://harbor-trivy:8080`.

## List the registrations

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define a helper that calls the Harbor REST API as `admin`, and list the registrations:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/scanners" | jq '.[] | {uuid, name, url, is_default, disabled, health, vendor, version}'
```

You see one registration. Its `is_default` is `true`, and `health` tells you whether Harbor reached the adapter at the last check. The `uuid` is the identifier the next commands use. Save it in a variable:

```sh
DEFAULT_UUID=$(api "$API/scanners" | jq -r '.[] | select(.is_default) | .uuid')
echo "$DEFAULT_UUID"
```

Harbor can also tell you what the scanner is able to do. The metadata of a registration lists the artifact types it accepts and the report types it produces:

```sh
api "$API/scanners/$DEFAULT_UUID/metadata" | jq '{scanner, capabilities}'
```

The capabilities name the vulnerability report and the SBOM report. This is how Harbor knows that this scanner can create an SBOM as well as a vulnerability report.

## Register a second scanner

An administrator adds a registration with a `POST` to `/scanners`. The body needs a name and a URL. Harbor asks the URL for its metadata when it saves the entry, so the request fails if nothing answers there. The Trivy adapter is also reachable under its full Service name, which is a different URL from the one already registered, so you can register it again under a new name:

```sh
api -X POST "$API/scanners" -d '{"name":"trivy-second","url":"http://harbor-trivy.harbor.svc.cluster.local:8080","description":"The same adapter under a second name"}'
api "$API/scanners" | jq '.[] | {name, url, is_default}'
```

The list now has two entries, and only `Trivy` is the default. Adding a registration never changes the default. In a real Harbor the second entry would point at a different scanner, for example a scanner that checks a different set of packages. The steps are the same.

## Choose the scanner of one project

Harbor lists the registrations a project may use as its **candidates**. Then a `PUT` to the project's `scanner` resource assigns one. Use the `uuid` of the new entry:

```sh
SECOND_UUID=$(api "$API/scanners" | jq -r '.[] | select(.name == "trivy-second") | .uuid')
api "$API/projects/inventory/scanner/candidates" | jq '.[].name'
api -X PUT "$API/projects/inventory/scanner" -d "{\"uuid\":\"$SECOND_UUID\"}"
api "$API/projects/inventory/scanner" | jq '{name, url}'
```

The last command shows that `inventory` now uses `trivy-second`. A scan of an artifact in `inventory` goes to that URL. Projects without their own setting keep using the default. To return `inventory` to the default scanner, assign the default `uuid` again:

```sh
api -X PUT "$API/projects/inventory/scanner" -d "{\"uuid\":\"$DEFAULT_UUID\"}"
```

You can now list the scanner registrations, read what a scanner can do, register another one and choose the scanner of one project. The default scanner stays the same until an administrator changes it. What you have not yet seen is how the Trivy adapter itself decides what to report, and that is set outside Harbor, in the adapter's environment.

## Common pitfalls

> [!WARNING]
> - **Registering a URL that Harbor cannot reach.** Harbor checks the metadata of the URL when it saves the entry, and the request fails.
> - **Expecting a new registration to become the default.** It does not. Set the default on purpose.
> - **Changing the project scanner and expecting old reports to change.** Existing reports stay as they are until the artifact is scanned again.
> - **Disabling the scanner of a project that scans on push.** Every push then ends with a failed scan.
