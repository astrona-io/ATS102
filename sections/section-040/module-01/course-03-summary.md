# Summary

A vulnerability report refuses nothing on its own. This module showed how a Harbor project turns its reports into a policy that refuses risky artifacts, and how to make narrow exceptions that end on their own.

## What you learned

Vulnerability prevention is two project settings: `prevent_vul` turns it on, and `severity` sets the threshold, one of `low`, `medium`, `high` or `critical`. On every manifest pull, `core` reads the artifact's report and refuses it when its worst finding is at or above the threshold. The refusal is `412 Precondition Failed` with the code `PROJECTPOLICYVIOLATION` and a message naming the number of vulnerabilities and the policy. The system administrator is refused like everyone else. Because a cluster cannot run what it cannot pull, the setting is called "Prevent vulnerable images from running".

Three cases need care. An artifact without a report is refused, so prevention needs scan on push. An image index is not checked itself, but each platform image is checked when it is pulled. The scanner's own pulls and the pulls of signing clients are exempt.

A CVE allowlist names CVE IDs that Harbor ignores when it decides. There is one system allowlist and one per project. The project key `reuse_sys_cve_allowlist` picks between them, and when it is not set, the project reuses the system list. Each list has `items` with a `cve_id` and an optional `expires_at` in seconds since the epoch; once that time is reached, Harbor ignores the whole list. A good exception lives in one project, lists only the reviewed findings of one image, and expires. The key facts to remember are these:

- The threshold blocks at or above its severity.
- Unscanned artifacts are refused while prevention is on.
- A project without `reuse_sys_cve_allowlist` uses the system allowlist.
- An expired allowlist is ignored, so the image is blocked again.

<!-- astrona:playground:destroy -->
