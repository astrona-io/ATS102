# Retention With Immutability And Garbage Collection

Retention deletes tags. Two other features decide whether it may, and how much space it frees. Immutable tags can protect a tag from deletion. Garbage collection gives the space back. This part joins the three.

## Retention and immutable tags

An immutable tag rule stops a tag from being overwritten or deleted. A retention run cannot delete an immutable tag. The tag stays, and the run reports it as not deleted. So an immutable rule on `release-*` is a second guard around the same tags that an `always` retention rule protects.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

List the immutable rules of the project:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory/immutabletagrules" | jq 'map({id, tag_selectors, disabled})'
```

The list is empty in the playground. Decide for your own project which of the two you want to be the source of truth, and write the other as a backstop.

## Deleted does not mean freed

When retention deletes a tag, Harbor removes the tag and the artifact record, but the blobs stay in storage. **Garbage collection** removes blobs that no artifact refers to. Until it runs, the disk usage does not drop.

Read the garbage collection schedule:

```sh
api "$API/system/gc/schedule" | jq '.'
```

An empty answer means no schedule. Schedule garbage collection after the retention run, not before it, so that the blobs freed by the run are collected the same night.

## Shared layers stay

A blob is removed only when no artifact needs it. Many images share base layers, so deleting one tag may free little. Retention shrinks the number of tags at once, and the disk shrinks as the unshared layers are collected.

## A design that works

| Tag family | Retention | Immutability |
| --- | --- | --- |
| `release-*` | `always` | Immutable |
| `main-*` build tags | Latest 20 pushed | Not immutable |
| Pull request tags | Pushed within 7 days | Not immutable |
| Everything else | Latest 5 pushed | Not immutable |

Retention rules are combined with or, so a release tag matched by `always` is kept even though the other rules would not keep it.

You now know how retention, immutability and garbage collection fit together.

## Common pitfalls

> [!WARNING]
> - **Expecting disk space to drop at once.** Run garbage collection.
> - **Relying on retention alone to protect releases.** Add an immutable rule and an `always` rule.
> - **Expecting a run to delete an immutable tag.** It cannot, and it reports the tag as not deleted.
> - **Running garbage collection before retention.** The blobs freed by the run wait for the next collection.
