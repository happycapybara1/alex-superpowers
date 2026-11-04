---
name: requesting-code-review
description: Use when a major feature or a whole plan is complete, or before merging, to have a fresh reviewer check the work against its requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:** after completing a major feature; before merge to main.

**Optional but valuable:** when stuck (fresh perspective); before refactoring (baseline check); after fixing a complex bug.

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git merge-base origin/main HEAD)  # or the commit you recorded before the work began
# not HEAD~1: it covers only the last commit
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch a `general-purpose` subagent,** filling the template at [code-reviewer.md](code-reviewer.md):
- `[DESCRIPTION]` - Brief summary of what you built
- `[PLAN_OR_REQUIREMENTS]` - What it should do
- `[BASE_SHA]` - Starting commit
- `[HEAD_SHA]` - Ending commit
- `[REVIEW_PACKAGE]` - Optional: path to a review package file, if you made one

**No subagent tool:** do the review yourself as a separate pass, following code-reviewer.md, and say in your report that it was a self-review.

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Handle the findings with alex-superpowers:receiving-code-review, including when the reviewer is wrong

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll just review the diff myself instead of dispatching a reviewer" | Reviewing inline burns the context window you need to keep driving the work. In a subagent, the diff and evaluation stay in its context; only the findings come back. |
| "The reviewer needs my whole session history to understand the change" | Precisely crafted context keeps the reviewer on the work product, not your thought process. |

## Red Flags

**Never** skip review because "it's simple", ignore Critical issues, proceed with unfixed Important issues, or argue with valid technical feedback.
