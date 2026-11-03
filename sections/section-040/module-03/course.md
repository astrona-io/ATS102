# Keep Storage Under Control With Retention

A registry that only grows becomes slow to browse, costly to store and hard to audit. Every CI build pushes a tag, and nobody deletes the old ones. A **retention policy** deletes tags for you, by rules you write down, and keeps the ones you say matter.

The question this module answers is: **which tags does a rule keep, and what happens to the rest?** A retention rule names the tags to keep. Everything in scope that no rule keeps is removed. This is the opposite of what many people expect, so read the rules carefully before you run them.

The module has four parts. **How Retention Rules Work** explains templates and selectors. **Dry Runs And Executions** runs a policy safely. **Applying A Policy To A Project** creates a policy and checks the result, and a graded lab follows it. **Retention With Immutability And Garbage Collection** covers how retention fits with immutable tags and the space that deletion frees.

## Learning objectives

After this module you can:

- Explain that a retention rule lists what to keep, and that the rest in scope is deleted.
- Choose a template such as most recently pushed, most recently pulled or pushed within a number of days.
- Write tag and repository selectors, including excluding selectors.
- Run a dry run and read what would be deleted before it happens.
- Create a policy through the API and start an execution.
- Say why deleted tags do not free disk space until garbage collection runs.

## Before you start

You need to know projects, repositories, tags and digests in Harbor. You will use `curl` and `jq` against a REST API.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. The `workstation` pod holds `regctl`, `curl` and `jq`. Open a shell in it on your machine with:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Harbor already holds the project `inventory` with `inventory/podinfo` at the tags `6.0.0`, `6.14.1` and `6.15.0`, pushed in that order.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
