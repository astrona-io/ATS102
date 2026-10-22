# Summary

A tag can point at a different image tomorrow, so a registry needs a way to prove that an artifact is the one its builder produced. This module showed how Harbor does that with Cosign signatures, and how a project makes Harbor refuse everything unsigned.

## What you learned

A signature covers a digest, the SHA-256 hash of an artifact's content, not its tag. Harbor stores a signature in the same repository as its subject and links it as an accessory: `signature.cosign` for Cosign, `signature.notation` for the Notary Project's Notation. Harbor removed its Notary server and Docker Content Trust in version 2.9.0, after deprecating them in 2.6.0, so `DOCKER_CONTENT_TRUST=1` no longer does anything with Harbor.

Cosign signs with a key pair made by `cosign generate-key-pair`: `cosign.key`, encrypted with the password in `COSIGN_PASSWORD`, and `cosign.pub`. `cosign login` lets Cosign push the signature to Harbor. You sign the digest with `cosign sign --key cosign.key`, and in a private environment you add `--tlog-upload=false` so nothing goes to the public Rekor transparency log. `cosign verify --key cosign.pub` checks the signature, with `--insecure-ignore-tlog=true` when no log entry exists. Keyless signing needs the public Sigstore services.

The project setting `enable_content_trust_cosign` makes Harbor refuse every pull of an artifact without a Cosign signature, with `412 Precondition Failed`, the code `PROJECTPOLICYVIOLATION` and the message `The image is not signed by cosign.`. The system administrator is not exempt. A Cosign or Notation client with push rights may still pull an unsigned manifest so it can sign it, and Harbor's scanner is exempt. Harbor checks only that a signature exists; checking that the team's key made it is the job of `cosign verify`. The key facts to remember are these:

- Sign the digest, not the tag.
- Signatures are accessories, linked to and deleted with their subject.
- Enforcement is off until a project turns it on, and then it refuses with `412`.
- Harbor accepts a signature from any key; verify with your own public key.

<!-- astrona:playground:destroy -->
