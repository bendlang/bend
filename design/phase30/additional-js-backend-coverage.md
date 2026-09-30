# Optional new JavaScript backend coverage on checked16

The13 broader JS selections in the retained Phase24 plan contain811 positive
fixture/lane rows beyond its22 positive JS pilot rows. They were **never
executed in Phase24**: the original report explicitly says the broader batches
were deferred after the pilot found actionable defects. This is prospective
new coverage, not renewal of historical result objects. The unexecuted early
Phase30 broad-js plan and its too-strict pass-only wrapper remain unchanged.
No811 execution is authorized until the parent grants it after clean timing and
release work.

Use exactly the13 retained JS-only selections, unchanged fixtures, oracles,
source hashes, pinned upstream and final16 immutable attempt. Freeze the
selection/inventory/host/tool/source identities and the new wrapper before
launch. Each unchanged Phase24 helper batch freshly runs both upstream and
candidate through the same maintained harness: isolated Node24.18.0, four jobs,
CPU3–6,4MiB stack,4GiB heap,30-second probes, at most64 rows per batch. Run
batches serially so fixture-local paths cannot overlap. No Clang, GPU, Bun,
network or native lane is added. A JS foreign-runtime requirement or spawn issue
is an observed capability/host limitation, never a passing fixture.

## Exact observations and explicit host metadata

Retain both complete raw result vectors and unchanged fixture verdicts. Require
all expected row identities exactly once, no missing/extra rows, healthy closed
workers, unchanged inputs/artifacts and a successfully verified archive before
accepting a batch. The old helper sets complete before archive completion, so
also require no helper error, empty changedInputs and the verified archive's
file count/hash; exit zero alone is insufficient.

Require the maintained paired exactAgreement and semanticAgreement flags and
then independently compare all observable result fields, including status,
phase, checked/typeAccepted, proofTrust/kernelChecked, unsafeDefinitions,
exitCode, diagnostic, output, stdout, stderr, error, reason, signal and sourceFile.
Missing optional values compare with explicit null, with raw objects preserved;
no error text, phase or output is normalized. Reject unknown result keys. Row
identity, namespace, negative/failureKind, verdict, evidence and reason must
also agree. Wall timings and artifact/replay locations remain side-specific
measurement/provenance data and are retained separately.

The adapters intentionally expose different host metadata, already visible in
the successful JS pilot. Bind and audit these differences explicitly:

- Candidate hostProvenance must name the exact frozen typed-driver and adapter
  hashes; the reference does not have that field.
- Candidate runtimeNodeArgs and reference executionArgs must equal the same
  frozen4MiB-stack/4GiB-heap flags wherever present; runtime positive observations
  require them. The reference executionMode must be js.
- The candidate's extra verdict banner, if present, must be the existing literal
  ordinary-library banner; it is not an extra mathematical proof result. The
  reference omits it.
- No other side-only metadata is ignored. An unexpected field is a stopped
  acquisition to inspect, not permission to add an exception after seeing it.

A positive fixture passes only if both unchanged judges say pass, both report
checked runtime success/exit0, their outputs meet the original fixture oracle
and the full observed fields agree. Do not accept matching host failures merely
because exactAgreement is true.

The sole non-pass completion allowed prospectively is the existing maintained
unprintable-main exemption, bound by the exact judge source hash. Both sides
must independently return verdict not-applicable and result status:error,
phase:compile, checked:true, exitCode1, and exactly equal complete diagnostics
without an extra signal/error/reason, and matching the existing `Error: main's type ... cannot be printed` rule (including
its existing optional explanatory suffix). Retain this as not applicable,
never as execution success. It is a narrow language-output restriction, not a
blanket allowance for matching errors. Keep unexpected paired failures,
unsupported outcomes, crashes, timeouts and environmental errors separate and
stop before the next batch. A new mismatch similarly stops for triage.

## Resource boundary and decision

The current22-row positive JS pilot took20.56 seconds for paired acquisition;
linear scaling suggests roughly13 minutes for811, but these new fixtures may
be larger or slower. This is a planning estimate, not a measured backend speed.
Use a hard1800-second campaign deadline, the existing420-second per-batch cap,
plus at most three seconds for process-group cleanup. Stop launching batches
at200MiB of new retained evidence or less than150MiB free filesystem space.
Keep the existing retain:failed artifact policy: complete observations remain
for successes; only successful generated programs may be omitted, with exact
regeneration inputs retained. Failed programs and their outputs stay.

The earlier22-row retained-all JS pilot plus other first-six pilot batches
occupy about6MiB compressed; the21 native retry occupies3.6MiB with45MiB before
compression. New JS batches retain only failed generated artifacts, but large
failures can exceed an estimate. Allow roughly30–150MiB in the normal case and
respect the explicit storage/free-space stop. There is no guarantee that all811
fit the deadline or storage allowance.

Report acquired/never-started/interrupted rows separately, per-side fixture
verdict counts, exact paired count, successful executed count and NA count.
New shared failures stay failures. A complete811 acquisition would add selected
backend coverage, not full conformance across all2654 eligible opportunities,
proof-kernel validation or generated-program speed evidence. The parent may
defer this optional scope if the native environment diagnosis/release consumes
the remaining budget.
