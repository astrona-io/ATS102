# Robot Accounts And Immutable Tags

Pipelines and clusters need to talk to Harbor, and they should not do it with a person's password. A pipeline that only deploys needs to pull, and nothing more. A release tag that people can overwrite is not a release at all, because the same name can mean a different image tomorrow.

This module covers two controls that close those gaps. A **robot account** is a Harbor account for a program, with a fixed set of permissions, a secret that Harbor shows once, and an expiry date. A **tag immutability rule** stops a tag from being overwritten or deleted once it matches the rule. Keep one sentence in mind: **give a program the least it needs for the shortest time it needs it, and make a release tag mean one image for good.**

The module has four parts. **Robot Accounts** creates one with exact permissions and a lifetime. **Using A Robot And Reading Refusals** signs in with it and reads what Harbor says when it refuses. **Immutable Tags** protects release tags, and a graded lab follows it. **A Pipeline Gate** puts the report and the policy together in a script that decides whether a release goes on.

## Learning objectives

After this module you can:

- Name the parts of a robot account: level, permissions, duration and secret.
- Create a project robot account that can only pull, and that expires.
- Sign in with a robot and tell its refusals apart by HTTP status.
- Refresh a robot secret and disable a robot account.
- Create a tag immutability rule and show what it blocks and what it allows.
- Write a gate script that fails a pipeline on a Critical finding with a fix.

## Before you start

You need to know what a project, a repository and a tag are in Harbor, and you will use `curl` and `jq` against a REST API.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `regctl`, `curl` and `jq`, and trusts Harbor's certificate. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds the project `inventory` with `inventory/podinfo:6.15.0`. It has no robot account and no immutability rule.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
