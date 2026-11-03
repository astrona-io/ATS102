# Section 020: Software Bills Of Materials

A vulnerability report answers one question: which known flaws are in this artifact today? A Software Bill of Materials (SBOM) answers a broader one: what is in this artifact at all? It lists every package, with its version and license, so that when a new flaw is announced next year, you can find every affected artifact without scanning anything again.

This section shows how Harbor produces SBOMs. Harbor asks its Trivy adapter for an SBOM in the SPDX format and stores it next to the artifact as an **accessory**. You generate one by hand, download and read it, and then make Harbor generate one for every new artifact on push.

**Topic covered:** SBOM

## What you will learn

- What an SBOM is, what the SPDX format holds, and how an SBOM differs from a vulnerability report.
- How Harbor stores an SBOM as an accessory of its subject artifact.
- Generating an SBOM through the Harbor REST API and following its status.
- Downloading an SBOM with `regctl` and reading its packages with `jq`.
- Turning on automatic SBOM generation for a project, and proving it worked on push.
- The structure of an SPDX document: packages, relationships, licenses and package URLs.
- Finding which artifacts contain a package, and recording it with a label.
- How an SBOM accessory is regenerated, copied and deleted, and how to check it against the digest.

## The learning path

### 1. Generate And Read Software Bills Of Materials

The module starts at its landing page, which also launches the playground. The playground holds Harbor with the project `inventory` and two versions of the `podinfo` image without any SBOM.

1. What An SBOM Is And How Harbor Stores It
2. Generating, Downloading And Reading An SBOM, followed by the lab **Generate An SBOM For Every Pushed Artifact**
3. Summary

### 2. Read And Use The Content Of An SBOM

The module starts at its landing page, which also launches the playground. The playground holds Harbor with the project `audit`, `podinfo:6.15.0` and `alpine:3.20`, without any SBOM.

1. The Structure Of An SPDX Document
2. Packages, Versions, Licenses And Package URLs
3. Find A Package Across Artifacts, followed by the lab **Label Artifacts By Package From Their SBOM**
4. The Life Of An SBOM Accessory
5. Summary

## Section capstone: Ship A Release With A Report And An SBOM

The capstone is one graded scenario. The project `release` must give every artifact both a vulnerability report and an SBOM, by hand for what is already there and on its own for everything that comes next. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-102-capstone-020
```
