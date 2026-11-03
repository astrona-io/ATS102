# Notation And Cosign Side By Side

Both tools put a signature next to the image in the registry, and both sign a digest. The differences are in what identifies the signer and where the decision to trust is made. This part sets the two models next to each other, and then shows how Harbor tells their signatures apart.

## What each tool uses

| | Cosign | Notation |
| --- | --- | --- |
| Signer identity | A key pair, or a short-lived certificate in keyless mode | An X.509 certificate with its private key |
| Who decides what to trust | The command line: `--key` or the identity flags | A trust policy file and trust stores |
| Signature format | A Sigstore bundle stored as an OCI artifact | A JWS or COSE envelope stored as an OCI artifact |
| Harbor accessory type | `signature.cosign` | `signature.notation` |
| Harbor project setting | `enable_content_trust_cosign` | `enable_content_trust` |

A **trust store** is a named folder of certificates that you trust. A **trust policy** is a JSON file that ties repositories to trust stores and to a verification level. Teams that already run a certificate authority often prefer Notation, because the signing certificate comes from the same system as their other certificates and can be revoked there.

## What Harbor does with Notation signatures

Harbor does not create Notation signatures. The client signs and pushes the signature to the repository, and Harbor links it to the signed digest as an accessory. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

List the accessories of the release. It has none yet:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/release/repositories/podinfo/artifacts/6.15.0/accessories" | jq 'length'
```

After a Notation signature is pushed, the same call lists an entry with the type `signature.notation`. The type is how Harbor, and your own scripts, tell the two tools apart.

## Check the tool

Print the version of the tool in the workstation, and list its commands:

```sh
notation version
notation --help
```

The commands you will use are `cert`, `key`, `login`, `sign`, `ls`, `inspect`, `policy` and `verify`.

## A project may use both

A project can hold Cosign and Notation signatures on the same artifact, and the two project settings are independent. If you turn on both, Harbor refuses a pull unless the artifact has a signature of each kind, or you accept only one in your own checks. Decide on one tool per release process, because two tools double the keys to protect and the policies to keep in step.

You now know what separates the two tools and how Harbor labels their signatures. The next step is to make a certificate and sign.

## Common pitfalls

> [!WARNING]
> - **Expecting Cosign to verify a Notation signature.** Each tool reads only its own format.
> - **Looking for the signature in the image layers.** It is a separate accessory.
> - **Turning on both project settings by accident.** Harbor then wants both kinds of signature.
> - **Treating the signing tool as a policy.** Notation signs. The trust policy decides.
