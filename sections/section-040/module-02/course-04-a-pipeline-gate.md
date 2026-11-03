# A Pipeline Gate

A release pipeline asks one question before it deploys: is this image allowed to go on? Robot accounts, signatures and the vulnerability report each hold a piece of the answer. A gate is a short script that reads those pieces and exits with a failure when one is missing. This part writes one, and shows why the checks come in this order.

## What the gate checks

The gate takes a project, a repository and a tag, and checks three things:

1. The artifact has a vulnerability report, and the scan finished.
2. The report has no Critical finding that a newer package fixes.
3. The tag is the one the pipeline expects, identified by its digest.

A script exits with `0` for success and a non-zero code for failure, and a pipeline stops on a non-zero code. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Write the gate

Save this as `gate.sh`. It reads the report through the REST API, so it needs a credential that may read it; this example uses the administrator for brevity, and a real pipeline uses a robot with the matching permissions:

```sh
cat > gate.sh <<'SCRIPT'
#!/bin/sh
# usage: gate.sh PROJECT REPOSITORY TAG
set -eu
API=https://harbor.localtest.me:8443/api/v2.0
BASE="$API/projects/$1/repositories/$2/artifacts/$3"
get() { curl -fsS -u admin:Harbor12345 "$@"; }

status=$(get "$BASE?with_scan_overview=true" | jq -r '[.scan_overview[]?.scan_status][0] // "None"')
if [ "$status" != "Success" ]; then
  echo "gate: scan status is $status, not Success" >&2
  exit 2
fi

blocking=$(get "$BASE/additions/vulnerabilities" | jq '[.[].vulnerabilities[] | select(.severity == "Critical" and ((.fix_version // "") != ""))] | length')
if [ "$blocking" -gt 0 ]; then
  echo "gate: $blocking Critical finding(s) with a fix" >&2
  exit 1
fi
echo "gate: $1/$2:$3 passed"
SCRIPT
chmod +x gate.sh
```

The script stops on its own errors because of `set -eu`, and it uses different exit codes: `2` when there is no finished scan and `1` when there is a blocking finding. A pipeline can show the difference to a person.

## Run it

Scan the artifact first, wait for `Success`, and then run the gate:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
curl -fsS -u admin:Harbor12345 -X POST "$API/projects/inventory/repositories/podinfo/artifacts/6.15.0/scan"
./gate.sh inventory podinfo 6.15.0; echo "exit code $?"
```

Run it again right after the scan starts and you can see exit code `2`, because the scan has not finished. Read the exit code each time; the text alone does not tell a pipeline what to do.

## Fail closed

A gate must refuse when it cannot decide. The script above does: no report, an unfinished report or an unreachable API all end in a failure, because `set -eu` turns a failed `curl` into a stop. The opposite mistake is a gate that prints a warning and exits `0` when it cannot reach Harbor. That gate passes everything during an outage.

## Pin the digest

Between the check and the deploy, a tag can move unless an immutability rule protects it. Make the gate print the digest it checked, and make the deploy step use that digest and not the tag. With an immutable `6.*` rule the tag cannot move, and with the digest the deploy does not depend on it either. Two protections for the same risk are the point.

You now know how to turn a report and a policy into a pass or fail, and why a gate must fail closed and pin a digest.

## Common pitfalls

> [!WARNING]
> - **Passing on an empty report.** No report means the scan has not run. Check the status first.
> - **Printing a warning and exiting `0`.** The pipeline never sees the failure.
> - **Counting findings without a fix.** They block the release forever and nobody can act on them.
> - **Deploying the tag after checking the digest.** Deploy the digest.
