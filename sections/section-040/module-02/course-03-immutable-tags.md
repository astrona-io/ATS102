# Immutable Tags

A tag is a movable name. Anyone with push rights can point `6.15.0` at a different image, and every deployment that uses the tag then runs the new image without a visible change. A **tag immutability rule** stops that: once a tag matches a rule, Harbor refuses to overwrite it and refuses to delete it. This part creates a rule, tests it, and ends with a graded lab.

## What a rule says

A rule selects tags in repositories, with patterns:

| Part | What it does |
| --- | --- |
| Repository selector | Which repositories the rule covers, for example every repository with `**` |
| Tag selector | Which tags it covers, for example `6.*` |
| Matches or excludes | Whether the patterns include or leave out what they match |
| Disabled | Switches a rule off without deleting it |

The patterns use the doublestar style. `6.*` matches `6.15.0` and `6.0.0`, and does not match `latest`. A tag that matches an enabled rule is immutable for everybody, administrators included.

## Create a rule

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Make a rule for the tags that start with `6.` in all repositories of `inventory`:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/projects/inventory/immutabletagrules" -d '{"disabled":false,"action":"immutable","template":"immutable_template","scope_selectors":{"repository":[{"kind":"doublestar","decoration":"repoMatches","pattern":"**"}]},"tag_selectors":[{"kind":"doublestar","decoration":"matches","pattern":"6.*"}]}'
api "$API/projects/inventory/immutabletagrules" | jq '.[] | {id, disabled, tag_selectors: [.tag_selectors[].pattern]}'
```

The listing shows the rule and its tag pattern.

## Test what it blocks

Try to overwrite `6.15.0` with a different image, and compare the digest before and after:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl image digest harbor.localtest.me:8443/inventory/podinfo:6.15.0
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:6.15.0
regctl image digest harbor.localtest.me:8443/inventory/podinfo:6.15.0
```

The copy is refused, and the digest is the same before and after. A tag that does not match the rule is not blocked. Push the same image under a name outside `6.*`:

```sh
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:candidate
```

This copy works, and `candidate` can be overwritten again later. Deleting an immutable tag is refused the same way as overwriting it:

```sh
curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X DELETE "$API/projects/inventory/repositories/podinfo/artifacts/6.15.0/tags/6.15.0"
```

Harbor answers with an error status instead of `200`, and the tag stays.

## Immutability and the rest of the policy

Immutability does not replace the other controls. It works next to them:

| Control | Question it answers |
| --- | --- |
| Robot permissions | Who may push at all |
| Immutability | May this tag change once it exists |
| Signatures | Is this the image the builders produced |
| Vulnerability gate | May this image run |

An immutable tag also affects retention and cleanup. A retention policy that would remove an immutable tag cannot remove it, so a rule with a broad pattern can keep old artifacts for a long time. Make the pattern as narrow as the release naming allows.

You can now protect release tags, show that overwriting and deleting are refused, and name the tags that stay free. The graded lab combines this with a robot account.

## Common pitfalls

> [!WARNING]
> - **Writing a pattern that also matches working tags.** `**` blocks every tag, including `latest` and branch builds.
> - **Creating the rule after the bad push.** A rule protects tags from now on. It does not undo an overwrite.
> - **Expecting administrators to bypass it.** The rule applies to them too.
> - **Forgetting the repository selector.** A rule with a tag pattern and no repository match covers nothing useful.

## Your mission: Create A Pull-Only Robot And Protect Release Tags

You can now create a robot with exact permissions and protect tags with a rule. The graded lab gives you the project `inventory` with `podinfo:6.15.0`, no robot and no rule. It asks you for a pull-only robot named `ci-pull` that lives for 30 days, its secret saved to a file, and an immutability rule for the tags that start with `6.`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-040-02
astrona start ats-102-playground-040-02
```
