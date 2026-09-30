# First general scalar-region compiler checkpoint

This is an intermediate implementation checkpoint, not a newly installed
release. Attempt07 passes the 36 focused exact frontend checks. Broader backend
integration and comparative runtime measurements remain pending.

The compiler now constructs a bounded private helper graph for eligible pure
scalar Nat loops. It preserves native U32/Bool/Nat representations, records
scalar types in three emitter-only term forms, emits ordinary private JavaScript
helpers, and checks the original public dependency descriptors once at entry.
Unsupported graphs use ordinary code. Original helper definitions and public
partial application remain available.

The semantic review substantially improved the entry rule. It found five
preexisting Phase29 failures involving outer overapplication and mutable self
bindings. A loop now requires the exact-saturation runtime entry, snapshots its
owner as well as dependencies, and falls back to the original generic body.
The same entry mechanism repairs an inherited constructor-field prebinding
scheduling gap. A follow-up preserves arrow versus ordinary callback shape.
The attempted exact-saturation arm extension is withdrawn after three independent
counterexamples; its small timing gain is retained as rejected evidence.

The separate literal-shift rule resolves compact native Nat counts after the
existing primitive provenance checks. It adds one small emitter function.
Counts at least 32 evaluate their operand without coercing it and return zero;
dynamic counts retain the old code. Actual attempt06 output passes 12,600 scalar
comparisons across old/candidate/TypeScript, 112 host-value observations, four
retained-partial checks and 96 operand-order/error comparisons. The differently
shaped scalar fixture passes 63 numeric points and five fallback points.

Attempt05 passes 22 admission books with 13 execution checks, all five inherited
loop witnesses, nine entry/reentry cases, 130 ordinary ABI/effect observations,
72 scalar-oracle observations, and the 72+22 arm controls. Attempt07 adds the
callable-kind repair and renews all those gates successfully, plus five callback
shape comparisons. See [the independent report](independent-integration-07.md).
Counts have different scopes and must not be added as a single conformance
percentage.

The diagnostic investigation also removed a validation-loop trap: formatting
one upstream type error previously exceeded 120 seconds. Bounded structural
formatting reports that error in 1.836 seconds. Successful emission agrees byte
for byte in its control. The new recipe has 19 admission/provenance checks;
historical recipe replay remains supported. Attempt04's intentional fail-closed
recipe rejection is retained. Five unrelated stale assertions in the legacy
equality suite fail identically before and after the recipe change.

Canonical Bend source is now 16,561 physical / 14,141 nonblank lines, 633,475 bytes,
65 modules, 1,813 definitions, 640 laws and 70 types. Relative to Phase29, that is
+354 lines, +51 definitions, +2 types and one module. This is a speed/correctness
investment, not a source-size reduction. The main new responsibilities are the
bounded private region plan, dependency snapshots and exact-entry permission.

Two compatibility limits stay explicit. Malformed host callbacks can receive
`code.call is not a function` where the older engine-generated error named
`f.code.call`; exception class and evaluation order agree. Monkeypatching global
prototype hooks can observe different administrative trampoline reads. The
three-way raw comparison retains those inherited differences; ordinary values
and errors agree in its probes. Neither is a claim of complete reflective-host
equivalence, and neither raw mismatch is relabelled as an exact pass.

See the linked [campaign index](README.md) for designs, rejected hypotheses and
independent reports. No new PR comment has been posted. Phase29 remains installed
until the surviving candidate passes broader validation and measurement.
