# P36-004 — avoid repeated exact-entry reflection within a full proof

Status: **rejected for no reliable speed gain**; named saved-output semantic
controls pass, no production patch applied.

[Design](../../design/phase36/guard-exact-entry.md).
The saved-output producer will record actual checked compiler parents and modify
only the guarded reflection branch of `invokeExact`. Private exact-code membership
and token lifetime remain unchanged. Public, delayed and error-reentry controls
are mandatory. Counter diagnostics run separately from clean original-ray timing.

Stop on any observable mismatch or a ≤3%/overlapping timing result. A successful
saved-output result permits considering a small production patch, not bypassing
checked compiler and final integration gates.

Outcome: five balanced clean rounds measure actual checked03 ray at 792.012ms and
the ablation at 793.867ms, a 0.234% slower median with overlapping/nonstationary
samples. All colf 57/200, scope 10, actual overflow 16/4 and counter/public-wrapper 7
controls pass. On the first mechanism point only 24 of 380 invokeExact calls skip
reflection; unchanged generic calls dominate. No production patch or successor
checked adapter was written. [Report](../../implementation/phase36/guard-exact-report.md),
[hashed summary](../../implementation/phase36/guard-exact-summary.json).
