# Implicit skill triggering: upstream vs fork (2026-11-04)

Does the calmer bootstrap (no "1% chance / ABSOLUTELY MUST", fewer red-flag
rows) change how often skills load when the task does not name one?

Upstream = obra/superpowers 2ce8aa1. Fork = cdc18e3 (7.0.1-alx). Each run:
`claude -p` on claude-opus-4-8 with the plugin via `--plugin-dir`, an empty
config directory and an empty working directory, tools Skill/Read/Glob/Grep,
`--max-turns 2`; a run counts as a hit when it invoked the expected skill
(for the control: no skill). 3 runs per prompt per version; $9.27 total.

| Prompt (no skill named) | Expected skill | Upstream | Fork |
| --- | --- | ---: | ---: |
| The login test started failing ... expected 200, got 500 | systematic-debugging | 3/3 | 3/3 |
| Add a CSV export button to the reports page. | brainstorming | 1/3 | 0/3 |
| Implement isLeapYear(year) in src/dates.js. | test-driven-development | 1/3 | 3/3 |
| I think the fix is done ... Let's commit it. | verification-before-completion | 1/3 | 1/3 |
| My teammate ... says I should replace every for loop with reduce. Should I? | receiving-code-review | 3/3 | 1/3 |
| The design in docs/design.md is approved. Turn it into an implementation plan. | writing-plans | 3/3 | 3/3 |
| What is 17 times 6? | (none) | 3/3 | 3/3 |
| **Total** | | **15/21** | **14/21** |

Reading: overall about equal. The fork loads TDD more reliably and
receiving-code-review less when the feedback arrives as a question ("Should
I?"). A likely cause is the removed bootstrap row "This is just a simple
question → Questions are tasks. Check for skills." Three runs per cell is a
small sample.
