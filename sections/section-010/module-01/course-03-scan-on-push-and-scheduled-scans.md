# Scan On Push And Scheduled Scans

Scanning by hand does not scale. A team pushes dozens of images a day, nobody remembers to scan each one, and an image that was clean last month may not be clean today. Harbor solves both problems with two settings: **scan on push**, which scans each new artifact as soon as it arrives, and a **scan-all schedule**, which scans every artifact again at a fixed time. This part turns both on and proves that Harbor scanned an artifact on its own.

## Turn on scan on push

Scan on push is a project setting. Its key in the Harbor API is `auto_scan`, and the `harbor` command-line tool sets it with `harbor project config update`. First look at the current settings of `inventory`.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, sign in if this shell has not yet, and list the project's settings:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config list inventory
```

The list shows the project's metadata keys and their values. `public` is `false`, and `auto_scan` is missing or `false`, which means new artifacts are not scanned. Turn it on:

```sh
harbor project config update inventory --auto-scan true
```

Run `harbor project config list inventory` again: `auto_scan` now reads `true`. The setting belongs to this project only. Every other project keeps its own value.

## Push an artifact and watch Harbor scan it

Now push a new artifact and do not ask for a scan. The tool `regctl` copies images between registries. It signs in once, and the `--platform linux/amd64` flag copies just the image for that platform instead of the whole multi-platform index:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:6.14.1
```

When the push finishes, `core` sees the new artifact in a project with `auto_scan` on and creates a scan job at once. Read the overview, with the helper for the API defined first:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory/repositories/podinfo/artifacts/6.14.1?with_scan_overview=true" \
  | jq '{push_time, scan: [.scan_overview[] | {scan_status, start_time}]}'
```

`scan_status` reads `Running` or already `Success`, although you never asked for a scan. Compare the two times: the scan's `start_time` is only seconds after the artifact's `push_time`. That gap is the proof that Harbor started the scan on push. A scan started by hand later would show a gap of minutes.

Scan on push only acts on new pushes. The artifacts that were in `inventory` before you turned it on keep whatever state they had. If one of them was never scanned, you still have to scan it once by hand.

## Scan everything on a schedule

Scan on push gives every new artifact a report on its first day. It does not update that report when the Trivy database learns about a new CVE next week. For that, Harbor has a system-wide **scan-all** job, which scans every artifact in every project. An administrator can start it once or put it on a schedule.

In the workstation shell, look at the current schedule, then set a daily one:

```sh
harbor scan-all view-schedule
harbor scan-all update-schedule daily
```

The first command shows that no schedule is set. After the second, `harbor scan-all view-schedule` shows the type `Daily` with the cron expression Harbor uses for it. Harbor's cron format has six fields, starting with seconds, so a daily scan at midnight is `0 0 0 * * *`; `update-schedule custom --cron` takes such an expression when the fixed choices do not fit.

The same schedule is a REST API resource, which is how a script or an audit reads it:

```sh
api "$API/system/scanAll/schedule" | jq '.schedule'
```

The JSON shows the `type` and the `cron` expression of the schedule. On a large Harbor, a scan of everything takes time and loads the Trivy adapter, so a daily or weekly run at night is the usual choice.

With scan on push and a scan-all schedule, every artifact gets a report when it arrives and a fresh one every day after. You can prove it from the times in the scan overview. The open question is what Harbor should do with those reports; on their own, they refuse nothing.

## Common pitfalls

> [!WARNING]
> - **Turning on scan on push and expecting old artifacts to be scanned.** It only acts on new pushes. Scan the existing artifacts once by hand, or run scan all.
> - **Relying on scan on push alone.** A report from the day of the push goes out of date. Add a scan-all schedule.
> - **Setting `auto_scan` on the wrong project.** It is a project setting. Check it with `harbor project config list <project>`.
> - **Using a five-field cron expression.** Harbor's schedules use six fields, starting with seconds.

## Your mission: Scan Every Pushed Artifact

You can now make Harbor scan every new artifact on push, scan everything daily, and prove that a scan started on push. The graded lab gives you the project `inventory` with scanning switched off and asks you to turn on both settings, push `podinfo:6.14.1` so that Harbor scans it on its own, and make sure every artifact in the repository has a successful report.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-010-01
astrona start ats-102-playground-010-01
```
