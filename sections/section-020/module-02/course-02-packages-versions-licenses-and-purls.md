# Packages, Versions, Licenses And Package URLs

A package entry is where an SBOM answers most real questions: what is it, which version, under which license, and where does it come from. This part reads those fields from the `alpine:3.20` SBOM and from a second SBOM for a program built with Go. It ends with a way to join an SBOM with a vulnerability report.

## The fields of one package

Each entry in `packages` has the fields below. Trivy fills the ones it can find. A field that has no value is missing or holds `NOASSERTION`, the SPDX word for "not stated".

| Field | What it holds |
| --- | --- |
| `name` and `versionInfo` | The package name and its installed version |
| `licenseDeclared` and `licenseConcluded` | The license the package states, and the license the tool decided on |
| `supplier` | Who supplies the package |
| `externalRefs` | Links to outside identifiers, including the package URL |
| `SPDXID` | The local identifier that the relationships use |

A **package URL (purl)** is a standard string that names a package, its ecosystem and its version, such as `pkg:apk/alpine/musl@1.2.5-r1`. The purl lives in `externalRefs`, in the entry whose `referenceType` is `purl`. Tools that match packages to advisories use the purl, because it is the same string in every tool.

## Read names, versions and purls

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

If the file `alpine-3.20.spdx.json` is not in the shell, download the SBOM again as in the earlier steps: ask for it with `{"scan_type":"sbom"}`, read the `sbom_digest`, and fetch it with `regctl artifact get`. Then list each package as one line with its name, version and purl:

```sh
jq -r '.packages[] | select(.versionInfo != null)
  | [.name, .versionInfo, ([.externalRefs[]? | select(.referenceType == "purl") | .referenceLocator][0] // "-")] | @tsv' alpine-3.20.spdx.json | sort | head -20
```

The `select` keeps only entries with a version, which leaves out the entry for the artifact itself. Each line shows one package. The `// "-"` prints a dash when no purl exists.

## Read the licenses

A license review asks which licenses occur and how often. Count the declared licenses:

```sh
jq -r '[.packages[] | .licenseDeclared // "NOASSERTION"] | group_by(.) | map({license: .[0], count: length}) | sort_by(-.count) | .[] | [.count, .license] | @tsv' alpine-3.20.spdx.json
```

The most common licenses come first. A line with `NOASSERTION` means Trivy found no declared license for those packages. A policy that bans one license starts with this list, and the matching packages are then found with a `select` on the license.

## Join the SBOM with a vulnerability report

The vulnerability report names a package and a version for every finding. The SBOM lists the same pairs. Join them to answer: which of my packages have findings? Scan the artifact and store the names of its vulnerable packages in a file:

```sh
api -X POST "$API/projects/audit/repositories/alpine/artifacts/3.20/scan"
api "$API/projects/audit/repositories/alpine/artifacts/3.20/additions/vulnerabilities" | jq -r '[.[].vulnerabilities[].package] | unique | .[]' > vulnerable-packages.txt
```

Wait for the scan status `Success` before you read the report, because an unfinished scan has no findings yet. Then print the packages that appear in both places:

```sh
jq -r '.packages[].name' alpine-3.20.spdx.json | sort -u | comm -12 - vulnerable-packages.txt
```

`comm -12` prints only the lines that both sorted lists share. The result can be empty when the image has no known findings. The point of the join is that the SBOM never changes, while the report does. When a new advisory arrives, you scan again and join again, and you do not need a new SBOM.

You can now read the fields of a package, the purl, the licenses, and join an SBOM with a report. All of that was for one artifact. An advisory asks about all of them, which is the next part.

## Common pitfalls

> [!WARNING]
> - **Counting `NOASSERTION` as a license.** It means the license is not stated.
> - **Matching packages by name only.** Two ecosystems can use one name. Compare the purl when it matters.
> - **Reading the vulnerability report before the scan ends.** An empty list then means the scan is not done.
> - **Expecting the SBOM to show risk.** It lists content. Risk comes from the report.
