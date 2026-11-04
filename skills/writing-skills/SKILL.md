---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing skills is Test-Driven Development applied to process documentation.** The test case is a pressure scenario run with a subagent; the production code is the SKILL.md; the cycle is RED-GREEN-REFACTOR (see below).

**Personal skills live in your runtime's skills directory:** `~/.claude/skills/` on Claude Code; see [codex-tools.md](../using-superpowers/references/codex-tools.md) or [gemini-tools.md](../using-superpowers/references/gemini-tools.md) for those runtimes. Codex, Copilot CLI, and Gemini CLI also recognize `~/.agents/skills/` as a cross-runtime alias.

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill; it defines the RED-GREEN-REFACTOR cycle this skill adapts.

**Anthropic's guidance:** references/anthropic-best-practices.md snapshots Anthropic's skill-authoring best practices (October 2025, lightly edited since; the live page may be newer). On descriptions this skill differs on purpose: a description says only when to use the skill.

## What is a Skill?

A **skill** is a reusable reference guide to a proven technique, pattern, or tool, so future agents can find and apply it. It is not a narrative about how you solved a problem once.

## When to Create a Skill

**Create when** the technique wasn't intuitively obvious to you, you'd reference it again across projects, the pattern applies broadly (not project-specific), and others would benefit.

**Don't create for:** one-off solutions; standard practices well-documented elsewhere; project-specific conventions (put them in your instructions file); mechanical constraints (if it's enforceable with regex/validation, automate it — save documentation for judgment calls).

## Skill Types

- **Technique:** concrete method with steps to follow (condition-based-waiting, root-cause-tracing)
- **Pattern:** way of thinking about problems (flatten-with-flags, test-invariants)
- **Reference:** API docs, syntax guides, tool documentation (office docs)

## File Organization

All skills share one flat, searchable namespace: `skills/skill-name/SKILL.md` (required), plus supporting files only if needed. Keep principles, concepts, code patterns (< 50 lines), and everything else inline. Use separate files only for:

1. **Heavy reference** (100+ lines): API docs, comprehensive syntax (e.g. `pptx/` with a 600-line `pptxgenjs.md` and `scripts/`).
2. **Reusable tools:** scripts, utilities, templates (e.g. `condition-based-waiting/example.ts`, helpers to adapt).

Invoke bundled scripts through their interpreter in the prose (`bash scripts/tool.sh`, `node scripts/tool.js`), never by bare path: some harness plugin packagers strip executable bits, and a bare `scripts/tool.sh` fails there with `Permission denied`.

## Writing SKILL.md

A skill's `description` says only when to use it: triggering conditions and
symptoms, starting with "Use when...". It never summarizes the skill's
workflow, because an agent that reads a workflow summary follows it instead
of reading the skill. Exception: a skill with `disable-model-invocation: true`
runs only when invoked by name, so no agent chooses it from its description;
a short summary of what it does is fine there.

When you write or change a skill's frontmatter, name or description, or
need to cut its size, read [references/discovery.md](references/discovery.md):
the SKILL.md template, description and keyword guidance, naming, token
budgets, and cross-referencing other skills.

## Flowcharts

When you add or change a flowchart in a skill, read
[references/flowcharts.md](references/flowcharts.md) first: when a flowchart
earns its place, the graphviz conventions, and how to render one.

## Code Examples

**One excellent example beats many mediocre ones;** you're good at porting. Pick the most relevant language (testing techniques → TypeScript/JavaScript; system debugging → Shell/Python; data processing → Python). Make it complete, runnable, from a real scenario, commented to explain WHY, and ready to adapt — not in 5+ languages, not a fill-in-the-blank template, not contrived.

## The Iron Law (Same as TDD)

```
NO BEHAVIOR CHANGE WITHOUT A FAILING TEST FIRST
```

This applies to new skills and to every edit that changes what an agent does. Show the failure first: a baseline run without the change (a pressure scenario, a micro-test, or an eval). Wrote the skill or the edit before seeing that failure? Delete it and start over.

An edit that changes no behavior (a path, a link, a typo, a rename, removing an exact duplicate) needs a careful read-through, not a test.

## Testing All Skill Types

| Type | Examples | Test with | Success criteria |
|---|---|---|---|
| **Discipline-enforcing** (rules) | TDD, verification-before-completion | Academic questions (understands the rules?); pressure scenarios, alone and combined (time + sunk cost + exhaustion); explicit counters for each rationalization | Follows the rule under maximum pressure |
| **Technique** (how-to) | condition-based-waiting, root-cause-tracing | Application and variation (edge-case) scenarios; missing-information tests (gaps?) | Applies the technique to a new scenario |
| **Pattern** (mental model) | reducing-complexity, information-hiding | Recognition scenarios (when does it apply?); application scenarios; counter-examples (when not?) | Identifies when and how to apply it |
| **Reference** (docs/APIs) | API docs, command references, library guides | Retrieval scenarios (finds the right information?); application scenarios; gap testing (common use cases covered?) | Finds and correctly applies the information |

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. |
| "It's just a reference" | References can have gaps and unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use the skill. |
| "Too tedious to test" | Less tedious than debugging a bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | An untested skill costs more time fixing later. |

**All of these mean: Test before deploying. No exceptions.**

## Match the Form to the Failure

Before writing guidance, classify the baseline failure. The form that bulletproofs one failure type measurably backfires on another.

| Baseline failure | Right form | Wrong form |
|---|---|---|
| Skips/violates a rule under pressure (knows better, does it anyway) | Prohibition + rationalization table + red flags (see references/bulletproofing.md) | Soft guidance ("prefer...", "consider...") |
| Complies, but output has the wrong shape (bloated prompt, buried verdict, restated spec) | Positive recipe or contract: state what the output is — its parts, in order | Prohibition list ("don't restate", "never narrate") |
| Omits a required element from something they already produce | Structural: REQUIRED field or slot in the template they fill in | Prose reminders near the template |
| Behavior should depend on a condition | Conditional keyed to an observable predicate ("if the brief exists, reference it") | Unconditional rule + exemption clauses |

**Why prohibitions backfire on shaping problems:** under a competing incentive ("make the prompt self-contained"), agents negotiate with "don't X". In head-to-head wording tests on dispatch-prompt guidance, the prohibition arm produced clearly more unwanted content than the recipe arm (fully separated distributions) and trended worse than even the no-guidance control. Micro-test your own case, but never reach for the prohibition by default. A recipe leaves nothing to negotiate: the output matches the stated shape or it doesn't.

**Rules for whichever form you pick:**
- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation: appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same wording tests. Express a real exception as its own conditional on an observable predicate.
- **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks. If part of the output must be exempt, restructure so the rule can't reach it.

## Bulletproofing Against Rationalization

When the baseline failure is a discipline failure, read
[references/bulletproofing.md](references/bulletproofing.md) before you write
the guidance: closing loopholes, the spirit-vs-letter line, the
rationalization table, and the red-flags list.

## RED-GREEN-REFACTOR for Skills

- **RED:** run the scenario without the skill (or without the edit) and record what the agent does, its rationalizations verbatim, and which pressures triggered them.
- **GREEN:** write the minimal skill text that addresses those specific failures, nothing for hypothetical cases. Rerun: the agent should now comply.
- **REFACTOR:** a new rationalization gets an explicit counter; rerun until it holds.

The full method (pressure types, scenario writing, meta-testing) is in [references/testing-skills-with-subagents.md](references/testing-skills-with-subagents.md).

### Micro-Test Wording Before Full Scenarios

Full pressure-scenario runs are the final gate, but slow and expensive per iteration. Verify the wording itself first:

1. **One fresh-context sample per call:** a raw API call, or a single-shot subagent without API access. System prompt = the realistic context the guidance will live in (the full skill or prompt template, not the guidance alone); user message = a task that tempts the failure.
2. **Always include a no-guidance control.** If the control doesn't exhibit the failure, there is nothing to fix: stop, don't author the guidance.
3. **5+ reps per variant.** Single samples lie.
4. **Manually read every flagged match,** even if you score programmatically: template echoes and quoted counter-examples masquerade as hits, so automated counts alone overstate both failure and success.
5. **Variance is a metric.** When guidance lands, reps converge on one shape. Five interpretations across five reps means the wording isn't binding: tighten the form before adding words.

Micro-tests verify wording; they do not replace pressure scenarios for discipline skills.

## Anti-Patterns

- **Narrative example** ("In session 2025-10-03, we found empty projectDir caused..."): too specific, not reusable.
- **Multi-language dilution** (example-js.js, example-py.py, example-go.go): mediocre quality, maintenance burden.
- **Code in flowcharts** (`step1 [label="import fs"]`): can't copy-paste, hard to read.
- **Generic labels** (helper1, helper2, step3, pattern4): labels should have semantic meaning.

## Skill Creation Checklist

- [ ] **RED:** baseline run without the skill or edit; failures and rationalizations recorded verbatim
- [ ] **GREEN:** `name` uses lowercase letters, numbers, hyphens; `description` is "Use when...", triggers only, third person (summary only with `disable-model-invocation: true`)
- [ ] Guidance form matches the failure type (Match the Form to the Failure)
- [ ] Behavior-shaping wording micro-tested against a no-guidance control (5+ reps, every flagged match read)
- [ ] Each baseline failure addressed; one excellent example at most; heavy detail in a referenced file
- [ ] Rerun with the skill: the agent complies
- [ ] **REFACTOR (discipline skills):** new rationalizations countered in the rationalization table; rerun until it holds
- [ ] **Deployment:** commit and push to your fork; contribute back via PR if broadly useful
