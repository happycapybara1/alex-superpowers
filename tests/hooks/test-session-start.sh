#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_UNDER_TEST="$REPO_ROOT/hooks/session-start"
WRAPPER_UNDER_TEST="$REPO_ROOT/hooks/run-hook.cmd"

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

make_home() {
    local name="$1"
    local home="$TEST_ROOT/$name/home"
    mkdir -p "$home"
    printf '%s\n' "$home"
}

assert_command_output() {
    local description="$1"
    local shape="$2"
    local contains="$3"
    local not_contains="$4"
    local home="$5"
    shift 5

    local output
    if ! output="$(env -i PATH="${PATH:-}" HOME="$home" "$@" 2>&1)"; then
        fail "$description"
        echo "    hook exited non-zero"
        echo "$output" | sed 's/^/      /'
        return
    fi

    if printf '%s' "$output" | \
        EXPECT_SHAPE="$shape" \
        EXPECT_CONTAINS="$contains" \
        EXPECT_NOT_CONTAINS="$not_contains" \
        node -e '
const fs = require("fs");

const input = fs.readFileSync(0, "utf8");
let payload;
try {
  payload = JSON.parse(input);
} catch (error) {
  console.error(`invalid JSON: ${error.message}`);
  process.exit(1);
}

function hasOwn(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

const shape = process.env.EXPECT_SHAPE;
let context;

if (shape === "nested") {
  if (!hasOwn(payload, "hookSpecificOutput")) {
    fail("missing hookSpecificOutput");
  }
  if (hasOwn(payload, "additional_context") || hasOwn(payload, "additionalContext")) {
    fail("nested output also included a top-level context field");
  }
  const hookOutput = payload.hookSpecificOutput;
  if (!hookOutput || typeof hookOutput !== "object" || Array.isArray(hookOutput)) {
    fail("hookSpecificOutput is not an object");
  }
  if (hookOutput.hookEventName !== "SessionStart") {
    fail(`unexpected hookEventName: ${hookOutput.hookEventName}`);
  }
  context = hookOutput.additionalContext;
} else if (shape === "cursor") {
  if (hasOwn(payload, "hookSpecificOutput")) {
    fail("cursor output included hookSpecificOutput");
  }
  if (!hasOwn(payload, "additional_context")) {
    fail("cursor output missing additional_context");
  }
  if (hasOwn(payload, "additionalContext")) {
    fail("cursor output included additionalContext");
  }
  context = payload.additional_context;
} else if (shape === "sdk") {
  if (hasOwn(payload, "hookSpecificOutput")) {
    fail("sdk output included hookSpecificOutput");
  }
  if (!hasOwn(payload, "additionalContext")) {
    fail("sdk output missing additionalContext");
  }
  if (hasOwn(payload, "additional_context")) {
    fail("sdk output included additional_context");
  }
  context = payload.additionalContext;
} else {
  fail(`unknown expected shape: ${shape}`);
}

if (typeof context !== "string" || context.trim() === "") {
  fail("injected context was empty");
}

const expectedText = process.env.EXPECT_CONTAINS || "";
if (expectedText && !context.includes(expectedText)) {
  fail(`context did not contain expected text: ${expectedText}`);
}

const forbiddenTexts = (process.env.EXPECT_NOT_CONTAINS || "")
  .split("\u001f")
  .filter(Boolean);
for (const forbiddenText of forbiddenTexts) {
  if (context.includes(forbiddenText)) {
    fail(`context contained forbidden text: ${forbiddenText}`);
  }
}
'; then
        pass "$description"
    else
        fail "$description"
        echo "    output:"
        echo "$output" | sed 's/^/      /'
    fi
}

echo "SessionStart hook output tests"

# Registration shape: the hook must declare shell:"bash" so Claude Code on
# Windows dispatches via Git Bash (or fails with an actionable error) instead
# of PowerShell/cmd.exe, whose parsers break on the quoted command string
# (PowerShell ParserError; cmd.exe quote-stripping on paths with metacharacters).
if node -e '
const hooks = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
const entry = hooks.hooks.SessionStart[0].hooks[0];
if (entry.shell !== "bash") {
  console.error(`SessionStart hook shell is ${JSON.stringify(entry.shell)}, expected "bash"`);
  process.exit(1);
}
if (!/run-hook\.cmd" session-start$/.test(entry.command)) {
  console.error(`unexpected SessionStart command shape: ${entry.command}`);
  process.exit(1);
}
' "$REPO_ROOT/hooks/hooks.json"; then
    pass "hooks.json registers SessionStart with shell:bash dispatch"
else
    fail "hooks.json registers SessionStart with shell:bash dispatch"
fi

claude_home="$(make_home claude-code)"
assert_command_output \
    "Claude Code emits nested SessionStart additionalContext" \
    "nested" \
    "" \
    "" \
    "$claude_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

wrapper_home="$(make_home run-hook-wrapper)"
assert_command_output \
    "run-hook.cmd wrapper dispatches to the named session-start script" \
    "nested" \
    "" \
    "" \
    "$wrapper_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$WRAPPER_UNDER_TEST" session-start

cursor_home="$(make_home cursor)"
assert_command_output \
    "Cursor emits top-level additional_context only" \
    "cursor" \
    "" \
    "" \
    "$cursor_home" \
    CURSOR_PLUGIN_ROOT="$REPO_ROOT" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

copilot_home="$(make_home copilot-cli)"
assert_command_output \
    "Copilot CLI emits top-level additionalContext only" \
    "sdk" \
    "" \
    "" \
    "$copilot_home" \
    COPILOT_CLI=1 \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

legacy_home="$(make_home legacy-warning-removed)"
mkdir -p "$legacy_home/.config/superpowers/skills"
assert_command_output \
    "SessionStart omits obsolete legacy custom-skill warning" \
    "nested" \
    "" \
    "Superpowers now uses"$'\037'"~/.config/superpowers/skills"$'\037'"~/.claude/skills"$'\037'"legacy" \
    "$legacy_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    bash "$HOOK_UNDER_TEST"

# Regression for #2310: Claude Code can spawn SessionStart:startup hooks with
# a broken/empty PATH (anthropics/claude-code#43127). session-start and
# run-hook.cmd's Unix half both shell out to external binaries (dirname, cat)
# that an empty PATH cannot resolve, even though bash itself was invoked by
# absolute path. Every call here should use bash's own builtins/redirection
# instead, so an empty PATH must not change the result.
bash_bin="$(command -v bash)"

broken_path_home="$(make_home broken-path)"
assert_command_output \
    "session-start with empty PATH still emits nested additionalContext" \
    "nested" \
    "" \
    "" \
    "$broken_path_home" \
    PATH="" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    "$bash_bin" "$HOOK_UNDER_TEST"

broken_path_wrapper_home="$(make_home broken-path-wrapper)"
assert_command_output \
    "run-hook.cmd with empty PATH still dispatches session-start" \
    "nested" \
    "" \
    "" \
    "$broken_path_wrapper_home" \
    PATH="" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    "$bash_bin" "$WRAPPER_UNDER_TEST" session-start

# Run by bare filename from inside hooks/ ($0 has no slash), the plugin root
# must still resolve.
bare_name_home="$(make_home bare-name)"
assert_command_output \
    "session-start run by bare filename from hooks/ still emits nested additionalContext" \
    "nested" \
    "" \
    "" \
    "$bare_name_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    "$bash_bin" -c 'cd "$1" && exec "$2" session-start' _ "$REPO_ROOT/hooks" "$bash_bin"

bare_name_wrapper_home="$(make_home bare-name-wrapper)"
assert_command_output \
    "run-hook.cmd run by bare filename from hooks/ still dispatches session-start" \
    "nested" \
    "" \
    "" \
    "$bare_name_wrapper_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    "$bash_bin" -c 'cd "$1" && exec "$2" run-hook.cmd session-start' _ "$REPO_ROOT/hooks" "$bash_bin"

# run-hook.cmd's Windows half starts bash with a backslash path
# (C:\...\hooks\session-start), so $0 can use \ as its separator. The skill
# must still be found. On Windows use the real Windows path; elsewhere build
# a plugin root whose hook is reached through a name containing a backslash.
backslash_home="$(make_home backslash)"
if command -v cygpath >/dev/null 2>&1; then
    backslash_cwd="$REPO_ROOT"
    backslash_hook="$(cygpath -w "$HOOK_UNDER_TEST")"
else
    backslash_cwd="$TEST_ROOT/backslash/root"
    mkdir -p "$backslash_cwd"
    ln -s "$REPO_ROOT/hooks" "$backslash_cwd/hooks"
    ln -s "$REPO_ROOT/skills" "$backslash_cwd/skills"
    ln -s "$REPO_ROOT/hooks/session-start" "$backslash_cwd/hooks\\session-start"
    backslash_hook='hooks\session-start'
fi
assert_command_output \
    "session-start reached through a backslash path still reads the skill" \
    "nested" \
    "" \
    "Error reading using-superpowers skill" \
    "$backslash_home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    "$bash_bin" -c 'cd "$1" && exec "$2" "$3"' _ "$backslash_cwd" "$bash_bin" "$backslash_hook"

# When cat is on PATH, the JSON must still go through it: the pipe absorbs
# EPIPE on Windows + Git Bash (#1612). The stub records that it ran.
cat_stub_dir="$TEST_ROOT/cat-stub/bin"
cat_marker="$TEST_ROOT/cat-stub/used"
mkdir -p "$cat_stub_dir"
printf '#!%s\n: > "%s"\nexec /bin/cat "$@"\n' "$bash_bin" "$cat_marker" > "$cat_stub_dir/cat"
chmod +x "$cat_stub_dir/cat"
cat_stub_home="$(make_home cat-stub)"
assert_command_output \
    "session-start with cat on PATH emits nested additionalContext" \
    "nested" \
    "" \
    "" \
    "$cat_stub_home" \
    PATH="$cat_stub_dir" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
    "$bash_bin" "$HOOK_UNDER_TEST"
if [[ -f "$cat_marker" ]]; then
    pass "session-start pipes its JSON through cat when cat is on PATH"
else
    fail "session-start pipes its JSON through cat when cat is on PATH"
fi

# alex-ring: superpowers stays quiet at session start while the ring is
# installed and enabled, and only then.
ring_home() {
    local name="$1" user_value="$2" local_value="$3" installed="$4"
    local home project
    home="$(make_home "$name")"
    project="$TEST_ROOT/$name/project"
    mkdir -p "$home/.claude/plugins" "$project/.claude"
    if [[ "$installed" == yes ]]; then
        printf '{"version":2,"plugins":{"alex-ring@alex":[{"scope":"user"}]}}\n' > "$home/.claude/plugins/installed_plugins.json"
    else
        printf '{"version":2,"plugins":{}}\n' > "$home/.claude/plugins/installed_plugins.json"
    fi
    [[ -z "$user_value" ]] || printf '{"enabledPlugins":{"alex-ring@alex": %s}}\n' "$user_value" > "$home/.claude/settings.json"
    [[ -z "$local_value" ]] || printf '{"enabledPlugins":{"alex-ring@alex": %s}}\n' "$local_value" > "$project/.claude/settings.local.json"
    printf '%s\n' "$home"
}

assert_quiet() {
    local description="$1" home="$2"
    shift 2
    local output
    if output="$(cd "$TEST_ROOT" && env -i PATH="${PATH:-}" HOME="$home" "$@" 2>&1)" && [[ -z "$output" ]]; then
        pass "$description"
    else
        fail "$description"
        echo "$output" | sed 's/^/      /'
    fi
}

home="$(ring_home ring-on true "" yes)"
assert_quiet "alex-ring enabled: session-start prints nothing" "$home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" CLAUDE_PROJECT_DIR="$TEST_ROOT/ring-on/project" bash "$HOOK_UNDER_TEST"

home="$(ring_home ring-disabled false "" yes)"
assert_command_output "alex-ring disabled: the bootstrap loads as usual" "nested" "" "" "$home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" CLAUDE_PROJECT_DIR="$TEST_ROOT/ring-disabled/project" bash "$HOOK_UNDER_TEST"

home="$(ring_home ring-local-off true false yes)"
assert_command_output "alex-ring off in this project's local settings: the bootstrap loads" "nested" "" "" "$home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" CLAUDE_PROJECT_DIR="$TEST_ROOT/ring-local-off/project" bash "$HOOK_UNDER_TEST"

home="$(ring_home ring-local-on "" true yes)"
assert_quiet "alex-ring on only in this project: session-start prints nothing" "$home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" CLAUDE_PROJECT_DIR="$TEST_ROOT/ring-local-on/project" bash "$HOOK_UNDER_TEST"

home="$(ring_home ring-not-installed true "" no)"
assert_command_output "a stale alex-ring setting without the install: the bootstrap loads" "nested" "" "" "$home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" CLAUDE_PROJECT_DIR="$TEST_ROOT/ring-not-installed/project" bash "$HOOK_UNDER_TEST"

home="$(ring_home ring-copilot true "" yes)"
assert_command_output "Copilot CLI ignores alex-ring (Claude Code only)" "sdk" "" "" "$home" \
    CLAUDE_PLUGIN_ROOT="$REPO_ROOT" COPILOT_CLI=1 CLAUDE_PROJECT_DIR="$TEST_ROOT/ring-copilot/project" bash "$HOOK_UNDER_TEST"

if [[ "$FAILURES" -gt 0 ]]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
fi

echo "STATUS: PASSED"
