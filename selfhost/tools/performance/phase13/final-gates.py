"""Read-only closure checks for the deferred Phase13 experiment."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[4]
start_file = root / 'selfhost/build/phase13/start-state.json'
output = root / 'selfhost/build/phase13/final-gates-01.json'
assert not output.exists()
start = json.loads(start_file.read_text())
report = {'kind': 'phase13-closure-checks', 'complete': False, 'pass': False,
          'baselineCommit': start['head'],
          'scope': 'Unchanged installed release and production files; unrelated workspace preservation. No new broad compiler validation.'}

def run(argv):
    result = subprocess.run(argv, cwd=root, capture_output=True, text=True, timeout=60)
    row = {'argv': argv, 'exitCode': result.returncode,
           'stdout': result.stdout, 'stderr': result.stderr}
    assert result.returncode == 0, row
    return row

try:
    report['release'] = run(['/home/ai/.nvm/versions/node/v24.18.0/bin/node',
                             'selfhost/tools/development/release.mjs', '--verify'])
    verified = json.loads(report['release']['stdout'])
    assert verified['complete'] is True
    assert verified['api']['sha256'] == '0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697'
    assert verified['sourceSha256'] == '828e6f650faf5bfb5fb1974f49facb6aaca850d2e002cb3afec8adc1335b2825'
    production = ['selfhost/src', 'selfhost/tools/development', 'selfhost/tools/typed-driver.mjs',
                  'selfhost/tools/typed-host.mjs', 'selfhost/tests', 'selfhost/dist',
                  'selfhost/cli.mjs', 'selfhost/package.json', 'bend2']
    report['productionDiff'] = run(['git', 'diff', '--name-only', start['head'], '--', *production])
    assert not report['productionDiff']['stdout']
    report['upstream'] = run(['git', '-C', 'selfhost/.bootstrap/upstream-phase8', 'rev-parse', 'HEAD'])
    assert report['upstream']['stdout'].strip() == 'b2111cf43244e65f76ddc278ee695e669f720cbf'
    report['upstreamStatus'] = run(['git', '-C', 'selfhost/.bootstrap/upstream-phase8', 'status', '--porcelain'])
    assert not report['upstreamStatus']['stdout']
    status = run(['git', 'status', '--porcelain=v1', '--untracked-files=all'])
    states = {line[3:]: line[:2] for line in status['stdout'].splitlines()}
    report['unrelatedPhase6'] = []
    for old in start['unrelatedPhase6']:
        file = root / old['path']
        row = {'path': old['path'], 'status': states.get(old['path']),
               'sha256': hashlib.sha256(file.read_bytes()).hexdigest()}
        assert row['status'] == old['status'], row
        assert row['sha256'] == old['sha256'], row
        report['unrelatedPhase6'].append(row)
    assert len(report['unrelatedPhase6']) == 75
    staged = run(['git', 'diff', '--cached', '--name-only'])
    report['stagedPaths'] = staged['stdout'].splitlines()
    assert not any('/phase6/' in name for name in report['stagedPaths'])
    report['complete'] = report['pass'] = True
except BaseException as error:
    report['error'] = repr(error)
    raise
finally:
    output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': report['complete'], 'pass': report['pass'],
                      'unrelatedPreserved': len(report.get('unrelatedPhase6', []))}))
