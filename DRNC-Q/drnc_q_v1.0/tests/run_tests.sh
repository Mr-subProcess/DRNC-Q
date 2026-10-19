#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/drnq"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$ROOT"

expect_fail() {
  local label="$1"; shift
  if "$@" >"$TMP/stdout" 2>"$TMP/stderr"; then
    echo "FAIL: $label unexpectedly succeeded" >&2
    cat "$TMP/stdout" "$TMP/stderr" >&2
    exit 1
  fi
}

"$BIN" --version | grep -q 'v1.0'
"$BIN" --about | grep -q 'standalone native compiler'

# Control flow, math, short circuit, recursion, scopes, list mutation, exceptions.
"$BIN" check examples/control_flow_math.drq | grep -q 'PASS:'
OUT="$("$BIN" run examples/control_flow_math.drq)"
grep -q 'arithmetic: 8' <<<"$OUT"
grep -q 'if branch selected' <<<"$OUT"
grep -q 'after for: 18' <<<"$OUT"
grep -q 'after while: 3' <<<"$OUT"
grep -q 'sqrt(9)=3' <<<"$OUT"
grep -q '2\^3=8' <<<"$OUT"
grep -Fq -- '-2^2=-4' <<<"$OUT"

OUT="$("$BIN" run examples/control_flow_short_circuit.drq)"
grep -q 'short-circuit and else-if PASS' <<<"$OUT"
! grep -q 'must not print' <<<"$OUT"

OUT="$("$BIN" run examples/language_core.drq)"
grep -q 'factorial=720' <<<"$OUT"
grep -q 'items=\[1, 10, 3, 4\]' <<<"$OUT"
grep -q 'sum=18' <<<"$OUT"
grep -q 'loop_sum=25' <<<"$OUT"
grep -q 'caught=division by zero' <<<"$OUT"
grep -q 'PASS normalized' <<<"$OUT"

# User-defined classes/method dispatch and constructor path.
OUT="$("$BIN" run examples/classes.drq)"
grep -q 'type=Vector2' <<<"$OUT"
grep -q 'length=5' <<<"$OUT"
grep -q 'scaled_length=10' <<<"$OUT"
grep -q 'new_length=13' <<<"$OUT"

# Standard library: strings/lists/null/cycle-safe formatting.
OUT="$("$BIN" run examples/standard_library.drq)"
grep -q 'cycle guard PASS' <<<"$OUT"
grep -q 'standard library PASS' <<<"$OUT"

# Quantum model: auto-generated basis, gates, normalization, entanglement, modular flow.
OUT="$("$BIN" run examples/quantum_gates.drq)"
grep -q 'DRNC-generated sectors' <<<"$OUT"
grep -q 'ENTANGLED' <<<"$OUT"
grep -q 'gate sequence complete' <<<"$OUT"
OUT="$("$BIN" run examples/quantum_dynamics.drq)"
grep -q 'DRNC modular flow ACTIVE' <<<"$OUT"
grep -q 'dimensionless internal relational parameter' <<<"$OUT"
OUT="$("$BIN" run examples/entangle_variables.drq)"
grep -q 'ENTANGLED' <<<"$OUT"
grep -q 'PASS normalized' <<<"$OUT"
OUT="$("$BIN" run examples/entangle_teleport.drq)"
grep -q 'logical teleportation complete' <<<"$OUT"
grep -q 'PASS normalized' <<<"$OUT"
OUT="$("$BIN" run examples/full_drncq_demo.drq)"
grep -q 'DRNC relational branch is coherent' <<<"$OUT"
grep -q 'logical teleportation complete' <<<"$OUT"

# Relative module import.
OUT="$("$BIN" run examples/modules/module_main.drq)"
grep -q 'square=25' <<<"$OUT"
grep -q 'cube=125' <<<"$OUT"

# Bytecode round-trip, including class and function manifests.
"$BIN" compile examples/classes.drq -o "$TMP/classes.drnb" > /dev/null
OUT="$("$BIN" exec "$TMP/classes.drnb")"
grep -q 'scaled_length=10' <<<"$OUT"
"$BIN" compile examples/modules/module_main.drq -o "$TMP/module.drnb" > /dev/null
OUT="$("$BIN" exec "$TMP/module.drnb")"
grep -q 'cube=125' <<<"$OUT"
"$BIN" ir examples/quantum_gates.drq | grep -q 'DRNC-Q v1.0 DRNQ-IR'
cp "$TMP/classes.drnb" "$TMP/corrupt.drnb"
printf 'X' | dd of="$TMP/corrupt.drnb" bs=1 seek=10 conv=notrunc status=none
expect_fail 'bytecode checksum' "$BIN" exec "$TMP/corrupt.drnb"
grep -q 'checksum mismatch' "$TMP/stderr"

# Standard file API; paths are local to this process and no service is contacted.
cat > "$TMP/file_io.drq" <<EOF2
program file_io;
DRNCQ = "path", "$TMP/data.txt";
DRNCQ = "written", write_file(path, "hello\\nworld");
assert(written == 11, "write_file byte count wrong");
assert(file_exists(path), "file_exists false after write");
DRNCQ = "content", read_file(path);
assert(content == "hello\\nworld", "read_file data mismatch");
print("file I/O PASS");
EOF2
OUT="$("$BIN" run "$TMP/file_io.drq")"
grep -q 'file I/O PASS' <<<"$OUT"
cat > "$TMP/input.drq" <<'EOF2'
program input_test;
DRNCQ = "raw", input("number: ");
DRNCQ = "n", to_number(raw);
assert(n == 42, "input conversion failed");
print("input PASS");
EOF2
OUT="$(printf '42\n' | "$BIN" run "$TMP/input.drq")"
grep -q 'input PASS' <<<"$OUT"

# Exceptions thrown in called functions unwind cleanly into caller's handler.
cat > "$TMP/throw.drq" <<'EOF2'
program throw_test;
fn explode() { throw "intentional"; }
try { explode(); } catch (err) {
    assert(contains(err, "intentional"));
    print("throw/catch PASS");
}
EOF2
OUT="$("$BIN" run "$TMP/throw.drq")"
grep -q 'throw/catch PASS' <<<"$OUT"

# Compile-time rejection: names, arity, scope, malformed control flow, invalid qubit refs.
cat > "$TMP/unknown_var.drq" <<'EOF2'
program invalid;
DRNCQ = "x", 1;
print(y);
EOF2
expect_fail 'undeclared variable' "$BIN" check "$TMP/unknown_var.drq"
grep -q "undeclared variable 'y'" "$TMP/stderr"
cat > "$TMP/function_arity.drq" <<'EOF2'
fn add(a, b) { return a + b; }
print(add(1));
EOF2
expect_fail 'function arity' "$BIN" check "$TMP/function_arity.drq"
grep -q 'expects 2 argument' "$TMP/stderr"
cat > "$TMP/constructor_arity.drq" <<'EOF2'
class Pair { fn init(self, x, y) { self.x = x; self.y = y; } }
DRNCQ = "p", Pair(1);
EOF2
expect_fail 'constructor arity' "$BIN" check "$TMP/constructor_arity.drq"
cat > "$TMP/scope_escape.drq" <<'EOF2'
if (true) { DRNCQ = "hidden", 4; }
print(hidden);
EOF2
expect_fail 'lexical scope escape' "$BIN" check "$TMP/scope_escape.drq"
cat > "$TMP/break_outside.drq" <<'EOF2'
break;
EOF2
expect_fail 'break outside loop' "$BIN" check "$TMP/break_outside.drq"
cat > "$TMP/non_qref_gate.drq" <<'EOF2'
DRNCQ = "q", qubitfonk();
cxgate(q, 1);
EOF2
expect_fail 'invalid controlled-gate operand' "$BIN" check "$TMP/non_qref_gate.drq"
cat > "$TMP/duplicate.drq" <<'EOF2'
DRNCQ = "x", 1;
DRNCQ = "x", 2;
EOF2
expect_fail 'duplicate global' "$BIN" check "$TMP/duplicate.drq"
cat > "$TMP/reserved.drq" <<'EOF2'
DRNCQ = "sqrt", 1;
EOF2
expect_fail 'reserved variable' "$BIN" check "$TMP/reserved.drq"
cat > "$TMP/divzero.drq" <<'EOF2'
DRNCQ = "x", 1;
print(x / 0);
EOF2
expect_fail 'division by zero' "$BIN" run "$TMP/divzero.drq"
grep -q 'division by zero' "$TMP/stderr"
cat > "$TMP/index_oob.drq" <<'EOF2'
DRNCQ = "xs", [1];
print(xs[3]);
EOF2
expect_fail 'index bounds' "$BIN" run "$TMP/index_oob.drq"
cat > "$TMP/cycle_a.drq" <<EOF2
import "$TMP/cycle_b.drq";
fn a() { return 1; }
EOF2
cat > "$TMP/cycle_b.drq" <<EOF2
import "$TMP/cycle_a.drq";
fn b() { return 2; }
EOF2
expect_fail 'cyclic import' "$BIN" check "$TMP/cycle_a.drq"
grep -q 'cyclic module import' "$TMP/stderr"

# A real program returning no value yields null, not a dangling stack value.
cat > "$TMP/null_return.drq" <<'EOF2'
fn noop() { return; }
DRNCQ = "n", noop();
assert(type(n) == "null");
print("null return PASS");
EOF2
OUT="$("$BIN" run "$TMP/null_return.drq")"
grep -q 'null return PASS' <<<"$OUT"

echo 'PASS: DRNC-Q v1.0 complete-core regression suite'
