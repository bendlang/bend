# Local law-fill parameter diagnostics

The [design](../../design/phase16/local-law-parameters.md) reuses the header's
already known declaration and the existing pre/post telescope cursors. An initial
`~` on a local law fill fails before parsing its telescope. A telescope syntax
failure retains priority; otherwise bare-name and minimum-template-count checks
produce their own errors before the colon/body path. The header already rejects
every non-fillable existing declaration, so its eligibility predicate is not
repeated in the parameter worker.

`local-law-build-01` passes genuine checked bootstrap, unchanged v5 and the
36-case development selection. `local-law-checks-01` is **20/20 exact** against
14 differences in `local-law-baseline-01`. This covers both corpus fixtures
(`comptime/err_law` and `err_fill_short`, four observations), typed/marked/short
and malformed fills, valid fills, trailing commas, ordinary template declarations
and too few names before a return arrow. All reference acceptance/refusal
contracts hold. No oracle was weakened.

The change uses two existing functions, with no new helper, type, term variant,
source scan or host change. Expanded formatting makes the separate error order
reviewable; no reduction in physical lines is claimed. The source snapshot is
`selfhost/build/phase16/local-law-source-01`, based on accepted wave6. Its patch
must compose with the loader's later declaration-context work. It is not yet
part of a full-corpus or released checkpoint.
