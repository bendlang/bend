# P16 parser diagnostics — preserve rejection information

- Owner: phase15_speed; reviewer: root and source-origin owner.
- Evidence cutoff: released Phase15 combined-02, upstream b2111cf.
- Correctness: baseline census only; no candidate has executed.
- Measurement: none; root owns timing and integration.
- Decision: investigate sequential stages in the [design](../../design/phase16/parser_diagnostics.md).

The falsifiable first claim is that one optional source-range/error-observation
record fixes the 24 parser observations with the correct expectation but the
wrong observed text or range. The full parser census contains 122 fixtures and
244 paired parse/check observations. The builder keeps the current KTerm ABI and
existing point-error fallback. A range is source coordinates, never reconstructed
from legacy prose; a custom observed string is explicit producer data.

Before probes, prepare an isolated parser-01 snapshot and capture the exact patch,
checked workflow config, baseline identities, and all 122 fixture IDs. Initial
range controls cover duplicate names with/without whitespace, constructor/name
keywords, one/multiple/multiline match patterns, invalid import paths with point
markers, valid sources, tabs, UTF-16 characters, EOF and paired competing errors.
Any changed successful book/import structure, behavior mismatch or lost exact
match rejects the attempt. Broaden only after exact causes are supported.

The implementation report records outcomes and further prospective supplements;
this pre-execution plan remains frozen. All unsuccessful attempts are retained.
