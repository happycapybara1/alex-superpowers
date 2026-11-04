---
name: dispatching-parallel-agents
description: Use when 2+ independent problems (unrelated test failures, bugs, investigations) can be worked on at once with no shared files or state. Not for executing a written plan.
---

# Dispatching Parallel Agents

## Overview

Investigating unrelated failures (different test files, subsystems, bugs) one after another wastes time when each investigation is independent.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

- 2+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from the others
- No shared state between investigations

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken (e.g. tool approval, batch completion, abort). Domains are independent when fixing one doesn't affect the others' tests.

### 2. Create Focused Agent Tasks

Each agent's prompt is self-contained and gives it:
- **Specific scope:** one test file or subsystem. "Fix agent-tool-abort.test.ts", not "Fix all the tests": a broad agent gets lost.
- **Context:** paste the error messages and test names. "Fix the race condition" doesn't say where.
- **Clear goal:** make these tests pass.
- **Constraints:** don't change other code ("Do not change production code" or "Fix tests only"), or it may refactor everything.
- **Expected output:** a summary of root cause and changes.

### 3. Dispatch in Parallel

Issue all dispatches in one response: calls in the same response run in parallel; one per response runs sequentially.

```text
Subagent (general-purpose): "Fix agent-tool-abort.test.ts failures"
Subagent (general-purpose): "Fix batch-completion-behavior.test.ts failures"
Subagent (general-purpose): "Fix tool-approval-race-conditions.test.ts failures"
```

### 4. Review and Integrate

When agents return: read each summary, verify the fixes don't conflict, run the full test suite, spot-check (agents can make systematic errors), and integrate all changes.

## Agent Prompt Structure

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

These are timing/race condition issues. Your task:

1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do not just increase timeouts; find the real issue.

Return: Summary of what you found and what you fixed.
```

## When Not to Use

- **Related failures:** fixing one might fix others; investigate together first
- **Need full context:** understanding requires seeing the entire system
- **Exploratory debugging:** you don't know what's broken yet
- **Shared state:** agents would interfere (editing same files, using same resources)
- **One checkout:** agents that edit files or run the test suite concurrently in the same checkout collide. Give each its own worktree, or have them investigate and report while you apply the fixes.
- **A written plan:** execute it with alex-superpowers:subagent-driven-development, which runs implementers one at a time.

## Real Example from Session

After a major refactoring, 6 failures across the three test files above, one agent per file. One replaced timeouts with event-based waiting, one fixed an event structure bug (threadId in wrong place), one added a wait for async tool execution to complete. No conflicts; full suite green.
