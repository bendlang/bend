#!/usr/bin/env python3
"""Derive ordinary scalar-root ablations from the checked lexical-only compiler."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PLAN = ROOT / 'design/phase30/ordinary-scalar-root-regions.md'
PARSER = HERE / 'inspect-terminal-region.py'
spec = importlib.util.spec_from_file_location('phase30_generated_parser', PARSER)
parser = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parser)
NAMES = ['rpix', 'pix', 'bkt', 'mit', 'asr8', 'sel', 'sel.go', 'b2u']
SMALL = ['b2u', 'asr8', 'sel', 'sel.go']
ARITIES = {'rpix': 10, 'pix': 2, 'bkt': 2}

def identity(path):
    path = Path(path).resolve()
    data = path.read_bytes()
    return {'file': str(path), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}

def lexical(name):
    return '$R' + ''.join('_' + str(ord(c)) for c in name)

def definitions(text):
    result = {}
    for name in NAMES:
        prefix = 'G[' + json.dumps(name) + ']='
        rows = [line for line in text.splitlines() if line.startswith(prefix)]
        assert len(rows) == 1, name
        result[name] = rows[0]
    return result

def derive(source, roots):
    assert '$lambdaRegion' not in source
    ds = definitions(source)
    mit = ds['mit']
    start = mit.index('(()=>{') + len('(()=>{')
    end = mit.index('const $guards=', start)
    declarations = mit[start:end]
    # The checked lexical-only compiler is a required control, not optional.
    assert 'Object.create(null)' not in declarations and '$R[' not in declarations
    assert set(re.findall(r'function (\$R(?:_\d+)+)\(', declarations)) == set(map(lexical, SMALL))
    loop_start = mit.index('for(;;){', mit.index('/* private scalar region */'))
    loop_end = parser.close(mit, loop_start + len('for(;;)')) + 1
    loop = mit[loop_start:loop_end]
    assert not any(x in loop for x in ['get(G,', 'callOwned(', 'jump('])
    bindings = {name: lexical(name) for name in SMALL}
    bindings.update(mit='$lambdaRegionMit', pix='$lambdaRegionPix', bkt='$lambdaRegionBkt')

    def private(expr):
        changed = parser.private_calls(expr, set(bindings))
        changed = re.sub(r'\$H\[("[^"\\]+")\]', lambda m: bindings[json.loads(m[1])], changed)
        assert not any(x in changed for x in ['get(G,', 'callOwned(', 'jump(', '$H['])
        return changed

    shared = declarations
    shared += 'function $lambdaRegionMit($count,' + ','.join('$s' + str(i) for i in range(1, 7)) + '){'
    shared += 'if($count===0n)return $s6;let $s0=$count-1n;' + loop + '}'
    extra_helpers = ''
    for name in ['pix', 'bkt']:
        body = parser.callback(ds[name], 'fn(2,function(a){')
        extra_helpers += 'function ' + bindings[name] + '(' + ','.join(body['params']) + '){return ' + private(body['expr']) + ';}'
    changed = dict(ds)
    evidence = []
    captured = set()
    for root in roots:
        n = ARITIES[root]
        original = ds[root]
        marker = 'fn(' + str(n) + ',function(a){'
        body = parser.callback(original, marker)
        assert len(body['params']) == n
        guards = ['pix', 'mit', 'asr8', 'sel', 'sel.go', 'b2u'] if root == 'pix' else NAMES
        checks = []
        for at, name in enumerate(body['params']):
            if at == 1:
                checks.append('(typeof ' + name + '==="bigint"&&' + name + '>=0n&&' + name + '<=281474976710655n)')
            else:
                checks.append('(typeof ' + name + '==="number"&&Number.isInteger(' + name + ')&&' + name + '>=0&&' + name + '<=4294967295)')
        prefix = 'G[' + json.dumps(root) + ']='
        fast = private(body['expr'])
        replacement = prefix + 'scalarCapture(' + json.dumps(root) + ',(()=>{' + shared
        if root == 'rpix':
            replacement += extra_helpers
        replacement += 'const $lambdaRegionGuards=' + json.dumps(guards, separators=(',', ':')) + ';'
        replacement += 'return fn(' + str(n) + ',exactCode(function(a,$entered){' + body['prefix']
        replacement += 'if($entered&&' + '&&'.join(checks) + '&&scalarGuard($lambdaRegionGuards))return ' + fast + ';'
        replacement += 'return ' + body['expr'] + ';}));})());'
        changed[root] = replacement
        captured.update(guards)
        evidence.append({'root': root, 'arity': n, 'guards': guards, 'slotPrefix': body['prefix'],
                         'original': original, 'replacement': replacement})
    # Register original compiler descriptors, without changing their callback.
    for name in captured - set(roots):
        prefix = 'G[' + json.dumps(name) + ']='
        if not ds[name].startswith(prefix + 'scalarCapture('):
            changed[name] = prefix + 'scalarCapture(' + json.dumps(name) + ',' + ds[name][len(prefix):-1] + ');'
            evidence.append({'captureOnly': name, 'original': ds[name], 'replacement': changed[name]})
    output = source
    for name in NAMES:
        assert source.count(ds[name] + '\n') == 1
        output = output.replace(ds[name] + '\n', changed[name] + '\n')
    return output, evidence

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('source', type=Path)
    ap.add_argument('out', type=Path)
    args = ap.parse_args()
    source = args.source.resolve()
    receipt = Path(str(source) + '.json')
    checked = json.loads(receipt.read_text())
    assert checked['complete'] and checked['observation']['checked']
    assert checked['output']['sha256'] == identity(source)['sha256']
    attempt = Path(checked['attempt']['file'])
    assert attempt.parent.name == 'attempt-08', 'Frozen lexical-only baseline required'
    assert checked['attempt']['sha256'] == identity(attempt)['sha256']
    inputs = [identity(p) for p in [source, receipt, attempt, PLAN, PARSER, Path(__file__)]]
    args.out.mkdir(parents=True, exist_ok=False)
    shutil.copyfile(Path(__file__), args.out / 'consumed-derive.py')
    shutil.copyfile(PLAN, args.out / 'plan.md')
    shutil.copyfile(source, args.out / 'baseline.mjs')
    report = {'kind': 'phase30-ordinary-scalar-lambda-region', 'complete': False, 'inputs': inputs,
              'variants': {}, 'compilerChanged': False, 'runtimeChanged': False,
              'scope': 'Stable host intrinsics; exactCode privilege; original generic/raw fallback; primitive scalar inputs; live closure guards.',
              'correctness': 'not run', 'timing': 'not run'}
    try:
        for label, roots in [('pix', ['pix']), ('rpix', ['rpix']), ('both', ['pix', 'rpix'])]:
            output, edits = derive(source.read_text(), roots)
            target = args.out / (label + '.mjs')
            target.write_text(output)
            report['variants'][label] = {'roots': roots, 'output': identity(target), 'edits': edits}
        report['complete'] = True
        report['baseline'] = identity(args.out / 'baseline.mjs')
    except Exception as error:
        report['error'] = repr(error)
        raise
    finally:
        (args.out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': True, 'out': str(args.out)}))

if __name__ == '__main__':
    main()
