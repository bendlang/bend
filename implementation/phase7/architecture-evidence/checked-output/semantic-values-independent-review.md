# Independent read-only review of P7-A02 semantic values

Reviewer: the P7-A01 implementer, who did not implement A02. This review reads
source and preserved evidence only; no compiler, benchmark or CPU test job was
run by the reviewer. Findings about additional witnesses below are derived from
source, not represented as already executed counterexamples.

The initially reviewed immutable source is attempt 05,
`selfhost/build/phase7/architecture/semantic-values-05/sources/semantic-values.bend`,
SHA256 `7650c4b6ac65d2270b2510aef1c1461ba3a44c28bb99fa6b970b531c402bf20f`.
Its checked stage0 component API is
`49654e6628f9bacc3d56bb7de43512da4e791e9939650731ca9bb77126294869`.
This is not a self-hosted checked B1 or an installed compiler release.

## Preserved correction history

Attempt 02 passes its initial 49 controls. Attempts 03 and 04 retain the same
source/API while strengthening the controls: 03 passes 72/82, exposing ten binder
quotation metadata differences; 04 passes 73/90, also exposing the neutral-spine
demand-order timeout and malformed-arity admission. Attempt 05 changes source,
retains binder names during fresh opening, compares neutral arguments in source
order, and tightens supported arities. Its 90/90 result is supported by the raw
report. The earlier failures are not overwritten or relabeled as passes.

## What the fixes establish

The binder quotation change uses the source binder's name when allocating a
fresh neutral variable, matching `norm_rebind`'s choice. The All-domain-first
quotation allocates fresh numbers in a different order from strong readback,
but the controls deliberately quotient only binder-number alpha renaming and
retain names, quantities, removed-name metadata and ordinary fields. This is a
reasonable oracle for the stated quotation scope. It is not byte-identical
readback. The existing head observation is only an observed head: its raw syntax
omits the semantic environment and application spine and cannot replace the
complete public `wnf` result contract.

Reversing stored argument cells before conversion corrects the preserved
`f(A, omega)` versus `f(B, omega)` witness. It does not establish all evaluation
demand behavior. The current supported predicate admits divergent lambda terms,
and the controls explicitly use them to test demand rather than type acceptance.
The following remaining differences therefore need new bounded witnesses or a
precisely narrower contract.

## Actionable remaining conversion findings in attempt 05

1. **Syntactic reflexivity must precede evaluation.** Production `norm_compare`
   calls `norm_exact` before evaluating either term (`core/normalize.bend:169`).
   `sv_equal` evaluates both inputs first. Thus identical `omega` terms, or
   identical `Wrap(omega)` terms, are predicted to return true immediately in the
   baseline and diverge in the prototype. Both pass `sv_supported`.

2. **The same issue occurs inside values.** Compare `Pair(omega, A)` with
   `Pair(omega, B)`. The outer syntax differs, but production's `norm_cmp_quick`
   accepts the identical first App field without evaluation, then finds A/B
   unequal. `sv_convert_cells` currently forces the first field before comparison.
   A top-level-only `norm_exact` shortcut would leave this witness unresolved.
   A cell shortcut must account for environments: equal syntax captured under
   different environments is not sufficient for semantic equality.

3. **Arity failure must precede field demand.** Production `norm_cmp_fields`
   compares lengths before scheduling any child comparison
   (`core/normalize.bend:491`). `sv_convert_cells` compares the common prefix
   before discovering unequal tails. `Pack(omega)` versus `Pack(omega, A)`, or
   neutral `f(omega)` versus `f(omega, A)`, is predicted to return false without
   forcing omega in the baseline and diverge in the prototype. These are admitted
   syntactic inputs even if not well-typed constructor applications.

Each witness can be isolated in a child process with a short timeout, retaining
both outcomes. The required fix is a demand contract for cells and spines, not
only a new argument order. No claim that these are fixed is made in this review
until a later immutable attempt and its controls are recorded.

## Scope and representation caveats

The production first-order core requires globally unique binder IDs
(`core/term.bend:16`). `sv_supported` checks tag/arity/range but does not establish
that invariant. Lexical semantic environments and the baseline's globally unique
ID substitution can disagree on nested binders reusing the same numeric ID.
For example, `Lam(1, Lam(1, Var(1)))` is admitted by the predicate but violates
the baseline invariant. Existing textual-shadowing tests use distinct numeric
IDs. The report should explicitly assume well-scoped unique IDs or extend the
boundary check; this is not a newly discovered failure of valid production core.

Other explicit exclusions remain material: no definition book or unfolding,
no match/rewrite/Min, no kind subtyping, and no stack-safe quotation guarantee.
References are opaque. The successful 100/1,000/5,000-depth quotation probes are
exploratory observations under a 4-MiB Node stack, not a proof of depth safety.
The heap has 32-bit cell/fresh counters without a demonstrated exhaustion policy.
The prototype's syntactic support scan itself traverses the whole input.

The benchmark's existing equivalence oracle uses semantic `compare`, not exact
output bytes or the complete metadata canonicalization oracle. Benchmark samples
therefore support only that oracle's stated semantics, while separate controls
cover selected quotation metadata. Repeated worker measurements also need their
warmup trend and narrow workload exposed. None establish a whole-compiler speed
ratio or justify deleting the existing normalizer/graph implementation.

## Initial status after attempt 05

Attempt 05 is useful evidence that shared first-order closures, memoized cells,
quotation and a limited conversion operation can coexist. Its current admission
predicate does not establish conversion demand equivalence for all admitted
syntax. Root and the A02 owner received the additional witnesses while preserving
the benchmark artifact. Follow-up attempts should supersede this review's
finding status explicitly; they must not alter attempt 05's evidence.

## Follow-up: preserved witnesses and attempt 06

The A02 owner subsequently executed the unique-binder-ID witnesses against the
unchanged attempt-05 API. The preserved
`semantic-values-demand-05-unique/controls.json` reports 95/100: the old compiler
finishes all six demand witnesses, while the candidate times out on reflexivity,
wrapped reflexivity, nested reflexivity, constructor arity and neutral arity.
This turns the initial source predictions into executed evidence for those exact
witnesses. The reviewer inspected the report and did not run those processes.

Attempt 06 source SHA256 is
`cde519a86320070df6373183651f7dd9ec317d5b5727eb4d69e995273a1aa576`;
its component API SHA256 is
`a4be15a4d9fe3586aa061291b31426e47470e3f82545558d0bab44b9cc52ca43`.
It adds entry-point syntactic reflexivity, a cell shortcut requiring identical
cell IDs or identical unforced syntax/environments, and spine/field arity checks
before comparisons. Its recorded 100/100 controls pass. The immutable 06 demand
harness still defines omega by reusing the same lambda binder ID in both operands;
that report alone must not be described as the unique-ID rerun. A separate
unique-ID control execution can establish that stronger claim without changing
the old evidence.

These changes address the original field-cell witnesses but still leave paired
suspension comparison incomplete. In immutable 06:

- `sv_convert_nodes:461` evaluates All domains directly before comparison.
  For `All(x, omega, A)` versus `All(y, omega, B)`, baseline comparison accepts
  the identical App domain without forcing it and then returns false for A/B;
  the prototype is predicted to diverge while evaluating the domain.
- `sv_convert_all_open:434` evaluates both codomains directly. For
  `All(x, A, omega)` versus `All(y, A, omega)`, with closed omega and different
  binder IDs, baseline substitution leaves omega unchanged and syntactic
  reflexivity returns true; the prototype is predicted to diverge.

Use separate IDs for the two lambdas inside omega and for x/y, satisfying the
production core invariant within each input. These terms are intentionally
untypechecked but admitted by the prototype's syntactic support predicate, as
are the existing divergence controls. These two additional predictions are
source-derived and were not executed by this reviewer. They were sent to root
and the A02 owner for a bounded preserved witness or explicit scope boundary.

The architectural issue is now precise: the conversion operation needs one
paired suspended-term entry that can preserve the baseline demand contract for
fields, domains, codomains and eta opening. Guarding only the public entry and
field cells does not provide that contract. Equality of raw syntax under
different environments also cannot be accepted blindly; a sufficient environment
condition or demand-preserving substitution/closure comparison is required.
The bounded experiment can legitimately stop with this residual limitation.
No global conversion-equivalence or replacement-readiness claim follows from
100/100 selected controls.

## Closing review note: immutable attempt 07

Attempt 07 retains the exact attempt-06 source and API hashes above and replaces
the demand harness with the distinct-ID version (SHA256
`d20585fbae539bff0f555597579858fd51c6c9fef82cfc4c031724c1b013babb`).
Its harness explicitly walks each input to assert that no binder ID occurs twice.
Its `controls.json` (SHA256
`f7ec9a81f3d8d100c928b891422d5fd46c1625efa2b7703129c6010a07e0c43f`)
records 100/100 passes. The first five demand failures are therefore repaired
for their preserved witnesses inside the documented unique-ID domain.

At review close, the two All domain/codomain witnesses remain source predictions;
the owner has been asked to execute and preserve only those final probes against
attempt 07, without continuing implementation fixes. The experiment report
should report their actual outcomes when available and retain this chronological
review status. This review is complete; the residual semantic scope, required
paired conversion boundary, selected-control evidence, benchmark caveats and
absence of whole-compiler replacement evidence are sufficiently clear to make
the architectural decision.

## Final observed status: residual probes against attempt 07

The owner completed the final bounded probes, preserved in
`selfhost/build/phase7/architecture/semantic-values-residual-07/report.json`.
The component API hash remains `a4be15a4d9fe3586aa061291b31426e47470e3f82545558d0bab44b9cc52ca43`;
the residual witness hash is
`ce85b74a54b19515a03ff3c38f7239c34b11ece7efa8277aa769bb3344ec4b9d`.
Both probes explicitly establish syntactic support and distinct binder IDs before
conversion. The reviewer inspected the raw outcomes without running CPU jobs.

| Probe | Existing conversion | Semantic-value conversion | Conclusion |
| --- | --- | --- | --- |
| All domain | False, completed in 0.0603 s | Timed out after 2.0143 s | Confirmed demand regression on admitted raw syntax |
| All body | Timed out after 2.0075 s | Timed out after 2.0143 s | No established difference |

The earlier prediction that the existing All-body comparison would return true
was incorrect. Its substitution operation beta-reduces omega while opening the
body, so the closed body is not merely preserved syntactically as the initial
review assumed. The raw timeout establishes failure to finish within the bound,
not a proof of nontermination. This correction supersedes that prediction while
leaving the original review and experiment history intact.

The final decision remains bounded: 100 selected controls pass, but the All-domain
probe establishes a remaining demand regression in syntax admitted by
`sv_supported`. The prototype therefore does not satisfy its full admitted raw
conversion domain and is not ready to replace production conversion. No further
implementation or investigation is part of this review.
