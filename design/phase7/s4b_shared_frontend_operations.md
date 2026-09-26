# S4 B: share existing frontend operations

Execution outcome: accepted as part of the [validated S4 checkpoint](../../implementation/phase7/s4-report.md).
The following is the original pre-implementation plan; actual results and limits
are in the report.

Pre-implementation plan. The source baseline is the corrected S4 A candidate
(`attempt-a02`): 14,857 physical / 12,668 nonblank Bend lines, 474,656 bytes,
1,450 definitions and 799 laws. Its checked/default APIs and all 55 exports are
identical to S3. Full checking of this source by Bend completed successfully
during the genuine self-reproduction run; that proof is still running.

This accepts A for further isolated source consolidation, not release promotion.
The completed A proof remains a release gate. B uses another source snapshot;
the proof's inputs remain immutable and heavy jobs stay serial. This is work
inside S4, not advancement through its unmet 50% milestone into S5.

## Exact changes and revised budget

The earlier S3-based 205-line budget overlaps A. Recounting actual A02 declarations
gives 195 prospective net lines before any explanatory comment or replacement
line cost. No signature saving is counted twice.

| Unit | Change | Prospective physical lines |
| --- | --- | ---: |
| Canonical graph loading | `f_graph_load` delegates to existing `fs_load` with `FSeed{"", Nil{}}`; remove four duplicate unseeded workers | 61 |
| Embedded error selection | `f_error_term`/`f_error_defs` project `nm` from existing `fpe_term`/`fpe_defs`; remove four string-only traversal workers | 44 |
| Selectors and length | Replace `f_dn/f_dt/f_dk/f_dx/f_len` with `dn/dt/dk/dx/terms_len` | 44 |
| List/name operations | Replace `f_concat/f_defs_append` with `norm_join/norm_defs_join`; replace `f_main_seen(name, seen)` with `has_name(seen, name)` | 39 |
| Unused checker projection | Delete unrooted `check_events` | 7 |

These retire 17 helpers and two duplicate algorithms. Existing public entry
points, records, error representation, legacy `f_load`, source/seed contracts,
host logic and bootstrap capability selection remain. Require at least 190 fewer
physical lines, 160 fewer nonblank lines and 4,000 fewer bytes after replacements.
Count test/tool additions separately. If a unit fails correctness or cost gates,
retain its failure and remove that unit's budget before judging the remainder.

No continuation inlining is included yet. Its distinct evaluation, sharing and
tail-call obligations require a separate bounded candidate after these units.

## Semantic obligations

An empty disabled seed is safe only because `fs_source` rejects missing/empty
source paths before `fs_cached` considers seed matching. Retain that ordering.
Compare whole ordered books, imports, errors and trace records for raw/parsed
sources, absent sources, empty Base paths, aliases/diamonds, cycles, namespace
conflicts and partial failures. Real Base seeds must still match both canonical
path and complete text, enter at their dependency position and be ignored when
unused. Preserve first errors and final freshening.

For error projection, compare nested terms and declarations directly. Cover an
`Error` with empty name and erroneous children, children in order, type versus
value versus constructor errors, then later declarations. Both absent sentinels
and empty error names must project to an empty string. Keep graph errors ahead
of embedded errors and embedded errors ahead of freshness errors. No earlier
parser short-circuiting is introduced.

Primitive substitutions retain types, quantities and ordering. The membership
helper reverses argument order explicitly. Public malformed-input behavior and
exact first-match rules remain in scope. A failed lookup is not a reason to
replace the legacy frontend finder with the indexed lookup's different sentinel.

## Validation and promotion

1. Implement only these changes in a fresh isolated source snapshot; review the
   actual diff and recount all production modules. Preserve A02 unchanged.
2. After the current proof releases the machine, run a fresh checked build and
   21 focused controls. Require the complete ordered 55-export interface.
3. Run affected cross-version graph/seed/provenance/error controls, all maintained
   components and the harness. Run the full 2,756 frontend observations against
   S3's frozen vector; preserve all existing strict failures and exact outputs.
4. Compare serial accepted/rejected workloads under fixed host, input, Base/cache,
   affinity and resource policies. Include unseeded raw/parsed graph loading,
   since that route now pays a disabled-seed predicate. Require accepted costs
   within 5%, RSS/API size within 10%, stable outputs and healthy observations.
5. Install only a complete validated attempt. Verify release integrity, ordinary
   check/interpreter/JS/native smoke and relocation. Source-authoring proof on A
   is reported as A's evidence; it is not relabeled as B's fixed point. The full
   final-source fixed point remains part of the actual 50% milestone gate.

Update the evolving S4 report and preserve raw inputs, commands, failures and
results. Publishing this bounded reduction cannot close S4 above 8,254 lines.
