# Summary

A registry stores whatever it is given, so Harbor needs a scanner to say what is inside an artifact and which known security flaws it carries. This module showed how Harbor does that with Trivy, how to read the result, and how to make it happen without anyone asking.

## What you learned

A scan is a background job that passes through several components. `core` accepts the request and stores the report. `jobservice` runs the job and calls the Trivy adapter, the `trivy` component, which pulls the artifact's layers from `registry`, lists the packages, and compares them with the Trivy database. That database comes from `mirror.gcr.io` or `ghcr.io`, is rebuilt every 12 hours, and must be downloaded before the first scan. When a scan fails, the health endpoint `/api/v2.0/health` shows which component is down.

You start a scan with `harbor artifact scan start <project>/<repository>/<reference>` or with a `POST` to the artifact's `scan` endpoint. The command returns at once. The scan overview, read with `with_scan_overview=true`, shows the `scan_status`, the worst severity and a count per severity. The full report is the addition `additions/vulnerabilities`, with one entry per CVE: its ID, severity, package, installed version and fixed version. That list tells the owner of the image what to rebuild.

Scan on push is the project setting `auto_scan`. It scans each new artifact within seconds of the push, which the gap between `push_time` and the scan's `start_time` proves. It does nothing for artifacts that were already in the project. A scan-all schedule, set with `harbor scan-all update-schedule`, scans every artifact in every project again, so reports follow the changing database. The key facts to remember are these:

- Harbor scans nothing until a person, a push or a schedule asks for it.
- The scan runs in `jobservice` and the `trivy` adapter, not in `core`.
- A report is only as current as the Trivy database it used.
- Harbor's cron expressions have six fields, starting with seconds.

<!-- astrona:playground:destroy -->
