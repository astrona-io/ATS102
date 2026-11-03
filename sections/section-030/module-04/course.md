# Replicate Signed Artifacts Between Projects

Harbor can copy artifacts from one place to another by itself. This is called **replication**. A team pushes to a staging project, and a replication rule copies the approved artifacts to production, to another Harbor, or to another registry. Done well, the copy keeps the digest the same, so a signature made in staging still checks out in production.

The question this module answers is: **what travels with the artifact, and how do you prove it arrived whole?** The artifact itself travels. Its accessories, which are the signatures and SBOMs, are meant to travel with it. You check both by comparing digests and by running the same verification against the copy.

The module has four parts. **Endpoints And Rules** sets up the pieces. **Filters And Triggers** controls what is copied and when. **Signatures And SBOMs In Replication** runs a rule and checks the accessories, and a graded lab follows it. **Reading Executions And Failures** shows how to find out why a copy did not happen.

## Learning objectives

After this module you can:

- Create a registry endpoint and a replication rule through the Harbor API.
- Use name filters, destination namespaces and the override setting.
- Choose between manual, scheduled and event-based triggers.
- Start an execution, wait for it, and read its status and tasks.
- Show that a replicated artifact has the same digest as the source.
- Check that the signature and the SBOM arrived with the artifact.

## Before you start

You need to know projects, digests and accessories in Harbor, and how to sign with Cosign. You will use `curl` and `jq` against a REST API.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `cosign`, `regctl`, `curl` and `jq`. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds the project `staging` with `staging/podinfo:6.15.0`, signed with a Cosign key pair in `/root/build` (password `build-signing-password`) and carrying an SBOM. The project `prod` is empty.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
