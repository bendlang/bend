#!/usr/bin/env python3
"""Remove only the private exact-entry permission record from actual12 output."""
from pathlib import Path
import ast
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PLAN = ROOT / 'design/phase30/scalar-exact-entry-state.md'
WRAPPER = HERE / 'prototype-acquire.py'
SOURCES = {
    'scalar': ROOT / 'selfhost/build/phase30/review-entry-state-source-12/candidate.mjs',
    'editdist': ROOT / 'selfhost/build/phase30/transfer-12/editdist/candidate.mjs',
}
EXPECTED = {'scalar': '990a2a7568cdb40541883237b97e008ee785a8d8e890400b9890fe21274204f5',
            'editdist': '10c684a5ff9768630848afd3b9ec455cc24fad3a265a37c7d095d1736afe3e32'}
OLD_STATE = '''let exactEntry=null;
function enterExact(code,inner,a){
  const entry=exactEntry;
  const entered=entry!==null&&entry.code===code&&entry.args===a&&!entry.used;
  if(entered)entry.used=true;
  return inner(a,entered);
}'''
NEW_STATE = '''let exactCurrentCode=null,exactCurrentArgs=null,exactCurrentUsed=false;
function enterExact(code,inner,a){
  const entered=exactCurrentCode===code&&exactCurrentArgs===a&&!exactCurrentUsed;
  if(entered)exactCurrentUsed=true;
  return inner(a,entered);
}'''
OLD_INSTALL = '''const invoke=code.call,env=f.env,previous=exactEntry;
  exactEntry={code,args:all,used:false};
  try{return Reflect.apply(code,env,[all]);}
  finally{exactEntry=previous;}'''
NEW_INSTALL = '''const invoke=code.call,env=f.env,previousCode=exactCurrentCode,
    previousArgs=exactCurrentArgs,previousUsed=exactCurrentUsed;
  exactCurrentCode=code;exactCurrentArgs=all;exactCurrentUsed=false;
  try{return Reflect.apply(code,env,[all]);}
  finally{exactCurrentCode=previousCode;exactCurrentArgs=previousArgs;exactCurrentUsed=previousUsed;}'''


def identity(path):
    path = Path(path).resolve()
    raw = path.read_bytes()
    return {'file': str(path), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def derive(text):
    assert text.count(OLD_STATE) == 1 and text.count(OLD_INSTALL) == 1
    assert 'exactCurrentCode' not in text
    result = text.replace(OLD_STATE, NEW_STATE).replace(OLD_INSTALL, NEW_INSTALL)
    assert 'exactEntry' not in result
    assert result.replace(NEW_STATE, OLD_STATE).replace(NEW_INSTALL, OLD_INSTALL) == text
    return result


out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [PLAN, WRAPPER, Path(__file__)]]
outputs = {}
tree = ast.parse(WRAPPER.read_text())
selected = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ['wrap', 'oracle']]
assert len(selected) == 2
namespace = {'json': json}
exec(compile(ast.Module(body=selected, type_ignores=[]), str(WRAPPER), 'exec'), namespace)
for kind, source in SOURCES.items():
    receipt_path = Path(str(source) + '.json')
    receipt = json.loads(receipt_path.read_text())
    assert receipt['complete'] and receipt['observation']['checked']
    assert identity(source)['sha256'] == EXPECTED[kind] == receipt['output']['sha256']
    attempt = Path(receipt['attempt']['file'])
    assert attempt.parent.name == 'attempt-12'
    assert identity(attempt)['sha256'] == receipt['attempt']['sha256']
    inputs += [identity(p) for p in [source, receipt_path, attempt, receipt['runtime']['file']]]
    assert identity(receipt['runtime']['file'])['sha256'] == receipt['runtime']['sha256']
    folder = out / kind
    folder.mkdir()
    (folder / 'checked-emission.json').write_bytes(receipt_path.read_bytes())
    original = source.read_text()
    pair = [('baseline', original), ('slots', derive(original))]
    outputs[kind] = {}
    for name, text in pair:
        target = folder / (name + '.mjs')
        target.write_text(text)
        outputs[kind][name] = identity(target)
        if kind == 'scalar':
            (folder / (name + '-diagnostic.mjs')).write_text(text + '\nexport {fn,callOwned,apply,force,jump,exactCode,build};\n')
        else:
            row = folder / (name + '-row.mjs')
            row.write_text(namespace['wrap'](text, False))
            outputs[kind][name + '_row'] = identity(row)
points = [{'args': [n, seed], 'expected': namespace['oracle'](n, seed)}
          for n in [0, 1, 2, 7, 16, 32, 64] for seed in [0, 1, 17, 0xffffffff]]
(out / 'row-points.json').write_text(json.dumps(points, indent=2) + '\n')
for name, path in [('plan.md', PLAN), ('derive.py', Path(__file__)), ('row-wrapper-source.py', WRAPPER)]:
    (out / name).write_bytes(path.read_bytes())
report = {'kind': 'phase30-scalar-exact-entry-state', 'complete': True, 'inputs': inputs,
          'outputs': outputs, 'rewrites': [{'old': OLD_STATE, 'new': NEW_STATE},
                                         {'old': OLD_INSTALL, 'new': NEW_INSTALL}],
          'unchanged': 'Registration, method/property order, Reflect.apply, callback/body/guard/primitive bytes and permission policy.',
          'compilerChanged': False, 'maintainedRuntimeChanged': False,
          'correctness': 'pending', 'measurement': 'pending'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
for label, kind, suffix, point in [
    ('scalar', 'scalar', '', {'args': [128, 524800], 'expected': 128}),
    ('row', 'editdist', '_row', next(p for p in points if p['args'] == [32, 17]))]:
    for protocol in ['screen', 'confirm']:
        config = {'protocol': protocol, 'inputs': [identity(out / 'derive.json'), *inputs],
                  'cases': [{'id': 'exact-entry-slots-' + label, 'point': point,
                             'modules': {name: outputs[kind][name + suffix]['file'] for name in ['baseline', 'slots']}}]}
        (out / (label + '-' + protocol + '.json')).write_text(json.dumps(config, indent=2) + '\n')
for label, tool in [('abi', 'review-scalar-compiler-run.mjs'), ('entry', 'review-scalar-entry.mjs')]:
    config = {'baseline': outputs['scalar']['baseline']['file'], 'candidate': outputs['scalar']['slots']['file'],
              'skipPrototypeControls': False, 'derivation': identity(out / 'derive.json'),
              'controlTool': identity(HERE / tool)}
    (out / (label + '.json')).write_text(json.dumps(config, indent=2) + '\n')
assert inputs == [identity(item['file']) for item in inputs]
print(json.dumps({'complete': True, 'out': str(out), 'outputs': outputs}))
