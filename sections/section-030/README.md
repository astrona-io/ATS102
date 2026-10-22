# Section 030: Signing With Cosign And Enforcing Signatures

A scan tells you what is inside an artifact. It does not tell you who built it, or whether the artifact you pull today is the one your pipeline pushed. Anyone with push rights to a project can replace a tag. A **signature** closes that gap: the builder signs the artifact's digest with a private key, and anyone with the matching public key can check that the artifact has not changed since.

This section shows how Harbor works with signatures. You sign an artifact with **Cosign** and a key pair, verify it, and then turn on the project setting that makes Harbor refuse every artifact without a Cosign signature. You also learn what happened to Docker Content Trust and Notary, and where Notation fits.

**Topic covered:** Content trust

## What you will learn

- How Harbor stores signatures as accessories of the signed artifact.
- Why Notary v1 and Docker Content Trust are gone from Harbor, and what Cosign and Notation do instead.
- Creating a Cosign key pair, signing an artifact by its digest, and verifying the signature.
- Signing without the public transparency log in a private environment.
- Making a project refuse unsigned artifacts, and reading Harbor's refusal.

## The learning path

### 1. Sign Artifacts With Cosign And Enforce Signatures

The module starts at its landing page, which also launches the playground. The playground holds Harbor with the project `release`, the release `podinfo:6.15.0` and the release candidate `podinfo:6.14.1-rc`, none of them signed.

1. Signatures, Accessories And Where Notary Went
2. Signing And Verifying With Cosign
3. Making A Project Refuse Unsigned Artifacts, followed by the lab **Allow Only Signed Releases**
4. Summary

## Section capstone: Lock Down A Release Project

The capstone is one graded scenario. The releases in the project `release` are signed, but with an old key the team no longer trusts, and the project accepts unsigned artifacts anyway. Sign every release with the team key and make the project refuse the rest. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-102-capstone-030
```
