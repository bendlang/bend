# P26-001 — erase scalar-to-word construction for numeric decisions

- Owner: root/implementation agent; independent review: call-lowering agent.
- Started: 2026-09-30. Frozen plan before candidate build or timing.
- Correctness: pending selected emitted-output and maintained focused gates.
- Measurement: pending; generated JavaScript only.
- Decision: investigate; no release promotion yet.
- Design: [direct U32 decisions](../../design/phase26/direct-u32-decisions.md).
- Results will be recorded in [the implementation report](../../implementation/phase26/direct-u32-decisions.md).

Hypothesis: native U32 decisions with closed literal leaves can operate directly
on the original unsigned scalar, eliminating33 temporary constructor values per
match and unused lifted matcher factories. Existing fn/call descriptors remain.
Native identity and the original ordered matcher tree justify the replacement;
unsupported captures, variable Word transport and arbitrary terms fall back.

Disproof: any semantic mismatch, absent constructor reduction, compile-time
pathological expansion, or no useful repeated speed improvement on the frozen
numeric kernels. No speed estimate is accepted as evidence. The unchanged
arithmetic/boundary controls test accidental runtime or measurement changes.

The design freezes correctness, calibration, timing and promotion boundaries.
Phase25 supplies the checked baseline artifacts and independent oracle corpus.
New acquisition uses immutable checked B1 attempts and explicit API/runtime/Base/
driver identities. Every failed attempt is retained; compilation, execution,
measurement validity and promotion remain distinct decisions.
