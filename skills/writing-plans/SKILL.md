---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write implementation plans for an engineer who has not seen this codebase or this spec. Assume they write idiomatic code in the project's language once they know the exact interface and test, and make a reasonable choice wherever the plan leaves one open. What they can't know is what you decided (files, names and signatures, the spec's values, the tests that prove each task), so document that, as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` (user preferences for plan location override this).

## Scope Check

If the spec covers multiple independent subsystems (brainstorming should have split it into sub-project specs), suggest separate plans, one per subsystem, each producing working, testable software on its own.

## File Structure

Before defining tasks, map which files will be created or modified and what each is responsible for. This locks in the decomposition.

- Design units with clear boundaries and well-defined interfaces, one clear responsibility per file.
- Prefer smaller, focused files: you work more reliably on code you can hold in context at once.
- Files that change together live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns; don't unilaterally restructure, though splitting a file you're modifying that has grown unwieldy is reasonable.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. Fold setup, configuration, scaffolding, and documentation into the task whose deliverable needs them; split only where a reviewer could meaningfully reject one task while approving its neighbor. Each task's changes make sense on their own and end in an independently testable deliverable.

## Step Granularity

Each step is one action with a checkable result: write the failing test; run it to see it fail; implement the minimal code to pass it; run the tests to see them pass; commit.

## Plan Document Header

**Every plan starts with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use the execution skill chosen at handoff (alex-superpowers:subagent-driven-development or alex-superpowers:executing-plans) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements; it travels
with the plan, and executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, exact values
copied verbatim from the spec. Every task's requirements implicitly include
this section.]

## Review Focus

[Up to five input classes or failure modes the spec implies but no task's
tests exercise, most likely to bite a person using this software first —
one line each: the input or condition, and the behavior a reasonable
person would expect. The spec's silence on an input is not permission for
it to break the program. Write the list once, with the spec in front of
you, then add each line's test to the task that owns the code, in that
task's step style.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. Implementers see only their own task; this block
  tells them the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach if the signature and test leave a choice (which
library call, which data structure); a code block only for an algorithm
they don't determine.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing from it: unambiguous, not complete. Each kind carries only what makes it so:

- **A test step:** the test's name and assertions, as code, with the spec's exact values.
- **A code step:** the exact signature (name, parameters, return type), its file, and the values the spec pins. The implementer writes the body; include one only for an algorithm the signature and tests don't determine, or for exact copy the spec fixes.
- **A verification step:** the command and the output that means it passed.
- **A reference to another task:** point to that task's Interfaces block; don't repeat its code.

A plan is the decisions the implementer can't make alone; one longer than the code it describes has written the code instead. The opposite failure is a line that decides nothing: "TBD", "handle edge cases", "add appropriate validation", "write tests for the above", a type or function no task defines.

## Self-Review

After writing the complete plan, check it against the spec with fresh eyes: a checklist you run yourself, not a subagent dispatch.

1. **Spec coverage:** for each spec section or requirement, point to the task that implements it. Add a task for any gap.
2. **Step scan:** check every step against What a Step Contains. Fix lines that decide nothing (gaps) and bodies the signature and tests already determine (transcripts).
3. **Type consistency:** types, signatures, and property names in later tasks match their definitions in earlier ones (`clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug).
4. **Review Focus:** for each input class or failure mode the spec implies, find a task whose tests exercise it. Up to five uncovered ones most likely to bite a person go in Review Focus, as its template says. An empty section means you checked and found none, not that you skipped the check.
5. **Proportion:** if the plan is several times longer than the spec, or code blocks are most of it, it's a transcript of the program: replace bodies with signatures, test names and assertions, keeping each step unambiguous.

Fix issues inline and move on; no need to re-review.

## Execution Handoff

After saving and self-reviewing the plan, link it for your human partner and wait for their review before implementation.

**When no execution method has already been supplied,** ask them to review it and choose one:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. For this plan I recommend <one of the two>, because <one sentence from the plan: how much the tasks depend on each other's interfaces, how many there are, what a shipped mistake would cost>.**

- **Subagent-driven** - A fresh subagent implements each task and a fresh reviewer checks it before the next one starts, then a whole-branch review at the end. Most thorough; costs a fresh context per task and per review.
- **Inline** - I implement every task myself in this session, the way this harness runs work, then one fresh reviewer on the most capable model checks the whole branch. Cheapest and fastest; no independent review until the end. Runs well with a mid-tier session model, since the plan carries the design.

**Does the plan capture what you want, and which approach should we use?"**

**When they have already explicitly supplied one,** ask only for the review, then use their method:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Please review the plan. Does it capture what you want?"**

**If Subagent-driven chosen:** REQUIRED SUB-SKILL: Use alex-superpowers:subagent-driven-development

**If Inline chosen:** REQUIRED SUB-SKILL: Use alex-superpowers:executing-plans
