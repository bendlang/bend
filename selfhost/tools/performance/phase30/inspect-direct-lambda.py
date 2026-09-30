#!/usr/bin/env python3
"""Derive the prospectively scoped, guarded five-site Mandelbrot call ablation."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'selfhost/build/phase29/transfer-04/mandelbrot/candidate.mjs'
PLAN = ROOT / 'design/phase30/direct-leading-lambda-amendment.md'
FOLLOWUP = ROOT / 'design/phase30/direct-leading-lambda-callable-guard.md'
EXPECTED = '11977282d5c364224eb3ac540fe3885345531d5819a68e5facfc72b03a836033'


def identity(path):
    b = path.read_bytes()
    return {'file': str(path.relative_to(ROOT)), 'sha256': hashlib.sha256(b).hexdigest(), 'bytes': len(b)}


def mask(text):
    return re.sub(r'/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', lambda m: ' ' * len(m[0]), text)


def rewrite_calls(line, name, count):
    prefix = 'call(get(G,' + json.dumps(name) + '),['
    hits = []
    begin = 0
    masked = mask(line)
    while (start := line.find(prefix, begin)) >= 0:
        arg_start = start + len(prefix)
        depth, at = 1, arg_start
        while depth and at < len(line):
            if masked[at] == '[':
                depth += 1
            elif masked[at] == ']':
                depth -= 1
            at += 1
        if depth or line[at] != ')':
            raise ValueError('Unexpected call argument framing')
        hits.append((start, at + 1, line[arg_start:at - 1]))
        begin = at + 1
    if len(hits) != count:
        raise ValueError(f'Expected {count} sites for {name}, saw {len(hits)}')
    for start, end, args in reversed(hits):
        line = line[:start] + '$p30_invoke_' + name + '(get(G,' + json.dumps(name) + '),' + args + ')' + line[end:]
    return line


def derive(text):
    helpers = {}
    for name, arity in [('asr8', 1), ('sel', 3)]:
        pattern = r'^G\["' + name + r'"\]=fn\(' + str(arity) + r',function\(a\)\{((?:const x\d+=a\[\d+\];)+)(.*)\}\);$'
        m = re.search(pattern, text, re.M)
        if not m:
            raise ValueError(f'Unrecognized leading-lambda body {name}')
        params = re.findall(r'const (x\d+)=a\[(\d+)\];', m[1])
        if [int(p[1]) for p in params] != list(range(arity)):
            raise ValueError('Unexpected parameter binding')
        probe = m[2].replace('(a,n)=>n>=32n?0:(a>>>Number(n))>>>0', '__known_native_shift')
        if re.search(r'(?<![\w$])(?:a|this)\b', mask(probe)):
            # Remove only the exact known native-shift closure with its own a;
            # every remaining use would expose the original parameter vector.
            raise ValueError('Parameter vector or this escapes body')
        helpers[name] = {'arity': arity, 'params': [p[0] for p in params], 'body': m[2]}
    lines = text.splitlines(keepends=True)
    indices = [i for i, line in enumerate(lines) if line.startswith('G["mit"]=')]
    if len(indices) != 1:
        raise ValueError('Expected one mit definition')
    i = indices[0]
    lines[i] = rewrite_calls(lines[i], 'asr8', 3)
    lines[i] = rewrite_calls(lines[i], 'sel', 2)
    declarations = '''
// Phase30 disposable direct-leading-lambda ablation: public descriptors unchanged.
const $p30_function_prototype=Function.prototype;
const $p30_function_call=Object.getOwnPropertyDescriptor($p30_function_prototype, 'call').value;
function $p30_fast(f, original, arity, code, bound) {
  if (f !== original) return false;
  if (Object.getPrototypeOf(f) !== Object.prototype) return false;
  for (const key of ['io', 'typeName']) {
    if (Object.getOwnPropertyDescriptor(f, key) || Object.getOwnPropertyDescriptor(Object.prototype, key)) return false;
  }
  if (Object.getOwnPropertyDescriptor(code, 'call') || Object.getPrototypeOf(code) !== $p30_function_prototype) return false;
  const invoke = Object.getOwnPropertyDescriptor($p30_function_prototype, 'call');
  if (!invoke || !Object.hasOwn(invoke, 'value') || invoke.value !== $p30_function_call) return false;
  const ad = Object.getOwnPropertyDescriptor(f, 'arity');
  const cd = Object.getOwnPropertyDescriptor(f, 'code');
  const ed = Object.getOwnPropertyDescriptor(f, 'env');
  const bd = Object.getOwnPropertyDescriptor(f, 'bound');
  if (!ad || !cd || !ed || !bd) return false;
  if (!Object.hasOwn(ad, 'value') || !Object.hasOwn(cd, 'value') || !Object.hasOwn(ed, 'value') || !Object.hasOwn(bd, 'value')) return false;
  if (ad.value !== arity || cd.value !== code || ed.value !== null || bd.value !== bound) return false;
  return Object.getOwnPropertyDescriptor(bound, 'length').value === 0;
}
'''
    for name, row in helpers.items():
        params = ','.join(row['params'])
        declarations += f'const $p30_original_{name}=G[{json.dumps(name)}];\n'
        declarations += f'const $p30_code_{name}=$p30_original_{name}.code;\n'
        declarations += f'const $p30_bound_{name}=$p30_original_{name}.bound;\n'
        declarations += f'function $p30_body_{name}({params}){{{row["body"]}}}\n'
        declarations += f'function $p30_invoke_{name}(f,{params}){{return $p30_fast(f,$p30_original_{name},{row["arity"]},$p30_code_{name},$p30_bound_{name})?force($p30_body_{name}({params})):call(f,[{params}]);}}\n'
    joined = ''.join(lines)
    marker = '\nexport {G,call,list,ctor};'
    if joined.count(marker) != 1:
        raise ValueError('Unexpected library exports')
    return joined.replace(marker, declarations + marker), helpers


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    if identity(SOURCE)['sha256'] != EXPECTED:
        raise ValueError('Input differs from frozen Phase29 module')
    transformed, helpers = derive(SOURCE.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    (args.out / 'baseline.mjs').write_bytes(SOURCE.read_bytes())
    target = args.out / 'guarded.mjs'
    target.write_text(transformed)
    upstream = ROOT / 'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs'
    (args.out / 'upstream.mjs').write_bytes(upstream.read_bytes())
    (args.out / 'derive.py').write_bytes(Path(__file__).read_bytes())
    (args.out / 'plan.md').write_bytes(PLAN.read_bytes())
    (args.out / 'callable-plan.md').write_bytes(FOLLOWUP.read_bytes())
    report = {'kind': 'phase30-generated-js-guarded-leading-lambda-prototype', 'complete': True,
              'inputs': [identity(SOURCE), identity(upstream), identity(PLAN), identity(FOLLOWUP), identity(Path(__file__).resolve())],
              'output': identity(target.resolve()), 'changedFunction': 'mit', 'changedCallSites': {'asr8': 3, 'sel': 2},
              'helpers': {name: {'arity': row['arity'], 'params': row['params']} for name, row in helpers.items()},
              'compilerChanged': False, 'runtimeSourceChanged': False,
              'correctness': 'not run', 'measurement': 'not run',
              'scope': 'Only five direct calls in mit; standard intrinsic Object/Reflect/Array behavior required.'}
    (args.out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': True, 'out': str(args.out), 'output': report['output']}))


if __name__ == '__main__':
    main()
