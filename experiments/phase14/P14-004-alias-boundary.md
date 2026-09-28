# P14-004 addendum: imported alias declaration boundary

Frozen before the first integrated build or full frontend run. The isolated law
controls establish that TypeScript refuses an alias-prefixed definition with an
explicit return annotation during parsing. Admitting only omitted-type fills is
part of the P14-001 boundary, and candidate04 now agrees on that refusal phase.

The existing `import/alias_decl.bend` check observation therefore changes from
checker refusal to parser refusal. Its parser diagnostic still differs exactly
from TypeScript. Permit this one named fixture's parse/check diagnostic changes
only while both lanes equal the reference's semantic/output axes: status, phase,
checked, typeAccepted, proofTrust, kernelChecked, unsafeDefinitions, exitCode and
output. It must remain a refusal, and an existing exact match may not regress.
No other alias or parser change receives this exception. The original policy
remains in P14-004-integration-gates.md; the v2 tool records this specific addition.

The integrated focused selection appends the four repaired imported-law trust
refusals to the existing22cases (26total), preserving the long-string-first order.
Their declared oracle is refusal at `verdict`; exact trust fields are additionally
required by isolated/full conformance gates. Two genuine checked builds separate
conformance-only changes from the combined source-dispatch change for paired
stack/history controls. Neither build replaces the default before release gates.
