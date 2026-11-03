# Filters And Triggers

A rule that copies everything is rare. Filters narrow what is copied and the trigger decides when. This part reads the filter types, and compares the three ways to start a rule.

## Filters

Each filter has a type and a value. A rule can have several filters, and an artifact must satisfy all of them.

| Filter type | What it matches | Example value |
| --- | --- | --- |
| `name` | The repository name | `staging/podinfo` or `staging/**` |
| `tag` | The tag | `6.*` |
| `label` | A label on the artifact | a label name |
| `resource` | The kind of resource | `image`, `chart` or `artifact` |

The wildcard `*` matches within one path level. The double wildcard `**` matches across levels. A filter with an empty value matches everything of that type.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Look at the filters of the rule from the previous part:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/replication/policies" | jq '.[] | {name, filters, override}'
```

If you change the filter to a tag filter of `6.14.*`, the rule does not match `6.15.0`, and an execution copies nothing. An execution that copies nothing still counts as a success, so an empty result is a reason to look at the filters first.

## Override

When `override` is true, Harbor replaces an artifact that already exists at the destination with the same name and tag. When it is false, Harbor skips it. For releases, many teams turn override off, so that a tag in production can never be replaced by a copy.

## Triggers

| Trigger | When it runs | Use it for |
| --- | --- | --- |
| `manual` | Only when somebody starts it | Promotion that a person approves |
| `scheduled` | On a cron schedule | Regular mirroring |
| `event_based` | After a push to the source project | Immediate copying to a mirror |

A scheduled trigger takes a cron expression with six fields, including seconds. An event-based trigger fits mirrors, and a manual trigger fits promotion, because a person decides that a build has earned its place in production.

Read the trigger of the rule:

```sh
api "$API/replication/policies" | jq '.[] | {name, trigger}'
```

## Copy only what is ready

A common design copies only artifacts with a certain label, and a build pipeline adds the label after the tests and the scan pass. The rule then moves exactly the approved artifacts and nothing else. That moves the decision into your pipeline and keeps the rule simple.

You can now narrow a rule and choose its trigger. The next part runs the rule and checks what arrived.

## Common pitfalls

> [!WARNING]
> - **A filter that matches nothing.** The execution succeeds and copies nothing.
> - **Using `*` when you need `**`.** The single wildcard stops at the path separator.
> - **Leaving override on for releases.** A later copy can replace a production tag.
> - **Event-based rules for promotion.** Every push is copied whether or not anybody approved it.
