#!/usr/bin/env python3
"""Hash-bound static inventory of matched source functions in two JS emitters.

This is an inspector, not a JavaScript parser or program profiler. It admits the
fixed library-emission formats below and fails closed if those formats change.
Counts are syntactic sites in source-defined function bodies; runtime support,
Base functions, registration metadata, and public export adapters are excluded.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
RUNTIME = ROOT / 'selfhost/build/phase29/attempt-04/snapshot/src/runtime.mjs'
CASES = {
    'mandelbrot': ('mandelbrot.bend', 'runtime-01'),
    'editdist': ('editdist.bend', 'runtime-01'),
    'lexer': ('lexer.bend', 'runtime-01'),
    'raytrace': ('raytrace-typed.bend', 'runtime-03-raytrace'),
}
SELECTED = {
    'mandelbrot': ['b2u', 'sel.go', 'sel', 'asr8', 'mit', 'hchunk', 'rcol'],
    'editdist': ['cell', 'cell.f1', 'cell.f2', 'cell.f3', 'cell.f4', 'row', 'dp'],
    'lexer': ['prng', 'cls', 'step.at', 'step', 'lex', 'gen', 'batch'],
    'raytrace': ['fl', 'nearest', 'nearest.t', 'isect5', 'colf', 'rowf', 'trace'],
}


def ident(path):
    data = path.read_bytes()
    return {'file': str(path.relative_to(ROOT)), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}


def mask_literals(text):
    """Preserve length while masking comments and quoted JS string literals."""
    pattern = re.compile(r'/\*[\s\S]*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
    if '`' in text:
        raise ValueError('Template literal needs explicit inspector support')
    return pattern.sub(lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), text)


def sites(text):
    mask = mask_literals(text)
    helpers = ['call', 'jump', 'fn', 'matcher', 'matcher1', 'matcher1p', 'project', 'build', 'ctor', 'get', 'arrayget', 'arrayset', 'force']
    counts = {name: len(re.findall(r'(?<![\w$])' + name + r'\s*\(', mask)) for name in helpers}
    counts.update({
        'direct_user_calls': len(re.findall(r'(?<!function )(?<![\w$])\$[\w$]+\$\s*\(', mask)),
        'loop_sites': len(re.findall(r'\b(?:for|while)\s*\(', mask)),
        'private_nat_loop_markers': text.count('/* private Nat loop */'),
        'primitive_markers': text.count('/* primitive */'),
        'bigint_literal_sites': len(re.findall(r'(?<![\w$])\d+n\b', mask)),
        'longest_consecutive_call_prefix': max((m[0].count('call') for m in re.finditer(r'(?:call\s*\(\s*)+', mask)), default=0),
        'record_object_literals': len(re.findall(r'\{\s*\$\s*:', mask)),
    })
    refs = re.findall(r'get\(G,"([^"\\]+)"\)', text)
    return {'sites': counts, 'global_refs': {name: refs.count(name) for name in sorted(set(refs))}}


def function_record(name, text, start, end):
    return {'name': name, 'startLine': start, 'endLine': end,
            'bytes': len(text.encode()), 'sha256': hashlib.sha256(text.encode()).hexdigest(),
            **sites(text)}


def extract_selfhost(text, names):
    out = {}
    for index, line in enumerate(text.splitlines(keepends=True), 1):
        m = re.match(r'^G\["([^"\\]+)"\]=', line)
        if m and m[1] in names:
            if m[1] in out or not line.rstrip().endswith(';'):
                raise ValueError('Unexpected selfhost global-definition format')
            out[m[1]] = (line, index, index)
    return out


def extract_upstream(text, names):
    out = {}
    for m in re.finditer(r'^function (\$[\w$]+\$)\([^\n]*\) \{\n[\s\S]*?^\}\n', text, re.M):
        name = m[1][1:-1].replace('$', '.')
        if name in names:
            if name in out:
                raise ValueError('Duplicate upstream function')
            start = text[:m.start()].count('\n') + 1
            out[name] = (m[0], start, start + m[0].count('\n') - 1)
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    report = {'kind': 'phase30-static-emission-comparison', 'complete': False,
              'scope': 'Syntactic sites, not executed operations or runtime shares. Source-defined functions only; matches keyed by source name.',
              'tool': ident(Path(__file__).resolve()), 'runtime': ident(RUNTIME),
              'upstreamCommit': '018751270e800bc222a93dad7f257083ee53a5f7',
              'candidateApiSha256': '10510efda268bac1f31cc8fed87a9315e8f9edfa15aad6b90b0d96756c217b11',
              'acquisition': ident(ROOT / 'selfhost/build/phase29/transfer-04/report.json'), 'cases': []}
    for case, (source_name, upstream_dir) in CASES.items():
        source = ROOT / 'selfhost/tools/performance/phase28/corpus' / source_name
        old = ROOT / 'selfhost/build/phase28' / upstream_dir / case / 'upstream.mjs'
        new = ROOT / 'selfhost/build/phase29/transfer-04' / case / 'candidate.mjs'
        names = re.findall(r'^def ([\w.]+)\(', source.read_text(), re.M)
        if len(names) != len(set(names)):
            raise ValueError('Unexpected duplicate source names')
        texts = {'upstream': old.read_text(), 'selfhost': new.read_text()}
        if not texts['selfhost'].startswith(RUNTIME.read_text()):
            raise ValueError('Candidate runtime prefix differs')
        extracted = {'upstream': extract_upstream(texts['upstream'], names),
                     'selfhost': extract_selfhost(texts['selfhost'], names)}
        matched = sorted(set(extracted['upstream']) & set(extracted['selfhost']))
        missing = {side: sorted(set(names) - set(rows)) for side, rows in extracted.items()}
        if missing != {'upstream': ['main'], 'selfhost': []}:
            raise ValueError(f'Unexpected missing functions: {case} {missing}')
        entry = {'id': case, 'source': ident(source), 'outputs': {'upstream': ident(old), 'selfhost': ident(new)},
                 'sourceDefinitions': len(names), 'matchedDefinitions': len(matched), 'excluded': missing,
                 'selfhostRuntimePrefixBytes': len(RUNTIME.read_bytes()), 'functions': [], 'selected': SELECTED[case]}
        for name in matched:
            row = {'name': name}
            for side in ['upstream', 'selfhost']:
                text, start, end = extracted[side][name]
                row[side] = function_record(name, text, start, end)
                if name in SELECTED[case]:
                    dest = args.out / case
                    dest.mkdir(exist_ok=True)
                    (dest / (name + '.' + side + '.js.txt')).write_text(text)
            entry['functions'].append(row)
        entry['matchedBodyBytes'] = {side: sum(row[side]['bytes'] for row in entry['functions']) for side in texts}
        entry['totals'] = {side: {key: sum(row[side]['sites'][key] for row in entry['functions'])
                                for key in entry['functions'][0][side]['sites']
                                if key != 'longest_consecutive_call_prefix'} for side in texts}
        entry['maximumConsecutiveCallPrefix'] = {side: max(row[side]['sites']['longest_consecutive_call_prefix'] for row in entry['functions']) for side in texts}
        report['cases'].append(entry)
    report['complete'] = True
    (args.out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': True, 'out': str(args.out), 'matched': {x['id']: x['matchedDefinitions'] for x in report['cases']}}))


if __name__ == '__main__':
    main()
