# Private contextual rows and groups

The private contextual parser now handles the original eight saved row/group
fixtures with the pinned diagnostic, cursor, lexical environment and fresh
counter. Those fixtures supplied16 historical parse/check observations; they
are tested here through the explicit private body/block boundary. Production
parse/check still uses the legacy route. This does not close the original monad
fixture, complete contextual parsing, change loader routing or demonstrate speed.

The current source is
`selfhost/build/phase19/context-row-source-05/project`, from Stage3
`context-body-source-03/project`. Its checked attempt is `context-row-build-05`.
The final independent owner audit is
`selfhost/build/phase19/context-row-audit-02/report.json` (complete/PASS).
The genuine checked API is `caf20ce299ca5a390935dec1be355e8929e3b424047cfbe8bf3137ceda572e87`;
the selected derived API is `681bf1bcc748a2a184cd9fa4d53ff78292809711d529ff36bd46c53922f379cf`.

The existing expression/row/group grammar now calls the contextual name and
pattern owners. Constructor arguments parse before constructor-name resolution;
row arity and patterns are checked before the row body, and row bindings close
before the sibling row. Row bodies defer flattening. A group calls the existing
`ff_flat` owner before demanding its close delimiter. The complete-block entry
uses the actual opened header parameters and the same result union as the
previous names/body experiments; it never labels partial syntax as Core.

Two shared flattener corrections were necessary. A matching numeric ID is now
eligible only on a Var head. A top-level Error propagates through flatten,
lambda, local, parallel, hit and miss continuations without constructing a
wrapper or visiting a later branch. This is shallow propagation, with no error
search or duplicate interpreter. Direct controls cover every continuation;
actual-source controls distinguish a failing hit that leaves next7 from the
reverse case that visits the later branch and reaches next8.

The private boundary preserves ordinary FName's actual Var syntax for match
heads. A qualified Ref becomes a temporary FComputedHead carrying the original
term and interval, so shared error classification reports a computed value.
The same conversion applies to a constructor-local scrutinee. This bridge avoids
changing the legacy route's already-lowered Ref convention or threading a mode
through every flatten worker. It cannot bind by ID, and successful complete-block
outputs are checked for escape. Legacy Var/Ref diagnostic controls remain explicit,
including the known qualified-Ref difference; it is not counted as a new match.

Successful block terms are compared modulo bound-ID alpha-renaming, not claimed
to be byte-identical scoped LTerms. Existing `ff_fields` uses 2^31+next, while
TypeScript uses next. The retained nested-field fallthrough has `_5` with
candidate ID2147483653 and pinned ID5. The failed exact-ID assertion remains in
`context-row-probe-05`. The final test first audits the unmodified binding graph:
all Var uses must resolve to the proper enclosing binder, free identities are
preserved, header IDs and state are exact, and generated IDs are disjoint from
the tested low lexical range. Then it applies the pinned alpha normalization
directly, without first running the Bend freshener. Complete raw graphs and
binder/use links are retained. This is a bounded low-ID seed guarantee, not an
unbounded U32 allocation proof.

Independent review also exposed a reusable legacy grammar bug: `match:` and a
row with no pattern could be accepted or report row arity, while pinned
`parse_terms` first requires a term. The two existing workers now reject a first
':' or ',' using constant-time `List.is_empty`. Bound-head/no-row remains valid.
The isolated patch is `context-row-source-05/first-element-only.patch`; it does
not depend on private contextual semantics. Root can integrate and validate
that small correction independently.

The added source is130 physical Bend lines and7,688 bytes across five Bend
files, plus19 host bytes for one experimental export root. There are22 additional
named definitions, including factoring of existing workers, no new result type,
and one temporary syntax marker. This is additional experimental implementation,
not a source-reduction result. No production branch or unchecked JS compiler
implementation was introduced.

The prospective contracts are saved-row-group-frontier.md,
shared-flatten-checkpoints.md and scoped-block-equivalence.md under design/phase19.
The source manifests retain complete parent/candidate memberships, modes, hashes,
patches and consumed plans/tools. Every extension probe records a distinct API
hash and verifies the genuine emitted production prefix is unchanged. Builds
and probes run on CPU3; no controlled timing was performed here.

The private final gate is35 fixture records:32 admitted pinned outcomes and3
explicit Unsupported owner boundaries (lambda, beta-redex and group annotation).
The old body40 and names46 fixtures/oracles remain unchanged; four formerly
excluded controls in each are now admitted and checked against their already
recorded pinned outcomes. The other unsupported records remain domain checks,
not language passes. State27, materialization13, maintained36 and raw194 pass.
Raw194 includes full Base/compiler source books and raw/lowered equivalence.
The saved196 public parse/check comparison is closed at
`context-row-validation-01`:136 exact outcomes versus128 in the frozen cursor
baseline, eight newly exact and none lost. Only parse/check observations of
nested-zero-head-match, zero-head-match, zero-head-match-argument and
zero-head-match-lambda changed. The first six also correct acceptance evidence.
Reference vectors are unchanged. This is a no-regression comparison with eight
improvements, not a claim that the whole selected suite passes.

The raw workflow remains pass:false/selectedComplete:false with60 strict
remaining differences. It collected all196 observations: reference195 pass plus
one observation; candidate192 pass, one observation and three retained failed
verdicts (monad check and body-comma parse/check). The reference child exits0 and
candidate child exits1 for those expected remaining verdict failures. Both
workers report zero failures/timeouts and no changed inputs. The final audit
keeps these raw statuses instead of rewriting them.

All failed attempts remain:

- Oracle01 handled the original eight errors, then its projector mishandled an
  absent optional span on a successful term. Oracle02 fixed only that tool rule;
  later oracle03/04/05 expanded frozen controls to29/32/35.
- Flatten-control preparation01 shadowed a Python path with a result dictionary;
  preparation02 fixed it. One direct control then omitted ff_miss_done's origin
  argument; preparation03 corrects that invocation without changing the contract.
- Source/build01 failed genuine bootstrap: computed call results need ordinary
  parameter callbacks before a Bend match. Source02 adds those callbacks.
- Probe01 could not serialize the repeatedly shared full Base lookup index.
  Probe02 records its immutable prior identity and index-construction recipe,
  retaining term/state payloads and checking actual scope equality.
- Source02's private gate was25/26: grouped Local produced a whole-group Let span
  instead of the binder span. Source03 attaches the actual pattern range.
- Source03 exposes the four first-element grammar errors, and the retained
  generated-field raw-ID assertion proves the explicit alpha convention above.
- Source04 passes the semantic gates but its first-element guard counted the
  whole accumulator repeatedly. Root review rejected that unnecessary traversal;
  source05 reuses constant-time List.is_empty. No measured cost claim is made.

- Audit01 incorrectly required the selected candidate child to exit0 despite
  the retained verdict failures. Audit02 explicitly requires exit1 and the exact
  three inherited failure IDs, verifies all196 healthy observations and the
  eight-only change set, and passes. Audit01 remains available.

Final source/controls are frozen. Root owns any production integration, broad
corpus/backend gates, timing, installation, archive and publication. This owner
has no active compiler/probe process and makes no promotion recommendation for
the incomplete contextual route; the constant-time first-element correction
is independently consumable.
