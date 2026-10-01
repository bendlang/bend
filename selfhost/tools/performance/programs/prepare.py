#!/usr/bin/env python3
"""Acquire checked modules before the execution-time budget starts."""
import argparse
import json
import os
from pathlib import Path
import shutil
import time

from support import ExecutionGuard, identity, save

HERE = Path(__file__).resolve().parent
CATALOG = HERE / 'catalog.json'


def select(catalog, set_name, cases):
    ids = cases.split(',') if cases else catalog['sets'][set_name]
    if not ids or len(set(ids)) != len(ids):
        raise ValueError('Case selection must be nonempty and contain no duplicates')
    lookup = {c['id']: c for c in catalog['cases']}
    if any(key not in lookup for key in ids):
        raise ValueError('Unknown case; inspect catalog.json or run.py --list')
    return [lookup[key] for key in ids]


def checked_source(case):
    item = case['source']
    relative = Path(item['path'])
    if relative.is_absolute() or '..' in relative.parts:
        raise ValueError('Invalid catalog source path')
    requested = HERE / relative
    source = requested.resolve()
    if not source.is_relative_to(HERE) or requested.is_symlink():
        raise ValueError('Source must remain inside the suite')
    actual = identity(source)
    if any(actual[k] != item[k] for k in ['sha256', 'bytes']):
        raise ValueError('Changed catalog source: ' + str(source))
    return source


def observe_row(source, typescript=False):
    """The unchanged Phase30 complete-row observer; its work stays timed."""
    marker = 'export default '
    if source.count(marker) != 1:
        raise ValueError('Expected one ordinary generated-library default export')
    observed = 'JSON.stringify([st.a,st.b,st.prev,st.cur])' if typescript else 'JSON.stringify(st.a.map(x=>x.array))'
    return (source.replace(marker, 'const $Owned_exports = ', 1)
            + '\nexport default {...$Owned_exports,bench:(n,seed)=>{const st=$Owned_exports["row.probe"](n,seed);return '
            + observed + ';}};\n')


def relative_identity(file, root):
    item = identity(file)
    item['path'] = str(Path(file).relative_to(root))
    return item


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True, help='New directory; existing output is never overwritten')
    compiler_group = parser.add_mutually_exclusive_group()
    compiler_group.add_argument('--attempt', type=Path, help='Checked development attempt; default verifies installed release')
    compiler_group.add_argument('--upstream', type=Path, help='Clean checkout at catalog pin; requires --role typescript')
    parser.add_argument('--set', choices=['fast', 'core', 'broad', 'full'], default='fast')
    parser.add_argument('--cases', help='Comma-separated case IDs, overriding --set')
    parser.add_argument('--role', choices=['candidate', 'baseline', 'typescript'], default='candidate')
    parser.add_argument('--node', default=shutil.which('node'))
    parser.add_argument('--cpu', type=int, default=min(os.sched_getaffinity(0)))
    parser.add_argument('--heap-mib', type=int, default=1024)
    parser.add_argument('--rss-mib', type=int, default=1600)
    parser.add_argument('--available-mib', type=int, default=2048)
    parser.add_argument('--timeout', type=int, default=180, help='Maximum seconds per checked emission')
    args = parser.parse_args()
    if bool(args.upstream) != (args.role == 'typescript'):
        parser.error('--upstream and --role typescript must be supplied together')
    if not args.node or not 128 <= args.heap_mib <= 2048 or not 256 <= args.rss_mib <= 4096:
        parser.error('Node is required; heap must be 128..2048 MiB and RSS 256..4096 MiB')
    if args.available_mib < 1024 or not 1 <= args.timeout <= 1800 or args.cpu not in os.sched_getaffinity(0):
        parser.error('Require available-memory floor >=1024 MiB, timeout 1..1800, and an allowed CPU')
    catalog = json.loads(CATALOG.read_text())
    selected = select(catalog, args.set, args.cases)
    sources = {case['source']['path']: checked_source(case) for case in selected}
    expected_sources = {case['source']['path']: case['source'] for case in selected}
    if len({source.stem for source in sources.values()}) != len(sources):
        parser.error('Different source paths must have distinct stems for module output names')
    verifiers = [HERE.parents[1] / 'development' / name for name in ['workflow.mjs', 'release.mjs']]
    node = Path(args.node).resolve()
    if not node.is_file():
        parser.error('Node executable does not exist')
    out = args.out.resolve()
    manifest = dict(kind='bend-program-bundle', schemaVersion=1, complete=False,
                    upstreamCommit=catalog['upstreamCommit'], catalogSha256=identity(CATALOG)['sha256'],
                    roles={}, cases=[])
    receipt = dict(kind='bend-program-preparation', schemaVersion=1, complete=False,
                   scope='Serial checked acquisition only; excluded from all execution-time budgets.',
                   producer=identity(__file__), worker=identity(HERE / 'emit-worker.mjs'),
                   supervisor=identity(HERE / 'support.py'), catalog=identity(CATALOG), node=identity(node),
                   verifiers=[identity(file) for file in verifiers],
                   cpu=args.cpu, heapMiB=args.heap_mib, sources=[], adapters=[])
    with ExecutionGuard(rss_mib=args.rss_mib, available_mib=args.available_mib) as guard:
        out.mkdir(parents=True, exist_ok=False)
        (out / 'modules').mkdir()
        (out / 'consumed').mkdir()
        for name in ['prepare.py', 'emit-worker.mjs', 'support.py', 'catalog.json']:
            shutil.copyfile(HERE / name, out / 'consumed' / name)
        for file in verifiers:
            shutil.copyfile(file, out / 'consumed' / ('verifier-' + file.name))
        save(out / 'manifest.json', manifest)
        save(out / 'preparation.json', receipt)
        try:
            modules = {}
            compiler = None
            for index, (name, source) in enumerate(sources.items()):
                if guard.interrupted:
                    raise RuntimeError('Preparation interrupted')
                target = out / 'modules' / (source.stem + '.mjs')
                command = ['taskset', '-c', str(args.cpu), str(node), '--stack-size=4096',
                           '--max-old-space-size=' + str(args.heap_mib), str(HERE / 'emit-worker.mjs'),
                           ('upstream:' + str(args.upstream.resolve())) if args.upstream else
                           str(args.attempt.resolve()) if args.attempt else 'installed', str(source), str(target)]
                process = guard.run(command, out / ('emit-' + str(index).zfill(2)), time.monotonic() + args.timeout)
                row = dict(source=identity(source), process=process)
                receipt['sources'].append(row)
                save(out / 'preparation.json', receipt)
                if not process['complete']:
                    raise RuntimeError('Checked emission failed: ' + str(source))
                emitted = json.loads(Path(str(target) + '.json').read_text())
                if not emitted['complete'] or not emitted['observation']['checked']:
                    raise RuntimeError('Unchecked or incomplete emission')
                expected = expected_sources[name]
                if (any(emitted['input'].get(k) != expected[k] or identity(source)[k] != expected[k]
                        for k in ['sha256', 'bytes'])
                        or emitted['output']['sha256'] != identity(target)['sha256']):
                    raise RuntimeError('Emission identity mismatch')
                if [item['sha256'] for item in emitted['verifiers']] != [item['sha256'] for item in receipt['verifiers']]:
                    raise RuntimeError('Verifier changed before emission')
                if compiler is None:
                    compiler = emitted['compiler']
                if compiler != emitted['compiler']:
                    raise RuntimeError('Compiler changed during acquisition')
                row['emission'] = relative_identity(Path(str(target) + '.json'), out)
                modules[name] = target
                print(json.dumps(dict(source=source.name, complete=True)), flush=True)
            for case in selected:
                checked_source(case)
                target = modules[case['source']['path']]
                if case.get('adapter'):
                    if case['adapter'] != 'generic-row':
                        raise ValueError('Unknown observer')
                    adapted = out / 'modules' / (target.stem + '-observed.mjs')
                    adapted.write_text(observe_row(target.read_text(), typescript=args.role == 'typescript'))
                    receipt['adapters'].append(dict(kind='complete-generic-row-serialization',
                        raw=relative_identity(target, out), adapted=relative_identity(adapted, out),
                        producer=receipt['producer'], historicalProducer='selfhost/tools/performance/phase30/prototype-owned-derive.py'))
                    target = adapted
                manifest['cases'].append(dict(id=case['id'], sourceSha256=case['source']['sha256'],
                    point=case['point'], modules={args.role:relative_identity(target, out)}))
            if identity(CATALOG)['sha256'] != manifest['catalogSha256']:
                raise RuntimeError('Catalog changed during acquisition')
            for name in ['prepare.py', 'emit-worker.mjs', 'support.py', 'catalog.json']:
                if identity(HERE / name)['sha256'] != identity(out / 'consumed' / name)['sha256']:
                    raise RuntimeError('Preparation producer changed during acquisition: ' + name)
            if identity(node) != receipt['node']:
                raise RuntimeError('Node changed during acquisition')
            for file, expected in zip(verifiers, receipt['verifiers']):
                if identity(file) != expected or identity(out / 'consumed' / ('verifier-' + file.name))['sha256'] != expected['sha256']:
                    raise RuntimeError('Verifier changed during acquisition: ' + str(file))
            manifest['roles'][args.role] = dict(label='Prepared checked ' + args.role, compiler=compiler)
            manifest['complete'] = receipt['complete'] = True
        except Exception as error:
            receipt['error'] = repr(error)
            raise
        finally:
            save(out / 'preparation.json', receipt)
            manifest['preparation'] = relative_identity(out / 'preparation.json', out)
            save(out / 'manifest.json', manifest)
    print(json.dumps(dict(complete=True, manifest=str(out / 'manifest.json'), cases=len(selected))))


if __name__ == '__main__':
    main()
