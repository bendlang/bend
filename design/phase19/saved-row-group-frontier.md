# Next bounded target: the saved row/group frontier

Prospective proposal after the ordinary-local checkpoint; root review required
before code. Keep the private contextual route isolated. The next target should
be the **original saved16 stage observations**, not another toy state protocol.
They exercise eight complete fixtures with prior globals, definition parameters,
constructor row patterns, nested match bodies and real grouped flatten boundaries.

The read-only, manually reviewed owner census is
`selfhost/build/phase19/context-frontier-census-02/report.json`. It binds the exact
selection and65 physical files:67 selection entries and130 observations
(saved16 + saved114). Counts overlap and describe source requirements, not
successful coverage. Literals occur in116 observations, rows32, constructor
patterns22, annotations46, marked syntax32, groups12, lambdas6 and do4. Census01
is retained unselected: it incorrectly included literal/constructor requirements
from the prior global declaration for one target body.

The immediate patch should add only the owners required by saved16:

1. **Existing literal and Type atom construction.** Permit these atoms through
   the contextual guard. Reuse compact literal construction and real token
   ranges; do not reintroduce eager literal expansion. Type remains the existing
   Typ/Qua form. Constructor syntax parses its arguments first and resolves the
   constructor name afterward, matching pinned `parse_term_base`.
2. **One contextual recursive pattern owner.** Extend the existing Stage3 owner
   through Ctr fields and literal stepping. Extract the shallow declared-name/
   arity check from `f_valid_ctor_pattern`, shared with legacy validation. The
   contextual recursion validates and opens each child left-to-right; no later
   child runs after a selected error. Do not independently copy those validation
   rules or invoke `f_patterns` plus another validation/scoping walk.
3. **The existing row parser.** At `f_case_pats`, check row arity, then run the
   pattern owner before `f_body_context`. At `f_case_body`, restore the row's
   outer lexical environment before its sibling. Retain each row's completed
   Body without flattening it. The Match and Local constructors stay shared;
   immediate Error/Unsupported propagation is audited at each reached callback.
4. **The real group boundary.** Reuse `f_group`; preserve the tuple-comma
   exception for Local/Match bodies. For a non-tuple group, run the existing
   `ff_flat(body,Nil{},next)` before annotation or close-delimiter demand, then
   carry its returned fresh counter in the cursor. No FGroup marker, replay,
   separate body interpreter or origin-order heuristic. Group annotations remain
   explicit Unsupported until their owner is migrated, after any earlier group
   flatten error has had its authoritative opportunity to win.
5. **Explicit block completion.** Use one shared contextual flatten helper for
   groups and the complete declaration-body test boundary. The latter supplies
   the actually opened header variables to `ff_flat`; it does not estimate their
   IDs. Reuse the same FContextSyntax union and label its success as a scoped
   LTerm, not final Core. The existing Body-stage entry retains its contract.

FName needs a precise boundary here. A Match's ordinary unbound name is still
the pinned Var syntax alternative; turning it into Ref first would change
flattening's named-head classification. Its allocated syntax ID cannot match an
already opened header/field ID. Expose that syntax view to the match owner;
bound names already are Var. Do not fake its ID or copy source coordinates into
it. Add explicit ordinary versus qualified Ref controls before changing shared
match error classification: the pinned flattener distinguishes those forms.

The saved fixtures must be run with original bytes and source intervals. Freeze
each selected definition/body boundary, prior declarations and actual pinned
header allocation events. A direct comparison must include the returned Body
or scoped LTerm, fresh counter, lexical restoration and diagnostic, with a
separate unchanged public parse/check run for the predecessor. A private
Unsupported cannot count as either a semantic match or a passing saved row.

The required paired outcomes are: an ungrouped first-row body defers flattening
and lets later syntax/pattern failure win; a grouped first-row body performs
flattening first; a completed ungrouped body eventually flattens; and bad local
or row patterns fail before later syntax. Retain valid nested-row/group siblings
and missing-close controls. Preserve Stage3 body40, names46, state27,
free-reference13, maintained36 and public/raw194.

Expected next patch is120–180 physical Bend lines across contextual/parser/
declarations/validate, with at most small literal-helper reuse. This is an
estimate, not permission to compress logic or omit a boundary. Review before
exceeding180 lines or adding a new general traversal. Stage3's computed-error
materializer is deliberately limited: pinned term_higher also beta-reduces
applications and interprets Sub, while ordinary freshening does not. Lambda
redexes and substitution-bearing terms must not be silently admitted into that
diagnostic domain by a group implementation. If a new required group reaches
those forms, stop and propose reuse of the existing semantic owner explicitly.

After saved16 is supported, the remaining114 census sets the next sequence:
annotation/lambda/All and parallel owners, marked/offload/family boundaries, then
the original two do fixtures. The main monad failure is still the general local
checkpoint: complete the real Result.bind lhs and RHS `p`, reject that computed
pattern, then never parse the orphaned return. Its type/operator/tuple/constructor
owners must be supported on the original fixture before claiming monad2 fixed.
No same-body instance-checker fix, production loader migration, net source
reduction or speed gain is implied by this private parser work.
