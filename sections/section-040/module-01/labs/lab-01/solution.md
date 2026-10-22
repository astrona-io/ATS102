# Solution: Block High Risk, Allow A Reviewed Exception

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: both policies, the refusals in `inventory`, the exception in `legacy`, and an empty system allowlist.

## Step 1: Read the starting state

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define the helper and look at both projects:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
for project in inventory legacy; do
  api "$API/projects/$project" | jq -c "{project: \"$project\", metadata, allowlist: .cve_allowlist.items}"
done
```

Neither project prevents vulnerable pulls, and neither has an allowlist.

## Step 2: Turn on prevention in inventory

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config update inventory --prevent-vul true --severity high
```

## Step 3: Collect the reviewed CVEs

The exception covers exactly the High and Critical findings of `legacy/podinfo:6.0.0`:

```sh
ITEMS=$(api "$API/projects/legacy/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq -c '[.[].vulnerabilities[] | select(.severity == "High" or .severity == "Critical") | .id] | unique | map({cve_id: .})')
echo "$ITEMS" | jq length
```

## Step 4: Write legacy's policy and allowlist

One request sets the policy, tells the project to use its own list, and writes the list with an expiry 14 days from now:

```sh
EXPIRES=$(( $(date +%s) + 14 * 24 * 3600 ))
api -X PUT "$API/projects/legacy" -d "{\"metadata\":{\"prevent_vul\":\"true\",\"severity\":\"high\",\"reuse_sys_cve_allowlist\":\"false\"},\"cve_allowlist\":{\"items\":$ITEMS,\"expires_at\":$EXPIRES}}"
api "$API/projects/legacy" | jq '{metadata, count: (.cve_allowlist.items | length), expires_at: .cve_allowlist.expires_at}'
```

`reuse_sys_cve_allowlist` must be `"false"`. Without it, `legacy` keeps using the empty system list and ignores its own.

## Step 5: Prove it with pulls

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl manifest get harbor.localtest.me:8443/inventory/podinfo:6.0.0 > /dev/null && echo "inventory 6.0.0 pulled"
regctl manifest get harbor.localtest.me:8443/legacy/podinfo:6.0.0 > /dev/null && echo "legacy 6.0.0 pulled"
```

`inventory` refuses `6.0.0` with `412`; `legacy` serves it. `inventory/podinfo:6.15.0` follows its own report.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add the CVEs to the system allowlist | `inventory` reuses it by default and lets `6.0.0` through too; the grader requires an empty system list |
| Allowlist every CVE of the image, Low and Medium included | The list grows beyond what was reviewed; the grader accepts only High and Critical CVEs of this artifact |
| Raise `legacy` to `critical` | High findings pass in every artifact of `legacy`, not only the reviewed one |
| Leave out `expires_at` | The exception never ends |

## Common mistakes

- Forgetting `reuse_sys_cve_allowlist: "false"`. The project's own list is then ignored.
- Writing `expires_at` in milliseconds. Harbor expects seconds since the epoch.
- Building the list from `inventory/podinfo:6.0.0`. It has the same CVEs today, but the exception is for the artifact in `legacy`; read its own report.
