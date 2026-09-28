"""Count explicitly declared maintained surfaces; no compiler or module execution."""
import argparse
import hashlib
import json
import re
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('config', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
config_file = args.config.resolve(strict=True)
config = json.loads(config_file.read_text())
allowed = {'shared', 'active', 'historical', 'tests', 'experimental', 'dependencies'}
identity = lambda file: {'file': str(file), 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()}
report = {
    'kind': 'phase13-declared-complexity-audit',
    'complete': False,
    'method': 'Physical/nonblank lines and bytes of explicit unique files. Concepts are author-declared obligations, not inferred complexity. Shared includes current and historical code in one file. No compiler execution.',
    'config': identity(config_file),
    'tool': identity(Path(__file__).resolve()),
    'variants': {},
}
imports = re.compile(r'''(?:\bfrom\s*|\bimport\s*)(['"])([^'"\n]+)\1''')
for name, variant in config['variants'].items():
    seen, files, totals, import_rows = set(), [], {}, []
    for category, names in variant['files'].items():
        if category not in allowed:
            raise ValueError('Unknown accounting category: ' + category)
        counts = {'files': 0, 'physical': 0, 'nonblank': 0, 'bytes': 0}
        for value in names:
            file = (config_file.parent / value).resolve(strict=True)
            if file in seen:
                raise ValueError('A file cannot be hidden by counting it in two categories: ' + str(file))
            seen.add(file)
            raw = file.read_bytes()
            text = raw.decode('utf-8')
            lines = text.splitlines()
            row = {**identity(file), 'category': category, 'bytes': len(raw),
                   'physical': len(lines), 'nonblank': sum(bool(line.strip()) for line in lines)}
            files.append(row)
            counts['files'] += 1
            for key in ('physical', 'nonblank', 'bytes'):
                counts[key] += row[key]
            if file.suffix in ('.mjs', '.js', '.ts'):
                for _, module in imports.findall(text):
                    if not module.startswith('node:'):
                        import_rows.append({'importer': str(file), 'specifier': module})
        totals[category] = counts
    for row in import_rows:
        specifier = row['specifier']
        target = (Path(row['importer']).parent / specifier).resolve() if specifier.startswith('.') else None
        row['accounted'] = target in seen if target else specifier in variant.get('externalPackages', {})
        row['resolved'] = str(target) if target else None
    maintained = [row for row in files if row['category'] != 'experimental']
    report['variants'][name] = {
        'files': files, 'categories': totals,
        'maintainedTotals': {key: sum(row[key] for row in maintained) for key in ('physical', 'nonblank', 'bytes')},
        'declaredConcepts': variant.get('concepts', []),
        'externalPackages': variant.get('externalPackages', {}),
        'importAudit': import_rows,
        'unaccountedImports': [row for row in import_rows if not row['accounted']],
        'importAuditLimitation': 'Conservative text scan of static import/from strings; dynamic imports and generated dependencies require explicit reviewer accounting.',
    }
for variant in report['variants'].values():
    for row in variant['files']:
        if identity(Path(row['file']))['sha256'] != row['sha256']:
            raise RuntimeError('Input changed: ' + row['file'])
if identity(config_file) != report['config']:
    raise RuntimeError('Configuration changed')
report['complete'] = True
with args.output.open('x') as stream:
    json.dump(report, stream, indent=2)
    stream.write('\n')
print(json.dumps({'complete': True, 'variants': {name: row['maintainedTotals'] for name, row in report['variants'].items()}}))
