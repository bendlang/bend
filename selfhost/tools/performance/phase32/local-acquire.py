#!/usr/bin/env python3
"""Acquire checked local fixtures serially through the memory supervisor."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
attempt, out = [Path(x).resolve() for x in sys.argv[1:3]]
selected = sys.argv[3:] or ['pair', 'fold', 'scope', 'vectors']
sources = {
    'pair': ROOT/'selfhost/build/phase31/local-data-source-01/row.bend',
    'fold': ROOT/'selfhost/build/phase31/local-data-fold-source-02/source.bend',
    'scope': HERE/'local-scope.bend',
    'vectors': HERE/'review-local-vectors.bend',
}
out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve()
    return dict(file=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest())
report = dict(complete=False, inputs=[ident(__file__), ident(attempt/'attempt.json'),
    ident(HERE/'bounded-run.py'), ident(HERE.parent/'phase26/emit.mjs')], cases=[])
shutil.copyfile(__file__, out/'consumed-acquire.py')
def save(): (out/'report.json').write_text(json.dumps(report, indent=2)+'\n')
save()
try:
    for name in selected:
        source = sources[name]
        report['inputs'].append(ident(source))
        output = out/(name+'.mjs')
        command = [sys.executable, str(HERE/'bounded-run.py'), '--seconds', '120',
            '--rss-mib', '1600', str(out/(name+'-outer')), '--', 'taskset', '-c', '4',
            '/home/ai/.nvm/versions/node/v24.18.0/bin/node', '--stack-size=4096',
            '--max-old-space-size=1024', str(HERE.parent/'phase26/emit.mjs'),
            str(attempt), str(source), str(output)]
        result = subprocess.run(command)
        row = dict(name=name, command=command, returncode=result.returncode)
        report['cases'].append(row); save()
        assert result.returncode == 0, name
        receipt = json.loads(Path(str(output)+'.json').read_text())
        assert receipt['complete'] and receipt['observation']['checked']
        row.update(output=ident(output), receipt=ident(str(output)+'.json')); save()
    for entry in report['inputs']: assert ident(entry['file']) == entry
    report['complete'] = True
except Exception as error:
    report['error'] = repr(error)
    raise
finally: save()
