# Solution: Tighten A Project That Lets Everything Through

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the project's policy and allowlist, the system allowlist's expiry, and the pulls.

## Step 1: Read the project's settings

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory" | jq '{metadata, project_allowlist: .cve_allowlist}'
```

Three settings are wrong: `prevent_vul` is `"false"`, `severity` is `"critical"`, and `reuse_sys_cve_allowlist` is `"true"`. Fixing only the first two is not enough, as the next step shows.

## Step 2: Read the system allowlist

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor cve-allowlist list
api "$API/system/CVEAllowlist" | jq '{count: (.items | length), expires_at}'
```

The system list holds many CVEs and has no expiry. Compare them with the report of `6.0.0`:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq -r '[.[].vulnerabilities[] | select(.severity == "High" or .severity == "Critical") | .id] | unique | .[]' | sort > high.txt
api "$API/system/CVEAllowlist" | jq -r '.items[].cve_id' | sort > system.txt
comm -23 high.txt system.txt | wc -l
```

The count is `0`: every High and Critical CVE of `6.0.0` is on the system list. Because `inventory` reuses that list, it would ignore all of them even with the policy on at `high`.

## Step 3: Fix the project

One request turns the policy on at `high`, stops reusing the system list, and gives the project an empty list of its own:

```sh
api -X PUT "$API/projects/inventory" -d '{"metadata":{"prevent_vul":"true","severity":"high","reuse_sys_cve_allowlist":"false"},"cve_allowlist":{"items":[]}}'
api "$API/projects/inventory" | jq '{metadata, items: .cve_allowlist.items}'
```

## Step 4: Give the system allowlist an expiry

Keep its entries and add `expires_at`, 6 days from now:

```sh
EXPIRES=$(( $(date +%s) + 6 * 24 * 3600 ))
api "$API/system/CVEAllowlist" | jq -c --argjson expires "$EXPIRES" '{items: (.items | map({cve_id})), expires_at: $expires}' > system-allowlist.json
api -X PUT "$API/system/CVEAllowlist" -d @system-allowlist.json
api "$API/system/CVEAllowlist" | jq '{count: (.items | length), expires_at}'
```

The count is unchanged, and `expires_at` is set.

## Step 5: Prove it with pulls

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl manifest get harbor.localtest.me:8443/inventory/podinfo:6.0.0 > /dev/null && echo "6.0.0 pulled"
regctl manifest get harbor.localtest.me:8443/inventory/podinfo:6.15.0 > /dev/null && echo "6.15.0 pulled"
```

`6.0.0` is refused with `412`. `6.15.0` follows its own report.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn `prevent_vul` on and set `high`, nothing else | `inventory` still reuses the system list, which allows every finding of `6.0.0` |
| Empty the system allowlist | Other teams lose their exception before the week is over; the task forbids it |
| Copy the system list into the project | The project lets `6.0.0` through again |
| Delete `6.0.0` | The task keeps it; the policy must refuse it |

## Common mistakes

- Missing the hidden fault. A project that reuses the system allowlist does not show the list in its own settings.
- Writing `expires_at` in milliseconds or in the past. Harbor ignores an expired list, which would end the other teams' exception today.
