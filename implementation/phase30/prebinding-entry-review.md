# Repair the inherited prebinding application boundary

The exact-arm investigation exposed an inherited partial-prebinding gap as
well. `review-prebind-entry-01` compares the actual attempt03 runtime's
matcher1p helper with matcher1 plus the same literal function arm. A constructor
supplies two fields to a three-argument arm, so this witness does not depend
on the rejected count-equals-total compiler extension.

Four of seven scopes differ: an oversaturated matcher with an observable outer
copied-vector length, the same getter throwing, raw matcher callback entry, and
a code.call hook observing the raw callback result. The old matcher returns an
arm bounce and defers field-vector slicing until forcing. Prebinding previously
performed that slice inside its callback. Consequently it could run a foreign
slice effect before a stopping outer length read, and raw callers saw a partial
descriptor where the original returned a bounce. Exact ordinary application,
partial application, and a throwing field slice already agreed in the probe.

After freezing [the prospective repair](../../design/phase30/exact-application-prebinding.md),
the reviewer reused the exact-application capability under its broader name
`exactCode`. The runtime's private registry names were updated consistently;
worker.bend changed only its emitted helper reference. matcher1p now registers
its public callback, so the token is consumed before parameter destructuring.
After the unchanged project, length read and literal code creation, an
unprivileged call returns the original generic unsliced-field bounce (or the
original zero-field descriptor). Only actual exact entry performs prebinding.

All seven paired controls pass in `review-prebind-entry-02`, with complete
effect/error traces and raw-return behavior matching the original helper. The
receipt retains the consumed actual core and tool; no old evidence was modified.
Runtime source hash after this repair is
`e86a5163540a0388c206382107ed8e038da9e2c7eb2bf232d1d3f645966a91cf`.
The lead regenerates the combined runtime and builds the checked compiler.

The compiler's arm admission remains the original strict count-less-than-total
rule. This correctness repair does not reinstate the rejected exact-arm widening.
The broader arm and preworker Nat-loop integration suites still need to pass on
the combined checked artifact. No performance claim follows from these seven
runtime controls; extra entry dispatch and wrapper allocation must be measured.

A subsequent callable-shape audit found that the shared ordinary wrapper made
the old arrow matcher callback constructible. The prospective amendment and
repair retain an anonymous one-argument arrow for matcher1p, while Nat successor
callbacks remain ordinary functions. A shared module-level entry consumer keeps
the same one-use token ordering. Core hash after this adjustment is
`e716cc08841d169e6f45a6489cf64ac8d3e7157ac82caac3e34170ec57b023d2`.
Five actual-emission shape comparisons, seven runtime scheduling scopes and
nine entry controls pass on exact diagnostic core substitutions. These fresh
receipts are review-callable-shape-02, review-prebind-entry-03 and
review-scalar-entry-02. A new checked compiler build remains the lead's next gate.

That next gate is now complete: actual attempt07 passes 72 historical and
22 additional arm observations in `review-arm-07`, plus all five callable-shape
comparisons in `review-callable-shape-03`. See the complete bounded checkpoint
in [independent-integration-07.md](independent-integration-07.md).
