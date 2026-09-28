# Collector review

The conformance agent reviewed `collect.py` independently without running CPU
jobs during the controlled timing window. The closed-producer capture sequence
was judged sound: source identity checks, selected-membership recheck, external
CAS verification and atomic staging are explicit.

The review found a real metadata integrity defect: a symlink manifest target
was not bound to its archived object bytes before recovery. The collector now
verifies target length and SHA256, permits only file/symlink rows, checks file
modes and binds external-object byte lengths. Canonical relative recovery names
are also required. Two regression controls cover symlink-target tampering and
external-size tampering. The final synthetic suite passed 19/19 controls before capture.

This review covers archive integrity, not the correctness of the compiler
experiments or completeness of environmental reproduction. External libraries
and copied historical report references remain explicit prerequisites.

The bounded capsule-schema extension reuses a prior migration capsule only
after its exact external prerequisites are loaded and verified. Additional
controls pass for chained recovery, missing prerequisites and mutated prior
manifests; the complete final collector suite passes 23/23.
