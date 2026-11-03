# How Retention Rules Work

A retention policy belongs to one project. It holds up to 15 rules, a trigger and a scope. Each rule says which artifacts to **keep**. An artifact that no rule keeps is deleted when the policy runs. A project with a policy and no rules keeps nothing, and a project with no policy deletes nothing.

## The parts of a rule

| Part | What it decides |
| --- | --- |
| Template | How many or how recent: the count or age that is kept |
| Repository selector | Which repositories the rule covers |
| Tag selector | Which tags in those repositories the rule covers |
| Untagged option | Whether untagged artifacts are in scope |

## Templates

| Template | Keeps |
| --- | --- |
| `latestPushedK` | The most recently pushed K artifacts in each repository |
| `latestPulledK` | The most recently pulled K artifacts |
| `nDaysSinceLastPush` | Artifacts pushed within the last N days |
| `nDaysSinceLastPull` | Artifacts pulled within the last N days |
| `always` | Every artifact that matches the selectors |

Rules in a policy are combined with **or**. An artifact kept by any rule is kept. The `always` template is how you protect tags: a rule that always keeps `release-*` stops every other rule from deleting them.

## Selectors

A selector has a `kind`, a `decoration` and a pattern. The kind is `doublestar`. The decoration says whether the pattern includes or excludes:

| Decoration | Meaning |
| --- | --- |
| `matches` | Include artifacts whose name matches the pattern |
| `excludes` | Include everything except artifacts whose name matches |
| `repoMatches` and `repoExcludes` | The same, for the repository selector |

The pattern `**` matches everything. The pattern `6.*` matches tags that start with `6.`.

## Look at a project

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

List the tags of the repository, with their push times:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory/repositories/podinfo/artifacts?with_tag=true" | jq -r '.[] | [.push_time, (.tags // [] | map(.name) | join(","))] | @tsv'
```

With the template `latestPushedK` and K set to 2, the two newest pushes, `6.14.1` and `6.15.0`, are kept and `6.0.0` is deleted. Check that you can name the survivors before you run anything.

## Common pitfalls

> [!WARNING]
> - **Reading a rule as "delete these".** A rule lists what to keep.
> - **Writing no rule that matches the tags you care about.** They are deleted.
> - **Forgetting that pull-based templates need pull history.** An artifact that was never pulled has no pull time.
> - **Using `matches` when you meant `excludes`.** The decoration flips the meaning.
