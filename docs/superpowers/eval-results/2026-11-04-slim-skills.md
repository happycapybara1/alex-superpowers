# Slimmed skills: test run and eval (2026-11-04)

Old = `main` at 0430840 (after the per-skill review). New = `slim-skills`
(compression, style pass, subagent templates read by path).

## Plan execution test run

One unattended run per version: a 3-task Node plan (words tokenizer,
topWords ranking, CLI) executed with subagent-driven-development,
controller on claude-opus-4-8, plugin loaded with `--plugin-dir` into an
empty config directory.

| | Old | New (templates by path, before compression) |
| --- | --- | --- |
| Result | 3/3 tasks, 11/11 tests, final review found 1 Important (fixed) | 3/3 tasks, 9/9 tests, final review clean |
| Cost / time / turns | $3.81 / 8.1 min / 49 | $3.88 / 9.5 min / 56 |
| Controller context peak | 102k tokens | 110k tokens |
| Dispatch prompts | 9, ~390 words each; 0 subagents read a template file | 7; reviewers and Task 1's implementer used the short by-path prompt and read their template; Tasks 2-3 got hand-written ~300-word prompts |

Findings: the old controller already summarized the templates instead of
pasting them, so by-path dispatch saves little context in practice. Its
value is fidelity: subagents that read the file get the full
instructions. SKILL.md now requires the by-path prompt for every task.

## Eval

8 cases x 2 trials per version, identical prompts, tools enabled
(Read/Edit/Write/Glob/Grep/Bash/Skill), fixture workspaces, blind judge
(claude-opus-4-8) on the i-have-adhd rubric. Cases:
`2026-11-04-slim-skills-cases.jsonl` (this folder). Generation $4.56 (old) + $4.45
(new), judging $0.79.

| Case | Old | New |
| --- | ---: | ---: |
| bugfix-root-cause | 4.90 | 4.95 |
| vague-feature | 4.80 | 4.85 |
| clear-small-task | 4.90 | 5.00 |
| wrong-review-comment | 4.78 | 4.68 |
| premature-done | 4.90 | 4.95 |
| flaky-after-two-fixes | 4.78 | 4.90 |
| simple-question | 4.95 | 4.95 |
| plan-request | 4.28 | 4.32 |
| **Weighted** | **4.78** | **4.83** |

No blocking findings in either version; release gate passed. Both
versions left the code untouched in the vague-feature, wrong-review and
premature-done cases, and edited it in the others. Mean reply length 855
vs 847 characters.

Caveats: 2 trials and 1 plan run per version; the judge is the same model
family; per-case differences under ~0.3 are noise.
