# Endpoints And Rules

A replication rule needs two things: a place to copy to or from, and a description of what to copy. The place is a **registry endpoint**. The description is the **replication policy**, which Harbor also calls a rule. This part creates both for a copy inside the same Harbor, which is enough to learn every field.

## Registry endpoints

An endpoint stores the address and the credentials of a registry. The type says what kind of registry it is: `harbor` for another Harbor, and others for Docker Hub, GitLab and more. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Set the helpers, and list the endpoints:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/registries" | jq 'map({id, name, type: .type, url})'
```

The list is empty. Create an endpoint that points at this Harbor, so that you can replicate between its projects:

```sh
api -X POST "$API/registries" -d '{
  "name": "self",
  "type": "harbor",
  "url": "https://harbor.localtest.me:8443",
  "insecure": true,
  "credential": {"type": "basic", "access_key": "admin", "access_secret": "Harbor12345"}
}'
api "$API/registries" | jq 'map({id, name, status})'
```

`insecure` means Harbor does not check the certificate of the endpoint. That is acceptable for a lab and wrong for production. In production, give a robot account to the endpoint and not an administrator login.

Pull replication copies from the endpoint to this Harbor. Push replication copies from this Harbor to the endpoint. The rule decides which one it is, and the endpoint is just the other end.

## The replication policy

A rule has these fields:

| Field | What it does |
| --- | --- |
| `name` | The name of the rule |
| `src_registry` | The endpoint to pull from. Leave it out for push rules |
| `dest_registry` | The endpoint to push to. Leave it out for pull rules |
| `dest_namespace` | The project to copy into. Leave it out to keep the source project name |
| `dest_namespace_replace_count` | How many levels of the source path to replace by the destination namespace |
| `trigger` | When the rule runs |
| `filters` | What to copy |
| `override` | Whether to overwrite an artifact that already exists at the destination |
| `enabled` | Whether the rule can run |

## Create a push rule

Find the id of the endpoint, and create a rule that copies everything in `staging` to `prod`:

```sh
EP=$(api "$API/registries" | jq '.[] | select(.name=="self") | .id')
api -X POST "$API/replication/policies" -d '{
  "name": "staging-to-prod",
  "dest_registry": {"id": '"$EP"'},
  "dest_namespace": "prod",
  "dest_namespace_replace_count": 1,
  "trigger": {"type": "manual"},
  "filters": [{"type": "name", "value": "staging/**"}],
  "override": true,
  "enabled": true
}'
api "$API/replication/policies" | jq 'map({id, name, dest_namespace, enabled})'
```

With `dest_namespace_replace_count` set to 1, the first level of the source path, `staging`, is replaced by `prod`. So `staging/podinfo` becomes `prod/podinfo`. With 0, the destination namespace is put in front instead, and the result would be `prod/staging/podinfo`. Harbor creates the destination project if your credentials allow it.

You have an endpoint and a rule. Nothing has been copied yet, because the trigger is manual and nobody started it.

## Common pitfalls

> [!WARNING]
> - **Giving an endpoint an administrator login in production.** Use a robot account with the least rights.
> - **Leaving `insecure` on.** It switches off the certificate check.
> - **Mixing up the replace count.** A wrong count puts artifacts under a path nobody expected.
> - **Pointing a rule at an endpoint and forgetting which end is the source.** Source and destination decide pull or push.
