# Scanning An Artifact And Reading The Report

A scan is only useful if you can read what it found and act on it. The web portal shows a coloured bar per artifact, but a pipeline, a script or an audit needs the same information as data. This part starts a scan from the command line, waits for it, and reads the vulnerability report through the Harbor REST API, from the one-line summary down to each CVE.

## Start a scan

The project `inventory` holds `podinfo:6.0.0`, an old release, and `podinfo:6.15.0`, a recent one. Neither has been scanned yet. Scan the old one first, because it will have the most to report.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, sign the `harbor` command-line tool in, if you have not done so in this shell's pod yet, and start the scan. The tool names an artifact as `<project>/<repository>/<reference>`, where the reference is a tag or a digest:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor artifact scan start inventory/podinfo/6.0.0
```

The command returns at once with a short confirmation. It does not wait for the result, because `core` only hands the scan to `jobservice` as a background job; the Trivy adapter does the work a little later.

## Wait for the result

The REST API shows the state of the scan in the artifact's **scan overview**. Define a helper in the workstation shell, so every API call carries the address and the lab-only credentials:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
```

Now read the overview of `6.0.0`. The query parameter `with_scan_overview=true` asks Harbor to include it, and `jq` keeps only the fields that matter here:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0?with_scan_overview=true" \
  | jq '.scan_overview[] | {scan_status, severity, complete_percent, summary: .summary.summary}'
```

The scan overview is an object keyed by the report's media type, so `.scan_overview[]` reaches into it without naming the key. While the scan runs, `scan_status` reads `Running` and `complete_percent` climbs. Run the command again until it reads `Success`. Then `severity` holds the worst severity found, and `summary` counts the findings per severity: `Critical`, `High`, `Medium`, `Low` and `Unknown`. For this old release, expect several High findings and probably some Critical ones; the exact numbers depend on the Trivy database of the day.

## Read the full report

The summary tells you how bad it is. The full report tells you what to fix. It is an **addition** of the artifact, a piece of extra data Harbor stores next to it, at the path `additions/vulnerabilities`. List the High and Critical findings, one line each:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq -r '.[].vulnerabilities[]
      | select(.severity == "High" or .severity == "Critical")
      | [.id, .severity, .package, .version, (.fix_version // "-")] | @tsv'
```

Each line names one CVE, its severity, the package it was found in, the version of that package in the image, and the first version that fixes it. Many lines name the same package, because one outdated package often carries several CVEs. A dash in the last column means nobody has published a fixed version yet.

These columns answer the practical question: what to change. A finding in a Go module such as `golang.org/x/net` is fixed by rebuilding the application with a newer module. A finding in an Alpine package such as `libcrypto3` is fixed by moving to a newer base image. The report does not fix anything; it tells the owner of the image where to look.

## Compare it with a recent release

One report is hard to judge on its own. Scan the recent release and compare the two summaries:

```sh
harbor artifact scan start inventory/podinfo/6.15.0
```

Wait until its `scan_status` is `Success`, using the same `api ... with_scan_overview=true` command with `6.15.0` instead of `6.0.0`. Then print both summaries next to each other:

```sh
for tag in 6.0.0 6.15.0; do
  printf '%s ' "$tag"
  api "$API/projects/inventory/repositories/podinfo/artifacts/$tag?with_scan_overview=true" \
    | jq -c '.scan_overview[].summary.summary'
done
```

The recent release has far fewer findings, and often none at High or Critical. That is the normal shape of a report over time: an image that nobody rebuilds collects CVEs, because the database learns about new flaws in packages that never change.

## The same data across all projects

The command-line tool can also read Harbor's **Security Hub**, a view that sums up the findings of every scanned artifact in every project. In the workstation shell, run:

```sh
harbor vulnerability summary --artifact --cve
```

It prints the totals per severity across Harbor, then the five most dangerous artifacts and the five most dangerous CVEs. On a large Harbor, this is where you start: it tells you which artifact to look at before you open any single report.

You can now start a scan, wait for it, and read both the summary and the full list of findings, as data you can filter and compare. The open question is how to stop doing this by hand: Harbor can scan every new artifact on its own, and every artifact again on a schedule.

## Common pitfalls

> [!WARNING]
> - **Reading the overview too early.** A scan runs in the background. `scan_status` must read `Success` before the counts mean anything.
> - **Expecting `harbor artifact scan start` to wait.** It only starts the job. Check the status afterwards.
> - **Scanning an image index and finding no report.** Harbor scans the platform images inside an index. Scan or read the platform manifest by its digest.
> - **Comparing reports from different days.** The Trivy database changes, so the same image can show new CVEs tomorrow. Scan both images on the same day before you compare them.
