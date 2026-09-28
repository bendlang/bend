# Bend-in-Bend upstream migration

The active compiler source targets upstream
[`b2111cf`](https://github.com/bendlang/bend/tree/b2111cf43244e65f76ddc278ee695e669f720cbf),
after the Bend2 2.0.32 release. The authoritative revision and version are in
`selfhost/src/compiler.json`. The checked release is installed; consult
[the migration report](../implementation/phase8/upstream_and_conformance.md)
for artifact-specific results rather than inheriting old corpus counts.

Bootstrap uses Node 24 and the immutable checkout
`selfhost/.bootstrap/upstream-phase8`. The old checkout remains historical.
The stage0 helper checks the whole source book and emits an eligible selected
library through current upstream APIs. Ordinary compilation still executes the
Bend implementation and never falls back to TypeScript.

The checker now knows every datatype and definition signature up front. Bodies
become available only after their chronological event checks successfully. Safe
live calls to future definitions remain invalid; unsafe code is separately
reported. Cached-prefix checking preserves the same declaration/body boundary.
Nested constructor patterns receive fresh telescope binders to preserve scope.

`--check-only` reports proof trust after ordinary checking. A safe book prints
`ALL PROOFS CHECK` and the upstream kernel hint; unsafe/foreign dependencies print
`SOME PROOFS FAIL` and exit 1. Running a validated main remains allowed. The port
**does not implement `--verdict` or independent BendTT/Lean validation**; asking
for it produces an explicit unsupported message. The upstream hint is compatibility
text, not a claim that this port can invoke that kernel.

Conformance reports distinguish syntax/type validation, proof trust, error phase,
exact diagnostic text and execution results. The current upstream gate has 1498
fixtures plus 11 support modules. The previous 1378-fixture and 6.03× timing results
belong to older recorded artifacts, not this migration.

The release workflow can install genuine checked B1 directly and verify its
source, recipe, API, Base and runtime identities after relocation. A checked
release is not a fixed point. Historical equality-derived verification remains
available for the old artifact; its source-sensitive transform is not applied to
new generated code without independent validation.

Source remains a 59-module first-order compiler. The migration reuses S4's shared
loader/error/index operations; a small do marker and declaration/body distinction
supply the new semantics. One foreign CID/FID scanner serves both backends, using
reachable effects for namespace ownership and the complete book for identifiers.
Native internal closure dispatch cannot collide with user Clo.apply.

Read the [current compiler guide](BEND-IN-BEND.md) for rebuilding the checked
release and the [conformance document](../selfhost/CONFORMANCE.md) before interpreting
pass counts. Component parity failures and literal/imported-law gaps are retained,
not bypassed. The default does not use the rejected Phase7 evaluator or binder
walker prototypes.
