# Summary

Retention keeps storage under control by deleting what no rule keeps. This module showed how to write the rules, how to test them with a dry run, and how deletion relates to immutability and garbage collection.

## What you learned

A retention policy belongs to one project. Each rule lists what to keep, using a template such as `latestPushedK`, a repository selector and a tag selector. Rules combine with or, and everything in scope that no rule keeps is deleted. The `always` template protects tags.

`POST /retentions` creates a policy with an algorithm, rules, a trigger and a scope of level `project` and the numeric project id. The retention id is then in the project metadata. `POST /retentions/{id}/executions` with `dry_run` set to true computes the result without deleting, and with false it deletes. Tasks report `retained` and `total` for each repository.

Immutable tags cannot be deleted by retention. Deleted artifacts free disk space only after garbage collection removes blobs that nothing refers to. The key facts to remember are these:

- A rule says what to keep, and the rest in scope is deleted.
- Always dry run first.
- `latestPushedK` ranks by push time, not by version.
- Garbage collection frees the space.

<!-- astrona:playground:destroy -->
