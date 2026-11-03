# Summary

Replication copies artifacts between projects and registries by rule. A signature belongs to a digest, so a copy with the same digest keeps its signature valid, and Harbor carries the accessories with the artifact.

## What you learned

A registry endpoint holds an address and credentials. A replication policy names the source or the destination endpoint, the destination namespace and how many path levels to replace, a trigger, filters, and override. Filters match the name, the tag, a label or the resource type. The trigger is manual, scheduled or event-based, and manual fits promotion.

`POST /replication/executions` starts a run. An execution has tasks, one for each artifact, and the task log gives the reason for a failure. An execution with a total of 0 usually means a filter matched nothing. The destination project applies its own rules, so a signature requirement or an immutable tag can make a task fail.

To prove a copy, compare the digest of the source and the destination, list the accessories at the destination, and run `cosign verify` there. The key facts to remember are these:

- Same digest means same artifact, and the signature stays valid.
- Check the accessories, never assume them.
- Success with a total of 0 means the filter matched nothing.
- Replication copies. It does not sign or approve.

<!-- astrona:playground:destroy -->
