# Attestations

A signature vouches for a digest. An attestation vouches for a statement about a digest: this image was built from that commit, these tests passed, this report was clean. The statement is data that a program can read, so a pipeline can decide from it. This part signs a statement, stores it next to the image, and reads it back.

## What an attestation contains

An attestation is a signed envelope in the **in-toto** format. The envelope holds three things:

| Part | What it holds |
| --- | --- |
| Subject | The digest of the artifact that the statement is about |
| Predicate type | A name that says what kind of statement it is |
| Predicate | The data of the statement, as JSON |

Cosign knows some predicate types by name, such as `slsaprovenance`, `spdxjson`, `cyclonedx` and `vuln`. For your own statements it has `custom`, which accepts any JSON. The signature over the envelope is made with the same kind of key as an ordinary signature.

## Attach an attestation

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Write a predicate that records a test result, and attach it to the release with the build key:

```sh
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
echo '{"suite":"smoke","result":"passed","commit":"3f2a9c1"}' > /tmp/tests.json
COSIGN_PASSWORD=build-signing-password cosign attest --yes --key /root/build/cosign.key \
  --use-signing-config=false --tlog-upload=false --type custom --predicate /tmp/tests.json \
  "harbor.localtest.me:8443/release/podinfo@$DIGEST"
```

The command signs the statement and pushes it to the repository as an object that refers to the artifact. The predicate here is only an example. A real pipeline writes the result of its real tests.

## Verify and read it

`cosign verify-attestation` checks the signature and the predicate type, and prints the envelopes:

```sh
cosign verify-attestation --key /root/build/cosign.pub --insecure-ignore-tlog=true --type custom \
  harbor.localtest.me:8443/release/podinfo:6.15.0 > /tmp/attestation.json
jq -r '.payload' /tmp/attestation.json | base64 -d | jq '{subject: .subject[0].digest, predicateType, predicate}'
```

The payload is base64 text. After decoding, the subject has the digest of the release, and the predicate holds the test result. A pipeline that deploys only after `result` is `passed` reads this predicate and stops when the value is different.

## Where Harbor shows it

List the objects that refer to the release:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/release/repositories/podinfo/artifacts/6.15.0/accessories" | jq -r '.[] | .type'
cosign tree harbor.localtest.me:8443/release/podinfo:6.15.0
```

The signature and the attestation are separate accessories, and `cosign tree` names each of them. Harbor stores an attestation but does not read it. The project setting that refuses unsigned artifacts checks for a signature, not for an attestation. The decision to use the data belongs to your pipeline or your cluster admission controller.

## Signature or attestation

| Need | Use |
| --- | --- |
| Show that a key vouched for this digest | A signature |
| Show that a claim like `approved-by=security` was made | A signature with an annotation |
| Carry a record such as a test result, a build record or an SBOM, signed | An attestation |

An annotation is a short label. An attestation is a document. Pick the annotation when one word is enough.

You now know how to attach a signed statement to an artifact and read it back. The keys that make these signatures need care of their own.

## Common pitfalls

> [!WARNING]
> - **Skipping `--type` on verification.** Cosign then checks the default type and finds nothing.
> - **Putting secrets in a predicate.** The attestation is stored next to the image and readable by everyone who can pull it.
> - **Assuming Harbor enforces attestations.** Harbor stores them. The consumer decides.
> - **Reading the payload without decoding it.** It is base64 text.
