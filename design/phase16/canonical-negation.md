# Canonical reference in negated equality

Prospective bounded experiment, 2026-09-29; parent is the frozen Phase16
`spans-shared-migration-01` project. This is a semantic correction independent of
source-range instrumentation. It changes no upstream code or oracle.

Pinned TypeScript constructs negated equality as an equality-to-`Ref("Empty")`
function. That reference bypasses both lexical lookup and module name resolution.
The local variable `ns` in its parser is the operator's source span, not a
namespace. The historical fixture comment describing an ADT is not authoritative.
Our delayed scope pass captures the generated ordinary Ref when a binder is named
Empty; later module qualification can also redirect it to an own declaration.

Represent this one generated canonical name with a surface `FGlobal` tag. Existing
scope and qualification traversals preserve this tag without binding or renaming
it. The existing final freshening pass consumes it into an ordinary Ref, preserving
the occurrence range. This adds no pass, kernel term, backend case, quantity flag
or new record field. Other references still follow normal lexical/module lookup.
An ADT shortcut is rejected: a legitimate global Empty type alias must remain a
reference, and a module's own Empty must not capture the canonical global name.

First freeze direct controls for local shadowing, explicit lexical use, root
Empty aliases, absent Empty, imported own Empty and qualified aliases. Compare
loaded term identities with pinned TypeScript, then run paired checking for the
original capture/reflexivity fixtures and controls. A checked build must retain
the maintained 36-case gate. Direct pre-fresh parser APIs may contain the surface
marker, as they already contain FUnboundVar; public loaded books must not.
Preserve every unexpected outcome and narrow the change if an ordinary reference
changes meaning. Full-corpus and timing acceptance belong to final integration.

The expected source delta is one conditional in the freshener and one constructor
tag change. Source origins for the generated reference must use the `!=` operator
range once the parser instrumentation is composed. Outcomes belong in
`implementation/phase16/canonical-negation.md`.
