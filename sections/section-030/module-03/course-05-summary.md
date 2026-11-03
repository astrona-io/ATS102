# Summary

Notation signs with certificates and verifies with a trust policy. This module showed how to sign, how to write the policy, and how to make Harbor enforce it.

## What you learned

Notation and Cosign both sign a digest and store the signature next to the image, but Harbor labels them with different accessory types: `signature.notation` and `signature.cosign`. Cosign trusts what the command line names. Notation trusts what the trust policy names.

`notation cert generate-test --default NAME` makes a test key and a self-signed certificate and fills a trust store. `notation login` signs in to the registry, `notation sign` signs a digest, `notation ls` lists the signatures, and `notation inspect` prints their contents. A trust policy is a JSON file with scopes, trust stores in the form `type:name`, trusted identities and a verification level of `strict`, `permissive`, `audit` or `skip`. `notation policy import` loads it and `notation verify` uses it. Without a matching policy entry, verification fails.

The project setting `enable_content_trust` makes Harbor refuse artifacts without a Notation signature with the status `412`. It checks that a signature exists, and the trust policy checks whose it is. The key facts to remember are these:

- The trust policy decides what a valid Notation signature is.
- Sign the digest, not the tag.
- `generate-test` is for tests, never for production.
- Harbor enforcement and client verification belong together.

<!-- astrona:playground:destroy -->
