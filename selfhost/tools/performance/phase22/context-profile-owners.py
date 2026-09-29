"""Attribute physical samples to generated owners without changing compiler code."""
from pathlib import Path
from collections import defaultdict
import bisect, importlib.util, json, re, sys

R = Path(__file__).resolve().parents[4]
helper = R / 'selfhost/tools/performance/phase9/profile-callers.py'
spec = importlib.util.spec_from_file_location('reader', helper)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
profile, api, destination = map(lambda x: Path(x).resolve(), sys.argv[1:])
destination.mkdir()
controls = m.self_test()
nf, parents, frames, metadata, count = m.read_profile(profile)
starts = []; functions = []
for number, line in enumerate(api.read_text().splitlines(), 1):
    match = re.match(r'^function ([\w$]+)\(', line)
    if match: starts.append(number); functions.append(match.group(1))
assert starts
api_url = api.as_uri()
def owner(frame):
    name, url, line, column = frame
    if url == api_url:
        i = bisect.bisect_right(starts, line) - 1
        if i >= 0: return functions[i]
    return name or '<anonymous>'
owners = [None] + [owner(f) for f in frames[1:]]
runtime = m.RUNTIME | {'kc', '$kc$', 'f_choose', '$f_choose$'}
targets = {'$f_ctor_lookup$', '$f_ctor_more$', '$f_declared$', '$f_eq$', '$dn$'}
cost = defaultdict(lambda: [0, 0]); callers = defaultdict(lambda: [0, 0]); witnesses = {}
sample_ids, deltas = metadata['samples'], metadata['timeDeltas']; assert len(sample_ids) == len(deltas)
for ident, delta in zip(sample_ids, deltas):
    own = owners[nf[ident]]; cost[own][0] += 1; cost[own][1] += delta
    if own not in targets: continue
    at = parents[ident]; chain = []
    while at:
        fid = nf[at]; ancestor = owners[fid]
        if len(chain) < 30: chain.append({'frame': frames[fid], 'owner': ancestor})
        if ancestor != own and ancestor not in runtime and not ancestor.startswith('(') and ancestor != '<anonymous>': break
        at = parents[at]
    ancestor = owners[nf[at]] if at else '<unattributed>'
    key = (own, ancestor); callers[key][0] += 1; callers[key][1] += delta
    if key not in witnesses: witnesses[key] = chain
total = sum(deltas)
rows = [{'owner': k, 'samples': v[0], 'selfUs': v[1], 'percentOfProfile': 100*v[1]/total} for k,v in cost.items()]
calls = [{'target': k[0], 'caller': k[1], 'samples': v[0], 'selfUs': v[1], 'percentOfProfile': 100*v[1]/total, 'witness': witnesses[k]} for k,v in callers.items()]
report = {'kind': 'phase22-generated-owner-physical-callers', 'complete': True,
    'scope': 'Exclusive signed CPU sample weights grouped by enclosing generated function; caller is first different physical owner after runtime frames. Not invocation/allocation counts. Tail callers may be absent.',
    'nodes': count, 'samples': len(sample_ids), 'totalSampleUs': total,
    'negativeDeltas': {'count': sum(d<0 for d in deltas), 'sumUs': sum(d for d in deltas if d<0)},
    'controls': controls, 'targets': sorted(targets),
    'owners': sorted(rows,key=lambda x:x['selfUs'],reverse=True),
    'callers': sorted(calls,key=lambda x:x['selfUs'],reverse=True),
    'inputs': [m.identity(p) for p in [profile,api,helper,Path(__file__)]]}
(destination/'report.json').write_text(json.dumps(report,indent=2)+'\n')
(destination/'consumed-tool.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'owners': report['owners'][:16], 'targetCallers': [{k:v for k,v in x.items() if k != 'witness'} for x in report['callers'][:30]]}))
