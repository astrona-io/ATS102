# Solution: Replicate A Signed Release To Production

Work the task yourself first. Running `astrona submit -c sections/section-030/module-04/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the rule exists and is correct, the digest in production equals the digest in staging, and the signature and SBOM are present in production.

## Step 1: Create the endpoint

In the workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/registries" -d '{
  "name": "self",
  "type": "harbor",
  "url": "https://harbor.localtest.me:8443",
  "insecure": true,
  "credential": {"type": "basic", "access_key": "admin", "access_secret": "Harbor12345"}
}'
```

## Step 2: Create the rule

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
```

## Step 3: Run it and wait

```sh
POL=$(api "$API/replication/policies" | jq '.[] | select(.name=="staging-to-prod") | .id')
api -X POST "$API/replication/executions" -d '{"policy_id": '"$POL"'}'
api "$API/replication/executions?policy_id=$POL" | jq '.[0] | {status, total, succeed, failed}'
```

Run the last command again until the status is `Succeed`.

## Step 4: Check the result

```sh
regctl image digest harbor.localtest.me:8443/staging/podinfo:6.15.0
DIGEST=$(regctl image digest harbor.localtest.me:8443/prod/podinfo:6.15.0)
echo $DIGEST
api "$API/projects/prod/repositories/podinfo/artifacts/6.15.0/accessories" | jq '.[] | .type'
cosign verify --key /root/build/cosign.pub harbor.localtest.me:8443/prod/podinfo@$DIGEST
```

The two digests are equal, both accessory types are listed, and the verification succeeds.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-04/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Copy the image with `regctl image copy` | The digest may match, but the grader also needs the rule and a successful execution, and the constraints forbid it |
| Sign the production copy again | The constraint forbids it, and the point is that the original signature travels |
| Use the filter `staging` without `/**` | The filter matches the repository name `staging`, which does not exist, and nothing is copied |

## Common mistakes

- Leaving the replace count at 0, so the artifact lands in `prod/staging/podinfo`.
- Reading `Succeed` with a total of 0 as success.
- Forgetting to start the execution, since the trigger is manual.
