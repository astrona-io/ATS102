# Solution: Get A Successful Scan For Every Release

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the Trivy adapter runs and is healthy, every artifact in `release/podinfo` has a successful report, and a new push is scanned on its own.

## Step 1: Read the failed scans

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define the API helper and read the scan status of both releases:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
for tag in 6.14.1 6.15.0; do
  printf '%s ' "$tag"
  api "$API/projects/release/repositories/podinfo/artifacts/$tag?with_scan_overview=true" \
    | jq -c '[.scan_overview[]? | {scan_status, start_time}]'
done
```

Both read `Error`. A scan error says the job could not finish; it does not say why.

## Step 2: Ask Harbor which component is down

```sh
curl -s https://harbor.localtest.me:8443/api/v2.0/health | jq '.components[] | {name, status}'
```

Every component is `healthy` except `trivy`, which is `unhealthy`. The scan jobs ran in `jobservice`, which could not reach the Trivy adapter.

## Step 3: Bring the Trivy adapter back

On your machine, look at the StatefulSet that runs the adapter:

```sh
kubectl -n harbor get statefulset harbor-trivy
```

It has `0/0` ready replicas: someone scaled it to zero. Scale it back to one and wait for it:

```sh
kubectl -n harbor scale statefulset harbor-trivy --replicas=1
kubectl -n harbor rollout status statefulset/harbor-trivy --timeout=10m
```

Run the health command in the workstation again until `trivy` reads `healthy`. The Trivy database is kept inside the pod, so a fresh pod may download it again before the next scan finishes.

## Step 4: Turn on scan on push

In the workstation shell:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config update release --auto-scan true
```

## Step 5: Scan both releases again

A failed scan is not retried by itself. Start a new scan of each release:

```sh
harbor artifact scan start release/podinfo/6.14.1
harbor artifact scan start release/podinfo/6.15.0
```

Run the loop from step 1 again until both read `Success`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

The grader copies a new tag, `grader-push`, into `release/podinfo` and waits for Harbor to scan it on its own.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Register a second scanner and make it the default | The task forbids it, and the broken built-in adapter is still there |
| Start the scans again without fixing the adapter | They end in `Error` again |
| Fix the adapter and rescan, but leave scan on push off | The next release still arrives without a report |
| Delete the artifacts with failed scans | The releases are gone, and nothing is fixed |

## Common mistakes

- Looking for the problem in `core`. The scan runs in `jobservice` and the Trivy adapter; the health endpoint names the component that is down.
- Expecting failed scans to retry once the adapter is back. Start them again.
- Starting the scans before the adapter is `healthy`. They fail again.
