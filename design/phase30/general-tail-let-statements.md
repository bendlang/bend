# Test direct Let statements in ordinary generated callbacks

This is a prospective extension experiment, separate from private helper Let
lowering. Much of the generic output still returns nested immediately invoked
arrow functions for source Lets. The pure-region ablation tests only a few
private helpers; it cannot establish whether the same representation costs more
in the generic record/array-heavy programs.

Derive an immutable variant of actual13 output without touching the runtime or
compiler. Parse JavaScript with the same pinned, recorded Node-bundled Acorn
used by the structural audit. Consider only ReturnStatements in generated code
after the exact runtime prefix. Recognize a complete tail IIFE whose callee is
a synchronous expression-bodied arrow, whose parameters are only emitted
`x<number>` identifiers and whose argument count matches those parameters.
Reject defaults, destructuring, rest/spread arguments, async and ambiguous forms.

Convert each admitted tail Let into nested statement blocks. Evaluate every
argument in its original order into fresh temporary names before declaring any
source binder, then emit the body in the extended inner block. Recurse only down
that tail Let chain. Leave all RHS expression bytes and non-Let terminal
expressions unchanged. Use `(0, (RHS))` for temporary initializers so introducing
an assignment cannot give an anonymous function or class a new inferred name.
The extra zero expression has no effect. Do not inline calls, change callback
kind/arity, enter delayed constructor fields early, or reassociate arithmetic.

The original arrow's lexical `this` and `arguments` are inherited from the same
enclosing generated callback. Blocks preserve that scope. Fresh administrative
identifiers cannot collide with any existing token. Parallel shadowing must keep
all RHS expressions outside the block defining the new source identifiers.
Escaped Bend closures must retain the same immutable per-invocation bindings.
No direct eval or with statement may occur in the transformed generated scope.

For nested AST edit ranges, select nonoverlapping deepest rewrites per round,
reparse, and retain every patch. Bound the rounds and reconstruct the complete
original bytes exactly by reversing every edit. Each module records its checked
attempt, source, runtime, tool/parser and output identities. These rewritten
modules are prototypes, never relabelled compiler output.

Before timing, run independent sequential/parallel-shadowing, exception-order,
anonymous-function-name and escaped-closure witnesses; retained public ABI and
entry controls; full edit-row state/alias controls; and original exact outputs.
Use a small real edit-distance row and the existing Mandelbrot point for the
first screen. Add small representative generic workloads only with their own
frozen exact outputs. Keep counter instrumentation out of timing.

If the ablation wins, a maintained implementation can add a small statement
return emitter using the existing Let value/name/context helpers and the
existing tail flag. Initially route only the same complete generated callback
return boundary through it. The existing expression emitter remains responsible
for RHS expressions, deferred fields, calls and all unsupported forms. No new
IR, runtime layout or purity analysis is justified by this proposal.

Promotion still requires a genuine checked compiler, actual-output controls,
original-program integration, a fresh clean comparison and measured compilation
cost. A private-helper result does not substitute for the general experiment.
