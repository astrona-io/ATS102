# Summary

An SBOM answers questions about content: which packages are in an artifact, which versions, under which licenses. This module showed how to read one and how to keep it trustworthy.

## What you learned

An SPDX document is a JSON object. Its top level holds the specification version, the license of the document, an identifier, a name, a unique namespace and the creation information with the Trivy version. The `packages` list has one entry per package, and the `relationships` list links the entries with `DESCRIBES` and `CONTAINS`, and sometimes `DEPENDS_ON`.

A package entry holds a name, a version, the declared and concluded license, the supplier, and external references. The package URL in the external references names the package, its ecosystem and its version in one string, and tools use it to match packages to advisories. The value `NOASSERTION` means the field is not stated. A `jq` filter reads any of these fields, groups licenses, and joins the package names with the packages of a vulnerability report.

An advisory for a new flaw needs the SBOM, because the vulnerability database does not know the flaw yet. A loop over the SBOMs of a repository finds every artifact that contains a package, and a Harbor label records the answer on the artifact. Harbor stores the SBOM as an accessory of type `sbom.harbor` that describes one digest. Regenerating creates a new accessory, replication copies the accessory with the artifact, and deleting the artifact deletes it. The key facts to remember are these:

- An SBOM lists content, and a report lists known risk.
- An SBOM describes one digest, not a tag.
- Compare `subject_artifact_digest` with the digest of the tag before you trust an SBOM.
- A label keeps the result of a search with the artifact.

<!-- astrona:playground:destroy -->
