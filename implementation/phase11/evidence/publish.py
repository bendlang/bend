"""Capture only after explicit root FREEZE, then verify complete byte/mode recovery."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import importlib.util
sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[3]
evidence = Path(__file__).resolve().parent
collector_file = root / 'implementation/phase8/migration-evidence/collect.py'
spec = importlib.util.spec_from_file_location('collector', collector_file)
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--root-freeze-record', required=True, type=Path)
parser.add_argument('--recovery', required=True, type=Path)
args = parser.parse_args()
freeze = json.loads(args.root_freeze_record.read_text())
assert freeze['rootExplicitFreeze'] is True, 'Root must explicitly close all producers before capture.'
assert freeze['captureAuthorized'] is True
selection_file = evidence / 'selection.json'
selection = json.loads(selection_file.read_text())
assert selection['complete'] is True
capsule = evidence / 'capsule-01'
run = evidence / 'publication-run-01'
run.mkdir()
report = {'kind': 'phase11-evidence-publication', 'complete': False, 'pass': False,
          'scope': 'One final capsule, retained failures and independently checked byte/mode recovery; not a new compiler validation claim.',
          'freeze': {'file': str(args.root_freeze_record.resolve()), **collector.identity(args.root_freeze_record)},
          'commands': []}
report_file = evidence / 'publication.json'
assert not report_file.exists()
def save():
    report_file.write_text(json.dumps(report, indent=2) + '\n')
def command(label, argv):
    result = subprocess.run(argv, cwd=root, capture_output=True, text=True)
    stdout, stderr = run / (label + '.stdout'), run / (label + '.stderr')
    stdout.write_text(result.stdout)
    stderr.write_text(result.stderr)
    record = {'label': label, 'argv': argv, 'exitCode': result.returncode,
              'stdout': {'file': str(stdout.relative_to(root)), **collector.identity(stdout)},
              'stderr': {'file': str(stderr.relative_to(root)), **collector.identity(stderr)}}
    report['commands'].append(record)
    save()
    if result.returncode:
        raise RuntimeError(label + ' failed; exact command output retained.')
    return json.loads(result.stdout)
save()
try:
    report['capture'] = command('capture', [sys.executable, str(collector_file), 'capture', str(selection_file), str(capsule)])
    manifest_file = capsule / 'manifest.json'
    manifest = json.loads(manifest_file.read_text())
    archive = capsule / manifest['archive']['file']
    for file in [archive, manifest_file]:
        assert file.stat().st_size < 100_000_000, 'Publication file exceeds100MB: ' + str(file)
    report['verification'] = command('verify', [sys.executable, str(collector_file), 'verify', str(capsule)])
    report['materialization'] = command('materialize', [sys.executable, str(collector_file), 'materialize', str(capsule), str(args.recovery)])
    recovery_file = evidence / 'recovery-01.json'
    command('recovery-check', [sys.executable, str(evidence / 'recovery-check.py'), str(capsule), str(args.recovery), str(recovery_file)])
    recovery = json.loads(recovery_file.read_text())
    assert recovery['complete'] and recovery['pass']
    report.update({'capsule': {'directory': str(capsule.relative_to(root)),
                              'manifest': {'file': str(manifest_file.relative_to(root)), **collector.identity(manifest_file)},
                              'archive': {'file': str(archive.relative_to(root)), **collector.identity(archive)},
                              'summary': manifest['summary']},
                   'recoveryCheck': {'file': str(recovery_file.relative_to(root)), **collector.identity(recovery_file)},
                   'externalCapsules': manifest['externalCapsules'],
                   'unresolvedRepositoryReferences': [r for r in manifest['references'] if r['status'] == 'unresolved-repository-reference'],
                   'remainingHistoricalExternalReferences': [r for r in manifest['references'] if r['status'] == 'external-prerequisite'],
                   'limitations': ['The seven bound prerequisite capsules and separately retained Phase9 profile gzip remain required.',
                                   'Node, Clang, headers and host libraries remain external toolchain prerequisites; replay paths need adaptation.',
                                   'Derived Base caches are omitted with identities and must be prepared again.',
                                   'The inherited unavailable lexical-selfhost API is historical context, not a Phase11 consumed compiler artifact.'],
                   'publisher': {'file': str(Path(__file__).relative_to(root)), **collector.identity(Path(__file__))}})
    assert not report['unresolvedRepositoryReferences'], 'Unresolved repository references require explicit review before publication.'
    report['complete'] = True
    report['pass'] = True
except BaseException as error:
    report['error'] = repr(error)
    raise
finally:
    save()
    print(json.dumps({'complete': report['complete'], 'pass': report['pass'],
                      'archiveBytes': report.get('capsule', {}).get('archive', {}).get('bytes'),
                      'recoveredFiles': report.get('materialization', {}).get('recoveredFiles')}))
