# Reading Executions And Failures

Replication runs in the background, so a mistake shows up later and somewhere else. This part reads executions and tasks, lists the usual causes of failure, and shows how to repeat a run safely.

## Executions and tasks

Every run of a rule is an **execution**. An execution has one **task** for each artifact it tries to copy. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

List the executions of a rule and its tasks:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
POL=$(api "$API/replication/policies" | jq '.[] | select(.name=="staging-to-prod") | .id')
EXE=$(api "$API/replication/executions?policy_id=$POL" | jq '.[0].id')
api "$API/replication/executions/$EXE" | jq '{id, status, total, succeed, failed}'
api "$API/replication/executions/$EXE/tasks" | jq 'map({id, status, src_resource, dst_resource})'
```

Each task shows the source, the destination and its own status. A task log explains a failure in words:

```sh
TASK=$(api "$API/replication/executions/$EXE/tasks" | jq '.[0].id')
api "$API/replication/executions/$EXE/tasks/$TASK/log"
```

## Usual causes of failure

| Symptom | Likely cause |
| --- | --- |
| The execution fails at once with a connection error | The endpoint address is wrong, or the network blocks it |
| Tasks fail with an unauthorized error | The endpoint credentials are wrong or have no push right |
| Tasks fail with a certificate error | The endpoint certificate is not trusted and `insecure` is off |
| The execution succeeds with a total of 0 | A filter matches nothing |
| Tasks fail with a forbidden error at the destination | A policy on the destination refuses the artifact, such as a vulnerability limit or a signature requirement |
| An artifact is skipped | Override is off and the tag already exists |

The destination project applies its own rules to a replicated artifact. If the production project requires a signature, Harbor refuses an artifact that arrives without one, and the task log says so.

## Run it again

Replication is safe to repeat. With override on, a second execution replaces the artifacts with identical content. With override off, it skips them. Start a new execution after you fix the cause, and compare the totals.

```sh
api -X POST "$API/replication/executions" -d '{"policy_id": '"$POL"'}'
```

## Immutable tags at the destination

If the destination project has an immutable tag rule, a copy with override cannot replace a matching tag, and the task fails. That is the rule working as designed. Decide in advance which side owns the tag, and turn override off on the replication rule so that the intent is clear.

You can now read executions and tasks, and tell the cause of a failure from its symptom.

## Common pitfalls

> [!WARNING]
> - **Reading only the execution status.** The tasks and their logs hold the reason.
> - **Fixing the destination and forgetting to run again.** A failed execution does not retry itself.
> - **Blaming replication for a destination policy.** The destination project can refuse an artifact on its own rules.
> - **Combining override with immutable tags.** The copy fails by design.
