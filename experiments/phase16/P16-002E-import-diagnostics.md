# P16-002E — explicit import diagnostic data

Status: prospective. Design: design/phase16/import-diagnostics.md.
Baseline: spans-integration-build-04, API
9a5294d51db35fc5317ae94bc8439bb62f586b4ea7b8314366cb4ff4473a4c11.
Reference: pinned upstream b2111cf43244e65f76ddc278ee695e669f720cbf.

Hypothesis: the seven import-specific fixtures differ because source-line/name/
point information is discarded by narrow validation branches. Error-only payloads
and existing shared formatting can recover exact diagnostics without adding a
source lookup architecture or changing successful import identity/resolution.

The opportunity ceiling is 14 exact observations; do not count them in advance.
Keep dependency-stage imported-law distinctions explicit. Retain every original
strict failure and any invalid runner/build; freeze each source/tool before use.
No compiler jobs until root releases its current exclusive timing window.
