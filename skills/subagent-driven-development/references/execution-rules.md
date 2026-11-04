# Execution Rules

Shared by superpowers:subagent-driven-development and
superpowers:executing-plans. Read it at skill start, and again after any
compaction. Script paths are relative to the subagent-driven-development
skill directory (from executing-plans: `../subagent-driven-development/`);
linked files sit next to this one.

## While the Plan Runs

**Continuous execution.** Do not pause to check in with your human partner
between tasks. Execute every task in the plan without stopping; the only
reasons to stop are the four below, or all tasks complete. "Should I
continue?" prompts and progress summaries spend their time — they asked
you to execute the plan, so execute it.

**Rulings, not stalls.** A running plan does not wait on a human.
Conflicts, ambiguities, plan defects, a cap you would have asked to exceed
— decide them. The spec is the binding authority, the plan is its
argument, and your judgment settles what neither answers. Record every
decision in the ledger as
`Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep
going. A wrong ruling costs rework your human partner can see and undo; a
session parked on a question costs their whole day and buys nothing.
Deviating from the plan without a ledgered ruling is a decision made in
secret.

**Four things stop you**, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this
worktree that norms say you ask about first (a merge, a push to a shared
branch, a publish); and a plan so broken that every path forward is a
guess. For those, stop and ask.

**Narration:** between tool calls, at most one short line — the ledger
and the tool results carry the record.

**Your context is resident.** Everything you print or paste into a
dispatch, and every tool result or subagent reply, stays in your context
for the rest of the session and is re-read on every later turn. Hand
artifacts over as files; redirect long output to a file in the workspace
and read its tail; after setup, read a task's brief, never the whole plan.

## The Ledger

Conversation memory does not survive compaction. Executors that lost
their place have redone entire completed task sequences — re-dispatched,
or re-implemented in their own context — the single most expensive
failure observed. Track progress in a ledger file, not only in todos:
harness todos are a live view; the ledger is the record. Its commits exist
in git even when your context no longer remembers making them: after
compaction, trust the ledger and `git log` over your own recollection.

Every tool call is a turn that re-reads your whole context. Bookkeeping
rides along with work: a ledger append goes in the same call as the
commit or the other bookkeeping, never in a call of its own, and never
batched for later.

Both skills use the same workspace and ledger format, so a plan can change
executors mid-flight and the new one resumes from the same ledger.

## Setup

1. **Isolated workspace.** Use superpowers:using-git-worktrees to create
   one or verify the existing one. Never start implementation on a
   main/master branch without your human partner's explicit consent.
2. **Plan workspace.** Run `bash scripts/sdd-workspace PLAN_FILE`. It
   prints the plan's git-ignored directory
   (`<repo-root>/.superpowers/sdd/<plan-basename>/`), home to every
   artifact for THIS plan: ledger, briefs, reports, review packages.
   Another plan's directory is never yours to read or write. `git clean
   -fdx` destroys it (it's git-ignored scratch); if that happens, recover
   from `git log`.
3. **Ledger.** If `<workspace>/progress.md` exists, read
   [resuming.md](resuming.md) before anything else: it says whose ledger
   it is and where to resume (a task with a complete line is never redone,
   by dispatch or by hand). Otherwise create it with its identity as the
   first line: `# SDD ledger — plan: <plan file path>`.
4. **Plan and spec.** Read the plan once, note its context and Global
   Constraints, and create a todo per task. If the plan names a Spec, read
   that too: the spec is the authority the plan argues from, and conflicts
   inside the plan resolve against it. A plan with no reachable spec gets a
   ledger note saying so — rulings made without one are provisional.
5. **Pre-flight scan**, once, before Task 1. Scan the plan for conflicts
   between tasks; its Interfaces blocks tell you where to look. One ledger
   row for every task that consumes what an earlier task produces: the two
   tasks, what one produces against what the other consumes, and what you
   found. Tasks that share nothing get no row; a plan whose tasks share
   nothing gets the single line `Pre-flight: no shared interfaces`. Rule
   on each conflict a row surfaces, spec as the binding authority, record
   the ruling beside its row, and start Task 1. Inline, each task's own
   text is checked when you read its brief; subagent-driven-development
   runs the fuller scan in [preflight.md](preflight.md) instead.

## Finish

Read this section again when the final review is done.

Before you delete anything, write your final message. Open it with one
line: tasks done, suite status, and how many rulings you made. Then
collect every ledger line containing `Ruling:` — pre-flight, plan
corrections, parked findings, breaker adjudications, final review, all of
them — under "Rulings I made", highest cost-if-wrong first, each with what
it costs if wrong. Then every `minor (deferred)` line no fix addressed,
under "Deferred minors". Both lists are exhaustive: if the ledger holds
it, the list holds it. Your final message is the only place the decisions
you took on your human partner's behalf — and the findings you chose not
to act on — reach them; they read it and rework whatever you got wrong. A
ruling that dies with the workspace was a decision made in secret.

When the final review is clean and its fixes are committed, delete this
plan's workspace (`rm -rf <workspace>`) — the git history is the record
now. Sibling directories belong to other plans; leave them alone.

Use superpowers:finishing-a-development-branch.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Let me check in before the next task" | Progress prompts spend your partner's time and buy nothing. Only the four stops stop you. |
| "The plan is wrong here, I'll just do the right thing" | Do the right thing and ledger the ruling. Unledgered deviation is a decision made in secret. |
| "I'll write the ledger lines after a few tasks" | Compaction does not wait for a convenient moment. One line per task, in the same call as the commit. |
| "Ledger bookkeeping is overhead" | The ledger is what survives compaction. Executors without one have redone entire completed task sequences. |
