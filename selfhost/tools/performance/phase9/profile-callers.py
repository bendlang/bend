"""Attribute existing V8 freshness samples without materializing the call tree.

Retained arrays use unsigned 32-bit integers in the recorded host byte order;
index is V8 node ID, with zero reserved for missing parent/frame. This is a
physical sampled stack analysis, not a reconstruction of trampoline tail calls.
"""
from array import array
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import sys
import time

TARGETS = {'$norm_max_term$', '$norm_max_defs$'}
RUNTIME = {'run_loop', 'run_tail', 'run_clo', 'run_lib', 'run_jump'}
MAX_NODE_ID = 16000000


def identity(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b''):
            digest.update(chunk)
    return {'file': str(path.resolve()), 'bytes': path.stat().st_size,
            'sha256': digest.hexdigest()}


def read_profile(source):
    decoder = json.JSONDecoder()
    node_frames, parents = array('I', [0]), array('I', [0])
    assert node_frames.itemsize == 4
    frames, frame_ids = [None], {}
    node_count = 0

    def reserve(ident):
        assert isinstance(ident, int) and 0 < ident <= MAX_NODE_ID, 'Invalid node ID'
        if ident >= len(node_frames):
            extra = ident + 1 - len(node_frames)
            node_frames.extend(array('I', [0]) * extra)
            parents.extend(array('I', [0]) * extra)

    with source.open() as stream:
        buffer = stream.read(1024 * 1024)
        prefix = '{"nodes":['
        assert buffer.startswith(prefix), 'Unsupported V8 profile prefix'
        cursor = len(prefix)
        while True:
            if cursor > 512 * 1024:
                buffer, cursor = buffer[cursor:], 0
            while cursor >= len(buffer):
                more = stream.read(1024 * 1024)
                assert more, 'Truncated nodes'
                buffer += more
            if buffer[cursor] in ' \n\r\t,':
                cursor += 1
                continue
            if buffer[cursor] == ']':
                cursor += 1
                break
            while True:
                try:
                    node, cursor = decoder.raw_decode(buffer, cursor)
                    break
                except json.JSONDecodeError:
                    more = stream.read(1024 * 1024)
                    if not more:
                        raise
                    buffer += more
            node_count += 1
            frame = node['callFrame']
            key = (frame['functionName'], frame['url'], frame['lineNumber'] + 1,
                   frame['columnNumber'] + 1)
            if key not in frame_ids:
                frame_ids[key] = len(frames)
                frames.append(key)
            ident = node['id']
            reserve(ident)
            assert not node_frames[ident], 'Duplicate node ID'
            node_frames[ident] = frame_ids[key]
            for child in node.get('children', []):
                reserve(child)
                assert not parents[child], 'Multiple parents'
                parents[child] = ident
        tail = buffer[cursor:] + stream.read()
        metadata = json.loads('{' + tail.lstrip().removeprefix(','))
    assert all(not parent or node_frames[parent] for parent in parents), 'Missing parent'
    return node_frames, parents, frames, metadata, node_count


def skip(frame):
    name = frame[0]
    if not name or name.startswith('('):
        return 'anonymous-or-pseudo-frame'
    if name in RUNTIME:
        return 'trampoline-runtime'
    if name.startswith('$norm_max') or name in {'$norm_book_bound$', '$norm_bound_found$'}:
        return 'freshness-maximum-helper'
    return None


def analyze(node_frames, parents, frames, metadata, additional_skip=()):
    samples, deltas = metadata['samples'], metadata['timeDeltas']
    assert len(samples) == len(deltas)
    costs, target_costs = defaultdict(lambda: [0, 0]), defaultdict(lambda: [0, 0])
    witnesses = {}
    # A zero cache means unresolved; UINT32_MAX means no meaningful ancestor.
    cache = array('I', [0]) * len(node_frames)
    missing = 0xffffffff

    def frame_skip(frame):
        return 'comparison-entrypoint' if frame[0] in additional_skip else skip(frame)

    def caller(ident):
        walked = []
        while ident and not cache[ident]:
            assert node_frames[ident], 'Unknown ancestor'
            if not frame_skip(frames[node_frames[ident]]):
                cache[ident] = ident
                break
            walked.append(ident)
            assert len(walked) <= len(parents), 'Parent cycle'
            ident = parents[ident]
        result = cache[ident] if ident else missing
        for item in walked:
            cache[item] = result
        return result

    for ident, delta in zip(samples, deltas):
        assert 0 < ident < len(node_frames) and node_frames[ident], 'Unknown sample'
        assert isinstance(delta, int), 'Non-integer sample delta'
        name = frames[node_frames[ident]][0]
        if name not in TARGETS:
            continue
        ancestor = caller(parents[ident])
        frame_id = 0 if ancestor == missing else node_frames[ancestor]
        key = (name, frame_id)
        costs[key][0] += 1
        costs[key][1] += delta
        target_costs[name][0] += 1
        target_costs[name][1] += delta
        if key not in witnesses:
            chain, at = [], ident
            while at and len(chain) < 120:
                fid = node_frames[at]
                chain.append({'nodeId': at, 'frameId': fid, 'frame': frames[fid],
                              'skipReason': frame_skip(frames[fid])})
                if at == ancestor:
                    break
                at = parents[at]
            witnesses[key] = {'sampledNodeId': ident, 'callerNodeId': None if ancestor == missing else ancestor,
                              'chainTruncated': bool(at and at != ancestor), 'chain': chain}
    total = sum(deltas)
    target_total = sum(item[1] for item in target_costs.values())
    rows = []
    for (target, frame_id), (count, duration) in costs.items():
        rows.append({'target': target, 'callerFrameId': frame_id,
                     'caller': frames[frame_id] if frame_id else ['<unattributed>', '', 0, 0],
                     'samples': count, 'selfUs': duration,
                     'percentOfTarget': 100 * duration / target_costs[target][1],
                     'percentOfAllFreshness': 100 * duration / target_total,
                     'percentOfProfile': 100 * duration / total,
                     'witness': witnesses[(target, frame_id)]})
    return {'nodes': sum(bool(n) for n in node_frames), 'samples': len(samples),
            'totalSampleUs': total, 'freshnessSampleUs': target_total,
            'negativeDeltas': {'count': sum(delta < 0 for delta in deltas),
                               'sumUs': sum(delta for delta in deltas if delta < 0),
                               'policy': 'Retain original signed weighting, matching streamed-summary.py; do not clamp or reorder samples.'},
            'targets': {key: {'samples': value[0], 'selfUs': value[1]} for key, value in target_costs.items()},
            'callers': sorted(rows, key=lambda row: row['selfUs'], reverse=True)}


def self_test():
    frames = [None, ('(root)', '', 1, 1), ('$norm_compare$', 'api', 10, 1),
              ('', 'api', 11, 1), ('run_loop', 'api', 1, 1),
              ('$norm_max_defs$', 'api', 20, 1), ('$norm_max_term$', 'api', 21, 1)]
    nf = array('I', [0, 1, 2, 3, 4, 5, 6, 6])
    parents = array('I', [0, 0, 1, 2, 3, 4, 5, 1])
    result = analyze(nf, parents, frames, {'samples': [6, 5, 7, 2], 'timeDeltas': [30, 10, 5, 55]})
    assert result['freshnessSampleUs'] == 45
    assert result['callers'][0]['caller'][0] == '$norm_compare$'
    assert result['callers'][0]['selfUs'] == 30
    assert result['callers'][1]['selfUs'] == 10
    assert result['callers'][2]['callerFrameId'] == 0
    return {'pass': True, 'checks': ['nested maxima/runtime/anonymous skipped',
                                  'weighted samples preserved', 'unattributed root retained',
                                  'non-target sample excluded from target but retained in denominator']}


def main():
    source, destination = map(Path, sys.argv[1:3])
    destination.mkdir(parents=True, exist_ok=False)
    start = time.monotonic()
    stat_before = source.stat()
    controls = self_test()
    reused = None
    if len(sys.argv) == 5 and sys.argv[3] == '--reuse':
        saved = Path(sys.argv[4])
        prior = json.loads((saved / 'report.json').read_text())
        nf, parents = array('I'), array('I')
        for name, values in [('node-frames.u32', nf), ('node-parents.u32', parents)]:
            with (saved / name).open('rb') as stream:
                values.fromfile(stream, prior['arrays']['entries'])
            assert identity(saved / name) in prior['arrays']['files']
        frames = json.loads((saved / 'frames.json').read_text())
        assert identity(saved / 'frames.json') in prior['arrays']['files']
        metadata = json.loads((saved / 'samples.json').read_text())
        count = prior['nodes']
        reused = [identity(saved / name) for name in ['report.json', 'samples.json']]
    else:
        assert len(sys.argv) == 3, 'Expected PROFILE DEST [--reuse ARRAY_DIRECTORY]'
        nf, parents, frames, metadata, count = read_profile(source)
    (destination / 'frames.json').write_text(json.dumps(frames) + '\n')
    for name, values in [('node-frames.u32', nf), ('node-parents.u32', parents)]:
        with (destination / name).open('xb') as stream:
            values.tofile(stream)
    (destination / 'samples.json').write_text(json.dumps(metadata) + '\n')
    result = analyze(nf, parents, frames, metadata)
    assert result['nodes'] == count
    above_compare = analyze(nf, parents, frames, metadata, {'$compare$', '$norm_compare$'})
    result['aboveComparisonCallers'] = above_compare['callers']
    script = Path(__file__).resolve()
    (destination / 'profile-callers.py').write_bytes(script.read_bytes())
    profile_id = identity(source)
    assert (stat_before.st_size, stat_before.st_mtime_ns, stat_before.st_ino) == (source.stat().st_size, source.stat().st_mtime_ns, source.stat().st_ino), 'Profile changed'
    result.update({'kind': 'phase9-streamed-freshness-callers', 'complete': True,
                   'profile': profile_id, 'tool': identity(script), 'controls': controls,
                   'reusedArrays': reused,
                   'skipPolicy': {'anonymousAndPseudo': True, 'runtimeNames': sorted(RUNTIME),
                                  'freshnessPrefixes': ['$norm_max'], 'freshnessNames': ['$norm_book_bound$', '$norm_bound_found$'],
                                  'aboveComparisonAdditionalSkips': ['$compare$', '$norm_compare$'],
                                  'views': 'callers and aboveComparisonCallers are alternative attributions of the same samples, never additive.'},
                   'scope': 'Exclusive target samples assigned to first meaningful physical ancestor; runtime tail calls may erase logical callers. No call counts, allocations, or full-compile speed claim.',
                   'arrays': {'format': 'unsigned-32', 'byteOrder': sys.byteorder, 'index': 'V8 node ID',
                              'zero': 'missing frame or parent', 'entries': len(nf),
                              'files': [identity(destination / name) for name in ['node-frames.u32', 'node-parents.u32', 'frames.json', 'samples.json']]},
                   'wallSeconds': time.monotonic() - start})
    (destination / 'report.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({key: result[key] for key in ['complete', 'nodes', 'samples', 'freshnessSampleUs', 'wallSeconds']}))
    for row in result['callers'][:20]:
        print(json.dumps({key: row[key] for key in ['target', 'caller', 'selfUs', 'percentOfTarget', 'percentOfProfile']}))


if __name__ == '__main__':
    main()
