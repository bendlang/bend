# Phase17: live-instance chronology at the authoritative checker

Prospective bounded investigation. Parent plan: `remaining_cost_and_chronology.md`.
Use unchanged Phase16 checked attempt `compact-final-build-01`, installed API
`35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315`, and pinned
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`. No compiler edit is authorized
by this witness phase. All probes use CPU1 and ordinary resource limits; their
wall times are not performance measurements.

## Hypothesis and causal boundary

Installed `infer_template` checks closed argument types but does not mint or
validate an instance. Program completion checks ordinary source definitions,
then calls the existing specializer. Consequently an invalid live instance
before an ordinary error in the same body can report that later ordinary error.
The reverse order should retain the earlier ordinary error. A valid earlier
instance is the negative control: it must not suppress a later ordinary error.

Pinned `term_infer`'s Ref case invokes `def_inst` at the encountered live reference.
`def_inst` checks comptime arguments in an empty caller context, computes one
canonical JSON key, enters an active memo/placeholder, calls the same `def_check`
while the caller is still declared, and publishes the completed instance. Its
Infer result says how many surrounding comptime applications to consume. Generic
source text and erased references do not instantiate; one book owns shared memo,
per-template numbering and active recursion state across successive subterms.

A second, independent boundary prevents a tiny `sp_template` relocation:
`sp_mint_type` walks a new instance with `sp_term` before `sp_validate` calls the
normal checker. Within that new instance, a later invalid nested template can
therefore precede an earlier ordinary failure exposed by substitution. We will
measure both nested orders and a valid-nested-instance negative control.
The Phase16 design `checker-chronology.md` records the earlier source04 reasoning;
this experiment revalidates the installed compact compiler, without changing
that frozen history.

## Frozen witness families

Create six small owned sources using the same Base Nat affine-duplication cause:
(1) invalid instance then Bool/Nat mismatch; (2) ordinary Bool/Nat mismatch then
invalid instance; (3) valid instance then Bool/Nat mismatch; (4) substitution-
exposed ordinary duplication then invalid nested instance; (5) those nested
operations reversed; (6) substitution-exposed duplication with a valid nested
instance. The first and fourth are prospective chronology counterexamples;
all six must remain checker refusals. Compare full exact diagnostics, not a
rank guessed from text or source offsets.

Copy the already frozen small source controls for repeated keys, interleaved
per-template names, nested instances, decreasing self recursion, erased calls,
same-spelling and renamed Lambdas, explicit quantity alternatives, and captured
caller variables. Add the pinned active-cycle and growing-template fixtures
without modifying them. Successful instance names/counts, type/trust outcomes,
raw diagnostics and failed expectations stay visible. Key identity, the 32768
UTF16 limit and depth64 are unchanged constraints, not tunable fixes.

No new acceptance oracle will manufacture conformance. Explicit accept/refuse
contracts only require the intended checker phase; exact paired differences are
recorded separately and retained. A complete experiment is an observation result,
not permission to install a compiler change. A bad witness/setup gets a new
numbered correction rather than overwriting consumed inputs.

## Proposal to assess after observations

Prefer a single checker-owned world (current book, instance memo and fresh-ID
bound), with the normal result carrying the updated world and consumed comptime
applications. Reuse the current instance mint/key/active-state operations but call
the same checker directly before continuing the caller. Sequential child checks
must use the previous child's world; eager `both(check(a),check(b),...)` cannot
carry effects correctly. Existing persistent book updates must preserve cache
visibility; the current plain-list specializer must not receive cached books.

A temporary memo-only materializer could ease elaborated-output migration only
if it can resolve already checked instances and refuses missing memo entries.
It cannot mint, check or arbitrate diagnostics. The desired final state removes
the duplicate specialization traversal and returns checked children from one
owner. A fresh local specializer per reference loses memo/cycle state. Definition-
event interleaving fails same-body ordering. Whole-definition/global replay and
a second partial checker are excluded.

Before implementing, report actual failing order, constructor/call-site scope,
removable visitor blocks versus added result/state plumbing, and plausible cost
risks. No net line reduction or speed gain is promised. A representation-only
cost ablation and root review precede semantic threading. Final promotion still
requires full frontend/backend, historical prefixes, cache/host and controlled
same-source cost gates from the parent plan.
