"""Group exclusive samples by their enclosing generated top-level function.

This is lexical ownership, not logical/inclusive caller attribution. Runtime
dispatch and GC remain separate; their cost is never assigned to a caller.
"""
import bisect
import collections
import hashlib
import json
import pathlib
import re
import sys

summary_file, api_file, output = map(pathlib.Path, sys.argv[1:])
summary = json.loads(summary_file.read_text())
lines = api_file.read_text().splitlines()
declarations = [(i, m.group(1)) for i, line in enumerate(lines, 1)
                if (m := re.match(r'^function ([\w$]+)\(', line))]
starts = [i for i, _ in declarations]
assert starts and starts == sorted(set(starts))
costs = collections.defaultdict(lambda: {'samples': 0, 'selfUs': 0, 'frames': []})
for row in summary['self']:
    owner = row['function']
    if row['file'] == api_file.resolve().as_uri() and not owner:
        index = bisect.bisect_right(starts, row['line']) - 1
        assert index >= 0 and row['line'] <= len(lines)
        owner = declarations[index][1]
    label = (row['file'], owner or '(unattributed anonymous)')
    item = costs[label]
    item['samples'] += row['samples']
    item['selfUs'] += row['selfUs']
    item['frames'].append(row)
assert sum(x['selfUs'] for x in costs.values()) == summary['totalSampleUs']
assert sum(x['samples'] for x in costs.values()) == summary['samples']
identity = lambda p: {'file': str(p.resolve()), 'bytes': p.stat().st_size,
                      'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
rows = [{'file': file, 'owner': owner, **values,
         'selfPercent': values['selfUs'] * 100 / summary['totalSampleUs']}
        for (file, owner), values in costs.items()]
report = {'kind': 'phase10-lexical-profile-owners', 'complete': True,
          'scope': __doc__, 'inputs': [identity(summary_file), identity(api_file),
                                      identity(pathlib.Path(__file__))],
          'samples': summary['samples'], 'totalSampleUs': summary['totalSampleUs'],
          'owners': sorted(rows, key=lambda x: x['selfUs'], reverse=True)}
with output.open('x') as stream:
    json.dump(report, stream, indent=2)
    stream.write('\n')
print(json.dumps([{k: r[k] for k in ('owner', 'selfPercent')} for r in report['owners'][:15]]))
