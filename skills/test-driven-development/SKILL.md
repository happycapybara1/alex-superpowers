---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:** new features, bug fixes (start with a failing test that
reproduces the bug), refactoring, behavior changes.

**No test needed:** generated code, and configuration or docs with no logic.

**Ask your human partner first:** throwaway prototypes.

Thinking "skip TDD just this once"? Stop. That's rationalization.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? Delete it and start over. This means code
you wrote for this task; never delete code your human partner wrote.

**No exceptions:** don't keep it as "reference", "adapt" it while
writing tests, or look at it. Delete means delete; implement fresh from
tests.

## Red-Green-Refactor

### RED - Write Failing Test

Write one minimal test showing what should happen: one behavior ("and"
in the name? split it), a name that describes the behavior, real code
(no mocks unless unavoidable), written against the API you want.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Clear name, tests real behavior, one thing
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```
Vague name, tests mock not code
</Bad>

### Verify RED - Watch It Fail

**MANDATORY. Never skip.** Run the test (`npm test path/to/test.test.ts`)
and confirm it fails (not errors), with the expected message, because
the feature is missing (not a typo).

**Test passes?** You're testing existing behavior. Fix the test.
**Test errors?** Fix the error; re-run until it fails correctly.

### GREEN - Minimal Code

Write the simplest code that passes the test. Don't add features
(YAGNI), refactor other code, or "improve" beyond the test.

### Verify GREEN - Watch It Pass

**MANDATORY.** Run it again: the test passes, other tests still pass,
output is pristine (no errors, warnings).

**Test fails?** Fix the code, not the test. **Other tests fail?** Fix now.

**"Other tests" means the project's suite, not just your file.** Before
calling the change done, run the project's test command (bare `pytest`,
`npm test`, `cargo test` — whatever the repo uses), even if your task
named one test file: scope bounds the deliverable, not your verification.
Report every failure that run shows by name, including ones you didn't
cause; omitting a red test you saw falsifies the report.

### REFACTOR - Clean Up

After green only: remove duplication, improve names, extract helpers.
Keep tests green. Don't add behavior. Then write the next failing test
for the next feature.

## Good Tests

When writing or changing any test, read [writing-good-tests.md](writing-good-tests.md). Its rules: name the production change that would make the test fail before writing it; assert on real behavior, never mock behavior; keep test-only code out of production classes; learn a dependency's side effects before mocking it.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests written after pass immediately, proving nothing: you never saw them fail, so never proved they catch the bug. They may test the implementation instead of the behavior, or the wrong thing. |
| "Tests after achieve same goals (spirit not ritual)" | Tests-after ask "what does this do?", tests-first "what should this do?" Biased by your code, they check the cases you remembered, not the ones you'd have discovered: coverage without proof the tests work. |
| "Already manually tested" | Ad-hoc: no record of what you covered, can't re-run when code changes, cases skipped under pressure. "Worked when I tried it" ≠ comprehensive. |
| "Deleting X hours is wasteful" | Sunk cost: the time is spent either way. Rewriting with TDD gives high confidence; bolting tests on after gives low confidence and likely bugs. Keeping untrustworthy code is the waste. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD catches bugs before commit, prevents regressions, makes refactoring safe. "Pragmatic" shortcuts mean debugging in production — slower. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it: add tests. They pass at once, so break the code briefly to see each fail. |

**Also stop** when you can't explain why a test failed, or catch yourself thinking "this is different because...". Any excuse in the table, or either of these, means: delete the code you wrote for this task and start over with TDD.

## Verification Checklist

Before marking work complete:

- [ ] Every new behavior has a test (writing-good-tests.md says what earns none)
- [ ] Watched each test fail for the expected reason before implementing
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass; output pristine
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check a box? Close that gap before calling it done.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |
