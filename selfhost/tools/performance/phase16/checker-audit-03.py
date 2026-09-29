from pathlib import Path
import json, hashlib
root = Path.cwd()
base = root / 'selfhost/build/phase16'
out = base / 'checker-audit-03'
out.mkdir()
inputs = []
def read(p): return json.loads(p.read_text())
def ident(p): return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
def run(name, count, primitive=True):
    p = base / name
    assert read(p / 'report.json')['complete']
    paired = read(p / 'selected/paired.json')
    assert len(paired['rows']) == count and not paired['missing']
    inputs.append(ident(p / 'selected/paired.json'))
    for side in ['reference', 'candidate']:
        f = p / 'selected' / f'{side}.json'
        x = read(f)
        inputs.append(ident(f))
        assert x['finished'] and len(x['results']) == count and not x['changedInputs']
        assert not x['identity']['adapterChangedDuringRun'] and not x['identity']['changedArtifacts']
        assert all(not w['errors'] and not w['stats']['timeouts'] and not w['stats']['failures'] for w in x['workers'])
    if primitive: assert all(r['semanticAgreement'] for r in paired['rows'])
    return {r['id']: r for r in paired['rows']}
final = run('checker-all-04', 84)
assert sum(r['exactAgreement'] for r in final.values()) == 25
prior = run('checker-focused-03', 55)
changed = {'check/error_window_rewrite_proof.bend', 'check/template_dup_binder.bend', 'comptime/err_generic.bend'}
assert {k for k in prior if prior[k]['candidate'] != final[k]['candidate']} == changed
assert sum(final[k]['exactAgreement'] for k in prior) == 13
assert all(not prior[k]['exactAgreement'] or final[k]['exactAgreement'] for k in prior)
for name, n in [('checker-boundaries-02', 12), ('checker-order-candidate-01', 12), ('checker-local-candidate-01', 10), ('checker-note-baseline-01', 1)]:
    previous = run(name, n)
    assert all(previous[k]['candidate'] == final[k]['candidate'] and previous[k]['reference'] == final[k]['reference'] for k in previous)
local_old = run('checker-local-baseline-01', 10, False)
fixed = 'p16-checker-local/template-duplicate-unused.bend'
assert [k for k in local_old if not local_old[k]['semanticAgreement']] == [fixed]
assert local_old[fixed]['candidate']['typeAccepted'] and not final[fixed]['candidate']['typeAccepted']
assert final[fixed]['candidate']['phase'] == 'check' and 'a fresh ~ binder name' in final[fixed]['candidate']['diagnostic']
for name in ['rewrite-valid', 'template-distinct', 'template-separate-owners']:
    assert final[f'p16-checker-local/{name}.bend']['candidate']['typeAccepted']
note = final['p16-checker-note/equal-nested-types.bend']['candidate']['diagnostic']
assert 'Note: +inner can be used many times, so its type must be Data.' in note
assert 'Note: +outer' not in note and 'Note: +again' not in note
witness = final['p16-checker-term-order/instance-before-later-type.bend']
assert 'consumed more than once' in witness['reference']['diagnostic'] and 'Location: app~0' in witness['reference']['diagnostic']
assert '- observed : Bool' in witness['candidate']['diagnostic'] and 'Location: main' in witness['candidate']['diagnostic']
for name in ['earlier-type-before-instance', 'valid-instance-before-later-type']:
    r = final[f'p16-checker-term-order/{name}.bend']
    assert r['reference']['diagnostic'].split('Location:')[0] == r['candidate']['diagnostic'].split('Location:')[0]
report = {'kind': 'phase16-local-checker-order-audit', 'complete': True, 'pass': True,
 'inputs': inputs + [ident(base / 'checker-source-04/manifest.json'), ident(Path(__file__))],
 'aggregate': {'observations': 84, 'exact': 25, 'strictDifferences': 59, 'primitiveAgreement': 84},
 'corpus': {'observations': 55, 'exact': 13, 'strictDifferences': 42, 'lostExact': 0, 'changedDiagnostics': sorted(changed)},
 'localControls': {'observations': 10, 'exact': 3, 'strictDifferences': 7, 'primitiveAgreementBefore': 9, 'primitiveAgreementAfter': 10, 'acceptanceFix': fixed},
 'unchangedScopes': {'priorBoundaries': 12, 'priorOrdering': 12, 'nestedNote': 1},
 'sameBodyPrecedence': {'observations': 3, 'primitiveAgreement': 3, 'knownWrongFirstError': witness['id'], 'negativeControlsPreserveContent': 2},
 'scope': 'Scoped source04 gates pass. All 59 strict differences remain failures. Definition-event interleaving is insufficient for the measured same-body witness. No full-corpus, speed, or complete chronology claim.'}
(out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: report[k] for k in ['complete', 'pass', 'aggregate', 'corpus', 'localControls', 'sameBodyPrecedence']}))
