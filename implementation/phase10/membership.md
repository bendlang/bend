# Loader membership: eliminate work before indexing it

The checked prototype changes two expressions and adds no definitions, datatypes,
modules or physical Bend source lines. It avoids declaration scans when an alias
has not changed a term's name and stops a successful membership search. Both
independent source candidates pass the existing 21-case checked development gate;
16 additional public loader/import cases preserve complete Phase9 observations.
No whole-compiler speed claim or production promotion is made by this subtask.

[Prospective plan](../../experiments/phase10/P10-002-membership.md).
Root owns independent review, integration, broad gates and controlled measurement.

## What the code was doing

`f_alias_named` appeared to guard ambiguity checks with
`name != original && declared(name) && declared(original)`. In this Bend program,
Boolean operators evaluate their operands eagerly. Generated JavaScript therefore
ran both membership scans even when the name had not changed. It did so for
ordinary term nodes as well as references. Each scan recursively visits every
definition and nested constructor in the loaded scope.

`f_declared` similarly used an eager disjunction: matching the first declaration
did not prevent visiting its constructors and every remaining declaration.
Changing these two expressions to the existing `f_choose` operation introduces
actual conditional control flow. It needs no new cache, mutation, hash index or
public ABI. Qualification and declaration order are unchanged. The alias-only
candidate still evaluates both membership predicates when the alias actually
changes the name; this isolates its outer guard from the scanner's early return.

The old local Phase6 membership attribution (`implementation/phase6/membership-attribution.md`)
concerned backend `has_name` sets, not these loader scans. It is retained as
historical context and does not supply these measurements.

## Operation evidence and independent ablations

`membership-counts-02` uses six valid/explicitly rejecting public module graphs
and direct typed membership controls. It generates four disposable images from
one frozen Phase9 API: counters only, lazy alias guard only, lazy scanner only,
and both. These are observational images, not checked production artifacts.
All complete loaded results and checking results match the original exactly.
The ordinary fixtures load a small dependency and a main module, each with N
ordinary definitions. Every positive fixture is asserted to load and type-check.

| Definitions per module | Baseline visited cells | Alias guard only | Scanner only | Combined |
| ---: | ---: | ---: | ---: | ---: |
| 4 | 294 | 70 | 178 | 14 |
| 8 | 902 | 198 | 514 | 26 |
| 16 | 3,078 | 646 | 1,666 | 50 |
| 32 | 11,270 | 2,310 | 5,890 | 98 |

Combined visited cells grow linearly in this particular valid family. A real
alias replacement retains its checks: cells change from18 to8, rather than
vanishing. Missing names still require a scan, and changing control flow adds
closures/trampoline operations; these counts do not prove a corresponding
elapsed-time factor on arbitrary modules. Root's fresh final-release profile
independently identifies `f_declared` self work, but exclusive self percentages
exclude equality and generated call costs and are not removable-cost estimates.

Direct controls include duplicate names, an empty name, nested constructors,
Unicode, successful and missing queries. No new hash index is introduced, so
hash collision handling is not a changed factor. The runner's original comment
mentioned hash collisions unnecessarily; its actual queries use plain strings.

## Checked source candidates and gates

Both isolated projects start from the immutable Phase9 integrated03 snapshot.
They use pinned upstream b2111cf, Node24.18.0, CPU1, 4MiB stack and 4GiB heap,
with a genuine checked bootstrap and maintained version3 equality derivation.
No generated JavaScript substitution is promoted as the implementation.

| Candidate | Selected API SHA256 | Concatenated Bend source SHA256 |
| --- | --- | --- |
| Phase9 baseline | `d27968f11fa322bf3685ff0d276d9577a3b589b9cbae80784f5e4d404f7c3529` | `dbab2d33de96f6d29baa027acefdf0061e557c14f6b09a87e2c66c1baaf81c2b` |
| Alias guard only | `a73a0e62bd1cf2746c4bf3f5a19fc29c939b4c47b5dce16e8d74a1b367129718` | `baa1acefc59b088ae4c72206290e5fef327715a1420baa9b25cbf23f229f7aea` |
| Alias + scanner | `308ac01412b000c848732f9b88d3b1aafb62187acdcbc936c4150e9464c31f91` | `a198ac9b1568835081d9fe3d52411e6a3deca5bc37d34c6dafed57d6b798fa21` |

Each candidate passes all21 selected development cases, retaining the same12
exact TypeScript differences. `membership-controls-03` then compares16 complete
public observations against Phase9 for each candidate: six synthetic graph
results, loader traces, type-check results and source provenance; and ten pinned
import fixtures. The latter include actual alias replacement, alias shadowing,
alias-prefixed declarations, duplicate aliases, file-name aliases, Base/template
shadowing, cross-file proof checks, imported unsafe laws and invalid import
suffixes. They cover both acceptances and existing refusals; all results match
Phase9 exactly. This does not repair existing imported-law trust discrepancies.
All consumed input hashes and immutable attempt verification are checked again
at completion. No broad conformance suite or backend execution is claimed here.

The patch is under
`selfhost/build/phase10/membership-candidates-01/combined.patch`; projects and
independent build/validation records live beside it. Root can integrate that
patch after review. Neither agent changed live production source or `dist`.

## Demand boundary and failures retained

For finite, well-typed `List<KDef>` values, the scanner computes membership over
definition names and nested constructors. Early success changes which *pure*
comparisons are performed, not the Boolean result. For unchanged alias names the
first conjunct is false regardless of both membership results. This argument
assumes ordinary typed inputs; it does not establish equality for arbitrary
JavaScript objects, getters, exceptions, cyclic lists or resource exhaustion.

Two explicit private boundary controls preserve that distinction. The old
helper throws on a null scope entry even when the alias is unchanged; the lazy
alias helper returns the ordinary term. The old scanner throws after an earlier
successful name when a later entry is null; the lazy scanner returns true.
These helpers are not public exports. Public parser-generated graph, trace and
origin observations are compared separately; this report does not silently
claim equivalence for malformed host-injected `FParsedSource` payloads.

Retained unsuccessful attempts:

- `membership-counts-01`: initial fixtures omitted the required `.bend`/`as`
  import syntax, and the harness failed to assert positive parsing. It reported
  equality but supplied no valid scaling evidence. `correction.json` explicitly
  excludes it. Its original runner was reconstructed byte-for-byte and verified
  against the recorded SHA; the corrected runner asserts load/check success.
  The corrected alias counter also preserves eager inner conjunction so only
  the outer alias guard is changed in that ablation.
- `membership-controls-01`: harness supplied wrong argument order to the source
  provenance API; it failed before recording any observation. Original runner
  and exception remain preserved.
- `membership-controls-02`: harness treated an expected duplicate-alias parser
  refusal during source discovery as an exception instead of letting `inspect`
  record the public refusal. Eight earlier controls passed. The original runner
  and failure remain preserved; corrected03 completes all16 cases.

None of those attempts is a compiler regression, successful positive parsing
result or timing sample. No failed rows were removed from a reported speed mean.

## Reproduction and preservation

From the repository root, use Node24.18.0 with CPU1, `--stack-size=4096` and
`--max-old-space-size=4096` for all three tools:

1. `selfhost/tools/performance/phase10/membership-counts.mjs` takes the frozen
   Phase9 attempt and a new output directory.
2. `membership-prepare.mjs` takes that attempt and a new candidate directory.
   It freezes isolated alias/combined projects and configurations. Run the
   ordinary development workflow on each generated config and a new attempt.
3. `membership-controls.mjs` takes baseline, alias, combined, corrected counter
   directory and a new output directory, in that order.

The original attempts are `membership-counts-01/02`,
`membership-candidates-01/{alias-01,combined-01}`, and
`membership-controls-01/02/03` under `selfhost/build/phase10/`. Each build carries
its frozen source, helpers, runtime, bootstrap provenance and API-specific Base
cache; counts preserve generated instrumented images and fixtures. Root's Phase10
preservation capsule must include these directories and the tracked runners,
plan and report before ignored local paths count as durable preservation. The
read-only untracked historical Phase6 inputs are copied with exact hashes under
`membership-history-01`; their original files remain untouched and unstaged.

**Decision:** advance the two-expression combined candidate to integration and
controlled measurement. The actual loader work removed is established; its full
compiler impact and broader semantic preservation remain root integration gates.
