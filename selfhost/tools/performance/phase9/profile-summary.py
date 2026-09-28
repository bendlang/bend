"""Summarize a large V8 CPU profile without loading its call tree in memory."""
import collections
from array import array
import hashlib
import json
import pathlib
import sys

source, destination = map(pathlib.Path, sys.argv[1:])
decoder = json.JSONDecoder()
costs = collections.defaultdict(lambda: [0, 0])
node_frames = array('I', [0])
frame_ids = {}
frames = [None]
node_count = 0
with source.open() as stream:
    buffer = stream.read(1024 * 1024)
    prefix = '{"nodes":['
    if not buffer.startswith(prefix):
        raise ValueError('Unsupported V8 profile prefix')
    cursor = len(prefix)
    while True:
        if cursor > 512 * 1024:
            buffer = buffer[cursor:]
            cursor = 0
        while cursor >= len(buffer):
            more = stream.read(1024 * 1024)
            if not more:
                raise ValueError('Truncated nodes')
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
        key = (frame['functionName'], frame['url'], frame['lineNumber'] + 1)
        if key not in frame_ids:
            frame_ids[key] = len(frames)
            frames.append(key)
        ident = node['id']
        if ident >= len(node_frames):
            node_frames.extend(array('I', [0]) * (ident + 1 - len(node_frames)))
        assert node_frames[ident] == 0, 'Duplicate node ID'
        node_frames[ident] = frame_ids[key]
    # Everything after nodes is small: metadata plus one ID/delta per sample.
    tail = buffer[cursor:] + stream.read()
    metadata = json.loads('{' + tail.lstrip().removeprefix(','))

samples, deltas = metadata['samples'], metadata['timeDeltas']
assert len(samples) == len(deltas)
for ident, delta in zip(samples, deltas):
    assert 0 <= ident < len(node_frames) and node_frames[ident], 'Unknown sampled node'
    key = frames[node_frames[ident]]
    costs[key][0] += 1
    costs[key][1] += delta
total = sum(deltas)
rows = [{'function': k[0], 'file': k[1], 'line': k[2], 'samples': v[0],
         'selfUs': v[1], 'selfPercent': 100 * v[1] / total} for k, v in costs.items()]
with source.open('rb') as stream:
    hasher = hashlib.sha256()
    for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b''):
        hasher.update(chunk)
    digest = hasher.hexdigest()
report = {'kind': 'phase9-streamed-cpu-profile-summary', 'complete': True,
          'profile': {'file': str(source.resolve()), 'bytes': source.stat().st_size, 'sha256': digest},
          'nodes': node_count, 'samples': len(samples), 'totalSampleUs': total,
          'scope': 'Time-weighted exclusive CPU samples including startup. Not call counts or allocation counts; no inclusive percentages.',
          'self': sorted(rows, key=lambda r: r['selfUs'], reverse=True)}
with destination.open('x') as stream:
    json.dump(report, stream, indent=2)
    stream.write('\n')
print(json.dumps({'complete': True, 'nodes': node_count, 'samples': len(samples), 'top': report['self'][:12]}))
