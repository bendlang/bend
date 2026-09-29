# Preserve parser checkpoint order before later syntax failures

This is a prospective design for the last two parser-order examples, based on
pinned TypeScript b2111cf and the frozen wave7 frontend vectors. No compiler edit
or candidate probe accompanies this design. Completion ABI2 is a separate,
already validated change. The context owner implements the completed-declaration
prefix stage below; the rejected-current-body stage requires explicit review.

## Two different source causes

`reg/framed_cell_capture.bend` parses a complete Match containing head `a` and no
rows, leaving the token `Bool` after the colon. TypeScript parse_def invokes
body_flatten before returning to parse_book, so the invalid match head wins.
Bend f_def_body records a raw Body and immediately calls f_tops. The later top
syntax error therefore wins before graph elaboration reaches the complete body.

`check/monad_do_destructure.bend` has a different checkpoint. The first do bind
and its tuple tail become a computed Result.bind/Ann expression; the following
`= p` makes that whole expression the left pattern of a local. TypeScript
parse_body parses the right value, then calls parse_patt on the left pattern,
then parses the continuation. Bend f_let_value parses the continuation eagerly;
f_let_body replaces the entire Local by its continuation Error (`return` outside
the already ended do expression). The earlier unsupported pattern disappears.
The eventual f_scope_local_valid already has the right semantic validator, but
never receives that pattern.

These are stage-order rules, not earliest source-offset rules. In particular,
a malformed case body must beat an invalid global match head: parse_body has not
returned, so TypeScript has not called body_flatten yet. A malformed local RHS
must beat an unsupported left pattern, while the unsupported pattern must beat
a malformed continuation. Globally sorting errors by source position is wrong.

## Stage A: only completed declarations

The context owner's approved failure-only completion hook lowers the retained
completed-declaration prefix before returning a later top parser failure. Reuse
f_graph_finish and its normal namespace/alias/scope rules. A structured frontend
Error from that completed prefix wins; otherwise preserve the original parser
failure verbatim. No incomplete current body participates. There is no extra
successful-path traversal or body parse. This targets framed_cell_capture and
independent earlier-declaration/later-syntax controls in both orders.

## Stage B hypothesis: reject at the pattern checkpoint

Prefer recording the real local-pattern checkpoint over retaining arbitrary
unfinished Local/Row trees and asking the normal flattener to choose an error.
That latter shortcut would report invalid global match heads before malformed
case bodies, contrary to TypeScript. It also loses the distinction between an
error while parsing the RHS and one while parsing the continuation.

Separate three outcomes after parsing the left term and RHS:

1. An existing inner syntax/semantic parse Error wins immediately.
2. A parser-guaranteed nonpattern is refused at this checkpoint, before parsing
   the continuation. Its structured pending failure retains the original term
   and enclosing lexical/module context so the existing lowerer and pattern
   validator can render the observed term accurately.
3. A possibly valid binder/constructor form follows the normal continuation.
   Scope-dependent binder identity, constructor arity and namespace resolution
   must not be guessed from spelling or parser tags.

The classifier needs a proof for each raw form. Ref can be a variable or a
qualified global; Ctr and Literal can be patterns. A raw zero-argument Call can
still be a variable and must not be rejected merely for its Call tag. FDo always
lowers to an application or annotation and is a guaranteed nonpattern, but the
implementation must express the shared syntactic classification rather than an
FDo-only fixture fix. Sugar that can reduce to a binder stays deferred until its
shape rule is established. Inner errors within sugar precede outer eligibility.

The pending record is typed compiler data, never a diagnostic string contract.
It must retain the original term, RHS-completed checkpoint, and the exact lexical
bindings/module scope valid there. Do not reconstruct scope from names, source
text, source offsets, or a whole-file final book. Reuse f_patterns,
f_valid_pattern and scope/lowering machinery when the context is available.
No new language semantics live in the host.

## Compare two transports before committing to an implementation

A minimal rejected-body transport keeps successful terms and public FParsed/
FResult shapes unchanged. Only a selected failure carries the pending pattern
and its enclosing lexical frames. Parent callbacks may add only context that was
already established before the failure; they must not run later parsing. The
contextual module path would retain the private FRawResult Error until the
completed declaration prefix is available, resolve the pending failure there,
then render the existing public FResult.error. Standalone legacy rendering keeps
its defined fallback, and supplied parsed inputs preserve their exact bytes.
This requires a precise inventory of every frame that can enclose such a failure:
parameters, nested lambdas, local and parallel bindings, match patterns and do
binders. Missing one is a correctness blocker, not a reason to fall back to an
empty environment. No current source implements this transport.

The alternative threads one immutable expression context through contextual
term/body parsing and checks each pattern before descending into its
continuation, like TypeScript. It is a larger parser change, but makes lexical
scope and semantic checkpoint order explicit and may eventually replace the
separate scope walk. It must use the existing module FParseScope rather than a
second namespace resolver. Repeated full scope walks on successful bodies are
not acceptable. A complete call-site/line-cost census is required before this
alternative is authorized.

Select rejected-body transport only if its explicit lexical frame inventory is
small and independently testable. If it effectively becomes a second parser or
scope interpreter, stop and propose contextual term parsing instead. Do not
implement a partially retained current-definition shell as a stopgap.

## Prospective independent controls and gates

Freeze oracle witnesses before candidate edits: unsupported computed pattern
before bad continuation; bad RHS before unsupported pattern; valid binder before
bad continuation; empty-call binder; constructor and literal patterns; qualified
bound versus unbound patterns; nested lambda/local/match/parallel/do contexts;
imported monad aliases; competing inner sugar errors; malformed case body before
invalid global head; completed invalid declaration before later top syntax; and
all reversed-order counterparts. Include successful versions of every retained
binding form. The two corpus fixtures are witnesses, never special cases.

First record exact TypeScript and frozen Bend outcomes and process health. Then
review the classifier proof and lexical transport census before any body edit.
An accepted candidate needs checked B1/v5, focused controls, exact new witnesses,
no lost previous exact matches on the adjacent full gate, and a measured
successful-path cost gate. Preserve all failed proposals/attempts. No timing,
line-count saving or universal chronology claim is made in this design.

## Read-only transport census

`parser-chronology-census-01.json` records the frozen source hashes and a lexical
transitive-caller upper bound for local-pattern, case-pattern and lambda-binder
checkpoints. It reaches104 functions:42 declaration workers,29 parser workers,
17 sugar workers, six parallel workers, five literal/array workers and five
validation workers. This is not a claim that all104 need edits; contextual
module parsing already threads some declaration context. It establishes that
full contextual expression parsing is a substantial interface migration, not a
two-call fix. The four principal parser files contain64 FParsed destructures;
replacing their result ADT would also be a broad change. Neither count measures
runtime cost. The static census tool executes no compiler and creates no candidate.


## Oracle follow-up

The corrected50-observation read-only suite and enclosing-frame inventory are
reported in implementation/phase16/parser_checkpoint_oracles.md and
parser_failure_frames.md. Only an already-bound empty call can stay a binder;
unbound x() is forced to its fallback Ref. The early hypothesis is now supported
by that positive/negative distinction, not by assuming all empty calls are valid.
The suite establishes30 chronology differences across15 fixtures, protects16
existing exact observations, and separately exposes a two-observation accepted
bound-call rejection plus a two-observation unbound-call span difference. No
compiler edit followed these oracle probes.
