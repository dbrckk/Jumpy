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
4. The trusted target handler then triggers `Validate Godot Project` with
   `workflow_dispatch` on the managed branch and passes the exact commit
   SHA. The separate validation workflow checks the SHA **before running
   the headless Godot parser**. It has `contents: read` only and does not
   use Studio credentials. Handoff itself never checks out Studio code.
5. The worker reports delivery only after confirming a real PR with the
   same head SHA and exact repository identity. Accepted dispatch alone
   cannot be reported as a PR. No automatic merge occurs.

## First-use prerequisite

In `dbrckk/Jumpy` → Settings → Actions → General → Workflow permissions,
allow GitHub Actions to create pull requests if the repository settings
currently prohibit it. The handoff workflow requests `contents: read`, `pull-requests: write`
and `actions: write` (the last permission is required to dispatch the
specific Godot validation workflow). Repository settings can still deny
PR creation or workflow dispatch. Never paste tokens into source files.

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


## Why draft PRs can show "Action required"

GitHub marks `pull_request` workflow runs created using a repository's
`GITHUB_TOKEN` as requiring human approval. This is a GitHub permission
boundary, not a failed Godot parse. The separate `workflow_dispatch`
check runs automatically and verifies the SHA, Godot parse and essential
production docs. The original approval-required PR check may still show
"Action required"; a maintainer can approve it on GitHub.

Only merge after reviewing the diff and ensuring the independent
exact-SHA Godot validation succeeded. Never treat a successful
`repository_dispatch` or PR creation alone as successful CI.
