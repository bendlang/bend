# Exact Base-prefix freshening: law passes, optimization deferred

Do not change the cache ABI for this optimization now. Reusing the exact checked
Base prefix is sound in the tested graphs, but it removes only **1.3244% of the
freshening worker's visits** on the actual compiler source. Its share of total
compiler work is smaller and no controlled elapsed-time gain has been measured.
The experiment changed no compiler function body, default or cache format.

The prospective plans are
[the finite proof](../../design/phase16/checker-base-prefix-proof.md) and
[the serial whole-source extension](../../design/phase16/checker-base-prefix-serial.md).
The machine-readable conclusion is [checker-base-prefix.json](checker-base-prefix.json).

## What the proof established

The export-only probe was genuinely checked and derived through the maintained
workflow. Its36 maintained cases pass their contracts, with4 strict differences
already present in the wave4 implementation. Every Bend module is byte-identical
to wave4-source-02; additional host exports expose existing workers only.

Freshening the checked Base at1 is byte-idempotent, including all source ranges.
Its actual next counter is3413. The Base contains28,780 KTerms,528 nested/top-level
definitions, and3,412 binder nodes. `norm_max_book + 1` is not an acceptable
replacement for this counter: that function also examines token-position IDs.

All11 finite controls pass in `checker-base-prefix-proof-03`:

- Seven graphs have an exact Base prefix. Full and prefix-preserving freshening
  produce identical complete terms, source ranges, list order and final counters.
  These include aliases, repeated physical imports, Base-first order, valid and
  invalid imported law fills, and a collision with a Base declaration.
- Base after an earlier declaration module and absent Base are explicitly
  ineligible. They retain ordinary full freshening.
- A malformed declaration and duplicate def fail during source discovery, before
  graph freshening. Wrong seed path/text controls refuse the seed.

The ordinary graph wrapper and public seed loader agree on the complete book and
exact error text. Nineteen instrumented finite outputs also equal their ordinary
outputs. Counters measure named worker entries; they are not a total allocation
census.

The whole compiler extension uses two fresh processes in sequence. Both consume
the exact source bound by `stage-matrix-01`, identical API/cache/input identities,
CPU1,4MiB stack and4GiB heap. One computes full freshening; the other obtains the
actual Base next, proves the prefix, and freshens only the suffix. Each streams
canonical JSON one definition at a time rather than retaining both comparison
results. Both finish successfully with the same error, counter and complete
337,202,666-byte book digest:

`53a70dffabc420ae52bbe3ba7ad569d7db5239993d08c42896eda92cc7eb7071`

The final next is20906; the output has2,894 top-level declaration events.

| Count on frozen compiler source | Full | Split |
| --- | ---: | ---: |
| Freshening worker entries | 2,170,908 | 2,142,156 |
| Final KTerms | 2,171,045 | 2,171,045 |
| Final object nodes | 8,648,663 | 8,648,663 |
| Final terms with source ranges | 150,871 | 150,871 |

The reduction is28,752 actual worker entries. The instrumented process durations
and RSS are retained as operational evidence, with no speed comparison inferred.

## Better next question

The same graph probe counts105,542 alias-term visits,86,588 scope entries and
1,464,231 pattern-substitution entries before2,170,908 freshening entries. The
large increase in term count occurs during ordinary elaboration. Diagnostic
origin reconstruction is absent from the successful source-check path.

Investigate compact literals and repeated body substitution before adding a Base
cache protocol. U32/Char/String lowering already constructs word/constructor
trees eagerly, and the earlier memo experiment proved that it loses the semantic
identity of a written U32 literal versus an explicit constructor. Preserving that
identity may improve correctness and remove substantial traversed data together.
A tag/literal-specific counter is still required: the present counts identify the
expansion boundary, not an exact attribution or promised gain.

## Preserved failures and limits

Build01 rejected a duplicate export. Probe01 used the wrong FFreshDefs field;
probe02 encountered the JavaScript string limit while indenting deep linked-list
JSON and exposed an earlier-than-planned duplicate-def rejection. Their corrected
successor retains compact complete AST evidence and exact error comparison.
Whole-source probe04 retained several full books together; it was stopped with
SIGTERM at about4GiB RSS and exit143. Its incomplete report and explicit
termination record remain. The successful serial replacement stores digests and
counts without simultaneous full/split results. Earlier consumed prospective
plan bytes are retained beside each attempt with their recorded hashes.

Phase12's rejected seed cleanup concerned normalizer fallback, not Base reuse,
so there is no direct source overlap. Its resource lesson still applies: four
fresh-process checks passed, but the exact53-request history made seed-only
fail the long-string case while JS-only passed, with all52 preceding observations
identical. That recorded history remains bound in this experiment. Finite data
equality does not establish resource/history equivalence, and any later source
optimization still needs that boundary plus the full frontend gate.
