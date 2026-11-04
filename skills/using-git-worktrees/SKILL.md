---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current workspace, or before executing an implementation plan
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

## Step 0: Detect Existing Isolation

**Before creating anything, check whether you are already isolated.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside a submodule. If `git rev-parse --show-superproject-working-tree 2>/dev/null` prints a path, you're in a submodule: treat it as a normal repo.

**If `GIT_DIR != GIT_COMMON` (not a submodule):** you're already in a linked worktree. Don't create another; skip to Step 2 and report:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or a submodule):** you're in a normal checkout.

- **Disposable checkout:** in a cloud or container session on a branch other than the default branch, the checkout is already disposable. Treat it as isolated and skip to Step 2 without asking.
- **Otherwise,** honor any worktree preference your instructions declare, without asking. With none declared, ask for consent before creating a worktree:

  > "Would you like me to set up an isolated worktree? It protects your current branch from changes."

  If the user declines, work in place and skip to Step 2.

## Step 1: Create Isolated Workspace

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). If you have a native way to create a worktree — a tool named like `EnterWorktree` or `WorktreeCreate`, a `/worktree` command, a `--worktree` flag — use it and skip to Step 2.

**Base of a new worktree:** Claude Code's `EnterWorktree` branches from `origin/<default-branch>` unless the `worktree.baseRef` setting is `head`. If the work needs local commits (`git log origin/<default-branch>..HEAD` lists some), create the worktree with Step 1b, then enter it with `EnterWorktree` and its `path`. Uncommitted files (a new design doc or plan) reach no new worktree; refer to them by absolute path.

### 1b. Git Worktree Fallback

**Only if Step 1a does not apply** — you have no native worktree tool.

#### Directory Selection

In priority order (explicit preference beats filesystem state):

1. **A worktree directory declared in your instructions:** use it without asking.
2. **An existing project-local directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If both exist, `.worktrees` wins.
3. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

Verify the directory is ignored before creating the worktree, or its contents get committed to the repository:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If not ignored, add it to `.git/info/exclude` (a local-only ignore, nothing to commit), then proceed.

#### Create the Worktree

```bash
path="$LOCATION/$BRANCH_NAME"
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** if `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked it and you're working in the current directory, then run setup and baseline tests in place.

## Step 2: Project Setup

Install dependencies with the tool the lockfile names:

| Lockfile | Command |
|----------|---------|
| `package-lock.json` | `npm ci` |
| `pnpm-lock.yaml` | `pnpm install` |
| `yarn.lock` | `yarn install` |
| `uv.lock` | `uv sync` |
| `poetry.lock` | `poetry install` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `go.sum` | `go mod download` |
| `Cargo.lock` | `cargo fetch` |

No lockfile: skip, unless the project's README names a setup command.

## Step 3: Verify Clean Baseline

Run the project's tests (`npm test` / `cargo test` / `pytest` / `go test ./...`). If they fail, report the failures and ask whether to proceed or investigate. If they pass, report:

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Harness-created isolation and submodules both fool eyeballing. |
| "`git worktree add` is quicker than hunting for a native tool" | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake: phantom state your harness can't see or manage. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. An unignored directory commits the whole tree into the repo. |
| "Any directory name works" | Explicit instructions beat an existing project-local directory, which beats the `.worktrees/` default. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. Proceeding past failures is your human partner's call. |
