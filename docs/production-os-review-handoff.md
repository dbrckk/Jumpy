# Production-OS trusted Jumpy review handoff

The GitHub Actions credential used by `dbrckk/ai-dev-server` may publish a
review branch but lack permission to create pull requests (HTTP 403). This
opt-in workflow uses the **target repository's GitHub Actions token** instead
of adding cross-repository PR-write permissions to the source credential.

## Safe delivery contract

1. Production-OS publishes a `studio/mp-<24 hex>` review branch to Jumpy.
2. If the direct pull-request API returns 401/403, the worker dispatches
   `production_os_review_handoff` with the **exact** branch tip SHA.
3. GitHub executes this default-branch-only `repository_dispatch` handler.
   It checks the repository identity, branch format, SHA, Git ref, bounded
   comparison against `main`, and rejects GitHub automation or submodule
   configuration changes before trying to create a **draft** PR.
4. The worker reports delivery only after confirming a real PR with the
   same head SHA and exact repository identity. Accepted dispatch alone
   cannot be reported as a PR. No automatic merge occurs.

## First-use prerequisite

In `dbrckk/Jumpy` → Settings → Actions → General → Workflow permissions,
allow GitHub Actions to create pull requests if the repository settings
currently prohibit it. The workflow explicitly requests the least-privilege
`contents: read` and `pull-requests: write` job permissions; repository
settings can still deny PR creation. Never paste tokens into source files.

The `dbrckk/ai-dev-server` credential still needs its existing
`Contents: write` permission to publish the branch and authorization
for `repository_dispatch`. It does **not** need `Pull requests: write`
for this fallback.

## Verification

A successful workflow run plus a GitHub URL is not enough by itself:
verify `pull_request.head.sha` against the published commit, the real
PR's `head.repo.full_name=dbrckk/Jumpy`, and GitHub validation/build
checks. If permission is denied, leave the branch intact, show the
`pull_request_write_denied` / handoff status, and do not claim delivery.
The workflow must never execute untrusted branch code as part of this handoff.

This workflow does not fix Godot errors, failed coding generations,
provider rate limits, or Android build/physical-device qualification.
