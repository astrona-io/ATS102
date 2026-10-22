# Summary

A vulnerability report says which known flaws are in an artifact today. A Software Bill of Materials (SBOM) says what is in it at all, and that never changes. This module showed how Harbor produces SBOMs, where it keeps them, and how to read them.

## What you learned

An SBOM lists every package in an artifact with its version, and usually its license and package URL. Harbor 2.15 writes it in the SPDX JSON format, `application/spdx+json`, with the fields `spdxVersion`, `name`, `creationInfo`, `packages` and `relationships`. Because the packages of an image are fixed when it is built, an SBOM stays true for the life of the image. It lets you find every image that contains a package without scanning anything again.

Harbor stores an SBOM in the registry as an accessory of its subject image: an OCI artifact with the accessory type `sbom.harbor` and the artifact type `application/vnd.goharbor.harbor.sbom.v1`. It is copied by replication and deleted with its subject. You ask for one with a `POST` to the artifact's `scan` endpoint and the body `{"scan_type":"sbom"}`. You follow it in `sbom_overview`, which gives the `scan_status` and, once it reads `Success`, the `sbom_digest`. With that digest, `regctl artifact get -m application/spdx+json` downloads the document, and `jq` answers questions from it.

The project setting `auto_sbom_generation` makes Harbor generate an SBOM for every artifact pushed to the project. The `harbor` command-line tool v0.0.27 has no flag for it, so you set it through the REST API. A start time seconds after the push time proves the SBOM came from the push. Artifacts pushed before the setting was on still need one by hand. The key facts to remember are these:

- An SBOM lists packages; a vulnerability report judges them.
- Harbor writes SPDX JSON and stores it as an accessory with its own digest.
- `{"scan_type":"sbom"}` turns a scan request into an SBOM request.
- Generation on push acts only on new pushes.

<!-- astrona:playground:destroy -->
