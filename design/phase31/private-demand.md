# Demand specialization within a closed private region

Prospective follow-up to checked04, before changing its demand rule. Its complete
local graph already removes generic calls while preserving record builds and
force at every non-scalar private call. Investigate two separate steps: eagerly
complete private helper returns, then remove now-redundant private-result force.
This retains public record/Array representations and mutable alias behavior.

The proof boundary is narrower than a general strictness pass. Public roots have
scalar inputs/results (or the already admitted inert terminal scalar record).
The first-order grammar excludes callbacks, global/foreign containers, function
fields, and recursive record types. Original bindings and runtime assumptions
are guarded before entry. Every private returned container either becomes a
non-tail operand/RHS, demanded before its next sibling, or travels through a tail
return chain with no source operation before that demand. Nested constructor
fields are demanded left-to-right recursively. No private delayed result escapes.
Consequently completing such a return at its producing helper should perform the
same reads/writes before the same next source operation. This does not permit
arbitrary hoisting of setters across a Let or changing public callback returns.

Independent review must challenge the argument using nested record fields,
zero/successor cases, mutually aliased arrays, first-field delayed setters,
argument evaluation ordering and public raw/saved/forged entry. Preserve the
known invalid delayed-write witness as a negative control. Compare complete
native traces and all physical arrays, not only a final checksum.

First freeze checked04 performance. A checked candidate changing only private
return demand is an ablation; the force-elimination step is separate. Reuse
ordinary constructor emission with tail=False, rather than add another data
representation. Keep all public generic emitters unchanged. Measure original
full pair, the distinct array-fold fixture, scalar canaries, full small benchmark
and compilation overhead. Unsupported programs keep their existing path.
