# Stage4 addendum: shared flatten identity and first failure

This narrows the unchanged-owner assumption in saved-row-group-frontier.md.
The independently reviewed pinned parser oracle is frozen at
`selfhost/build/phase19/context-row-oracle-02/oracle/report.json`:26 original
and boundary fixtures, including the original eight saved fixtures. The exact
header parser allocates n:Nat as Var1 with next3; n:Type is Var0 with next2.
No candidate-derived seed or source-position substitute is used.

The shared ff_match fast path currently tests only f_has_id(vars,ix(head));
ff_column tests only matching IDs. Pinned match_flatten requires the head to
be a Var first. Use one explicit Var eligibility rule in both existing workers.
The four n:Type controls distinguish bound Var0 from Ref, App and Ctr nodes
that also have id0. They are semantic controls, not representation equality
requirements; an old false acceptance must become a recorded correction.

A shared FFlatten failure contract is also necessary: its term is either a
successful flattened term or a top-level Error. ff_flat must preserve a direct
Error; ff_lam, ff_let and ff_parallel preserve an Error returned by their child;
ff_hit_done must stop before the miss branch; ff_miss_done preserves a failing
miss instead of constructing Mat. Each check is shallow. No error-tree scan or
alternative body interpreter is added. Completed contextual Body input is
otherwise Error-free: all reached parser callbacks propagate Error/Unsupported
before constructing a containing node. Direct injected-Error controls test the
contract at each worker, including Local and Parallel, and a positive sibling
ensures ordinary construction still occurs.

The actual hit-error-before-miss-allocation fixture finishes parsing at next7.
Pinned flattening throws on the first hit and retains next7. Its later Succ{
Succ{k}} row would allocate an extra field if demanded. The reverse fixture
successfully passes the first hit, allocates that field and fails at next8.
Both complete-file diagnostics independently match the direct pinned boundary.
Do not recover wording by scanning a partial flattened tree after visiting the
later branch; the fresh counter and demand order are part of the observation.

A remaining representation decision needs root review before code: legacy
scope has already turned an ordinary global name into Ref, while contextual
syntax retains the actual Var alternative in FName. Pinned diagnostics differ:
ordinary global is a def/consumed-binder error; qualified Ref is a computed-value
error; Ctr is an already-constructed error. Changing every Ref to computed in
f_match_error would discard the information relied on by the legacy route.
Prefer an explicit normalization at the existing Match construction boundary
and preserve the existing semantic flattener, over threading a mode through
all match workers. No inference from numeric IDs, ranges or rendered text is
permitted. The exact chosen normalization will be frozen in a further addendum
before source preparation.

The first oracle tool attempt is retained unselected. It completed the original
eight cases, then its JSON projector incorrectly assumed every optional span
was present on a successful lowered term. Version2 handles absent optional
spans and preserves non-Err tool exceptions instead of masking their cause.
No fixture or expected semantic outcome changed.

Root approved the narrow private bridge after independent review. The existing
contextual Match-head boundary converts ordinary FName to its actual Var syntax
and qualified Ref to FComputedHead{original Ref}, preserving its occurrence
range. Apply the same head conversion at a constructor-local scrutinee boundary;
ordinary local values are unchanged. The wrapper is never eligible for an ID
match and follows the existing computed-head diagnostic branch. It is consumed
by rejection or discarded with an unreachable column, as pinned flattening does;
it cannot escape a successful scoped LTerm. Keep raw ordinary and qualified Ref
diagnostic observations visible without relabeling legacy mismatches as success.
This temporary bridge is not a new core node, alternate FName convention or
invented App. No mode is passed down the flattener. Later legacy representation
cleanup may remove it after a full consumer and corpus audit.
