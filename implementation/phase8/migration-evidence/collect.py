#!/usr/bin/env python3
"""Preserve completed Phase8 evidence as verified content-addressed objects."""
import argparse
from collections import deque
import gzip
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import tarfile
import tempfile

if not __debug__:
    raise RuntimeError('Run this verifier without Python -O; integrity checks require assertions.')

HEX = re.compile(r'^[0-9a-f]{64}$')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def safe_name(name):
    path = PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or not path.parts or path.as_posix() != name:
        raise ValueError('Unsafe relative path: ' + name)
    return path


def identity(path):
    before = path.lstat()
    if stat.S_ISLNK(before.st_mode):
        blob = os.readlink(path).encode('utf-8')
        result = {'type': 'symlink', 'target': blob.decode('utf-8'),
                  'bytes': len(blob), 'sha256': digest(blob), 'mode': before.st_mode & 0o777}
    elif stat.S_ISREG(before.st_mode):
        h = hashlib.sha256()
        with path.open('rb') as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                h.update(block)
        result = {'type': 'file', 'bytes': before.st_size, 'sha256': h.hexdigest(),
                  'mode': before.st_mode & 0o777}
    else:
        raise ValueError('Non-regular evidence input: ' + str(path))
    after = path.lstat()
    fields = ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_ctime_ns', 'st_mode')
    if any(getattr(before, key) != getattr(after, key) for key in fields):
        raise RuntimeError('Input changed while reading: ' + str(path))
    return result


def exclusion(name, selection):
    parts = PurePosixPath(name).parts
    if '__pycache__' in parts or name.endswith(('.pyc', '.pyo')):
        return 'Rebuildable Python bytecode; source is retained.'
    if any(parts[i:i + 3] == ('build', 'typed', 'cache') for i in range(len(parts) - 2)):
        return 'Derived Base cache; retain identity only and prime again from the archived API/Base/host recipe.'
    for rule in selection.get('omit', []):
        if re.fullmatch(rule['pattern'], name):
            return rule['reason']
    return None


def selected_paths(root, selection):
    paths = set()
    names = list(selection['include'])
    for pattern in selection.get('includeGlobs', []):
        safe_name(pattern)
        found = sorted(root.glob(pattern))
        if not found:
            raise FileNotFoundError('Selection glob has no matches: ' + pattern)
        names.extend(path.relative_to(root).as_posix() for path in found)
    for name in names:
        safe_name(name)
        start = root / name
        if not start.exists() and not start.is_symlink():
            raise FileNotFoundError('Selected input is missing: ' + name)
        if start.is_dir() and not start.is_symlink():
            for directory, dirs, files in os.walk(start, followlinks=False):
                for child in dirs[:]:
                    path = Path(directory) / child
                    if path.is_symlink():
                        paths.add(path)
                        dirs.remove(child)
                paths.update(Path(directory) / child for child in files)
        else:
            paths.add(start)
    return sorted(paths)


def json_references(value, origin, pointer=''):
    if isinstance(value, dict):
        pairs = [('sha256', ('file', 'path', 'canonicalPath', 'source', 'target', 'snapshot')),
                 ('apiSha256', ('api', 'apiPath', 'apiFile')),
                 ('baseSha256', ('base', 'basePath')),
                 ('runtimeSha256', ('runtime', 'runtimePath')),
                 ('checkedApiSha256', ('checkedApi', 'checkedApiFile'))]
        for hash_key, path_keys in pairs:
            expected = value.get(hash_key)
            if isinstance(expected, str) and HEX.fullmatch(expected):
                for key in path_keys:
                    name = value.get(key)
                    if isinstance(name, str) and name and not name.startswith(('http:', 'https:')):
                        yield {'report': origin, 'pointer': pointer + '/' + key,
                               'path': name, 'sha256': expected}
        for key, child in value.items():
            yield from json_references(child, origin, pointer + '/' + str(key))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from json_references(child, origin, pointer + '/' + str(index))


def external_stores(root, names):
    stores, keys = [], {}
    for name in names:
        safe_name(name)
        file = root / name
        raw = file.read_bytes()
        manifest = json.loads(raw)
        modern = isinstance(manifest['archive'], dict)
        info = manifest['archive'] if modern else {'file': manifest['archive'], 'sha256': manifest['archiveSha256'], 'bytes': manifest['archiveBytes']}
        archive = file.parent / info['file']
        safe_name(archive.relative_to(root).as_posix())
        actual = identity(archive)
        assert actual['sha256'] == info['sha256']
        assert actual['bytes'] == info['bytes']
        if modern:
            for prerequisite in manifest['externalCapsules']:
                assert prerequisite in stores, 'Declare nested capsule prerequisites first.'
            for row in manifest['files']:
                if row['store'] != 'self':
                    assert keys[row['sha256']] == {'manifest': row['store'], 'bytes': row['bytes']}
        expected = {row['sha256']: row['bytes'] for row in manifest['files'] if not modern or row['store'] == 'self'}
        verify_objects(archive, expected)
        stores.append({'manifest': name, 'manifestSha256': digest(raw),
                       'archive': archive.relative_to(root).as_posix(),
                       'archiveSha256': actual['sha256'], 'archiveBytes': actual['bytes'],
                       'objects': len(expected)})
        for key in expected:
            keys.setdefault(key, {'manifest': name, 'bytes': expected[key]})
    return stores, keys


def verify_objects(archive, expected):
    seen = set()
    with tarfile.open(archive, 'r:gz') as tar:
        for member in tar:
            key = member.name.removeprefix('objects/')
            assert member.isfile() and member.name == 'objects/' + key and HEX.fullmatch(key)
            assert key in expected and key not in seen
            blob = tar.extractfile(member).read()
            assert len(blob) == expected[key] and digest(blob) == key
            seen.add(key)
    assert seen == set(expected)
    return seen


def inventory(root, selection):
    records, omitted, objects, refs, unparsed = {}, {}, {}, [], []
    stores, external = external_stores(root, selection.get('externalCapsules', []))
    prerequisites = []
    for specification in selection.get('externalPrerequisites', []):
        path = Path(specification['path'])
        path = path if path.is_absolute() else root / path
        canonical = path.resolve(strict=True)
        prerequisites.append({**specification, 'canonicalPath': str(canonical), **identity(canonical)})
    initial = selected_paths(root, selection)
    queue = deque(initial)
    scanned = set()
    sizes = {}
    observed = {}
    while queue:
        path = queue.popleft()
        name = path.relative_to(root).as_posix()
        if name in scanned:
            continue
        scanned.add(name)
        if path not in observed:
            observed[path] = identity(path)
        row = {'file': name, **observed[path]}
        reason = exclusion(name, selection)
        if reason:
            omitted[name] = {**row, 'reason': reason}
            continue
        records[name] = row
        objects.setdefault(row['sha256'], path)
        sizes.setdefault(row['sha256'], row['bytes'])
        if path.suffix not in ('.json', '.jsonl') or row['type'] != 'file':
            continue
        new_refs = []
        try:
            raw = path.read_bytes()
            if digest(raw) != row['sha256']:
                raise RuntimeError('JSON input changed: ' + name)
            data = raw.decode('utf-8')
            values = [json.loads(line) for line in data.splitlines() if line.strip()] if path.suffix == '.jsonl' else [json.loads(data)]
            for value in values:
                new_refs.extend(json_references(value, name))
        except (ValueError, UnicodeError) as error:
            # Intentionally malformed negative controls remain exact raw bytes.
            unparsed.append({'file': name, 'reason': str(error)})
        # Add only repository-local dependencies whose current bytes match the
        # recorded hash. Historical variants may instead be present in snapshots.
        refs.extend(new_refs)
        for ref in new_refs:
            candidate = Path(ref['path'])
            candidate = candidate if candidate.is_absolute() else root / candidate
            try:
                local = candidate.absolute().relative_to(root)
                safe_name(local.as_posix())
            except ValueError:
                continue
            if candidate.is_file() and not candidate.is_symlink() and not exclusion(local.as_posix(), selection):
                if candidate not in observed:
                    observed[candidate] = identity(candidate)
                if observed[candidate]['sha256'] == ref['sha256'] and local.as_posix() not in scanned:
                    queue.append(candidate)
    prerequisite_keys = {row['sha256'] for row in prerequisites}
    for ref in refs:
        if ref['sha256'] in external:
            ref['status'] = 'captured-external-object'
        elif ref['sha256'] in objects:
            ref['status'] = 'captured-object'
        elif ref['sha256'] in prerequisite_keys:
            ref['status'] = 'external-toolchain-identity'
        else:
            path = Path(ref['path'])
            path = path if path.is_absolute() else root / path
            try:
                name = path.absolute().relative_to(root).as_posix()
                ref['status'] = 'omitted-derived-input' if name in omitted else 'unresolved-repository-reference'
            except ValueError:
                ref['status'] = 'external-prerequisite'
    grouped_refs = {}
    for ref in refs:
        key = (ref['path'], ref['sha256'], ref['status'])
        group = grouped_refs.setdefault(key, {'path': ref['path'], 'sha256': ref['sha256'], 'status': ref['status'], 'observedIn': {}})
        group['observedIn'].setdefault(ref['report'], []).append(ref['pointer'])
    files = sorted(records.values(), key=lambda row: row['file'])
    for row in files:
        row['store'] = external[row['sha256']]['manifest'] if row['sha256'] in external else 'self'
    omissions = sorted(omitted.values(), key=lambda row: row['file'])
    return {'kind': 'phase8-migration-evidence', 'schema': 1,
            'scope': selection['scope'], 'operatorDeclaredComplete': selection.get('complete', False),
            'selection': selection, 'originalRoot': str(root), 'files': files, 'externalCapsules': stores,
            'omitted': omissions, 'references': list(grouped_refs.values()), 'unparsedJson': unparsed, 'externalPrerequisites': prerequisites,
            'summary': {'files': len(files), 'objects': len(objects),
                        'logicalBytes': sum(row['bytes'] for row in files),
                        'uniqueBytes': sum(sizes.values()),
                        'newArchiveObjects': sum(key not in external for key in objects),
                        'newArchiveBytesBeforeCompression': sum(size for key, size in sizes.items() if key not in external),
                        'externalPrerequisites': len(prerequisites), 'omittedFiles': len(omissions), 'omittedBytes': sum(row['bytes'] for row in omissions),
                        'referenceStatuses': {status: sum(ref['status'] == status for ref in refs)
                            for status in sorted({ref['status'] for ref in refs})}}}, {key: value for key, value in objects.items() if key not in external}, initial


def verify(directory, root):
    manifest = json.loads((directory / 'manifest.json').read_text())
    archive = directory / manifest['archive']['file']
    safe_name(manifest['archive']['file'])
    actual = identity(archive)
    assert actual['sha256'] == manifest['archive']['sha256'] and actual['bytes'] == manifest['archive']['bytes']
    expected = {row['sha256']: row['bytes'] for row in manifest['files'] if row['store'] == 'self'}
    assert len({row['file'] for row in manifest['files']}) == len(manifest['files'])
    bound, keys = external_stores(root, [store['manifest'] for store in manifest['externalCapsules']])
    assert bound == manifest['externalCapsules']
    for row in manifest['files']:
        safe_name(row['file'])
        assert HEX.fullmatch(row['sha256'])
        assert row['type'] in ('file', 'symlink')
        assert isinstance(row['mode'], int) and 0 <= row['mode'] <= 0o777
        if row['type'] == 'symlink':
            blob = row['target'].encode('utf-8')
            assert digest(blob) == row['sha256'] and len(blob) == row['bytes']
        if row['store'] == 'self':
            assert expected[row['sha256']] == row['bytes']
        else:
            assert keys[row['sha256']]['manifest'] == row['store']
            assert keys[row['sha256']]['bytes'] == row['bytes']
    seen = verify_objects(archive, expected)
    return {'pass': True, 'files': len(manifest['files']), 'objects': len(seen),
            'externalCapsules': len(bound), 'archiveSha256': actual['sha256'],
            'archiveBytes': actual['bytes'],
            'scope': 'Archive byte identity only; recorded failed experiments remain failures.'}


def capture(root, selection, destination):
    if not selection.get('complete'):
        raise ValueError('Selection is still draft; finish the runs before capturing.')
    if destination.exists() or destination.is_symlink():
        raise FileExistsError('Refuse to replace an existing capsule: ' + str(destination))
    manifest, objects, initial = inventory(root, selection)
    destination.parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix='.capture-', dir=destination.parent))
    try:
        archive = stage / 'raw.tar.gz'
        with archive.open('xb') as raw, gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0, compresslevel=6) as compressed:
            with tarfile.open(fileobj=compressed, mode='w|') as tar:
                for key, path in sorted(objects.items()):
                    blob = os.readlink(path).encode('utf-8') if path.is_symlink() else path.read_bytes()
                    if digest(blob) != key:
                        raise RuntimeError('Input changed before archiving: ' + str(path))
                    member = tarfile.TarInfo('objects/' + key)
                    member.size, member.mode, member.mtime = len(blob), 0o444, 0
                    tar.addfile(member, io.BytesIO(blob))
        # Membership and all included/omitted bytes must still match. This does
        # not infer completion: the operator must first close the producers.
        if selected_paths(root, selection) != initial:
            raise RuntimeError('Selected file membership changed during capture.')
        for row in manifest['files'] + manifest['omitted']:
            now = identity(root / row['file'])
            if any(now[key] != row[key] for key in ('type', 'bytes', 'sha256', 'mode')):
                raise RuntimeError('Input changed during capture: ' + row['file'])
        for row in manifest['externalPrerequisites']:
            now = identity(Path(row['canonicalPath']))
            if now['sha256'] != row['sha256']:
                raise RuntimeError('External tool changed during capture: ' + row['canonicalPath'])
        manifest['archive'] = {'file': archive.name, 'bytes': archive.stat().st_size,
                               'sha256': identity(archive)['sha256']}
        (stage / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        result = verify(stage, root)
        (stage / 'verification.json').write_text(json.dumps(result, indent=2) + '\n')
        if destination.exists() or destination.is_symlink():
            raise FileExistsError('Destination appeared during capture: ' + str(destination))
        os.rename(stage, destination)
        return result
    except BaseException:
        shutil.rmtree(stage)
        raise


def materialize(directory, destination, root):
    verify(directory, root)
    if destination.exists() or destination.is_symlink():
        raise FileExistsError('Recovery requires a new directory.')
    manifest = json.loads((directory / 'manifest.json').read_text())
    symlinks = {row['file'] for row in manifest['files'] if row['type'] == 'symlink'}
    for row in manifest['files']:
        if any(parent.as_posix() in symlinks for parent in PurePosixPath(row['file']).parents):
            raise ValueError('Recovery path has a selected symlink ancestor: ' + row['file'])
        if row['type'] == 'symlink':
            target = PurePosixPath(row['target'])
            location = (destination / row['file']).parent / row['target']
            if target.is_absolute() or '..' in target.parts or not location.resolve().is_relative_to(destination.resolve()):
                raise ValueError('Unsafe recovery symlink; inspect its manifest entry manually: ' + row['file'])
    destination.mkdir(parents=True)
    by_hash = {}
    for row in manifest['files']:
        by_hash.setdefault(row['sha256'], []).append(row)
    pending_links = []
    archives = [directory / manifest['archive']['file']] + [root / store['archive'] for store in manifest['externalCapsules']]
    for archive in archives:
        with tarfile.open(archive, 'r:gz') as tar:
            for member in tar:
                key = member.name.split('/')[1]
                if key not in by_hash:
                    continue
                blob = tar.extractfile(member).read()
                assert digest(blob) == key
                for row in by_hash.pop(key):
                    assert len(blob) == row['bytes']
                    output = destination / row['file']
                    output.parent.mkdir(parents=True, exist_ok=True)
                    if row['type'] == 'symlink':
                        pending_links.append((output, row['target']))
                    else:
                        output.write_bytes(blob)
                        output.chmod(row['mode'])
    assert not by_hash
    for output, target in pending_links:
        output.symlink_to(target)
    return {'pass': True, 'recoveredFiles': len(manifest['files']), 'destination': str(destination)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['plan', 'capture', 'verify', 'materialize'])
    parser.add_argument('input', type=Path)
    parser.add_argument('destination', type=Path, nargs='?')
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[3])
    args = parser.parse_args()
    if args.mode in ('plan', 'capture'):
        selection = json.loads(args.input.read_text())
        if args.mode == 'plan':
            result, _, _ = inventory(args.root.resolve(), selection)
            if args.destination:
                args.destination.write_text(json.dumps(result, indent=2) + '\n')
            result = result['summary']
        else:
            if not args.destination:
                parser.error('capture requires a new destination directory')
            result = capture(args.root.resolve(), selection, args.destination.resolve())
    elif args.mode == 'verify':
        result = verify(args.input.resolve(), args.root.resolve())
    else:
        if not args.destination:
            parser.error('materialize requires a new destination directory')
        result = materialize(args.input.resolve(), args.destination.resolve(), args.root.resolve())
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
