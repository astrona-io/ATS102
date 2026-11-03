# Summary

Robot accounts limit what a program can do, and immutable tags limit what a tag can become. Together with a gate script they turn Harbor's reports and policies into decisions a pipeline can make alone.

## What you learned

A robot account has a level, a name with the prefix `robot$project+name`, a list of permissions, a duration in days and a secret that Harbor shows once. A project robot reaches one project and a system robot can reach several. A pull-only robot has the action `pull` on `repository` and nothing else. `PATCH` on the robot replaces its secret, and `disable` stops it without deleting it. The name must be quoted in a shell because of the `$`.

A refusal is read from the HTTP status. `401` means the credential is not accepted, for example a wrong name, an expired robot or a disabled one. `403` means the permissions are not enough. `404` means the artifact is not visible. `412` means a project policy blocked the request. A login can succeed while a pull fails, because the permissions apply when the token is used.

A tag immutability rule selects repositories and tags with doublestar patterns. Matching tags can be neither overwritten nor deleted, by anyone. A narrow pattern leaves working tags free. A gate script reads the scan status and the report, exits with different codes, fails closed when it cannot decide, and passes on the digest that it checked. The key facts to remember are these:

- Give a program the fewest permissions and the shortest lifetime that work.
- A robot secret is shown once; refresh it instead of recreating the robot.
- `401`, `403`, `404` and `412` have four different causes.
- An immutable tag means one image for good, and the digest is still the safest reference.

<!-- astrona:playground:destroy -->
