# P15-003: fresh profile and one bounded source optimization

Prospective plan under the [phase design](../../design/phase15/parser_conformance_and_speed.md).
Profile the actual Phase14 API9136be92 and its full-source check before choosing
an operation. Use the existing profile/worker contract, exact inputs and a quiet
CPU0 window. A profile is not a new performance comparison.

Freeze one candidate-specific hypothesis after reading the profile and source.
Prefer removed repeated work/allocation and no new maintained JS machinery.
Initial feasibility budget is90minutes from root's profile grant. Source changes
must preserve demand/error order, ABI and actual saved stack histories. Retain
seed/branch counterexamples; no higher limits or hidden recycling. Count work on
instrumented copies, then checked B1/26focus/independent controls/fresh+53/60history
before exclusive ABBA timing. CPU3 correctness after profiling. Root owns final
integration/TS comparison; rejection is a valid outcome if benefits do not justify
complexity. Preserve all attempts and account for maintained source/host/test cost.
