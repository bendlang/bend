#!/usr/bin/env python3
"""Copy a verified bundle and replace explicit modules for an unchecked JS screen."""
import argparse
import json
from pathlib import Path
import shutil

from run import load_bundle, relative_path, require, verify
from support import identity, save

HERE = Path(__file__).resolve().parent


def local_identity(file, root):
    item = identity(file)
    item['path'] = str(Path(file).relative_to(root))
    return item


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--from', dest='origin', type=Path, default=HERE / 'baseline/manifest.json')
    parser.add_argument('--replace', action='append', required=True, metavar='CASE=FILE')
    parser.add_argument('--out', type=Path, required=True, help='New directory; earlier outputs are preserved')
    parser.add_argument('--catalog', type=Path, default=HERE / 'catalog.json')
    args = parser.parse_args()
    catalog = json.loads(args.catalog.read_text())
    require(catalog.get('schemaVersion') == 1, 'Unsupported catalog')
    origin = json.loads(args.origin.read_text())
    roles = set(origin.get('roles', {}))
    require(roles in ({'baseline', 'typescript'}, {'candidate'}), 'Unsupported source bundle roles')
    source_role = 'baseline' if 'baseline' in roles else 'candidate'
    by_id = {case['id']: case for case in catalog['cases']}
    require(len(by_id) == len(catalog['cases']), 'Duplicate catalog cases')
    names = [case['id'] for case in origin['cases']]
    require(names and len(names) == len(set(names)) and all(name in by_id for name in names),
            'Source bundle contains empty, duplicate or unknown cases')
    require(all(name.replace('-', '').replace('_', '').isalnum() for name in names), 'Unsafe case ID')
    replacements = {}
    for spec in args.replace:
        require('=' in spec, 'Replacement must be CASE=FILE')
        name, file = spec.split('=', 1)
        require(name in names and name not in replacements, 'Unknown or duplicate replacement: ' + name)
        replacements[name] = Path(file).resolve()
    inputs = [identity(p) for p in [__file__, HERE / 'run.py', HERE / 'support.py', args.catalog]]
    catalog_hash = inputs[-1]['sha256']
    for name in names:
        case = by_id[name]
        inputs.append(verify(relative_path(args.catalog.parent, case['source']['path']), case['source']))
    replacement_inputs = {name: identity(file) for name, file in replacements.items()}
    require(all(0 < item['bytes'] <= 64 * 1024**2 for item in replacement_inputs.values()),
            'Replacement size outside supported bounds')
    inputs.extend(replacement_inputs.values())
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    manifest = dict(kind='bend-program-bundle', schemaVersion=1, complete=False,
                    upstreamCommit=catalog['upstreamCommit'], catalogSha256=catalog_hash,
                    roles={'candidate': dict(kind='prototype', checked=False,
                        label='Manual JavaScript prototype', sourceRole=source_role)}, cases=[])
    receipt = dict(kind='bend-program-prototype', schemaVersion=1, complete=False, checked=False,
                   scope='Manual generated-JavaScript experiment only. Same-source origin is a user assertion; '
                         'no compiler checking or output validation is performed. Run paired execution separately.',
                   inputs=inputs, sourceRole=source_role, replacements=[])
    save(out / 'manifest.json', manifest)
    save(out / 'prototype.json', receipt)
    try:
        bundle = load_bundle(args.origin, catalog, catalog_hash, [by_id[n] for n in names],
                             sorted(roles), inputs, out / 'original')
        shutil.copyfile(args.origin, out / 'source-manifest.json')
        receipt['sourceManifest'] = local_identity(out / 'source-manifest.json', out)
        receipt['sourceRoleMetadata'] = bundle['roles'][source_role]
        shutil.copyfile(__file__, out / 'prototype.py')
        receipt['producer'] = local_identity(out / 'prototype.py', out)
        for name in names:
            case = by_id[name]
            source = bundle['points'][name][source_role]
            module = Path(source['resolved'])
            if name in replacements:
                suffix = '.cjs' if replacements[name].suffix == '.cjs' else '.mjs'
                module = out / 'replacements' / (name + suffix)
                module.parent.mkdir(exist_ok=True)
                shutil.copyfile(replacements[name], module)
                verify(module, replacement_inputs[name])
                receipt['replacements'].append(dict(id=name, original=source,
                    input=replacement_inputs[name], copied=local_identity(module, out)))
            manifest['cases'].append(dict(id=name, sourceSha256=case['source']['sha256'],
                point=case['point'], sourceRole=source_role, replaced=name in replacements,
                modules={'candidate': local_identity(module, out)}))
        for item in inputs:
            verify(item['path'], item)
        verify(out / 'source-manifest.json', identity(args.origin))
        verify(out / 'prototype.py', inputs[0])
        manifest['complete'] = receipt['complete'] = True
    except Exception as error:
        receipt['error'] = repr(error)
        raise
    finally:
        save(out / 'prototype.json', receipt)
        manifest['prototype'] = local_identity(out / 'prototype.json', out)
        save(out / 'manifest.json', manifest)
    print(json.dumps(dict(complete=True, checked=False, manifest=str(out / 'manifest.json'),
                          cases=len(names), replacements=list(replacements))))


if __name__ == '__main__':
    main()
