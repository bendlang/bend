#!/usr/bin/env python3
"""Remove only native applications within the already checked private row."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PARSER = HERE / 'inspect-terminal-region.py'
spec = importlib.util.spec_from_file_location('owned_native_parser', PARSER)
parser = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parser)
ARITIES = {'Array.new': 3, 'Array.get': 3, 'Array.set': 4}

def ident(p):
    p = Path(p).resolve()
    raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')

def replace_once(text, old, new):
    assert text.count(old) == 1, old
    return text.replace(old, new)

def rewrite(text, counts):
    at, output = 0, ''
    token = re.compile(r'(?<![\w$])(callOwned|jump)\(')
    while match := token.search(parser.mask(text), at):
        start = match.start()
        end = parser.close(text, text.index('(', start)) + 1
        original = text[start:end]
        name, args = parser.application(original)
        if name in ARITIES:
            assert len(args) == ARITIES[name] and args[0] == 'null'
            direct = '$Owned_native_' + name.split('.')[1] + '(' + ','.join(rewrite(a, counts) for a in args) + ')'
            replacement = 'force(' + direct + ')' if match[1] == 'callOwned' else direct
            counts[name] += 1
        else:
            left = original.index('(')
            replacement = original[:left + 1] + rewrite(original[left + 1:-1], counts) + ')'
        output += text[at:start] + replacement
        at = end
    return output + text[at:]

def derive(text):
    native = "native('Array.new',3,(_t,d,v)=>arrayfill(v,d,'^'));native('Array.get',3,(_t,a,i)=>arrayget(a,i));native('Array.set',4,(_t,a,i,v)=>arrayset(a,i,v));"
    assert text.count(native) == 1
    counts = dict.fromkeys(ARITIES, 0)
    rewrites, lines = [], []
    for line in text.splitlines(keepends=True):
        original = line
        if line.startswith('function $Owned_cell') and '_fields(' in line:
            line = rewrite(line, counts)
        elif line.startswith('G["row.probe"]='):
            before, fast = line.split('/* owned row entry */', 1)
            fast, after = fast.split('/* owned row generic */', 1)
            before = replace_once(before, '&&scalarGuard($Owned_guards)', '&&$Owned_arrayMarkersSafe()&&scalarGuard($Owned_guards)')
            line = before + '/* owned row entry */' + rewrite(fast, counts) + '/* owned row generic */' + after
        if line != original:
            rewrites.append({'before': original, 'after': line})
        lines.append(line)
    assert counts == {'Array.new': 4, 'Array.get': 4, 'Array.set': 1}, counts
    changed = ''.join(lines)
    helpers = '''// Additional closed-array root eligibility; never a per-native-call guard.
const $Owned_arrayPrototype=Array.prototype,$Owned_arrayParent=Object.prototype;
function $Owned_arrayMarkersSafe(){
 if(Object.getPrototypeOf($Owned_arrayPrototype)!==$Owned_arrayParent)return false;
 for(const k of ['request','bounce','build','code'])if(Object.getOwnPropertyDescriptor($Owned_arrayPrototype,k))return false;
 return true;
}
function $Owned_native_new(_t,d,v){return arrayfill(v,d,'^');}
function $Owned_native_get(_t,a,i){return arrayget(a,i);}
function $Owned_native_set(_t,a,i,v){return arrayset(a,i,v);}
'''
    changed = replace_once(changed, 'const $Owned_guards=', helpers + 'const $Owned_guards=')
    for line in text.splitlines():
        if line.startswith('G[') and not line.startswith('G["row.probe"]='):
            assert line in changed.splitlines(), line
    assert changed.count(native) == 1
    return changed, {'staticNativeSites': counts, 'rewrites': rewrites, 'helpers': helpers}

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('source', type=Path)
    ap.add_argument('out', type=Path)
    a = ap.parse_args()
    a.source = a.source.resolve(); a.out = a.out.resolve()
    a.out.mkdir(parents=True, exist_ok=False)
    design = ROOT / 'design/phase30/closed-owned-row-native-calls.md'
    controls = HERE / 'prototype-owned-controls.mjs'
    counts = HERE / 'prototype-owned-counts.mjs'
    inputs = [Path(__file__), PARSER, design, a.source / 'derive.json', a.source / 'points.json', controls, counts]
    record = {'kind': 'phase30-owned-native-derivation', 'complete': False, 'inputs': [ident(p) for p in inputs], 'variants': {}}
    save(a.out / 'derive.json', record)
    try:
        prior = json.loads((a.source / 'derive.json').read_text())
        assert prior['complete']
        for name, entry in prior['variants'].items():
            assert ident(entry['file']) == entry
            target = a.out / (name + '.mjs')
            shutil.copyfile(entry['file'], target)
            record['variants'][name] = ident(target)
        changed, proof = derive((a.source / 'private_row.mjs').read_text())
        target = a.out / 'private_native.mjs'; target.write_text(changed)
        record['variants']['private_native'] = ident(target); record['rewrites'] = proof
        shutil.copyfile(a.source / 'points.json', a.out / 'points.json')
        original = controls.read_text()
        adapted = replace_once(original, "const variants=['baseline','private_cell','private_scalar','private_row'];", "const variants=['baseline','private_cell','private_scalar','private_row','private_native'];")
        assert adapted.count('modules.slice(0,4)') == 1 and adapted.count('i<4') == 1 and adapted.count('files.slice(0,4)') == 1
        adapted = adapted.replace('modules.slice(0,4)', 'modules.slice(0,variants.length)').replace('i<4', 'i<variants.length').replace('files.slice(0,4)', 'files.slice(0,variants.length)')
        (a.out / 'controls.mjs').write_text(adapted)
        adapted_counts = replace_once(counts.read_text(), "['baseline','private_cell','private_scalar','private_row']", "['baseline','private_cell','private_scalar','private_row','private_native']")
        (a.out / 'counts.mjs').write_text(adapted_counts)
        record['adaptedTools'] = [ident(a.out / 'controls.mjs'), ident(a.out / 'counts.mjs')]
        shutil.copyfile(Path(__file__), a.out / 'consumed-derive.py'); shutil.copyfile(design, a.out / 'design.md')
        record['complete'] = True
    except Exception as error:
        record['error'] = repr(error)
        raise
    finally:
        save(a.out / 'derive.json', record)
    print(json.dumps({'complete': True, 'out': str(a.out)}))

if __name__ == '__main__':
    main()
