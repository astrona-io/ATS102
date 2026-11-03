# Solution: Keep The Two Newest Tags With A Retention Policy

Work the task yourself first. Running `astrona submit -c sections/section-040/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the project has a retention rule of the template `latestPushedK` with the value 2, and the tags in the repository after the run.

## Step 1: Create the policy

In the workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
PID=$(api "$API/projects/inventory" | jq '.project_id')
api -X POST "$API/retentions" -d '{
  "algorithm": "or",
  "rules": [
    {
      "disabled": false,
      "action": "retain",
      "template": "latestPushedK",
      "params": {"latestPushedK": 2},
      "tag_selectors": [{"kind": "doublestar", "decoration": "matches", "pattern": "**", "extras": "{\"untagged\":true}"}],
      "scope_selectors": {"repository": [{"kind": "doublestar", "decoration": "repoMatches", "pattern": "**"}]}
    }
  ],
  "trigger": {"kind": "Schedule", "settings": {"cron": "0 0 0 1 1 *"}},
  "scope": {"level": "project", "ref": '"$PID"'}
}'
RID=$(api "$API/projects/inventory" | jq -r '.metadata.retention_id')
echo $RID
```

## Step 2: Dry run

```sh
api -X POST "$API/retentions/$RID/executions" -d '{"dry_run": true}'
EXE=$(api "$API/retentions/$RID/executions" | jq '.[0].id')
api "$API/retentions/$RID/executions/$EXE/tasks" | jq 'map({repository, status, retained, total})'
```

Expect a total of 3 and a retained count of 2.

## Step 3: Run for real

```sh
api -X POST "$API/retentions/$RID/executions" -d '{"dry_run": false}'
api "$API/retentions/$RID/executions" | jq '.[0] | {status, dry_run}'
```

Run the last call again until the status is `Succeed`.

## Step 4: Check

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts?with_tag=true" | jq -r '.[] | (.tags // [] | map(.name) | join(","))'
```

Only `6.14.1` and `6.15.0` are listed.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `6.0.0` by hand | The constraint forbids it, and the grader checks that a rule exists |
| Create the policy and never run it | The tag is still there |
| Use the project name as the scope reference | The API needs the numeric project id |

## Common mistakes

- Setting K to 1 or 3, so the wrong number of tags remain.
- Reading the dry run status as proof of deletion. A dry run deletes nothing.
- Looking up the retention id before the policy exists.
