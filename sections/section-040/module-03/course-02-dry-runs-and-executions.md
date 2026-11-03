# Dry Runs And Executions

A retention run deletes artifacts, and a deleted tag is gone. Harbor offers a **dry run** that computes the result and deletes nothing. This part shows the order to work in: write the policy, dry run it, read the result, and only then run it for real.

## Triggers

A policy has a trigger that decides when it runs. The trigger is a schedule, a cron expression with six fields, or none. A policy with a schedule runs by itself, and you can start any policy by hand. For a first policy, start by hand.

## Execution statuses

| Status | Meaning |
| --- | --- |
| `Running` | The run is in progress |
| `Succeed` | The run finished |
| `Failed` | The run stopped on an error |

An execution has tasks, one for each repository. A task reports how many artifacts were retained and how many were deleted.

## Run a dry run

You need the policy first. The policy for the project is created in the next part. Here, read how an execution is started and read, so that the calls are familiar. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Read the retention id of the project and its executions:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
RID=$(api "$API/projects/inventory" | jq -r '.metadata.retention_id // empty')
echo "retention id: ${RID:-none}"
```

A project without a policy has no retention id. After a policy exists, the id appears in the project metadata. With an id, a dry run and a real run are started the same way and differ in one field:

```sh
# dry run: computes the result, deletes nothing
api -X POST "$API/retentions/$RID/executions" -d '{"dry_run": true}'
# real run: deletes what no rule keeps
api -X POST "$API/retentions/$RID/executions" -d '{"dry_run": false}'
```

Do not run these two lines now. There is no policy yet, so there is no id.

## Read an execution

```sh
api "$API/retentions/$RID/executions" | jq '.[0] | {id, status, dry_run}'
EXE=$(api "$API/retentions/$RID/executions" | jq '.[0].id')
api "$API/retentions/$RID/executions/$EXE/tasks" | jq 'map({repository, status, retained, total})'
```

The `total` is the number of artifacts in the repository that the rule looked at, and `retained` is the number it keeps. The difference is what a real run deletes.

## The safe order

1. Write the policy for one project.
2. Run a dry run.
3. Read the tasks. Compare `retained` with the number you expected.
4. Fix the selectors if the number is wrong, and dry run again.
5. Run for real.

You can now plan a retention run that does not surprise you. The next part builds the policy.

## Common pitfalls

> [!WARNING]
> - **Skipping the dry run.** Deletion cannot be undone.
> - **Reading `Succeed` as "deleted the right things".** It means the run finished.
> - **Starting a real run to see what happens.** Use the dry run for that.
> - **Setting a schedule on a policy you have not checked.** It will delete on its own.
