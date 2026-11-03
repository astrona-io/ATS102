# Summary

A signature is a narrow statement. This module showed how to widen it with claims and data, and how to keep the keys behind it healthy.

## What you learned

A signature is stored as its own accessory of the artifact. `cosign tree` and the Harbor accessories API list it. A successful `cosign verify --key` proves that a signature for the digest exists, that the matching private key made it, and that the signed data is unchanged. It does not prove that the image is safe, and it is only as good as the public key you check against, which must come from a source you control.

An annotation is a key and value pair inside the signed payload, added with `-a key=value`. Verifying with `-a` accepts only signatures that carry the claim. An artifact can hold many signatures, each with its own key and its own annotations, and each is verified on its own. An attestation is a signed in-toto statement with a subject, a predicate type and a predicate. `cosign attest` creates it, `cosign verify-attestation` with `--type` checks it, and the payload is base64 JSON. Harbor stores attestations and does not enforce them.

Keys need care: separate keys per role, a secret store, a password apart from the file. Keyless signing replaces the key with a short-lived certificate and a public log, and needs the Sigstore services. Rotation works by overlap: sign with the new key, let consumers trust both, then retire the old one. The key facts to remember are these:

- A signature proves who signed a digest, not that the image is safe.
- `-a key=value` adds a claim, and the same flag on `cosign verify` requires it.
- A second signature sits next to the first and replaces nothing.
- Rotate with an overlap, and trust only a public key you control.

<!-- astrona:playground:destroy -->
