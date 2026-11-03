# The Life Of An SBOM Accessory

An SBOM is a stored object, and stored objects are created, replaced, copied and deleted. If you know how Harbor treats the accessory in each case, you know when an SBOM can be trusted and when it is stale. This part follows one SBOM through those events.

## What Harbor stores

Harbor stores the SBOM as an OCI artifact of the type `application/vnd.goharbor.harbor.sbom.v1` in the same repository as the artifact it describes. It records the link to the subject, so the portal and the API show it as an accessory with the type `sbom.harbor`. The accessory has its own digest, which the SBOM overview reports as `sbom_digest`.

An SBOM describes one digest. If you push a new image under the same tag, the tag now points at a different digest, and the old SBOM describes the old digest. The new image has no SBOM until one is generated, by hand or by the project setting `auto_sbom_generation`.

## List the accessories

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Define the helpers, make sure the artifact has an SBOM, and list its accessories:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/projects/audit/repositories/alpine/artifacts/3.20/scan" -d '{"scan_type":"sbom"}'
api "$API/projects/audit/repositories/alpine/artifacts/3.20/accessories" | jq '.[] | {type, digest, subject_artifact_digest}'
```

If the list is empty, the SBOM job is still running. Run the command again after a moment. Each entry has the type `sbom.harbor`, its own `digest`, and the digest of its subject.

## Regenerate an SBOM

Ask for an SBOM again for the same artifact and compare the digests before and after:

```sh
api "$API/projects/audit/repositories/alpine/artifacts/3.20?with_sbom_overview=true" | jq -r '.sbom_overview.sbom_digest'
api -X POST "$API/projects/audit/repositories/alpine/artifacts/3.20/scan" -d '{"scan_type":"sbom"}'
api "$API/projects/audit/repositories/alpine/artifacts/3.20?with_sbom_overview=true" | jq -r '.sbom_overview | [.scan_status, .sbom_digest] | @tsv'
```

Wait for `Success` and compare the two digests. Harbor makes a new accessory for the new document. Regenerating makes sense after a Trivy upgrade, because a newer Trivy can find more packages or write more fields for the same image.

## Copy and delete

Harbor treats an accessory as part of its subject. When a replication rule copies the artifact to another registry, Harbor copies its accessories too, so the SBOM goes with the image. When someone deletes the artifact, Harbor deletes its accessories. When someone deletes only the SBOM accessory, the artifact stays and the SBOM overview shows no SBOM.

A retention policy and the garbage collector use the same link. A tag that is removed by a policy can leave its digest without a tag, and an artifact without tags is cleaned up with its accessories when its project policy says so. Keep this in mind before you rely on an old SBOM: check that its subject digest is the digest that runs in production.

## Check that the SBOM matches the image

The check is one comparison. Read the digest of the tag and the `subject_artifact_digest` of the accessory:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl image digest harbor.localtest.me:8443/audit/alpine:3.20
api "$API/projects/audit/repositories/alpine/artifacts/3.20/accessories" | jq -r '.[] | select(.type == "sbom.harbor") | .subject_artifact_digest'
```

The two lines are the same digest when the SBOM describes the image the tag points at. If they differ, the SBOM is for an older image.

You now know where an SBOM lives, how Harbor links it to its subject, and what happens to it when you regenerate, copy or delete the artifact. With that, the SBOM is a record you can check, not just a file you hope is current.

## Common pitfalls

> [!WARNING]
> - **Trusting an SBOM by tag.** Compare digests. A tag can move.
> - **Expecting a regenerated SBOM to keep its digest.** A new document has a new digest.
> - **Deleting the accessory and expecting the image to change.** Only the SBOM is gone.
> - **Assuming old artifacts get an SBOM when the setting is turned on.** The setting acts on new pushes only.
