#!/usr/bin/env python3
"""Package complete checked baseline and pinned TypeScript preparations.

Produces a deterministic archive and a portable manifest. No compiler or emitted
program is executed here. The bundle retains acquisition receipts and logs.
"""
import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path
import tarfile

from prepare import HERE, CATALOG, checked_source
from support import identity, save


def record(data, path):
    return dict(path=path, sha256=hashlib.sha256(data).hexdigest(), bytes=len(data))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True, help='Completed prepare.py --role baseline --set full directory')
    parser.add_argument('--typescript', type=Path, required=True, help='Completed prepare.py --role typescript --set full directory')
    parser.add_argument('--out', type=Path, required=True, help='New reference directory')
    args = parser.parse_args()
    catalog = json.loads(CATALOG.read_text())
    catalog_sha = identity(CATALOG)['sha256']
    files, manifests, roles, before = {}, {}, {}, {}
    inputs = dict(baseline=args.baseline.resolve(), typescript=args.typescript.resolve())
    for role, root in inputs.items():
        manifest = json.loads((root / 'manifest.json').read_text())
        assert manifest['complete'] and manifest['catalogSha256'] == catalog_sha
        assert manifest['upstreamCommit'] == catalog['upstreamCommit'] and set(manifest['roles']) == {role}
        assert len(manifest['cases']) == len(catalog['cases'])
        assert {c['id'] for c in manifest['cases']} == set(catalog['sets']['full'])
        manifests[role] = {c['id']: c for c in manifest['cases']}
        roles[role] = manifest['roles'][role]
        preparation = json.loads((root / 'preparation.json').read_text())
        assert preparation['complete']
        assert record((root / 'preparation.json').read_bytes(), 'preparation.json') == manifest['preparation']
        for file in sorted(root.rglob('*')):
            if file.is_symlink():
                raise ValueError('Prepared bundle contains a symlink')
            if file.is_file():
                name = role + '/' + str(file.relative_to(root))
                files[name] = file.read_bytes(); before[str(file)] = identity(file)
    # Verify both pinned compiler sources and Base agreement, not only target names.
    compiler = roles['typescript']['compiler']
    assert compiler['kind'] == 'checked-pinned-typescript'
    ts_base = next(item for item in compiler['sources'] if item['file'].endswith('/base.bend'))
    assert roles['baseline']['compiler']['base']['sha256'] == ts_base['sha256']
    roles['typescript']['label'] = 'Pinned upstream TypeScript'
    if roles['baseline']['compiler']['api']['sha256'] == '8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92':
        roles['baseline']['label'] = 'Phase32 checked03'
    cases = []
    for case in catalog['cases']:
        checked_source(case)
        row = dict(id=case['id'], sourceSha256=case['source']['sha256'], point=case['point'], modules={})
        for role in inputs:
            ready = manifests[role][case['id']]
            assert ready['sourceSha256'] == row['sourceSha256'] and ready['point'] == row['point']
            assert set(ready['modules']) == {role}
            item = ready['modules'][role]
            relative = Path(item['path'])
            assert not relative.is_absolute() and '..' not in relative.parts
            name = role + '/' + str(relative)
            assert record(files[name], str(relative)) == item
            row['modules'][role] = record(files[name], name)
        cases.append(row)
    provenance = dict(kind='bend-program-frozen-reference-provenance', complete=True,
        producer=identity(__file__), adapterProducer=identity(HERE / 'prepare.py'), catalog=identity(CATALOG),
        preparations={role:identity(root / 'preparation.json') for role, root in inputs.items()},
        acquisitionScope='Fresh checked sequential emissions, one process per source and compiler. Complete acquisition receipts and logs retained under each role in the archive. Absolute receipt paths are historical provenance only, never runtime dependencies.',
        observationScope='Scalar/string outputs and an explicit full-state generic-row serializer. Archive creation executes no compiler or generated program and establishes no timing result.')
    files['consumed/freeze-reference.py'] = Path(__file__).read_bytes()
    files['provenance.json'] = (json.dumps(provenance, indent=2) + '\n').encode()
    out = args.out.resolve(); out.mkdir(parents=True, exist_ok=False)
    archive = out / 'programs.tar.gz'
    with archive.open('xb') as stream, gzip.GzipFile(fileobj=stream, mode='wb', filename='', mtime=0) as compressed:
        with tarfile.open(fileobj=compressed, mode='w|') as tar:
            for name, data in sorted(files.items()):
                info = tarfile.TarInfo(name); info.size = len(data); info.mode = 0o644
                info.mtime = 0; info.uid = info.gid = 0; info.uname = info.gname = ''
                tar.addfile(info, io.BytesIO(data))
    with tarfile.open(archive, 'r:gz') as tar:
        members = tar.getmembers()
        assert {m.name for m in members} == set(files) and len(members) == len(files)
        for member in members:
            assert member.isfile() and tar.extractfile(member).read() == files[member.name]
    for file, expected in before.items():
        assert identity(file) == expected, 'Input changed during reference capture'
    for case in catalog['cases']:
        checked_source(case)
    assert catalog_sha == identity(CATALOG)['sha256']
    manifest = dict(kind='bend-program-bundle', schemaVersion=1, complete=True,
        upstreamCommit=catalog['upstreamCommit'], catalogSha256=catalog_sha, roles=roles,
        archive=record(archive.read_bytes(), archive.name), cases=cases,
        provenance=record(files['provenance.json'], 'provenance.json'),
        preservation={'members':len(files), 'uncompressedBytes':sum(map(len, files.values())), 'reopenedVerified':True})
    save(out / 'manifest.json', manifest)
    save(out / 'provenance.json', provenance)
    print(json.dumps(dict(complete=True, manifest=str(out / 'manifest.json'), archiveBytes=archive.stat().st_size,
                         cases=len(cases), members=len(files))))


if __name__ == '__main__':
    main()
