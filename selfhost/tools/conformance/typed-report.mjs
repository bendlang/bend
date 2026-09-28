import {semanticSummary} from './semantic-summary.mjs';
import path from 'node:path';
export function typedReport(report,file) {
  const rows=report.results,inv=report.inventory,sem=semanticSummary(rows,inv.tests);
  const lanes=['parse','check','interpreter','js','native','metal','cuda'];
  const n=(rs,status)=>rs.filter(r=>r.status===status).length;
  const laneRows=(lane,namespace,negative)=>rows.filter(r=>r.lane===lane&&(!namespace||r.namespace===namespace)&&(negative===undefined||r.negative===negative));
  const ratio=(lane,namespace)=>{const rs=laneRows(lane,namespace,false),exempt=n(rs,'not-applicable');return `${n(rs,'pass')}/${rs.length}${exempt?' ('+exempt+' exempt)':''}`;};
  const evidence=kind=>rows.filter(r=>r.evidence===kind).length;
  return `# Compatibility matrix

This report measures the typed Bend compiler against the complete pinned upstream
corpus. **Strict full-suite verdict: ${report.complete?'complete':'incomplete'}.**
There are ${inv.total} gate fixtures in ${Object.keys(inv.namespaces).length} namespaces:
${inv.tests.filter(t=>!t.negative).length} positive and ${inv.tests.filter(t=>t.negative).length}
with an expected failure or proof-trust refusal. No namespace is removed. GPU hardware gates and
negative rejection differences remain visible; they never count as successful tests.

Pinned upstream: \`${inv.revision}\`.
Run: ${report.started}–${report.finished}; ${report.host.node}, ${report.host.platform}/${report.host.arch};
${report.options.jobs} workers, ${report.options.timeout} ms per isolated probe.
Requested lanes: \`${report.options.lanes}\`. Missing lanes are not inferred from others.
Evidence: [full JSON](../tests/conformance/${path.basename(file)}).
These counts apply to the recorded artifact hashes. Later source changes need
separate validation; they do not retroactively change this run's verdicts.
The earlier unchecked compiler is recorded separately in [PROTOTYPE-BASELINE.md](PROTOTYPE-BASELINE.md).

## Exact fixture comparisons

| Lane | Total | Pass | Fail | Timeout | Crash | Exempt | Unsupported | Hardware gate | Observation |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
${lanes.map(l=>{const rs=laneRows(l);return `| ${l} | ${rs.length} | ${['pass','fail','timeout','crash','not-applicable','unsupported','hardware-gated','observed'].map(s=>n(rs,s)).join(' | ')} |`;}).join('\n')}

A pass requires the expected output and exit behavior. Parse observations for
negative sources do not prove a checking rule. Compiled exemptions use the pinned
upstream's exact refusal to print a function, Type, or erased/dependent field.
Hardware execution requires a real device, a forced device run, and adapter evidence;
CPU fallback is never a GPU pass.

## Checking versus diagnostics

The real checker accepted **${sem.positiveChecks.accepted}/${sem.positiveChecks.total} positive programs**.
${sem.positiveChecks.other.length ? `The remaining ${sem.positiveChecks.other.length} include actual errors, timeouts, or crashes;
they are not omitted from the denominator.` : 'No positive checker rejection, timeout, or crash was observed.'}

| Error-expectation check observation | Count |
|---|---:|
${Object.entries(sem.errorExpectations.rejectedByPhase).map(([phase,count])=>`| Rejected during ${phase} | ${count} |`).join('\n')}
| Accepted by checker; exact later rejection confirmed | ${sem.errorExpectations.acceptedWithExpectedLaterRejection.length} |
| Accepted; expected later rejection not established | ${sem.errorExpectations.acceptedWithoutExpectedLaterRejection.length} |
| Timeout or crash | ${sem.errorExpectations.timeoutsOrCrashes.length} |
| Declaration-only trust refusals after type acceptance | ${sem.proofTrustExpectations.typeAccepted}/${sem.proofTrustExpectations.total} |
| Exact trust-refusal matches | ${sem.proofTrustExpectations.exactPasses} |

There are **${evidence('checker-rejection')} exact checker-rejection comparisons** across
all lanes, **${evidence('frontend-rejection')} exact frontend rejections**, and
**${evidence('compile-rejection')+evidence('runtime-rejection')} exact compile/runtime rejections**.
A generic or unrelated rejection is not an exact conformance pass. An
\`Error:\` fixture can describe a runtime/emission error; check-only acceptance of
such a fixture is not by itself a checker defect. Supplemental negative execution
lanes preserve their actual rejection phase for that distinction.

The [negative-test audit](NEGATIVE-COMPATIBILITY.md) separately examines the
recorded a6f release. It distinguishes presentation evidence, different rejection
rules/phases, and cases whose intended-rule coverage remains unproven.

${sem.errorExpectations.acceptedWithExpectedLaterRejection.length?'Correctly deferred errors: '+sem.errorExpectations.acceptedWithExpectedLaterRejection.map(x=>'`'+x.id+'` ('+x.phases.join('/')+'; '+x.lanes.join(', ')+')').join(', ')+'.\n':''}
${sem.errorExpectations.acceptedWithoutExpectedLaterRejection.length?'Accepted Error-expectation fixtures still requiring triage: '+sem.errorExpectations.acceptedWithoutExpectedLaterRejection.map(x=>'`'+x+'`').join(', ')+'.\n':''}
## Positive programs by namespace

Cells show exact passes/probes. Exempt compiled outputs remain in the denominator
and are listed separately. The check column measures actual validated acceptance,
so declaration-report text mismatches do not conceal successful checking.

| Namespace | Positive | Parse | Checked acceptance | Interpreter | JavaScript | Native |
|---|---:|---|---|---|---|---|
${Object.entries(inv.namespaces).map(([name,counts])=>{const rs=laneRows('check',name,false);return `| ${name} | ${counts.positive} | ${ratio('parse',name)} | ${rs.filter(r=>r.result?.status==='ok'&&r.result?.checked===true).length}/${rs.length} | ${ratio('interpreter',name)} | ${ratio('js',name)} | ${ratio('native',name)} |`;}).join('\n')}

## Remaining positive checking failures

${sem.positiveCheckingFailureGroups.length?sem.positiveCheckingFailureGroups.map(g=>'- '+g.reason.replace(/\n/g,' ')+' ('+g.count+'): '+g.ids.map(id=>'`'+id+'`').join(', ')).join('\n'):'No positive checker rejection, timeout, or crash was observed in this run.'}

## Remaining positive execution failures

${sem.positiveExecutionFailureGroups.length?sem.positiveExecutionFailureGroups.map(g=>'- '+g.lane+': '+g.reason.replace(/\n/g,' ')+' ('+g.count+'): '+g.ids.map(id=>'`'+id+'`').join(', ')).join('\n'):'No positive execution failure, timeout, crash, or unsupported result was observed in the requested lanes.'}

## Scope and implementation

The generated Bend API performs parsing, import loading, elaboration, checking,
specialization, normalization, annotation, and JS/native emission. The JavaScript
shell supplies file IO, ABI conversion, runtime loading, and host toolchain steps.
The upstream compiler is used to bootstrap an API, not to process ordinary programs.
Base reuse is bound to compiler/source hashes and canonical path, verified against
source text by the Bend loader and against the complete core prefix by the checker.

Separate component evidence is in [component-report.json](../dist/component-report.json).
Primary self-hosting evidence is in [seed-verification/report.json](../dist/selfhost/seed-verification/report.json).
[Earlier failed attempts](../dist/selfhost/release/report.json) are retained separately.
The direct verification report records a completed 49-minute checked rebuild
whose output is byte-identical to the self-emitted seed. This fixed point is
separate from upstream conformance and is tied to the recorded source/Base paths.

The inventory records all upstream compiler exports and function names, ${inv.effects.length}
effect source files, and ${inv.fixtures.length} non-Bend support fixtures. Benchmarks,
demos, hub/publishing behavior, installation/release parity, and the Lean
formalization are not established by these fixture results.

| Upstream source | Lines | Exported declarations |
|---|---:|---:|
${inv.sources.map(s=>`| ${s.file} | ${s.lines} | ${s.exports.length} |`).join('\n')}

## Reproduce

Use the pinned checkout and artifact hashes below. See
[the harness protocol](../tools/conformance/README.md) for frozen host adapters,
process deadlines, exact diagnostics, progress files, and GPU gating.

\`node tools/conformance/run.mjs --adapter tools/conformance/adapters/typed.mjs --jobs ${report.options.jobs} --timeout ${report.options.timeout}\`

${Object.entries(report.identity.artifacts||{}).map(([name,artifact])=>'- '+name+' SHA-256: `'+artifact.sha256+'`').join('\n')}
`;
}
