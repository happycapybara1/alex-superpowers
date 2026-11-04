---
name: using-superpowers
description: Use when starting any conversation, before your first response
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

## The Rule

**If a skill plausibly applies, invoke it before acting**: before any response or action, including clarifying questions, exploring the codebase, or checking files. If it turns out not to fit the situation, drop it.

Then follow the skill, and name it in one short line near the top of your reply. If it has a checklist, create a todo per item.

**Evidence before claims:** before saying work is done, fixed, or passing, run the command that proves it and show the result (details: superpowers:verification-before-completion).

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.

## Red Flags

These thoughts usually mean you're skipping a skill you need:

| Thought | Reality |
|---------|---------|
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Claude Code: `references/claude-code-tools.md`
- Codex: `references/codex-tools.md`
- Hermes Agent: `references/hermes-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
