#!/usr/bin/env python3
"""Retain scoped synthetic and original-program controls for private Let lowering."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
DERIVER = HERE / 'inspect-private-let-derive.py'
TREE_CONTROLS = HERE / 'prototype-tree-region-controls.mjs'
TREE_BOUNDARIES = HERE / 'review-tree-boundaries.mjs'
spec = importlib.util.spec_from_file_location('private_let_deriver', DERIVER)
deriver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(deriver)
parser = deriver.parser


def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}


def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')


def edit(source, old, new):
    assert source.count(old) == 1, old
    return source.replace(old, new)


whole, helper, out = (Path(x).resolve() for x in sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [Path(__file__), DERIVER, deriver.PARSER, deriver.DESIGN,
                               TREE_CONTROLS, TREE_BOUNDARIES, NODE]]
derivations = {}
for name, directory in [('whole', whole), ('helper', helper)]:
    report = json.loads((directory / 'derive.json').read_text())
    assert report['complete'] and report['reconstructedOriginal']
    for row in report['inputs']:
        assert identity(row['file']) == row
    for row in report['outputs'].values():
        assert identity(row['file']) == row
    inputs += [identity(directory / 'derive.json'), *report['outputs'].values()]
    derivations[name] = report
assert derivations['whole']['helpersChanged'] > 0
report = {'kind': 'phase30-private-let-controls', 'complete': False, 'pass': False,
          'inputs': inputs, 'steps': [], 'syntaxRefusals': [],
          'scope': 'Independent scope/order examples and unchanged numeric/public controls. Acquisition only.'}
shutil.copyfile(Path(__file__), out / 'consumed-controls.py')
env = {k: v for k, v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS', 'NODE_PATH']}


def run(label, arguments, result_file, timeout=90):
    command = ['taskset', '-c', '7', str(NODE), '--stack-size=4096', '--max-old-space-size=1024', *map(str, arguments)]
    row = {'name': label, 'command': command, 'complete': False}
    report['steps'].append(row)
    save(out / 'report.json', report)
    start = time.monotonic()
    with (out / (label + '.stdout')).open('w') as stdout, (out / (label + '.stderr')).open('w') as stderr:
        try:
            row['exitCode'] = subprocess.run(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr, timeout=timeout).returncode
        except subprocess.TimeoutExpired:
            row['timeout'] = True
    row['wallSeconds'] = time.monotonic() - start
    row['stdout'], row['stderr'] = identity(out / (label + '.stdout')), identity(out / (label + '.stderr'))
    if result_file.exists():
        row['result'] = identity(result_file)
        result = json.loads(result_file.read_text())
        row['complete'] = row.get('exitCode') == 0 and result.get('complete') and result.get('pass')
    save(out / 'report.json', report)
    assert row['complete'], label


try:
    synthetic = out / 'synthetic'
    synthetic.mkdir()
    examples = [
        {'name': 'parallel-shadow', 'expr': '((x1,x2,)=>x1*100+x2)(mark("first",x2),mark("second",x1),)',
         'args': [11, 22], 'expected': {'value': 2211, 'events': [['first', 22], ['second', 11]]}},
        {'name': 'nested-shadow', 'expr': '((x1,)=>((x1,x2,)=>x1*100+x2)(mark("inner",x1+1),mark("outer",x2),))(mark("start",x1+2),)',
         'args': [3, 7], 'expected': {'value': 607, 'events': [['start', 5], ['inner', 6], ['outer', 7]]}},
        {'name': 'parallel-nested-shadow', 'expr': '((x1,x2,)=>((x1,)=>[x1,x2])(x1+1,))(1,x1,)',
         'args': [10, 0], 'expected': {'value': [2, 10], 'events': []}},
        {'name': 'later-argument-throws', 'expr': '((x1,x2,)=>mark("body",x1+x2))(mark("first",x2),mark("throw",x1),)',
         'args': [11, 22], 'expected': {'error': {'name': 'Error', 'message': 'argument sentinel'}, 'events': [['first', 22], ['throw', 11]]}},
        {'name': 'primitive-IIFE-preserved', 'expr': '((x1,)=>((a,b)=>Math.imul(a,b)>>>0)(x1,3))(mark("first",x1),)',
         'args': [4294967295, 0], 'expected': {'value': 4294967293, 'events': [['first', 4294967295]]}},
        {'name': 'negative-zero', 'expr': '((x1,)=>x1)(mark("first",x1),)',
         'args': ['negative-zero', 0], 'expected': {'value': '-0', 'events': [['first', '-0']]}},
        {'name': 'nan', 'expr': '((x1,)=>x1)(mark("first",x1),)',
         'args': ['nan', 0], 'expected': {'value': 'NaN', 'events': [['first', 'NaN']]}},
    ]
    for row in examples:
        source = 'function $R_1(x1,x2,mark){return ' + row['expr'] + ';}\nexport default $R_1;\n'
        lowered, evidence = deriver.derive(source)
        assert evidence['helpersChanged'] == 1
        for side, text in [('baseline', source), ('candidate', lowered)]:
            target = synthetic / (row['name'] + '-' + side + '.mjs')
            target.write_text(text)
            row[side] = identity(target)
        row['derivation'] = evidence
    save(synthetic / 'config.json', {'examples': examples})
    (synthetic / 'run.mjs').write_text('''import fs from 'node:fs';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const [config,result]=process.argv.slice(2),rows=JSON.parse(fs.readFileSync(config)).examples;
const norm=x=>Object.is(x,-0)?'-0':typeof x==='number'&&Number.isNaN(x)?'NaN':x;
const report={complete:false,pass:false,observations:[]};
try{for(const row of rows)for(const side of ['baseline','candidate']){
 const m=await import(pathToFileURL(row[side].file)),events=[];
 const args=row.args.map(x=>x==='negative-zero'?-0:x==='nan'?NaN:x);
 const observed={events};try{observed.value=norm(m.default(...args,(name,value)=>{events.push([name,norm(value)]);if(name==='throw')throw Error('argument sentinel');return value}))}
 catch(e){observed.error={name:e.name,message:e.message}}
 assert.deepEqual(observed,row.expected,row.name+' '+side);report.observations.push({name:row.name,side,observed});
}report.complete=true;report.pass=true}catch(e){report.error=e.stack;process.exitCode=1}
fs.writeFileSync(result,JSON.stringify(report,null,2)+'\\n',{flag:'wx'});
''')
    run('synthetic', [synthetic / 'run.mjs', synthetic / 'config.json', synthetic / 'report.json'], synthetic / 'report.json')
    for expression in ['((x1,x1,)=>x1)(1,2,)', '((x1,x2,)=>x1)(1,)',
                       '((x1=0,)=>x1)(1,)', '((x1,)=>{return x1})(1,)',
                       '((x1,)=>arguments[0])(1,)', '((x1,)=>`template`)(1,)']:
        try:
            deriver.derive('function $R_1(){return ' + expression + ';}')
        except (AssertionError, ValueError) as error:
            report['syntaxRefusals'].append({'expression': expression, 'error': str(error)})
        else:
            raise AssertionError('Ambiguous expression was not refused: ' + expression)
    # Adapt only module labels and the diagnostic sentinels to the actual12 tree.
    controls = edit(TREE_CONTROLS.read_text(), "const variants=['baseline','public_leaf','private_leaf'];",
                    "const variants=['baseline','candidate'];")
    start = controls.index("    const original=path.join(dir,variant+'.mjs');let text=")
    end = controls.index('    const m=await import(pathToFileURL(file));', start)
    controls = controls[:start] + "    const file=path.join(dir,variant+'-depth-sentinel.mjs');\n" + controls[end:]
    paired = out / 'whole-pair'
    paired.mkdir()
    for side in ['baseline', 'candidate']:
        source = (whole / (side + '.mjs')).read_text()
        marker = '/* private scalar tree */'
        assert source.count(marker) == 1
        owner = next(line for line in source.splitlines() if marker in line)
        assert owner.startswith('G["rcol"]=')
        fast_open = owner.index(marker) - 1
        assert owner[fast_open] == '{'
        fast_close = parser.close(owner, fast_open)
        callback_open = owner.rfind('function(a,$entered){', 0, fast_open) + len('function(a,$entered){') - 1
        callback_close = parser.close(owner, callback_open)
        sentinel_owner = owner[:fast_open + 1] + 'return "fast";' + owner[fast_close:fast_close + 1] + 'return "generic";' + owner[callback_close:]
        (paired / (side + '.mjs')).write_text(source)
        (paired / (side + '-depth-sentinel.mjs')).write_text(edit(source, owner, sentinel_owner))
    shutil.copyfile(whole / 'derive.json', paired / 'derive.json')
    (paired / 'controls.mjs').write_text(controls)
    run('whole-oracle', [paired / 'controls.mjs', paired, out / 'whole-oracle'], out / 'whole-oracle/report.json')
    boundary_config = out / 'whole-boundaries.json'
    save(boundary_config, {'variants': {side: str(whole / (side + '.mjs')) for side in ['baseline', 'candidate']},
                           'inputs': [str(whole / 'derive.json')]})
    run('whole-boundaries', [TREE_BOUNDARIES, boundary_config, out / 'whole-boundaries'], out / 'whole-boundaries/report.json')
    if derivations['helper']['helpersChanged']:
        helper_config = out / 'helper-config.json'
        save(helper_config, {side: str(helper / (side + '.mjs')) for side in ['baseline', 'candidate']})
        for name, filename in [('helper-scalar', 'review-scalar-compiler-run.mjs'), ('helper-entry', 'review-scalar-entry.mjs')]:
            tool = HERE / filename
            inputs.append(identity(tool))
            run(name, [tool, helper_config, out / name], out / name / 'report.json')
    else:
        assert (helper / 'baseline.mjs').read_bytes() == (helper / 'candidate.mjs').read_bytes()
        report['unchangedHelper'] = 'Exact byte-identical derivation; no distinct helper timing or duplicate execution.'
    assert all(identity(row['file']) == row for row in inputs)
    report.update({'complete': True, 'pass': True})
except Exception as error:
    report['error'] = repr(error)
    raise
finally:
    save(out / 'report.json', report)
print(json.dumps({'complete': True, 'pass': True, 'steps': len(report['steps']), 'syntaxRefusals': len(report['syntaxRefusals'])}))
