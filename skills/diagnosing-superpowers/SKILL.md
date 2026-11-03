---
name: diagnosing-superpowers
description: Use when your human partner asks why a superpowers session went wrong — repeated work, ignored plans, stumbles, poor results, a skill that didn't fire, too slow, too expensive — for this session or a past one
---

# Diagnosing Superpowers

## Overview

Pin down with your human partner what went wrong in a session, read the
transcripts on disk, and report what happened with evidence. After the
report you may propose changes to skills, each labeled as a proposal; you
never edit skill files here. Your human partner decides what changes.

**Core principle:** Every finding cites `path:line`. No citation, no
finding. Every number comes from the transcript or from a command you ran,
never from memory.

## Workflow

Create a todo per step. Steps 5–6 run only on their stated condition.

1. **Problem intake.** Ask one question at a time until you can write a
   statement naming the session(s), the turn range if known, what your
   partner expected, what happened, and the observable they care about
   (wall-clock, tokens, repeated actions, one specific action). "It took
   too long" is a complaint, not a problem statement.
2. **Locate.** Resolve each session to verified absolute filesystem paths using
   `references/session-discovery.md`. Confirm a past session by quoting its
   first prompt and timestamp, and list every candidate you rejected with the
   reason, or "none". Enumerate subagent transcripts. Create
   `~/.superpowers/diagnosing-superpowers/<session-id>/`, tell your
   partner the path, and fill `templates/case.md` there, following its
   provenance rules for environment and skill observations.
3. **Triage.** Read the region around the reported problem yourself. Then
   dispatch one analyst subagent per dimension the Quick reference picks,
   in parallel, each given the
   case file path, `prompts/analyst-common.md`, and one dimension file from
   `prompts/`: `skill-timeline.md`,
   `plan-adherence.md`, `repeated-work.md`, `stumbles.md`,
   `quality-evidence.md`, `request-conflicts.md`, `cost-and-time.md`.
   Split a dimension by turn range when the transcript is long. Discard
   any returned finding without `path:line`.
4. **Report.** Fill every section of `templates/report.md` in order, write
   it to the workspace, and give the path. In the reply, show the §2
   verdict and the strongest findings; the full report is in the file. Check what cited content
   actually proves and preserve the supporting case; a symlink alias is not a
   redundant copy.
5. **Proposals** — when your partner asks what to change, or report §7
   says possible or likely. For each finding that implicates a skill, name
   the skill file and line and propose one change, labeled as a proposal,
   with the evidence line it answers. Never edit skill files in this skill.
6. **Similar sessions** — when asked. Turn confirmed findings into a
   signature, list candidates by mtime and size, find marker line numbers,
   dispatch `prompts/similar-session.md` per candidate in parallel, and
   append report §9.

## Quick reference

Run the analysts in the complaint's row plus skill-timeline; run all seven
when your partner asks or the complaint fits no row. The table also says
which region to read yourself in step 3 and which findings to lead with in
the verdict.

| Complaint | Read first, lead with |
|---|---|
| "It took too long" | cost-and-time, stumbles |
| "Why did it do this extra work?" | repeated-work, plan-adherence |
| "Why is it so expensive?" | cost-and-time |
| "What the hell is it doing?" (still running) | skill-timeline; note in-progress in coverage |
| "It ignored the plan" | plan-adherence, compaction lines first |
| "Skill X never fired" | skill-timeline |

## Hard rules

- **Context safety.** One transcript line can be a megabyte. Follow
  `references/context-safety.md` on every session file, every time.
- **Read-only.** Never modify, move, or delete a session file.
- **Exact paths to subagents.** A subagent's "current session" is its
  own. Pass absolute paths and ids.
- **Human prompts only.** Hook output, system reminders, and tool results
  are not your partner's words. In a subagent transcript, "user" is the
  parent agent.
- **Proposals, not edits.** Report §7 states involvement. A change to a
  skill is a labeled proposal (step 5), never an edit made here; your
  partner decides.
- **Intake before analysis.** Nothing in steps 2–6 starts until your
  partner has answered. If they are away, write the questions and stop.
  A statement you reconstructed for them is not an answer. An
  already-scoped request — one specific event, what is running now, or
  the analysis to run — is itself the statement: answer it, then ask.
  A whole-session "why" is a complaint.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The problem is obvious, skip intake" | The problem statement scopes everything. Ask. |
| "They're away, so I'll reconstruct the statement" | You cannot reconstruct what they wanted. Write the questions and stop. |
| "I'll sweep everything now and ask at the end" | An unscoped sweep spends their budget on the wrong question. Ask first. |
| "Small, targeted edit, no restructuring needed" | Not in this skill, however small. Propose it with its evidence; your partner decides and edits. |
| "The price per token is well known" | Numbers you did not compute from the transcript are invented. Cite or drop. |
