# Enforcing Notation Signatures In Harbor

Verification by the client depends on every client doing it. Harbor can refuse unsigned pulls for everybody. This part turns on the Notation project setting, reads the refusal, and then compares it with the Cosign setting so that you can choose.

## The project setting

The project metadata `enable_content_trust` makes Harbor refuse to serve an artifact that has no Notation signature. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Create a project to try it on, copy the release into it, and turn the setting on:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/projects" -d '{"project_name":"gated","metadata":{"public":"false"}}'
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl image copy --platform linux/amd64 harbor.localtest.me:8443/release/podinfo:6.15.0 harbor.localtest.me:8443/gated/podinfo:6.15.0
api -X PUT "$API/projects/gated" -d '{"metadata":{"enable_content_trust":"true"}}'
```

## Read the refusal

Ask for the manifest with a token, the way a client would, and print the status and the body:

```sh
TOKEN=$(curl -fsS -u admin:Harbor12345 "https://harbor.localtest.me:8443/service/token?service=harbor-registry&scope=repository:gated/podinfo:pull" | jq -r '.token')
curl -s -w '\nHTTP %{http_code}\n' -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' https://harbor.localtest.me:8443/v2/gated/podinfo/manifests/6.15.0
```

Harbor answers with the status `412` and a JSON error whose message says that the image is not signed by notation. As with Cosign, this is a policy refusal and not a credential problem.

## Sign and pull again

Sign the copy in `gated`, with the key from the previous parts. A client with push rights may read an unsigned manifest to sign it, which is why the signing step works:

```sh
notation login -u admin -p Harbor12345 harbor.localtest.me:8443
DIGEST=$(regctl image digest harbor.localtest.me:8443/gated/podinfo:6.15.0)
notation sign harbor.localtest.me:8443/gated/podinfo@$DIGEST
```

Run the manifest request again. It now answers `200`. Harbor checked only that a Notation signature exists, not that it came from your certificate. The check against your certificate is `notation verify` with the trust policy, in your pipeline or in an admission controller.

## Choosing between the two settings

| Question | Answer |
| --- | --- |
| Which tool do our other systems use | Use the same tool, so one policy covers everything |
| Do we have a certificate authority | Notation fits it directly |
| Do we want key pairs without a certificate authority | Cosign is simpler |
| Do we need keyless signing | Cosign supports it |

Whatever you choose, use the Harbor setting and the client check together. The Harbor setting keeps unsigned artifacts from being served. The client check makes sure the signature is the right one.

You now know how to enforce Notation signatures in Harbor, how to read the refusal, and what the setting does not check.

## Common pitfalls

> [!WARNING]
> - **Turning the setting on and relying on it alone.** It checks that a signature exists, not whose it is.
> - **Reading the `412` as a login problem.** It is a policy refusal.
> - **Enabling the Cosign and the Notation settings together without meaning to.** Artifacts then need both kinds of signature.
> - **Copying an artifact into a gated project and expecting its signatures to follow.** A plain copy does not carry the signature along.
