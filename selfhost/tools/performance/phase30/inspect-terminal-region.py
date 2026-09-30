#!/usr/bin/env python3
"""Derive four frozen hchunk ablations without changing compiler/runtime sources."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'selfhost/build/phase30/transfer-07/mandelbrot/candidate.mjs'
PLAN = ROOT / 'design/phase30/terminal-record-nested-region.md'
EXPECTED = '6c5ebcc9f07c0294e876754a6dce168fa0fee489fd2038bc56efe914d24abd3e'
NAMES = ['hchunk', 'pix', 'bkt', 'mit', 'asr8', 'sel', 'sel.go', 'b2u']
ARITIES = {'pix': 2, 'bkt': 2, 'mit': 7, 'asr8': 1, 'sel': 3, 'sel.go': 3, 'b2u': 1}


def identity(path):
    raw = path.read_bytes()
    return {'file': str(path.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def mask(text):
    return re.sub(r'/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
                  lambda m: ' ' * len(m[0]), text)


def close(text, start):
    masked = mask(text)
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack = [pairs[masked[start]]]
    for pos in range(start + 1, len(masked)):
        char = masked[pos]
        if char in pairs:
            stack.append(pairs[char])
        elif char in ')]}':
            if not stack or char != stack.pop():
                raise ValueError('Unbalanced generated JavaScript')
            if not stack:
                return pos
    raise ValueError('Unterminated generated JavaScript')


def split(text):
    masked = mask(text)
    depth, start, parts = 0, 0, []
    for pos, char in enumerate(masked):
        if char in '([{': depth += 1
        elif char in ')]}': depth -= 1
        elif char == ',' and depth == 0:
            parts.append(text[start:pos]); start = pos + 1
    if text[start:]: parts.append(text[start:])
    return parts


def application(expr):
    """Decode only an exact generated callOwned/jump spine; retain argument text."""
    args = []
    while expr.startswith(('callOwned(', 'jump(')):
        left = expr.index('(')
        if close(expr, left) != len(expr) - 1:
            raise ValueError('Unexpected application suffix')
        parts = split(expr[left + 1:-1])
        if len(parts) != 2 or not parts[1].startswith('[') or not parts[1].endswith(']'):
            raise ValueError('Unexpected application vector')
        args = split(parts[1][1:-1]) + args
        expr = parts[0]
    found = re.fullmatch(r'get\(G,"([^"\\]+)"\)', expr)
    return (found[1] if found else None), args


def private_calls(expr, admitted):
    """Rewrite exact saturated known spines, including calls nested in primitives."""
    at, output = 0, ''
    token = re.compile(r'(?<![\w$])(callOwned|jump)\(')
    while match := token.search(mask(expr), at):
        start = match.start(); end = close(expr, expr.index('(', start)) + 1
        original = expr[start:end]
        name, args = application(original)
        if name in admitted and len(args) == ARITIES[name]:
            replacement = '$H[' + json.dumps(name) + '](' + ','.join(private_calls(a, admitted) for a in args) + ')'
        else:
            left = original.index('(')
            replacement = original[:left + 1] + private_calls(original[left + 1:-1], admitted) + ')'
        output += expr[at:start] + replacement
        at = end
    return output + expr[at:]


def lets(expr):
    """Unroll the emitted single-binding IIFEs in their original evaluation order."""
    bindings = []
    while match := re.match(r'^\(\((x\d+),\)=>', expr):
        end = close(expr, 0)
        if expr[end + 1] != '(' or close(expr, end + 1) != len(expr) - 1:
            raise ValueError('Unexpected IIFE call')
        args = split(expr[end + 2:-1])
        if len(args) != 1: raise ValueError('Unexpected IIFE arity')
        bindings.append((match[1], args[0]))
        expr = expr[match.end():end]
    return bindings, expr


def callback(line, marker):
    start = line.index(marker) + len(marker)
    end = close(line, start - 1)
    body = line[start:end]
    match = re.match(r'((?:const x\d+=a\[\d+\];)+)return (.*);$', body)
    if not match: raise ValueError('Unexpected callback body')
    params = re.findall(r'const (x\d+)=a\[(\d+)\];', match[1])
    if [int(p[1]) for p in params] != list(range(len(params))):
        raise ValueError('Unexpected callback slot sequence')
    return {'start': start, 'end': end, 'prefix': match[1], 'params': [p[0] for p in params],
            'expr': match[2], 'body': body}


def derive(text, variant):
    lines = text.splitlines(keepends=True)
    definitions = {}
    for name in NAMES:
        found = [line.rstrip('\n') for line in lines if line.startswith('G[' + json.dumps(name) + ']=')]
        if len(found) != 1: raise ValueError('Expected one definition: ' + name)
        definitions[name] = found[0]
    hchunk = definitions['hchunk']
    successor = callback(hchunk, 'matcher1p("Succ",1,11,()=>(0,function(a){')
    zero = callback(hchunk, 'matcher("Zero",()=>fn(10,function(a){')
    if len(successor['params']) != 11 or len(zero['params']) != 10:
        raise ValueError('Unexpected hchunk slots')
    expected_zero = 'build("Hl",[' + ''.join('()=>' + p + ',' for p in zero['params'][2:]) + '])'
    if zero['expr'] != expected_zero: raise ValueError('Unexpected terminal constructor')
    if 'constructorNative["Hl"]=false;constructorOwn["Hl"]="Hl";constructors["Hl"]=["h0","h1","h2","h3","h4","h5","h6","h7",];' not in text:
        raise ValueError('Unexpected Hl representation')
    if re.search(r'^G\["Hl"\]=', text, re.M): raise ValueError('Unexpected callable Hl')
    bindings, tail = lets(successor['expr'])
    owner, next_args = application(tail)
    if owner != 'hchunk' or len(next_args) != 11 or next_args[0] != successor['params'][0] or len(bindings) != 10:
        raise ValueError('Unexpected hchunk transfer')
    admitted = set() if variant == 'outer' else {'pix', 'bkt', 'b2u', 'sel', 'sel.go', 'asr8'}
    mit = definitions['mit']
    declarations = '// Disposable Phase30 terminal-record region: ' + variant + '.\n'
    declarations += 'const $chunkGuards=' + json.dumps(NAMES, separators=(',', ':')) + ';\n'
    helper_start = mit.index('const $R=Object.create(null);')
    helper_end = mit.index('const $guards=')
    declarations += mit[helper_start:helper_end].replace('$R', '$H') + '\n'
    for name in ['pix', 'bkt']:
        helper = callback(definitions[name], 'fn(2,function(a){')
        body = private_calls(helper['expr'], admitted | ({'mit'} if variant == 'nested' else set()))
        # The retained public mit tail is forced at the same caller demand point.
        if name == 'pix' and variant != 'nested': body = 'force(' + body + ')'
        declarations += '$H[' + json.dumps(name) + ']=function(' + ','.join(helper['params']) + '){return ' + body + ';};\n'
    loop_start = mit.index('for(;;){', mit.index('/* private scalar region */'))
    loop_end = close(mit, loop_start + len('for(;;)')) + 1
    mit_loop = mit[loop_start:loop_end].replace('$R', '$H')
    if any(t in mit_loop for t in ['get(G,', 'callOwned(', 'jump(']):
        raise ValueError('Unexpected public application inside private mit')
    declarations += '$H["mit"]=function($count,' + ','.join('$s' + str(i) for i in range(1, 7)) + '){if($count===0n)return $s6;let $s0=$count-1n;' + mit_loop + '};\n'
    slots = ['$h' + str(i) for i in range(11)]
    outer = 'function $chunkLoop(' + ','.join(slots) + '){for(;;){'
    outer += ''.join('const ' + p + '=' + s + ';' for p, s in zip(successor['params'], slots))
    outer += ''.join('const ' + name + '=' + private_calls(expr, admitted) + ';' for name, expr in bindings)
    outer += ''.join('const $next' + str(i) + '=' + private_calls(expr, admitted) + ';' for i, expr in enumerate(next_args))
    outer += 'if($next0===0n){const a=[' + ','.join('$next' + str(i) for i in range(1, 11)) + '];' + zero['body'] + '}'
    outer += '$h0=$next0-1n;' + ''.join('$h' + str(i) + '=$next' + str(i) + ';' for i in range(1, 11)) + 'continue;}}\n'
    declarations += outer
    checks = []
    for i, p in enumerate(successor['params']):
        if i in [0, 2]:
            checks.append('(typeof ' + p + '==="bigint"&&' + p + '>=0n&&' + p + ('<' if i == 0 else '<=') + '281474976710655n)')
        else:
            checks.append('(typeof ' + p + '==="number"&&Number.isInteger(' + p + ')&&' + p + '>=0&&' + p + '<=4294967295)')
    new_body = successor['prefix'] + 'if($entered&&' + '&&'.join(checks) + '&&scalarGuard($chunkGuards))return $chunkLoop(' + ','.join(successor['params']) + ');return ' + successor['expr'] + ';'
    # Replace only the successor's (0,function(a){...}) expression. Outer Zero is byte-identical.
    begin = successor['start'] - len('(0,function(a){')
    finish = successor['end'] + 2
    if hchunk[begin:successor['start']] != '(0,function(a){' or hchunk[successor['end']:finish] != '})':
        raise ValueError('Unexpected callback expression framing')
    changed = hchunk[:begin] + 'exactCode(function(a,$entered){' + new_body + '})' + hchunk[finish:]
    prefix = 'G["hchunk"]='
    changed = prefix + 'scalarCapture("hchunk",' + changed[len(prefix):-1] + ');'
    for i, line in enumerate(lines):
        if line.rstrip('\n') == hchunk: lines[i] = declarations + changed + '\n'
        for name in ['pix', 'bkt']:
            if line.rstrip('\n') == definitions[name]:
                prefix = 'G[' + json.dumps(name) + ']='
                lines[i] = prefix + 'scalarCapture(' + json.dumps(name) + ',' + definitions[name][len(prefix):-1] + ');\n'
    return ''.join(lines), {'hchunkBindings': bindings, 'hchunkTailArguments': next_args,
                           'guardClosure': NAMES, 'privateCalls': sorted(admitted | ({'mit'} if variant == 'nested' else set())),
                           'sourceCallback': successor, 'terminalCallback': zero}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if identity(SOURCE)['sha256'] != EXPECTED: raise ValueError('Frozen attempt07 source changed')
    args.out.mkdir(parents=True, exist_ok=False)
    (args.out / 'derive.py').write_bytes(Path(__file__).read_bytes())
    (args.out / 'plan.md').write_bytes(PLAN.read_bytes())
    (args.out / 'baseline.mjs').write_bytes(SOURCE.read_bytes())
    outputs, evidence = [], {}
    for variant in ['outer', 'acyclic', 'nested']:
        target = args.out / (variant + '.mjs')
        body, proof = derive(SOURCE.read_text(), variant)
        target.write_text(body); outputs.append(identity(target)); evidence[variant] = proof
    report = {'kind': 'phase30-generated-terminal-record-nested-Nat-region', 'complete': True,
              'inputs': [identity(p) for p in [SOURCE, PLAN, Path(__file__)]],
              'outputs': [identity(args.out / 'baseline.mjs'), *outputs], 'derivation': evidence,
              'compilerChanged': False, 'runtimeSourceChanged': False,
              'correctness': 'not run', 'measurement': 'not run',
              'scope': 'Exact entered hchunk successor; primitive scalar inputs; eight original descriptors; standard host intrinsics; original build forcing.'}
    (args.out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': True, 'outputs': outputs}))


if __name__ == '__main__': main()
