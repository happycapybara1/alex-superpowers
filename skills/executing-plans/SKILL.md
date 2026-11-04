---
name: executing-plans
description: Use when executing an implementation plan in the current session as the implementer yourself — your human partner chose inline execution, or no subagent tool is available
---

# Executing Plans

Execute the plan yourself, task by task, in this session: no implementer
subagent per task, no reviewer per task. One fresh-context review of the
whole branch at the end.

**Why inline:** Subagent-driven development pays for a fresh implementer
and a fresh reviewer on every task, each re-reading the codebase from zero.
Inline execution pays for one context (yours) plus one reviewer at the end.
It gives up a fresh context and a second pair of eyes per task, and keeps
what they bought by other means: the brief is the spec, the ledger is your
memory, TDD is the per-task gate, and the final reviewer is the second pair
of eyes.

**Core principle:** The plan already did the thinking. Execute it exactly,
prove each step with a test you watched fail and then pass, and leave a
record that survives your own forgetting.

**Read [execution-rules.md](../subagent-driven-development/references/execution-rules.md) now, and again after any compaction** — the rules this skill shares with subagent-driven-development: continuous execution (your partner chose inline to spend less, not to answer "should I continue?"), rulings, the four things that stop you, narration, the ledger, Setup, and Finish.

## When to Use

- You have a plan from superpowers:writing-plans and your human partner
  chose inline execution at the handoff.
- Your harness has no subagent tool (see the per-platform references in
  `../using-superpowers/references/`). Never fabricate a dispatch; run
  the plan here.

A fully specified plan makes inline execution transcription plus testing:
it runs well on a mid-tier session model, and the one place the most
capable model earns its cost is the final review, which this skill
dispatches separately. Tell your human partner so when they choose inline.

Prefer superpowers:subagent-driven-development when your human partner
wants a review gate on every task, or when the plan is long enough that
its later tasks would run on a compacted context. Inline execution over a
long plan still works — the ledger makes it recoverable — but the last
tasks get the least of you.

## Setup

Run Setup from execution-rules.md (worktree, plan workspace, ledger, plan
and spec, pre-flight scan). Then:

**REQUIRED SUB-SKILL:** load superpowers:test-driven-development now,
before Task 1. It governs every step of every task below; a plan whose
steps already say "write the failing test first" does not exempt you
from reading it.

## The Task Loop

### 1. Take the task

- Run this skill's `scripts/task-start PLAN_FILE N`. It prints the brief
  path and BASE (the commit the task's range is cut from) in one call.
  Read the brief for every task, including ones you remember from setup:
  what you remember is a summary; the brief has the exact values,
  signatures, and test cases.
- Mark the task's todo in_progress.

### 2. Work the steps

The plan's steps are already in RED-GREEN order; follow them in that
order under superpowers:test-driven-development. A test step's code is
written first and run first. Watching it fail is a step, not a formality
— a test that passes before the implementation exists is a finding about
the test.

Every step that runs a command has an `Expected:` line. Run the command,
read its output, and compare. Three outcomes:

- **Matches.** Next step.
- **The code is wrong.** Use superpowers:systematic-debugging. Find the
  cause; never patch the symptom to make the step's output match.
- **The plan is wrong** — a step contradicts the spec, an interface from an
  earlier task doesn't match what this task consumes, a command that
  cannot work. Rule on the smallest change that satisfies the spec, ledger
  it as `Task <N>: Ruling: <finding> — <what you decided and why>`, and
  continue. Later tasks that touch the same interface read the ruling from
  the ledger, not from memory.

Commit as the plan's commit steps say. A task may span several commits;
BASE is what the review range is cut from, never `HEAD~1`.

### 3. The completion contract

Before a task's ledger line, all of the following are true, with evidence
in this session — not inferred from the diff looking right:

- Every test the brief names exists and ran in this task, and you read
  the output.
- The final test run for the task passed — `task-done` is that run, and
  it writes the command and result into the ledger line.
- Every `Expected:` line in the brief was compared against real output.
- Every deviation from the brief has a `Ruling:` line in the ledger.

**REQUIRED SUB-SKILL:** superpowers:verification-before-completion governs
the claim. If any item is missing, the task is not complete: finish it.

### 4. Complete the task

Run this skill's `scripts/task-done PLAN_FILE N BASE -- <test command>`
with the test command the brief names for the whole task. It runs the
tests, keeps the full output in the workspace, prints the tail, and — only
if they pass — appends the completion line to the ledger:

`Task <N>: complete (commits <base7>..<head7>, tests: <command> → <result>)`

A failing run records nothing; the task is not complete. When it records,
mark the todo complete and take the next task.

## Final Review

Run `../subagent-driven-development/scripts/review-package PLAN_FILE MERGE_BASE HEAD`
(MERGE_BASE = the commit the branch started from, e.g.
`git merge-base main HEAD`) and review from the file it prints.

**With a subagent tool:** dispatch the reviewer with
superpowers:requesting-code-review's
[code-reviewer.md](../requesting-code-review/code-reviewer.md) on the
most capable available model — the whole-branch review is a judgment
task. Specify the model explicitly; an omitted model inherits the
session's, which may not be the most capable. Give it the package path,
the plan and spec paths, the plan's Review Focus section verbatim if it
has one (the input classes and failure modes the plan's tests do not
exercise — the reviewer checks each deliberately), and a pointer to the
ledger's `Ruling:` lines so it can weigh the calls you made. This is the
one fresh context the whole run buys: do not skip it, and do not replace
it with your own read of the diff.

**Without a subagent tool:** read code-reviewer.md and perform that review
yourself against the package, as a separate pass after the last task's
ledger line. Write `Final review: self-review (no subagent tool)` to the
ledger and say so in your final message: a self-review by the author is
weaker than a fresh reviewer, and your human partner decides whether that
is enough before merge.

Sort the findings before you act on any of them; the reviewer's severity
labels are advice, the gate is yours. Re-grade first, by effect: the spec
is a vision document, and a finding's grade is what a reasonable person
using this software gets if it ships, not whether the spec names the
input that triggers it — a reviewer who set a finding at Minor because
the spec was silent graded the spec, not the effect. Its "Declined to
judge" list is yours too: every line is a ruling you make and ledger,
like a plan conflict — `Final: Ruling: <behavior the reviewer set aside> —
<what a reasonable person using this software gets, and why that stands
or why it is now a finding> — <cost if wrong>`. Then:

- **Critical and Important** enter the fix pass.
- **Minor** goes to the ledger as `Final: minor (deferred): <one-liner>`
  and to your final message under "Deferred minors". Minors never enter
  the fix pass and never become rulings — a ruling decides a conflict; it
  is not a note that you declined a polish suggestion.

Fix the Critical and Important findings yourself, in ONE pass. Each fix is
verified by TDD, not by a second reviewer: write the test that reproduces
the finding, watch it fail, make it pass, then run the whole suite. Ledger
each as `Final: fixed <finding> — <test name> RED→GREEN, suite <N>/<N>`. A
fix without a test that failed first is not verified; a suite that is not
green means the pass is not over. Do not dispatch a re-review: the
covering tests already answer "addressed" and the suite run already
answers "broke nothing".

A finding you decide not to fix is a ruling — `Final: Ruling: <finding> —
<why the code stands> — <cost if wrong>` — and reaches your human partner
in the rulings list. There is no second fix pass.

## Finish

Re-read the Finish section of execution-rules.md now and follow it: the
final message with "Rulings I made" and "Deferred minors", workspace
cleanup, then superpowers:finishing-a-development-branch.

## Common Rationalizations

The rows on check-ins, unledgered deviations, and the ledger are in
execution-rules.md.

| Excuse | Reality |
|--------|---------|
| "I remember what Task N says" | You remember a summary. The brief has the exact values. Read it. |
| "The plan's code is right, skip watching the test fail" | A test you never saw fail proves nothing. It is one step. Run it. |
| "I'll run the full suite at the end instead of per step" | Per-step runs show which step broke it. The end-of-task run is the contract, not a substitute. |
| "I read my own diff carefully; the final reviewer is redundant" | Same author, same blind spots. The reviewer is the only fresh context this run buys. |
| "Tests should pass, the change was trivial" | "Should" is not evidence. The contract requires the command and its output. |
| "Subagents are slow and expensive, I'll skip the final review too" | Inline already removed the per-task reviewers. One whole-branch review is the floor, not the ceiling. |
| "The reviewer said Minor, so it's Minor" | The label graded the spec's silence. Grade what the person gets, then gate. |
| "The fix is obvious, no need for a failing test first" | The failing test is the only proof the finding was real and is now gone. Without it you have a diff and a hope. |
| "I'll fix the minors too while I'm in there" | Each is a test, a fix, and a suite run your partner did not ask for. Ledger them; your partner decides. |
