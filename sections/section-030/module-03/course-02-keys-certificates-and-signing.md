# Keys, Certificates And Signing

Notation signs with a private key whose certificate says who the signer is. In production the certificate comes from a certificate authority. In this playground you make a self-signed test certificate, which is enough to learn the commands. This part creates it, signs the release, and reads the signature back.

## Create a test key and certificate

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Generate a key and a self-signed certificate, and make them the default signing key:

```sh
notation cert generate-test --default release-signer
notation key list
notation cert list
```

`generate-test` is meant for tests only. It stores the private key and certificate under the Notation configuration folder of the current user, and it adds the certificate to a trust store of type `ca` named `release-signer`. The two list commands show the key and the certificate.

## Sign by digest

Sign in to the registry, read the digest of the release, and sign it:

```sh
notation login -u admin -p Harbor12345 harbor.localtest.me:8443
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
notation sign harbor.localtest.me:8443/release/podinfo@$DIGEST
```

Signing by digest makes sure you sign the image you looked at. Notation warns when you sign a tag, because a tag can move before the signature is made.

## Read the signature back

List the signatures of the artifact, and inspect them:

```sh
notation ls harbor.localtest.me:8443/release/podinfo@$DIGEST
notation inspect harbor.localtest.me:8443/release/podinfo@$DIGEST
```

`notation ls` lists the signature objects. `notation inspect` prints what is inside them: the signing time, the signature format and the subject of the certificate. Harbor shows the same object as an accessory:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/release/repositories/podinfo/artifacts/6.15.0/accessories" | jq '.[] | {type, digest, subject_artifact_digest}'
```

The type is `signature.notation`, and `subject_artifact_digest` is the digest you signed.

## Where the files are

Notation keeps its state in a configuration folder in the home directory of the user. That folder holds the keys, the trust stores and the trust policy. In the workstation, the user is `root`, so the files belong to `root` and a new shell as `root` finds them again. If you remove the folder, you lose the private key and every certificate, and you cannot sign with the same identity again.

You now have a signed release. A signature is useful when somebody verifies it, and verification needs a trust policy.

## Common pitfalls

> [!WARNING]
> - **Using `generate-test` outside a test.** The certificate is self-signed and the key is not protected the way a production key must be.
> - **Signing a tag.** Notation warns about it. Sign the digest.
> - **Forgetting `notation login`.** The signature cannot be pushed to a private project.
> - **Losing the configuration folder.** The private key goes with it.
