# agentic-rails: agent instructions

A Rails 8 pet shop on SQLite, Ruby 3.3.8 via asdf. The README covers routes, telemetry and the port plan
(`.meta/port-plan.org`).

## Rules

- gmake, not make. `gmake check` is the gate; bare `bin/rails` outside gmake can pick up the system Ruby, so put
  `~/.asdf/shims` first on `PATH` when running it directly.
- Tests never write to the owner's state dir. Run the suite with `XDG_STATE_HOME=$(mktemp -d)` from a worktree.
- Main on `127.0.0.1:4900` is the owner's review server. If it is down, restart it (`gmake serve` in a detached tmux
  session) and say so; never stop or restart another repo's server.
- Open questions get a best guess, not a question to the owner: this repo explores where the contract is
  silent. Write the guess, the reason and what would change it in `.meta/` or the PR, then carry on. Ask only
  for what an agent can't do (a credential, a click).
- Work in `worktrees/<task>` on a branch `agent/<task>`, one PR per concern. An unrelated fix found on the way
  gets its own PR, and the feature branch is rebased onto it so the fix lands first.
- Conventional commits; co-author lines go in with `git commit --trailer`.
- This repo is public: committed text names other projects by role, not by repo, and carries no personal details.

## Before leaving draft

1. `gmake check` passes from the worktree, with the run count stated in the PR.
2. Read `REVIEW.md`, then run `/code-review` on the branch.
3. Answer every finding in the PR: fixed (with the commit), or not fixed and why.
4. Only then mark the PR ready for review.

@REVIEW.md
