# Solution: Scan Every Pushed Artifact

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: scan on push is on, the scan-all schedule is daily, `6.14.1` was scanned on push, and every artifact has a successful report.

## Step 1: Look at the starting state

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, sign the `harbor` tool in and look at the project's settings and artifacts:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config list inventory
harbor artifact list inventory/podinfo
```

`auto_scan` is `false`, and the repository holds `6.0.0` and `6.15.0`. The tool may warn that no system keyring exists and that it uses a file instead; that is expected in the workstation.

## Step 2: Turn on scan on push

```sh
harbor project config update inventory --auto-scan true
harbor project config list inventory
```

`auto_scan` now reads `true`. From now on, `core` creates a scan job for every artifact pushed to `inventory`.

## Step 3: Scan everything daily

```sh
harbor scan-all update-schedule daily
harbor scan-all view-schedule
```

The schedule now has the type `Daily`. This is a system-wide job: it scans every artifact in every project, so reports follow the changing Trivy database.

## Step 4: Push the new release

`regctl` copies the image from `ghcr.io` into Harbor. `--platform linux/amd64` copies only that platform, so the new artifact is one image and not an index:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:6.14.1
```

Do not start a scan. Instead, check that Harbor started one, and compare the times:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory/repositories/podinfo/artifacts/6.14.1?with_scan_overview=true" \
  | jq '{push_time, scan: [.scan_overview[] | {scan_status, start_time}]}'
```

The scan's `start_time` is seconds after `push_time`, and `scan_status` reaches `Success` after a short while.

## Step 5: Scan what was there before

Scan on push did nothing for `6.0.0` and `6.15.0`, because they were pushed before it was on. Scan them once by hand:

```sh
harbor artifact scan start inventory/podinfo/6.0.0
harbor artifact scan start inventory/podinfo/6.15.0
```

Then check all three until each reads `Success`:

```sh
for tag in 6.0.0 6.14.1 6.15.0; do
  printf '%s ' "$tag"
  api "$API/projects/inventory/repositories/podinfo/artifacts/$tag?with_scan_overview=true" \
    | jq -r '[.scan_overview[]?.scan_status][0] // "None"'
done
```

Starting a scan-all run would also work, with `harbor scan-all run`, but it scans every project, which takes longer on a large Harbor.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Push `6.14.1` first, then turn on scan on push | `6.14.1` is never scanned on push; the grader sees a scan that started long after the push |
| Scan `6.14.1` by hand right after the push | It gets a report, but nothing proves the project would scan the next release |
| Rely on the schedule alone | New artifacts wait up to a day without a report |
| Delete `6.0.0` because its report is bad | The task is to report on every artifact, not to hide one |

## Common mistakes

- Copying without `--platform`. The artifact becomes an image index, and its reports belong to the platform images inside it.
- Reading the status too early. Scans run in the background; wait for `Success`.
- Forgetting the old artifacts. Scan on push acts only on new pushes.
