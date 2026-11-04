---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Overview

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue: test failures, production bugs, unexpected
behavior, performance problems, build failures, integration issues.

**ESPECIALLY when** guessing is tempting: under time pressure (rushing
guarantees rework), "just one quick fix" seems obvious, the issue seems
simple, previous fixes didn't work, or you don't fully understand it.

## The Four Phases

You MUST complete each phase before proceeding to the next. Phases can be short: when the error states the cause outright, Phase 1 is reading it and confirming.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully** - Read errors, warnings, and stack
   traces completely; they often contain the exact solution. Note line
   numbers, file paths, error codes.

2. **Reproduce Consistently** - Can you trigger it reliably, every time?
   With what exact steps? Not reproducible → gather more data, don't guess.

3. **Check Recent Changes** - What changed? Git diff, recent commits,
   new dependencies, config changes, environmental differences.

4. **Gather Evidence in Multi-Component Systems** - **WHEN the system
   has multiple components** (CI → build → signing, API → service →
   database), add diagnostic instrumentation BEFORE proposing fixes: at
   EACH boundary, log what data enters and exits, whether
   environment/config propagated, and the state at that layer. Run once
   to see WHERE it breaks, then investigate that component.

   ```bash
   # Same line in the CI step, build.sh, and deploy; run once: which layer loses the value?
   echo "build.sh: API_TOKEN=$([ -n "${API_TOKEN:-}" ] && echo SET || echo UNSET)"
   ```

5. **Trace Data Flow** - **WHEN the error is deep in the call stack**,
   trace backward (`root-cause-tracing.md`): where does the bad value
   originate, and what called this with it? Keep going up to the source
   and fix there, not at the symptom.

Phase 1 is done when you understand WHAT is broken and WHY.

### Phase 2: Pattern Analysis

1. **Find Working Examples** - Locate similar working code in the same
   codebase.

2. **Compare Against References** - If implementing a pattern, read the
   reference implementation COMPLETELY, every line; understand it fully
   before applying it.

3. **Identify Differences** - List every difference between working and
   broken, however small. Don't assume "that can't matter".

4. **Understand Dependencies** - What components, settings, config, and
   environment does this need? What does it assume?

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis** - Write it down, specifically: "I think X
   is the root cause because Y".

2. **Test Minimally** - Make the SMALLEST possible change to test it,
   one variable at a time. Don't fix multiple things at once.

3. **Verify Before Continuing** - Worked? → Phase 4. Didn't? Form a NEW
   hypothesis; DON'T add more fixes on top.

4. **When You Don't Know** - Say "I don't understand X". Don't pretend
   to know. Ask for help or research more.

### Phase 4: Implementation

1. **Create Failing Test Case** - Simplest possible reproduction (an
   automated test, or a one-off script if there's no framework), written
   with `superpowers:test-driven-development`. MUST have before fixing.

2. **Implement Single Fix** - ONE change, addressing the root cause. No
   "while I'm here" improvements or bundled refactoring.

3. **Verify Fix** - Test passes? No other tests broken? Issue actually
   resolved? Use `superpowers:verification-before-completion` before
   claiming success.

4. **If Fix Doesn't Work** - STOP and count your fixes. Under 3: return
   to Phase 1 with the new information. **3 or more: question the
   architecture (step 5)** - DON'T attempt Fix #4 without that discussion.

5. **If 3+ Fixes Failed: Question Architecture** - Suspect the
   architecture when each fix reveals new shared state, coupling, or
   problems elsewhere, creates new symptoms, or needs "massive
   refactoring". Is the pattern fundamentally sound, or are we "sticking
   with it through sheer inertia"? Should we refactor the architecture
   instead of fixing symptoms? **Discuss with your human partner before attempting
   more fixes.** This is NOT a failed hypothesis - this is a wrong
   architecture.

## Red Flags - STOP and Follow Process

If you catch yourself thinking (beyond the excuses in the table below):
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.** (After 3+ failed fixes:
Phase 4, step 5.)

## your human partner's Signals You're Doing It Wrong

- "Is that not happening?" - You assumed without verifying
- "Will it show us...?" - You should have added evidence gathering
- "Stop guessing" - You're proposing fixes without understanding
- "Ultra-think this" - Question fundamentals, not just symptoms
- "We're stuck?" (frustrated) - Your approach isn't working

**When you see these:** STOP. Return to Phase 1.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Production down: mitigate first (roll back, turn the feature off) and call it a mitigation, not a fix. Then Phase 1; systematic is still faster than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## When Process Reveals "No Root Cause"

If investigation shows the issue is truly environmental, timing-dependent,
or external, you've completed the process: document what you
investigated, implement appropriate handling (retry, timeout, error
message), and add monitoring/logging for future investigation.

**But:** most "no root cause" cases are incomplete investigation.

## Supporting Techniques

In this directory:

- **`root-cause-tracing.md`** - Trace bugs backward through call stack to find original trigger
- **`defense-in-depth.md`** - Add validation at multiple layers after finding root cause
- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling
