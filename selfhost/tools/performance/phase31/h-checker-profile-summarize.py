#!/usr/bin/env python3
"""Select checker invocation samples by verified shared monotonic timestamps."""
import collections
import hashlib
import json
import pathlib
import re
import sys

result_path=pathlib.Path(sys.argv[1]).resolve()
out=pathlib.Path(sys.argv[2]).resolve()
assert not out.exists()
data=json.loads(result_path.read_text())
assert data['complete'] and data['pass']
profile_path=pathlib.Path(data['cpuProfile']['file'])
assert hashlib.sha256(profile_path.read_bytes()).hexdigest()==data['cpuProfile']['sha256']
profile=json.loads(profile_path.read_text())
clock=data['profileClock']
assert clock['beforeStartHrUs']<=profile['startTime']<=clock['afterStartHrUs']
assert clock['beforeStopHrUs']<=profile['endTime']<=clock['afterStopHrUs']
events=data['traceEvents']
active=False; bounds={}
for event in events:
    if event['kind']=='request-start': active=event['index']==1
    if event['kind']=='request-end': active=False
    if active and event['kind']=='stderr':
        matched=re.search(r'\] ABI check_program_diagnostic (invoke|decode) ',event['text'])
        if matched:
            assert matched[1] not in bounds
            bounds[matched[1]]=event['hrUs']
assert set(bounds)=={'invoke','decode'}
assert profile['startTime']<bounds['invoke']<bounds['decode']<profile['endTime']
nodes={n['id']:n for n in profile['nodes']}
parents={}
for node in nodes.values():
    for child in node.get('children',[]):
        assert child not in parents
        parents[child]=node['id']
request=json.loads((result_path.parent/'request.json').read_text())
image=pathlib.Path(request['plan']['variants']['generated_h']['file'])
assert hashlib.sha256(image.read_bytes()).hexdigest()==request['plan']['variants']['generated_h']['sha256']
lines=image.read_text().splitlines()
url=image.as_uri()
def frame(n):
    f=n['callFrame'];line=f['lineNumber'];column=f['columnNumber'];excerpt=None
    if f['url']==url and 0<=line<len(lines):
        source=lines[line]
        matched=re.match(r'^G\[("(?:[^"\\]|\\.)*")\]=',source)
        name='Bend:'+json.loads(matched[1]) if matched else 'Runtime:'+(f['functionName'] or '<anonymous>')
        excerpt=source[max(0,column):max(0,column)+160]
    else:
        name='Other:'+(f['functionName'] or '<anonymous>')
    return dict(label=name,function=f['functionName'],url=f['url'],line=line+1,column=column+1,source=excerpt)
frames={k:frame(n) for k,n in nodes.items()}
selected=[];when=profile['startTime']
assert len(profile['samples'])==len(profile['timeDeltas'])
for sample,delta in zip(profile['samples'],profile['timeDeltas']):
    when+=delta
    if bounds['invoke']<=when<bounds['decode']:selected.append(sample)
assert selected
self_counts=collections.Counter(selected)
groups=collections.Counter(frames[s]['label'] for s in selected)
inclusive=collections.Counter()
for sample in selected:
    labels=set();cursor=sample
    while cursor is not None:
        labels.add(frames[cursor]['label']);cursor=parents.get(cursor)
    inclusive.update(labels)
def ranked(counts):
    return [dict(label=name,samples=n,percent=100*n/len(selected)) for name,n in counts.most_common()]
report=dict(kind='phase31-h-checker-cpu-profile-summary',complete=True,**{'pass':True},
    result=dict(file=str(result_path),sha256=hashlib.sha256(result_path.read_bytes()).hexdigest()),
    profile=data['cpuProfile'],clock=clock,profileStartUs=profile['startTime'],profileEndUs=profile['endTime'],
    checkerBoundsUs=bounds,checkerIntervalMs=(bounds['decode']-bounds['invoke'])/1000,
    profileSamples=len(profile['samples']),selectedSamples=len(selected),
    selfGroups=ranked(groups),inclusiveGroups=ranked(inclusive),
    selfFrames=[dict(id=n,**frames[n],samples=count,percent=100*count/len(selected)) for n,count in self_counts.most_common()],
    scope='One instrumented checker invocation after one warm request. Self sample observations, not stable cost fractions or speedups. Inclusive counts overlap; source association is not a causal attribution.')
out.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(dict(complete=True,selectedSamples=len(selected),top=report['selfGroups'][:15])))
