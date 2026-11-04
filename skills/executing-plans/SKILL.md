---
name: executing-plans
description: Use when executing an implementation plan in the current session as the implementer yourself — your human partner chose inline execution, or no subagent tool is available
---

# Executing Plans

Execute the plan yourself, task by task, in this session: no implementer
subagent per task, no reviewer per task. One fresh-context review of the
whole branch at the end.

**Why inline:** Subagent-driven development pays for a fresh implementer
and reviewer on every task, each re-reading the codebase from zero; inline
pays for one context (yours) plus one reviewer at the end. What the
per-task seats bought, this skill keeps by other means: the brief is the
spec, the ledger is your memory, TDD is the per-task gate, and the final
reviewer is the second pair of eyes.

**Core principle:** The plan already did the thinking. Execute it exactly,
prove each step with a test you watched fail and then pass, and leave a
record that survives your own forgetting.

**Narration:** between tool calls, at most one short line — the ledger
and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner
between tasks. They chose inline execution to spend less, not to answer
"should I continue?" after every task. Execute all tasks without stopping.

**Rulings, not stalls.** Conflicts, ambiguities, plan defects — decide
them. The spec is the binding authority, the plan is its argument, and
your judgment settles what neither answers. Record every decision in the
ledger as `Ruling: <what you decided> — <why> — <what it costs if wrong>`,
and keep going. Deviating from the plan without a ledgered ruling is a
decision made in secret.

Four things stop you, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this
worktree that norms say you ask about first (a merge, a push to a shared
branch, a publish); and a plan so broken that every path forward is a
guess. For those, stop and ask.

## When to Use

- You have a plan from alex-superpowers:writing-plans and your human partner
  chose inline execution at the handoff.
- Your harness has no subagent tool (see the per-platform references in
  `../using-superpowers/references/`). Never fabricate a dispatch; run
  the plan here.

A fully specified plan makes inline execution transcription plus testing:
a mid-tier session model runs it well, and the most capable model earns
its cost only in the final review, which this skill dispatches
separately. Tell your human partner so when they choose inline.

Prefer alex-superpowers:subagent-driven-development when your human partner
wants a review gate on every task, or the plan is long enough that later
tasks would run on a compacted context: the ledger keeps a long inline
run recoverable, but the last tasks get the least of you.

## Setup

Work in an isolated workspace: alex-superpowers:using-git-worktrees creates
or verifies one. Never start implementation on a main/master branch
without your human partner's explicit consent.

Conversation memory does not survive compaction. An inline executor that
loses its place re-implements tasks whose commits already exist. Track
progress in a ledger file, not only in todos: todos are a live view, the
ledger is the record. Workspace and ledger format are shared with
alex-superpowers:subagent-driven-development, so a plan can switch executors
mid-flight.

- At skill start, run
  `../subagent-driven-development/scripts/sdd-workspace PLAN_FILE`. It
  prints the plan's git-ignored directory
  (`<repo-root>/.superpowers/sdd/<plan-basename>/`), home to every
  artifact for THIS plan: ledger, briefs, review packages. Another plan's
  directory is never yours to read or write. `git clean -fdx` destroys
  this git-ignored scratch; if that happens, recover from `git log`.
- Check for this plan's ledger at `<workspace>/progress.md`. If its first
  line names your plan file, tasks with a `Task <N>: complete` line are
  DONE — do not redo them; resume at the first task without one. Their
  commits exist even when you no longer remember making them: after
  compaction, trust the ledger and `git log` over your recollection. A
  ledger naming a different plan file is another plan's: leave it and
  start your own.
- Otherwise create the ledger with its identity as the first line:
  `# SDD ledger — plan: <plan file path>`.

Read the plan once, note its context and Global Constraints, and create a
todo per task. If the plan names a Spec, read that too: the spec is the
authority the plan argues from, and conflicts inside the plan resolve
against it. A plan with no reachable spec gets a ledger note saying so —
rulings made without one are provisional.

**REQUIRED SUB-SKILL:** load alex-superpowers:test-driven-development now,
before Task 1. It governs every step of every task below; a plan whose
steps already say "write the failing test first" does not exempt you
from reading it.

Before Task 1, scan the plan's Interfaces blocks for conflicts between
tasks: one ledger row for every task that consumes what an earlier task
produces — the two tasks, what one produces against what the other
consumes, what you found. A plan whose tasks share nothing gets the single
line `Pre-flight: no shared interfaces`. Rule on each conflict, record the
ruling beside its row, and start Task 1. Each task's own text is checked
when you read its brief, not here.

## The Task Loop

Everything you print, and every tool result, stays resident in your
context for the rest of the session: redirect long test output to a
workspace file and read its tail; read a brief, not the whole plan.

### 1. Take the task

- Run this skill's `scripts/task-start PLAN_FILE N`. It prints the brief
  path and BASE (the commit the task's range is cut from) in one call.
  Read the brief for every task, even ones you remember from setup: the
  brief has the exact values, signatures, and test cases.
- Mark the task's todo in_progress.

Every tool call is a turn that re-reads your whole context. Bookkeeping
rides along with work — a ledger append in the same call as the commit,
never in a call of its own.

### 2. Work the steps

The plan's steps are already in RED-GREEN order; follow them in that
order under alex-superpowers:test-driven-development. A test step's code is
written first and run first. Watching it fail is a step, not a formality
— a test that passes before the implementation exists is a finding about
the test.

Every step that runs a command has an `Expected:` line. Run the command,
read its output, and compare. Three outcomes:

- **Matches.** Next step.
- **The code is wrong.** Use alex-superpowers:systematic-debugging. Find the
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

Before a task's ledger line, all of these are true, with evidence
in this session — not inferred from the diff looking right:

- Every test the brief names exists and ran in this task, and you read
  the output.
- The final test run for the task passed — `task-done` is that run, and
  it writes the command and result into the ledger line.
- Every `Expected:` line in the brief was compared against real output.
- Every deviation from the brief has a `Ruling:` line in the ledger.

**REQUIRED SUB-SKILL:** alex-superpowers:verification-before-completion governs
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
alex-superpowers:requesting-code-review's
[code-reviewer.md](../requesting-code-review/code-reviewer.md) on the
most capable available model, named explicitly — an omitted model
inherits the session's, which may not be the most capable. Give it the
package path, the plan and spec paths, the plan's Review Focus section
verbatim if it has one (untested input classes and failure modes the
reviewer checks deliberately), and a pointer to the ledger's `Ruling:`
lines so it can weigh the calls you made. This is the one fresh context
the whole run buys: do not skip it, and do not replace it with your own
read of the diff.

**Without a subagent tool:** read code-reviewer.md and perform that review
yourself against the package, as a separate pass after the last task's
ledger line. Write `Final review: self-review (no subagent tool)` to the
ledger and say so in your final message: an author's self-review is
weaker than a fresh reviewer, and your human partner decides whether that
is enough before merge.

Sort the findings before you act on any of them; the reviewer's severity
labels are advice, the gate is yours. Re-grade first, by effect: a
finding's grade is what a reasonable person using this software gets if
it ships, not whether the spec names the input that triggers it. Its
"Declined to judge" list is yours too: every line is a ruling you make
and ledger — `Final: Ruling: <behavior the reviewer set aside> — <what a
reasonable person gets, and why that stands or is now a finding> — <cost
if wrong>`. Then:

- **Critical and Important** enter the fix pass.
- **Minor** goes to the ledger as `Final: minor (deferred): <one-liner>`,
  which Finish reports. Minors never enter the fix pass and never become
  rulings — a ruling decides a conflict, not a declined polish suggestion.

Fix the Critical and Important findings yourself, in ONE pass. Each fix is
verified by TDD, not by a second reviewer: write the test that reproduces
the finding, watch it fail, make it pass, then run the whole suite. Ledger
each as `Final: fixed <finding> — <test name> RED→GREEN, suite <N>/<N>`. A
fix without a test that failed first is not verified; a suite that is not
green means the pass is not over. No re-review: the covering tests
answer "addressed" and the suite run answers "broke nothing".

A finding you decide not to fix is a ruling — `Final: Ruling: <finding> —
<why the code stands> — <cost if wrong>` — and reaches your human partner
in the rulings list. There is no second fix pass.

## Finish

Before you delete anything, write your final message: one opening line
(tasks done, suite status, how many rulings you made); every ledger line
containing `Ruling:` under "Rulings I made", highest cost-if-wrong first,
each with what it costs if wrong; every `minor (deferred)` line under
"Deferred minors". Both lists are exhaustive: your final message is the
only place the decisions you took on your human partner's behalf — and
the findings you chose not to act on — reach them.

When the final review is clean and its fixes are committed, delete this
plan's workspace directory — the git history is the record now. Sibling
directories belong to other plans; leave them alone.

Use alex-superpowers:finishing-a-development-branch.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I remember what Task N says" | You remember a summary; the brief has the exact values. Read it. |
| "The plan's code is right, skip watching the test fail" | A test you never saw fail proves nothing. Run it. |
| "I'll run the full suite at the end instead of per step" | Per-step runs show which step broke it; the end-of-task run is the contract, not a substitute. |
| "The plan is wrong here, I'll just do the right thing" | Do it and ledger the ruling. Unledgered deviation is a decision made in secret. |
| "I'll write the ledger lines after a few tasks" | Compaction does not wait. One line per task, in the same call as the commit. |
| "Let me check in before the next task" | They chose inline to spend less. Only the four stops stop you. |
| "I read my own diff carefully; the final reviewer is redundant" | Same author, same blind spots. The reviewer is the only fresh context this run buys. |
| "Tests should pass, the change was trivial" | "Should" is not evidence. The contract requires the command and its output. |
| "Subagents are slow and expensive, I'll skip the final review too" | Inline already removed the per-task reviewers. One whole-branch review is the floor. |
| "The reviewer said Minor, so it's Minor" | The label graded the spec's silence. Grade what the person gets. |
| "The fix is obvious, no need for a failing test first" | The failing test is the only proof the finding was real and is now gone. |
| "I'll fix the minors too while I'm in there" | Each costs a test, a fix, and a suite run nobody asked for. Ledger them; your partner decides. |
