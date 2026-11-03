#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/skills/systematic-debugging/find-polluter.sh"

FAILURES=0
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    pass "$description"
  else
    fail "$description (expected output to contain: $needle)"
  fi
}

# Toy project: one top-level test, one nested test. A stubbed `npm` on PATH
# creates the pollution marker whenever any test runs, so the first test file
# executed is always identified as the polluter.
setup_project() {
  PROJECT="$TEST_ROOT/project"
  rm -rf "$PROJECT"
  mkdir -p "$PROJECT/src/feature" "$PROJECT/bin"
  echo "test('top')" > "$PROJECT/src/top.test.ts"
  echo "test('nested')" > "$PROJECT/src/feature/nested.test.ts"
  cat > "$PROJECT/bin/npm" <<'EOF'
#!/usr/bin/env bash
touch pollution.marker
EOF
  chmod +x "$PROJECT/bin/npm"
}

# run_polluter <pattern> — runs the script in the toy project with the stub
# npm first on PATH; captures combined output, never aborts on exit code.
run_polluter() {
  local pattern="$1"
  rm -f "$PROJECT/pollution.marker"
  (
    cd "$PROJECT"
    PATH="$PROJECT/bin:$PATH" "$SCRIPT_UNDER_TEST" 'pollution.marker' "$pattern" 2>&1
  ) || true
}

echo "Test: documented pattern finds nested test files (issue #2008)"
setup_project
OUTPUT="$(run_polluter 'src/**/*.test.ts')"
assert_contains "$OUTPUT" "FOUND POLLUTER" "documented pattern runs tests and detects pollution"

echo "Test: documented pattern also finds top-level test files"
setup_project
OUTPUT="$(run_polluter 'src/**/*.test.ts')"
assert_contains "$OUTPUT" "Found 2 test files" "src/**/*.test.ts matches src/top.test.ts and src/feature/nested.test.ts"

echo "Test: ./-prefixed pattern matches the same files"
setup_project
OUTPUT="$(run_polluter './src/**/*.test.ts')"
assert_contains "$OUTPUT" "Found 2 test files" "leading ./ on the pattern is accepted"

echo "Test: non-matching pattern reports an honest zero"
setup_project
OUTPUT="$(run_polluter 'nomatch/**/*.test.ts')"
assert_contains "$OUTPUT" "Found 0 test files" "empty result counts as 0, not 1"
assert_contains "$OUTPUT" "No polluter found" "empty result exits via the clean path"

echo "Test: pollution that already exists is refused, not reported clean"
setup_project
touch "$PROJECT/pollution.marker"
STATUS=0
OUTPUT="$(cd "$PROJECT" && PATH="$PROJECT/bin:$PATH" "$SCRIPT_UNDER_TEST" 'pollution.marker' 'src/**/*.test.ts' 2>&1)" || STATUS=$?
assert_contains "$OUTPUT" "already exists" "pre-existing pollution names the problem"
if [ "$STATUS" -eq 2 ]; then pass "pre-existing pollution exits 2"; else fail "pre-existing pollution exits 2 (got $STATUS)"; fi
case "$OUTPUT" in *"No polluter found"*) fail "pre-existing pollution must not claim a clean run" ;; *) pass "pre-existing pollution does not claim a clean run" ;; esac

echo "Test: a custom test command replaces npm test"
setup_project
printf '#!/usr/bin/env bash\nexit 0\n' > "$PROJECT/bin/npm"
printf '#!/usr/bin/env bash\n[ "$1" = run ] && touch pollution.marker\n' > "$PROJECT/bin/vitest"
chmod +x "$PROJECT/bin/npm" "$PROJECT/bin/vitest"
OUTPUT="$(cd "$PROJECT" && rm -f pollution.marker && PATH="$PROJECT/bin:$PATH" "$SCRIPT_UNDER_TEST" 'pollution.marker' 'src/**/*.test.ts' 'vitest run' 2>&1)" || true
assert_contains "$OUTPUT" "FOUND POLLUTER" "third argument runs the given command with its own arguments"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
