# Summary

A default Harbor scans well enough, but a report is only as useful as the setup behind it. This module showed how to choose the scanner, set the Trivy adapter up, read what it finds, and follow a scan that goes wrong.

## What you learned

Harbor calls a scanner through a scanner registration, which holds a name and a URL. Exactly one registration is the system default, and a project can use another one. A new registration is never the default, and changing the scanner of a project changes only later scans.

The Trivy adapter reads its settings from environment variables that start with `SCANNER_TRIVY_`. They decide which severities and package types a report lists, whether findings without a fix are hidden, whether the database is downloaded, and how long a scan may run. A change with `kubectl set env` restarts the adapter pod and is lost at the next `helm upgrade` unless the Helm values hold the same setting. A report changes only after a new scan, and a setting that hides findings changes the report, not the image.

A finding has an identifier, a package, an installed version, a fixed version, a severity and a CVSS score. The severity comes from the data source Trivy trusts, so it can differ from the band of the score, and Harbor's pull rules compare the severity. A scan is in one of the states `Pending`, `Running`, `Success`, `Error` or `Stopped`. The log of the report is the first place to read when a scan fails. The key facts to remember are these:

- Every report comes from one scanner registration.
- Trivy settings live in the adapter's environment, not in the portal.
- An empty fixed version means no fix exists yet.
- Stopping a scan works only while it runs.

<!-- astrona:playground:destroy -->
