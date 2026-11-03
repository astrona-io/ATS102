# Find A Package Across Artifacts

When a new flaw is announced in a package, the first question is not "how bad is it" but "where do we use it". One SBOM answers that for one artifact. A repository holds many artifacts, so the answer needs a loop. This part builds that loop, checks the result, and records it in Harbor so that the next person does not repeat the search.

## Why the SBOM answers this and a report does not

A vulnerability report lists a package only when the scanner knows a flaw in it. A new flaw is not in the database yet, so the report of every artifact still looks clean. The SBOM lists every package no matter what the database knows, so it answers the question today. This is the main use of an SBOM in an incident.

## Make SBOMs for both artifacts

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Define the helpers, and ask for an SBOM of each artifact in the project `audit`:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/projects/audit/repositories/podinfo/artifacts/6.15.0/scan" -d '{"scan_type":"sbom"}'
api -X POST "$API/projects/audit/repositories/alpine/artifacts/3.20/scan" -d '{"scan_type":"sbom"}'
```

Follow the status of each until it reads `Success`:

```sh
for pair in podinfo:6.15.0 alpine:3.20; do
  api "$API/projects/audit/repositories/${pair%%:*}/artifacts/${pair##*:}?with_sbom_overview=true" | jq -r '.sbom_overview.scan_status'
done
```

## Search every SBOM for a package

Write the search as a function, so that you can run it for any package name. The function reads the SBOM digest of each artifact, downloads the document, and prints the artifact when the package is in it:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
has_package() {
  for pair in podinfo:6.15.0 alpine:3.20; do
    repo=${pair%%:*}; tag=${pair##*:}
    digest=$(api "$API/projects/audit/repositories/$repo/artifacts/$tag?with_sbom_overview=true" | jq -r '.sbom_overview.sbom_digest')
    regctl artifact get "harbor.localtest.me:8443/audit/$repo@$digest" \
      | jq -r --arg name "$1" --arg ref "audit/$repo:$tag" 'select([.packages[]? | select(.name == $name)] | length > 0) | "\($ref) has \($name)"'
  done
}
has_package musl
has_package curl
```

The first call lists the artifacts whose SBOM contains `musl`, and the second lists the ones with `curl`. The two answers do not have to be the same. A base image has few packages, and an application image often adds tools to it. The function prints nothing for an artifact that does not contain the package.

## Record the answer as a label

A **label** is a short tag that an administrator attaches to an artifact in Harbor, and it shows in the portal and in the API. A label turns the answer into data that stays with the artifact. A global label is created by the system administrator and any project can use it. Create one and attach it to an artifact:

```sh
api -X POST "$API/labels" -d '{"name":"uses-musl","scope":"g","color":"#1E88E5","description":"The SBOM lists musl"}'
LABEL_ID=$(api "$API/labels?name=uses-musl&scope=g" | jq -r '.[0].id')
api -X POST "$API/projects/audit/repositories/alpine/artifacts/3.20/labels" -d "{\"id\":$LABEL_ID}"
api "$API/projects/audit/repositories/alpine/artifacts/3.20" | jq '[.labels[]?.name]'
```

The last command lists the labels of the artifact. Harbor can then list every artifact with that label, so the answer outlives your shell session.

You can now search the SBOMs of several artifacts for one package and record the result as a label. The result is true for the SBOM that was read. A new image tag needs a new SBOM, and an old SBOM can be replaced, which is how Harbor treats them in the last part.

## Common pitfalls

> [!WARNING]
> - **Using the vulnerability report to find a package.** The report names only packages with a known flaw.
> - **Searching by part of a name.** An exact `select(.name == $name)` does not match `libcurl` when you ask for `curl`.
> - **Labelling by hand from memory.** Label from the document that you read.
> - **Forgetting artifacts without an SBOM.** Their digest is empty, and the loop then reads the wrong thing.

## Your mission: Label Artifacts By Package From Their SBOM

You can now generate SBOMs, read a package from them and attach a label. The graded lab gives you the project `audit` with two artifacts and no SBOMs. It asks you to generate both SBOMs and to label exactly the artifacts whose SBOM lists a package named `curl`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-020-02
astrona start ats-102-playground-020-02
```
