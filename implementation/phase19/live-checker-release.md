# Shared live checker: installed release

The installed compiler now checks and produces template instances at their live
use, through the ordinary checker. Removing the separate specialization visitor
closes the two saved instance-order gaps and three let-closure diagnostic
differences. All 2,996 main frontend result objects remain identical to the
previous installed release. This is progress on the broader semantic controls,
not a reduction of the main inventory's two remaining parser observations.

The release is API `a15d150a920b89d9c0781372356424e559edabef3246ca281741069b0fe739b6`,
derived by unchanged guarded v5 transformations from genuine checked B1
`d4e57543cdb0a01e93adae9839e81c27e17512b995976230ffde4502c7d518d0`.
Source04/build03 and all earlier failed attempts remain distinct. The upstream
pin is unchanged: `b2111cf43244e65f76ddc278ee695e669f720cbf`.

The [implementation report](instance-live-checking.md) explains the source-world,
freshness, memo and output invariants, original failures and exact census. The
[integration plan](../../design/phase19/live-checker-integration.md) defines the
cost and promotion gates; the [independent review](instance-independent-review.md)
records public-boundary scope and the internal generic-helper precondition.
The [machine summary](live-checker-release.json) binds the release evidence.

## Functionality and compatibility

The source book remains authoritative for lookup, conversion and substitution.
The checked output is separate data, accumulated as checks finish. A live
template use validates its closed arguments, consults/reserves its canonical memo
entry, and checks the fresh instance immediately. Subsequent children receive
its returned state. Generic success restores only its private source-book view;
memo, freshness and output survive. Failures retain their actual world and owner.

The old specialization visitor and three traversal-state types are removed.
`specialize_book` uses the same source-event checker and projects the historical
four-field public checked payload. The checked book now places nested instances
before their callers, in completion order. Rechecking materialized output works
without an extra skip protocol. The public program path uses the checked output
directly, then applies the existing TODO/open-law completion policy.

The prefix proof repair remains installed. Source-only prefix caches cannot
restore the live memo and output, so prefix APIs replay source checking. The host
and cache formats, runtime, public export set and guarded derivative are unchanged.
This avoids another semantic owner but leaves prefix-state reuse as a potential
future optimization requiring its own soundness and cost argument.

The frozen historical public18 suite deliberately remains **12 pass / 6
differences**, with `pass:false`. Its assumptions about late instance validation,
raw book order and old failure worlds no longer describe the intended behavior.
All nine stable payload/projection-demand rows pass. The separately pinned
104-control suite validates the new boundaries; its call/datatype-head projection
does not prove full checked-term equivalence. Execution gates provide separate
evidence of generated-program behavior.

## Validation on the installed candidate

| Gate | Result | Evidence under `selfhost/build/phase19/` |
| --- | --- | --- |
| Genuine checked B1 and maintained selection | 36 pass; two known strict diagnostic differences | `instance-build-03/` |
| Complete main frontend | 2,996 results; all identical to preceding release | `instance-frontend-01/`, `instance-frontend-parent-comparison-01.json` |
| Saved instance chronology | 22 exact, including both earlier gaps | `instance-paired-02/` |
| Let-close first-error and source intervals | 6 exact, closing three strict differences | `instance-let-paired-03/` |
| Memo/name sets and parsed instances | 8 and 29 exact | `instance-memo-02/`, `instance-parsed29-01/` |
| Canonical keys and exact growth boundaries | 61 exact | `instance-key61-01/` |
| World, freshness, demand and checked output | 40 pass | `instance-direct-02/` |
| Additional safe/unsafe recursion | 4 exact | `instance-recursion-paired-01/` |
| Independent public boundaries | 104 pass | `instance-boundary-candidate-03/` |
| Selected actual backends | 41 exact, including JS/native/interpreter | `instance-backend-01/` |
| Literal JS/native execution | 20 exact | `instance-literal-execution-01/` |
| Original complete request histories | 226 paired results agree, plus fresh long-string checks | `instance-history-01/` |
| Unchanged derivative controls/replays | 16 groups and 5 authentic historical replays pass | `instance-helper-01/` |
| Installed/relocated package | All 42 checks pass | `instance-smoke-01/` |

The history gate preserves the original 53- and 60-request sequences under the
same 4 MiB stack and 4 GiB heap limits. It compares complete results under
identical host bytes and keeps historical observations separate. This is finite
stack-safety evidence, not a claim of unlimited input depth. Control sets overlap;
their row counts are not unique conformance program counts.

## Broader saved selections

The original integration selection now has **198/198 exact TypeScript result
matches**, up from197/198; its same-body instance witness is fixed. The immutable
runner still returns `pass:false` because14 correctly refused negative parse rows
carry the inherited `observed` verdict rather than `pass`. Raw acquisition and
exact-reference comparison are reported separately from that runner contract.

The original group selection retains **128/196 exact matches and68 differences**.
Both sides acquired all196 results without worker failure or timeout. Its raw
runner remains failed/incomplete at its selected-completion assertion because
inherited acceptance failures remain. A separate complete-vector audit records
regressions against its prior candidate; it does not turn the strict oracle into
a pass. The [supplemental audit](instance-broader-regressions.md) confirms zero changed
group result objects and zero lost exact matches in either selection. The
group/pattern failures still require parser work.

## Controlled checking cost

All other compiler, probe and archive jobs were held during the six fresh-process
TS/B/C/C/B/TS matrix on CPU0. Every variant checked the same candidate-assembled
compiler source. All 35 host files had identical membership and bytes; Base,
runtime, pinned checkout, v5 profile and resource limits agreed. Each Bend image
used its own validated Base cache; TypeScript checked Base. OS caches were not
flushed. No emission was requested.

| Image | Mean process wall | Mean request | Peak RSS |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 3.482922 s | 2.405262 s | 481,252 KiB |
| Installed prefix predecessor | 11.570560 s | 10.470022 s | 646,828 KiB |
| Live checker | 11.057018 s | 9.956728 s | 649,288 KiB |

Both Bend order pairs favor the rewrite. The means are **4.44% lower process
time** and **4.90% lower request time**, with **0.38% higher peak RSS**. The
same-window TypeScript ratio changes **3.3221× → 3.1746×**. This passes the
prospective 5% regression screen with a small favorable measurement; two samples
per image do not establish a general speedup. The 3.40× number in the prefix
report comes from a different window and must not be subtracted or multiplied
into a claimed gain.

Process time includes startup, hashing and output capture. Request time wraps
the adapter probe and includes lazy API loading; adapter import is outside it.
All six rows passed actual type acceptance and the expected unsafe-definition
trust refusal, with equal unsafe-definition sets. The result measures compiler
checking/trust reporting, not mathematical proof validity or emitted-code speed.
Raw rows, resource measurements and identities are in `instance-matrix-01/`;
the prospective host review and exclusive readiness record are in
`instance-matrix-inputs-01/`.

## Complexity and installation

The 59 production modules decrease from **16,355 to 15,880 physical lines**
(-475, 2.9%) and from 13,956 to 13,527 nonblank lines. Bytes fall from 581,508 to
575,893. Law declarations decrease 775→719; definitions increase 1,657→1,659 and
types increase 66→67. The important conceptual change is removal of a second
recursive semantic traversal. Explicit world/freshness transport still has a
cost, and this is well short of the earlier 50%/75% whole-compiler goals.

`instance-promotion-01` verified all 214 source/host members and the preceding
installed identity, then copied exactly six reviewed Bend files: checker kernel,
specialization, annotation, diagnostic production/trace and driver API. It
installed the genuine checked lineage and derivative using the maintained
release tool. All 75 protected unrelated Phase6 file hashes/statuses remained
unchanged. `instance-smoke-01` then passed all installed and relocated CLI checks.
No promotion or package-check attempt failed.

The contextual parser prototype is not installed. Main-corpus parse/check for
`monad_do_destructure` still differs in its first diagnostic, and broader grouped
pattern and namespace controls retain gaps. Independent proof-kernel validation,
GPU/platform coverage and a fresh self-hosted fixed point are not claimed.
The next semantic work is the parser's real pattern/group/do checkpoints; speed
work should profile this installed checker rather than assume the removed
specializer is still a bottleneck.

The scoped preservation capsule is a separate closure step, with active parser
work excluded. Commits remain local while the earlier automatic approval review
blocks remote pushes; no published GitHub revision is claimed by this report.
