---
name: receiving-code-review
description: Use when receiving code review feedback (from your human partner, a PR, or a reviewer subagent), before implementing any of it, especially when an item seems unclear or wrong
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time; run the affected tests after each, the full suite once at the end
```

## Forbidden Responses

**Don't say:** "You're absolutely right!", "Great point!", "Excellent feedback!", "Let me implement that now" (before verifying), or any thanks ("Thanks for [anything]").

**Instead:** restate the technical requirement, ask clarifying questions, push back with technical reasoning if it's wrong, or just start working; the code shows you heard the feedback. About to write "Thanks"? Delete it and state the fix.

## Handling Unclear Feedback

If any item is unclear, implement nothing yet: ask about the unclear items first. Items may be related, and partial understanding means wrong implementation. Asked to "Fix 1-6" with 4 and 5 unclear, don't implement 1,2,3,6 and ask later; say: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."

## Source-Specific Handling

### From your human partner
Trusted: implement after understanding; still ask if scope is unclear. No performative agreement; skip to action or technical acknowledgment.

### From External Reviewers
Be skeptical, but check carefully. Before implementing: Technically correct for THIS codebase? Breaks existing functionality? Reason for the current implementation? Works on all platforms/versions? Does the reviewer understand the full context?

If the suggestion seems wrong, push back with technical reasoning. If you can't easily verify it, say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?" If it conflicts with your human partner's prior decisions, stop and discuss with them first.

## YAGNI Check for "Professional" Features

If a reviewer suggests "implementing properly", grep the codebase for actual usage. Unused: propose removal. Used: implement properly. You and the reviewer both report to your human partner; if the feature isn't needed, don't add it.

```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

## Implementation Order

After clarifying, fix blocking issues (breaks, security) first, then simple fixes (typos, imports), then complex fixes (refactoring, logic). Run the affected tests after each fix and the full suite once at the end to check for regressions.

## When To Push Back

Push back when the suggestion breaks existing functionality, the reviewer lacks full context, it violates YAGNI, it's technically incorrect for this stack, legacy/compatibility reasons exist, or it conflicts with your human partner's architectural decisions. Use technical reasoning, not defensiveness: ask specific questions, reference working tests/code, and involve your human partner if it's architectural.

```
Reviewer: "Remove legacy code"
❌ "You're absolutely right! Let me remove that..."
✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**If you're uncomfortable pushing back out loud:** name that tension, then tell your partner about the issue you've seen. They'll appreciate your honesty.

## Acknowledging Correct Feedback

```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]
```

## Gracefully Correcting Your Pushback

Pushed back and were wrong? State the correction factually and move on, without long apologies, defending the pushback, or over-explaining:

```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."
```

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.
