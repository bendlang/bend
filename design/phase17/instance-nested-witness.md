# Phase17 nested instance witness correction

The unchanged-image `instance-paired-01` experiment completed all 18 observations.
Only the original instance-before-type witness differs. The first nested proposal
was not a counterexample: repeated consumption of the outer lambda's `x` is
checked at that lambda's exit, after its nested template call. Both compilers
therefore report `app~0` first. Keep these results; do not reinterpret them as a
failed compiler control or change the oracle.

A corrected prospective witness must expose an ordinary failure before the
nested call is reached by the authoritative checker. Bind a local annotated
lambda `g: Nat -> Nat = n => f(n)` in the generic template. Generic opaque `f`
is valid; substituting the closed duplication lambda makes this local lambda's
`n` fail as soon as that let value is checked. The later nested invalid `app`
should lose to this earlier failure upstream. Our specializer prewalk does not
check ordinary lambda quantities and may reach the later `app` first. Its
`sp_type` helper infers at erased demand zero, so it is not an alternative live
validation point.

Freeze four small controls before probing: local-lambda error before invalid
instance; reverse order; local-lambda error before valid instance; valid local
lambda before invalid instance. All are checker refusals. Full strict paired
results and explicit fixture contracts stay unchanged. This is still an
unchanged-image investigation, not authorization for a compiler edit.
