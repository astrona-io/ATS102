# Scan States, Stopping A Scan And The Scan Log

Scans run in the background, so the only way to learn what they are doing is to read their state. A scan that sits in one state for too long, or ends in a state nobody expected, needs a place to look. This part names the states, stops a scan that is running, and reads the log that the scan wrote. It closes the module with the questions to ask in the order that finds a failed scan fastest.

## The states of a scan

Every scan report has a `scan_status`. The overview of an artifact shows it, with the time the scan started and ended and the percentage that is done.

| State | What it means |
| --- | --- |
| `Pending` | `core` created the scan, and `jobservice` has not started the job yet |
| `Running` | The job runs, and the Trivy adapter works on the artifact |
| `Success` | The report is stored and complete |
| `Error` | The job ended with a failure, for example because the adapter was not running |
| `Stopped` | A person stopped the scan before it finished |

A scan stays in `Pending` when the job queue is full or `jobservice` does not run. A scan in `Running` for longer than the adapter's timeout ends in `Error`. The setting that controls this time is `SCANNER_TRIVY_TIMEOUT`.

## Follow a scan and stop it

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Define the helper, then start the scan of `6.15.0` and read the status right away:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
BASE="$API/projects/inventory/repositories/podinfo/artifacts/6.15.0"
api -X POST "$BASE/scan"
api "$BASE?with_scan_overview=true" | jq '.scan_overview[] | {scan_status, complete_percent, start_time, end_time}'
```

A scan of a small image ends within seconds when the database is present, so you may already read `Success`. Stopping works only while the scan runs. Start another scan and stop it at once:

```sh
api -X POST "$BASE/scan"; api -X POST "$BASE/scan/stop"
api "$BASE?with_scan_overview=true" | jq '[.scan_overview[]?.scan_status][0]'
```

If the scan was still `Pending` or `Running` when the stop request reached `core`, the status reads `Stopped`. If the scan had already finished, the stop request has nothing to stop and the status stays `Success`. To get a final `Success` again after a `Stopped` scan, start a new scan.

## Read the scan log

Each scan keeps a log of what the adapter did. The log belongs to the report, so first read the `report_id` from the overview, then ask for the log of that report:

```sh
REPORT_ID=$(api "$BASE?with_scan_overview=true" | jq -r '[.scan_overview[]?.report_id][0]')
api "$BASE/scan/$REPORT_ID/log"
```

The log is plain text. For a successful scan it shows the steps of the scan. For a failed scan it holds the error that the adapter returned, which is the first thing to read when `scan_status` is `Error`. The same text is available in the portal, behind the scan status of the artifact.

## Where to look when a scan fails

Work from the outside in, and stop at the first place that shows the cause:

1. The status and the log of the report: it often names the cause, for example a timeout or an artifact the adapter cannot pull.
2. The health endpoint, `GET /api/v2.0/health`, which shows whether the `trivy` and `jobservice` components are healthy.
3. The pods in the `harbor` namespace: `kubectl -n harbor get pods` shows a `harbor-trivy-0` pod that is not ready.
4. The logs of the pod: `kubectl -n harbor logs harbor-trivy-0` shows the database download or the Trivy error.

```sh
kubectl -n harbor get pods
```

Run the last command on your machine. All the pods of a healthy Harbor are `Running` and ready. The order matters because each step costs more time than the one before it.

You can now name the states of a scan, stop a scan, read its log, and follow a short order of checks when a scan fails. Together with the earlier parts, you can choose the scanner, set it up, read its findings and find out why it failed.

## Common pitfalls

> [!WARNING]
> - **Stopping a scan that has already finished.** The request has nothing to stop, and the report stays as it was.
> - **Reading the log before the scan has a `report_id`.** Wait until the overview shows one.
> - **Starting a second scan while one runs.** Harbor refuses the request with a conflict. Wait or stop the first one.
> - **Looking at the pods first.** The log of the report is faster and often names the cause on its own.
