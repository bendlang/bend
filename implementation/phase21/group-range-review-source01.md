# Independent review of R1 source01

**Withhold source01.** The shared Local producer change is correctly isolated, but locating Local stops `f_locate` from descending through `f_span_created`; its synthetic typed `Ann` loses its existing origin and becomes 0/0. Pinned `parse_body` explicitly gives that annotation the original body cursor through the returned RHS cursor. The old whole-group span was also inaccurate; removing it does not make this candidate acceptable. Review the explicit producer correction separately.

All 214 project members match the checked snapshot byte-for-byte and retain parent modes. Only `src/front/declarations.bend` changes: one `kt` becomes `kt_span`, adding 23 bytes with no lines, definitions, laws or types. All eight prospective preparation inputs still match their frozen hashes. Genuine checked bootstrap and strict maintained36 completed normally with zero exact differences. Parent API is `40c8f7f3…`; candidate API is `ab48c7c6…`.

The independent68 observations improve from 44 to 60 exact (+16, no lost exact matches or changed primitive outcomes). The original failed oracle assumptions remain visible. The 102 structural observations retain every nonrange field and acceptance result; all 46 legacy observations keep absent ranges. That structural pass allows origin differences and therefore does not approve them. Full Base graphs were compared, but no complete compiler-workload graph was claimed.

The original saved196 launcher report remains incomplete and false after asserting `selectedComplete` on its known-failing selection. A separate raw-vector audit is needed for any healthy-acquisition or no-regression claim; this review does not relabel that report. No compiler probe, production edit, timing or promotion was performed by this reviewer.

Exact source, build and independent report identities are bound in `group-range-review-source01.json`. Preservation planning is recorded separately in `group-evidence/PLAN.md`; capture awaits root's final freeze and anchor selection.
