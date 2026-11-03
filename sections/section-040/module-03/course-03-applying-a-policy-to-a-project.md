# Applying A Policy To A Project

This part creates a policy that keeps the two newest tags of every repository in a project, dry runs it, runs it, and checks what is left. A graded lab follows it.

## Create the policy

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Look up the id of the project, because the policy is tied to it:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
PID=$(api "$API/projects/inventory" | jq '.project_id')
echo $PID
```

Create a policy with one rule, the two most recently pushed artifacts of every repository, scheduled but not yet run:

```sh
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
api "$API/retentions/$RID" | jq '{id, rules: (.rules | map({template, params}))}'
```

The cron expression runs once a year, so the policy does not run by itself during the exercise. The `scope` ties the policy to the project by its numeric id.

## Dry run, then read

```sh
api -X POST "$API/retentions/$RID/executions" -d '{"dry_run": true}'
EXE=$(api "$API/retentions/$RID/executions" | jq '.[0].id')
api "$API/retentions/$RID/executions/$EXE/tasks" | jq 'map({repository, status, retained, total})'
```

For `podinfo` you expect a total of 3 and a retained count of 2. If you see anything else, stop and fix the rule.

## Run it for real

```sh
api -X POST "$API/retentions/$RID/executions" -d '{"dry_run": false}'
api "$API/retentions/$RID/executions" | jq '.[0] | {status, dry_run}'
```

Run the second call again until the status is `Succeed`.

## Check the result

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts?with_tag=true" | jq -r '.[] | (.tags // [] | map(.name) | join(","))'
```

Only `6.14.1` and `6.15.0` remain. The oldest push, `6.0.0`, is gone, and nothing you did named it.

You can now create a policy, dry run it, run it and check it. The graded lab asks you to do it from a fresh start.

## Common pitfalls

> [!WARNING]
> - **Using the project name where the numeric id is needed.** The scope reference is the id.
> - **Expecting the policy to run at creation.** A trigger only sets when it runs. Start it yourself.
> - **Counting by tag name instead of push time.** `latestPushedK` ranks by push time, not by version number.
> - **Forgetting untagged artifacts.** They are in scope only if the selector says so.

## Your mission: Keep The Two Newest Tags With A Retention Policy

You can now write a retention rule, dry run it and run it. The graded lab gives you the project `inventory` with three tags of `podinfo`. It asks you to create a retention policy that keeps the two most recently pushed tags and to run it, so that the oldest tag is removed.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-040-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-040/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-040-03
astrona start ats-102-playground-040-03
```
