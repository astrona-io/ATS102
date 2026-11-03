# Using A Robot And Reading Refusals

A robot is only proven when you use it. This part signs in with the robot from the previous part, does one thing it may do and two things it may not, and reads each refusal. Reading a refusal correctly is a daily skill: the HTTP status tells you whether the problem is the credential, the permission or the policy.

## Sign in and pull

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Create a short-lived pull-only robot again for this part, and save its secret:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
SECRET=$(api -X POST "$API/robots" -d '{"name":"reader","level":"project","duration":1,"disable":false,"permissions":[{"kind":"project","namespace":"inventory","access":[{"resource":"repository","action":"pull"}]}]}' | jq -r '.secret')
regctl registry login harbor.localtest.me:8443 -u 'robot$inventory+reader' -p "$SECRET"
regctl image digest harbor.localtest.me:8443/inventory/podinfo:6.15.0
```

The digest prints, because the robot may pull from `inventory`.

## Try what the robot may not do

Pushing needs the `push` action. Copy a small image into the repository with the robot's login:

```sh
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:9.9.9
```

The push fails, because the robot has no `push` permission. Reading from another project fails differently. Ask the registry directly, with the robot's credentials, for a repository in a project it has no access to:

```sh
curl -s -o /dev/null -w '%{http_code}\n' -u 'robot$inventory+reader:'"$SECRET" 'https://harbor.localtest.me:8443/service/token?service=harbor-registry&scope=repository:warmup/anything:pull'
```

The token service answers `200` even for a scope the robot lacks, and it returns a token that grants nothing for it. The refusal comes when the token is used on the registry. That is why a login can succeed while a pull still fails, and why "I can sign in" is not "I have access".

## Read the status

Use the status code to find the cause:

| Status | Meaning | What to check |
| --- | --- | --- |
| `401` | Harbor does not know who you are | The name, the quotes around `$`, the secret, the expiry, and whether the robot is disabled |
| `403` | Harbor knows you and says no | The permissions of the robot, and the project it names |
| `404` | The repository or tag is not visible to you | The name, and whether the robot may see the project |
| `412` | A project policy refused the request | The project settings, such as content trust or the vulnerability gate |

A `401` after a week of working is almost always an expired robot. A `412` has nothing to do with the credential, because the request was understood and the artifact is blocked by a rule. Print the status of a pull yourself with `curl -s -o /dev/null -w '%{http_code}'` against the manifest URL when a client only says "failed".

## Expiry in practice

```sh
api "$API/robots?q=name=~reader" | jq '.[] | {name, creation_time, expires_at}'
```

The duration of `1` gives a robot that lives for one day, which suits a task such as one deployment. Choose the shortest lifetime that your rotation can renew, and put the renewal in the pipeline, not on a calendar.

You can now sign in with a robot, tell its refusals apart, and read its expiry. A robot controls who may pull and push, but not what a tag means after a push, which is the job of immutability rules.

## Common pitfalls

> [!WARNING]
> - **Reading every failure as a wrong password.** A `403` and a `412` are not credential problems.
> - **Trusting a successful login.** The permissions apply when the token is used.
> - **Debugging through the client's summary.** Read the HTTP status.
> - **Forgetting renewals.** A robot with a short life needs a plan to be replaced before it expires.
