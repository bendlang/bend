# P15-005: preserve cycle refusal before parser errors

Prospective addendum, frozen before candidate03 source edits. P15-001's local-import
correction changes two finite control observations outside the pinned corpus:
when both modules in a cycle have malformed bodies, Phase14 reports the parent's
parser error, candidate01/host02 reports the child's, and pinned TypeScript reports
the import cycle before parsing either body. The new non-exact error-selection
change is not accepted as an inherited failure. Evidence:
`selfhost/build/phase15/behavior-cycle-validation-01/report.json`.

Add active/completed tracking to the IO host's existing canonical source traversal.
A reentry into an active canonical file stops discovery at that import edge; a
completed physical alias remains valid. This is filesystem traversal orchestration,
while language diagnostic text and source formatting stay in Bend. The Bend graph
loader retains its own cycle refusal for supplied-source APIs. Share the existing
import diagnostic renderer for missing-file and cycle messages, keeping original
import-token position, caller source and canonical cycle path. Catch only the
internal traversal-cycle signal and ENOENT; preserve other IO errors and missing
entry behavior. Feature-detect the new helper for historical APIs. Do not add a
Bend wrapper solely to restate a host Set membership operation.

Candidate03 must retain source01/02 and its checked attempt. Build genuinely checked
B1 on CPU2, run26 focused and58 existing behavior observations, plus the10 original
cycle/alias observations. Extend finite controls with canonical symlink reentry,
completed diamond aliases, and a cycle preceding a later missing dependency. All
cycle diagnostics should become exactly pinned-compatible; previously exact
acyclic results must stay exact. Re-run host IO/legacy/precedence controls with the
shared helper and retain any failed attempt. No universal cycle or stack-safety
claim follows. Root reviews the final host/source patch, then rebuilds combined
and conformance-only candidates before broad integration gates.
