---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work
---

# Finishing a Development Branch

## Overview

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

## Step 1: Verify Tests

Run the project's full test suite (`npm test` / `cargo test` / `pytest` / `go test ./...`). If it fails, report and stop — the menu comes after a green suite:

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]
```

## Step 2: Detect Environment

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
# Capture now: Step 5 leaves the workspace before cleanup (Step 6) needs it
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 3 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 3 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 2 options (no merge) | Externally managed — leave in place |

**Cloud or container session:** anything that stays local vanishes when the container is reclaimed. Use the cloud menu in Step 4.

## Step 3: Determine Base Branch

The base branch is whatever this work forked from, usually named in the plan, the conversation, or the branch's upstream. If it is not known, ask: "This branch split from <your best guess> - is that correct?" Confirm it before merging.

## Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 3 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)

Which option?
```

**Cloud or container session — present these 2 options:**

```
Implementation complete. This session's machine is temporary, so the work needs to be pushed.

1. Push and create a Pull Request
2. Push the branch only (I'll handle it later)

Which option?
```

**Detached HEAD — present exactly these 2 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)

Which option?
```

Present the menu as written, every option from the list above, optionally opened with one line: "Recommended: <N> — <reason>". Discarding happens only when your human partner explicitly asks (see below). Wait for their answer; the integration decision is theirs.

## Step 5: Execute Choice

### Option 1: Merge Locally

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull --ff-only
git merge <feature-branch>
<test command>   # on the merged result
```

If it fails, stop and investigate with worktree and branch in place; the unpushed merge is recoverable. Once green, clean up the worktree (Step 6), then `git branch -d <feature-branch>`.

### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>
# From a detached HEAD, name the new branch on the remote:
# git push origin HEAD:refs/heads/<new-branch>
```

Open the pull/merge request against <base-branch> with the forge's CLI or the creation URL most forges print on push, following the repo's PR template and conventions, and report the URL. Keep the worktree: your human partner iterates on PR feedback there.

### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

### If your human partner asks to discard the work

Only on an explicit request to throw the work away. Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for that exact confirmation. Then `cd` to the main repo root as in Option 1, clean up the worktree (Step 6), and force-delete the branch: `git branch -D <feature-branch>`.

## Step 6: Cleanup Workspace

**Runs for Option 1 and confirmed discards only.** Both have already moved to the main repo root (removal must run from outside the worktree); use the values captured in Step 2.

**If `GIT_DIR == GIT_COMMON`:** normal repo, nothing to clean up.

**If `WORKTREE_PATH` is under `.worktrees/`, `worktrees/`, or the worktree directory your instructions declare:** Superpowers created it, so we own cleanup:

```bash
git worktree remove "$WORKTREE_PATH"
git worktree prune  # clean up stale registrations
```

**If removal is refused** (`contains modified or untracked files`), those files (uncommitted plans, notes, scratch work) exist nowhere else. Never `--force` on your own initiative. Run `git -C "$WORKTREE_PATH" status --porcelain -uall` and ask:

```
Worktree removal refused — these files were never committed:

<file list>

1. Commit them to <branch> before cleanup
2. Move them into <main repo root>
3. Delete them (unrecoverable)

Which?
```

Carry out the choice, then remove the worktree.

**Otherwise:** the host owns this workspace — leave it in place, using your platform's workspace-exit tool if it has one. Claude Code: a worktree from `EnterWorktree` lives under `.claude/worktrees/`; after Option 1 or a confirmed discard, call `ExitWorktree` with `remove`, which deletes the branch too (skip `git branch -d`/`-D`).

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | A green run only proves the tree it ran on; rerun on the tree you're integrating. |
| "They obviously want it merged" | Integration is your human partner's call. Present the menu and wait. |
| "They seem done with this feature — I'll offer to discard it" | The menu is complete as written. Discard only on explicit request. |
| "'Yeah, get rid of it' counts as confirmation" | Only the typed word `discard` authorizes deletion. |
| "The PR is up, so the worktree is clutter now" | PR feedback gets fixed there; it stays until the work lands. |
| "This other worktree looks stale — I'll clean it too" | Only worktrees under `.worktrees/`, `worktrees/`, or your declared directory are ours; the rest belong to the host. |
| "Removal refused — `--force` is just finishing the cleanup" | `--force` permanently destroys files that exist only there. Show your human partner and ask. |
| "The merged-result failure is probably flaky" | It stops everything; branch and worktree stay put while you investigate. |
| "The base branch is obviously main" | Confirm the fork point or ask. A wrong-base merge is expensive to undo. |
| "The push was rejected — force-push will fix it" | The remote moved. Investigate; force-push only on your human partner's explicit request. |
