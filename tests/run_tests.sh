#!/usr/bin/env bash
# Runs every tests/test_*.gd headlessly. Used by CI (.github/workflows/tests.yml)
# and runnable locally:  GODOT=/path/to/godot tests/run_tests.sh
#
# A test passes only if Godot exits 0 AND prints "RESULT: PASS". Godot output is
# not grepped for "ERROR:" since some tests print those on purpose.
set -uo pipefail

GODOT="${GODOT:-godot}"
TIMEOUT_SECS="${TEST_TIMEOUT_SECS:-120}"
cd "$(dirname "$0")/.."

# Guard against a test that never calls quit(). macOS has no `timeout` by default.
if command -v timeout >/dev/null 2>&1; then
	run() { timeout "$TIMEOUT_SECS" "$@"; }
else
	run() { "$@"; }
fi

shopt -s nullglob
tests=(tests/test_*.gd)
if [ ${#tests[@]} -eq 0 ]; then
	echo "No tests/test_*.gd scripts found" >&2
	exit 1
fi

# Fresh checkouts need an import pass so class_name scripts are registered.
echo "== Importing project"
run "$GODOT" --headless --path . --import || {
	echo "Import failed" >&2
	exit 1
}

failed=()
for t in "${tests[@]}"; do
	echo "== $t"
	log="$(mktemp)"
	run "$GODOT" --headless --path . -s "$t" 2>&1 | tee "$log"
	code=${PIPESTATUS[0]}
	if [ "$code" -ne 0 ]; then
		echo "-- $t: FAILED (exit code $code)"
		failed+=("$t")
	elif ! grep -q "^RESULT: PASS" "$log"; then
		echo "-- $t: FAILED (no 'RESULT: PASS' line)"
		failed+=("$t")
	else
		echo "-- $t: passed"
	fi
	rm -f "$log"
done

echo
if [ ${#failed[@]} -gt 0 ]; then
	echo "${#failed[@]} of ${#tests[@]} test script(s) failed:"
	printf '  %s\n' "${failed[@]}"
	exit 1
fi
echo "All ${#tests[@]} test script(s) passed."
