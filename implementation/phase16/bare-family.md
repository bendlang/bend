# Bare family reference correction

The [design](../../design/phase16/bare-family.md) is validated in isolated
`bare-family-build-01`. A single predicate in `f_scope_reference` preserves bare
parameterized datatypes as references. The existing checker then handles them
correctly. Zero-arity datatypes, explicit family applications, +D quantity syntax
and lexical shadowing retain their existing paths. The patch adds **no physical
lines, definitions, laws or term variants**.

All **eight paired controls are exact**, including the existing
`check/family_head_bare.bend`. The same frozen controls on the parent had three
differences: ordinary bare-family wording, the upstream fixture wording, and a
real acceptance bug. The old compiler silently filled the quantity parameter of
a bare `Token<q>` family; TypeScript rejects it until the family is explicitly
instantiated or marked with +. The candidate now rejects it exactly, while all
five positive boundaries remain exact.

The genuine checked build and unchanged v5 derivation pass the maintained
36-case gate with seven inherited differences. Records under
`selfhost/build/phase16/`: `bare-family-source-01/manifest.json` and patch,
`bare-family-build-01`, `bare-family-fixtures-01`, `bare-family-baseline-01`, and
`bare-family-checks-01/selected/paired.json`. The parent is the isolated canonical
reference candidate; the only incremental source change is this predicate.

This candidate is not installed. Its tiny patch is being composed with the full
range/checker work; full-corpus and final performance gates still apply.
