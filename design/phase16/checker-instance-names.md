# Phase16: derive instance numbers from each template's existing memo

Prospective bounded wave, independent of the larger chronology design. Pinned
`def_inst` numbers entries in `book.tmps[template]`. Our shared global serial
instead makes the first `bounce` instance `bounce~1` after minting `loop~0`.
This is visible in the retained `check/template_inst_cycle.bend` diagnostic.

Remove the global serial field and its accessor from KSpecState. On a genuine
memo miss, count entries for that template in the existing memo and use that
ordinal. Do not increment on hits, key/depth refusal or active-cycle reentry.
Count active entries too, as upstream installs a memo entry before checking it.
Keep the separate fresh variable-ID bound and every checker/visibility rule.
Only check/specialize.bend changes beyond frozen checker-source-04.

This removes one state concept and one field copied through each state rebuild.
It adds a linear memo scan only on a new instance, after the existing miss scan;
cache hits do not scan a second time. Prefer that explicit small helper over a
new per-template counter map or overloading fields in the memo's miss sentinel.
No speed gain is claimed; the root whole-host gate will measure any cost.

Freeze six direct positive witnesses before running: two different templates,
repeated same-key instances, interleaved distinct keys, nested templates,
decreasing recursive reuse, and an erased template application. Compare actual
materialized instance-name sets from the genuine checked baseline and candidate
against pinned TypeScript and declared expected sets. Keep direct source/pin/API
identities bound before and after the probe. Include these witnesses in the
paired strict checker selection, plus two custom diagnostic cases where another
template precedes an invalid instance and repeated memo hits precede it. Reuse
the corpus cycle, affine-instance, depth-growth and key-growth witnesses.

Require the genuine checked B1 workflow and all 36 maintained cases. Run the
prior 84 observations once, with the original 55 as an audited subset; only the
predicted cycle instance name may change in those 84. Run the new selected
witnesses against both baseline and candidate. Primitive outcomes must agree;
strict text differences remain failures until actual source-range integration
fixes them. No old attempt, production source or pinned TypeScript edit.
