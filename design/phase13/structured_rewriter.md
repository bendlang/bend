# Phase13: structured generated-code rewriting with explicit branch workers

Prospective design,2026-09-28. The user authorizes the complete proposed staged
experiment, validation, reporting and publication. No old time budget is renewed.
The baseline is released Phase12 commit9a4e1098043ef32a080a41440aa84728078d0d7b,
checked attempt `selfhost/build/phase12/integrated-03`, API
`0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697`.
Upstream stays b2111cf43244e65f76ddc278ee695e669f720cbf. Preserve unrelated Phase6
work and all historical pinned sources; do not edit human-written bend2/bend.ts.

## Objective and evidence cutoff

Reduce useful compiler iteration cost with a representation that makes generated
calls, branches, captures and execution boundaries explicit. The current default
is a guarded checked-B1 derivative. This experiment targets that artifact; it
must not transfer old H/self-emission results to a new compiler or claim emitted
user-program runtime gains from compiler-host speed alone.

Phase12 same-source checking is26.897s versus29.558s Phase11 and2.855s pinned TS,
a9.42×process gap. Nat300JS is7.902s and C emission2.784s. These are historical
workload measurements, not future speed estimates. Source has15130physical Bend
lines; the maintained equality helper has296lines/27345bytes. Its tokenizer and
module/dependency/choice recognition overlap. A new representation must justify
its total code/concept cost, counting support, guards and historical replay.

Broad branch inlining failed fresh and matched-history string checks. The seed
cleanup independently failed a matched53-request history. Keep the original
normalizer and runtime; do not revive either rejected mechanism. The released
164-site leaf lowering passes both53/60request histories at4MiB. Moving nested
non-tail work into a larger enclosing frame was a concrete hazard. Explicit
worker lifting must preserve the old execution boundary and argument demand.

## Sequential stages

1. Verify the installed release and profile its actual complete-source checking
   on CPU0 with unchanged Phase9 tooling. Other owners initially do static work.
   Retain complete raw samples; profiling time is never a speed-ratio sample.
   Attribute the current functions before selecting a worker family.
2. Build a small structured view of the admitted generated program: function
   boundaries, calls, literal branch arrows, returns, lexical bindings and
   source spans. Unknown shapes fail closed. Reproduce version5 output exactly
   from the genuine checked parent, and authentic historical versions1–5.
   Share parsing/recognition where it actually retires duplication; do not wrap
   unchanged duplicate scans in a new name or introduce a general JS compiler.
3. Prototype one frequently executed family by lifting literal branch bodies
   into named module workers with explicit capture parameters. Preserve the
   original selected-branch execution boundary through the existing tail
   message/runtime. No body work executes before that boundary. A selected
   capture must be definitely initialized and immutable at the original point;
   reject mutable/TDZ/unknown captures, receiver dependence, lexical rebinding,
   unsupported destructuring/control flow and public ABI drift. Name collisions
   fail closed. Preserve Unit identity within each branch, escaping closures,
   argument/error order, partial application, demand and stack limits.
4. Count exactly which closures/messages disappear and which capture arrays or
   records replace them. Challenge with independent controls before timing.
   First run the fresh6,000-character string and exact53/60request histories at
   4MiB, preserving every predecessor digest and real worker state. Keep every
   failed artifact/tool version. An isolated success does not excuse a history
   regression. A failed launch invalidates results even with status0.
5. Measure a surviving prototype in opposite-order fresh-process comparisons
   against the current baseline on identical source/host/cache/resource inputs.
   Expand by structural rule only after useful whole-source evidence. Roughly
   20% less full-source time, or a compelling smaller gain plus demonstrably
   simpler maintained machinery, is the investment criterion. It is not a
   forecast. If the pilot merely exchanges allocations, regresses or requires
   excessive complexity, reject/defer it and retain a usable baseline.
6. Integrate only a justified survivor. Replace overlapping maintained rules;
   retain exact historical replay and genuine checked-parent lineage. Run a
   fresh checked workflow and22focused cases, maintained guard/control tests,
   complete2996frontend vector equality, applicable37paired backend controls,
   actual native execution and same-source TS/old/new/new/old/TS comparison.
   Run affected JS/C emission matrices separately, preserving output bytes and
   execution. If Bend source stays unchanged, do not claim a source-line saving.
7. Install an accepted release, verify42ordinary/relocated CLI checks, document
   the user workflow/architecture and conclusions. Keep candidate/source/API/
   runtime/host identities separate; no newH→H, Lean or GPU claim without its
   actual gate. Update README, report, ledger and steering; preserve exact
   evidence after all producers close, then commit and push. A well-supported
   negative outcome is a completed experiment, with the baseline still usable.

## Bounded ownership and resource policy

Root owns profiling, stage decisions, integration, controlled final timings,
release, documentation and publication. The rewriter owner builds isolated
prototypes; an independent owner challenges capture/demand/stack semantics;
a measurement owner prepares replay and complexity accounting. Initial static
reviews are bounded, followed by small discriminating probes before broad runs.
A few-hour pilot is a planning timebox; production generalization may require
longer only when the measured candidate justifies it. No broad speculative wave.

Use Node24.18.0,4MiB stack,4GiB heap and separately validated Base caches; pin CPU0
for root comparisons. Released CPU1/2/3 may run bounded correctness work. Pause
all intentional compiler/archive jobs for controlled timing. Record source,
artifact, runtime/Base/host/tool hashes and all launch error/signal/timeout/overflow
fields. OS caches are not flushed. TS checks Base while Bend uses validated disk
Base caches; report workflow ratios honestly. Do not multiply historical ratios.

Plans freeze before probes; outcomes belong in the report/frontier. Preserve
superseded tools and rejected attempts. Keep new archival metadata small where
possible, but retain exact observed inputs and raw failures or explicit recovery
recipes. Canonical outcome: [implementation report](../../implementation/phase13/structured_rewriter.md).
