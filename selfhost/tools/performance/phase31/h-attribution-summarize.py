#!/usr/bin/env python3
"""Attribute diagnostic intervals; do not infer clean timing speed ratios."""
import collections
import hashlib
import json
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()
assert not out.exists()
data = json.loads(source.read_text())
assert data['complete'] and data['pass']
events = data['traceEvents']
report = dict(kind='phase31-h-attribution-summary', complete=False, variant=data['variant'],
              input=dict(file=str(source), sha256=hashlib.sha256(source.read_bytes()).hexdigest()),
              scope='Instrumented, non-exclusive elapsed intervals; no clean speed comparison.', requests=[])
abi_re = re.compile(r'\] ABI (\S+) (encode|invoke|decode|return) (\{[^\n]*\})\n$')
request = None
call = None
for event in events:
    kind, now = event['kind'], event['ms']
    if kind == 'request-start':
        assert request is None and call is None
        request = dict(index=event['index'], start=now, calls=[], stages=[])
    elif kind == 'request-end':
        assert request is not None and call is None
        assert request['index'] == event['index']
        request['end'] = now
        request['elapsedMs'] = now-request['start']
        by_export = collections.defaultdict(lambda: dict(calls=0, apiMs=0., encodeMs=0., invokeMs=0., decodeMs=0., wrapperMs=0., encodedObjects=0, unwrappedViews=0, directDecodedViews=0))
        previous_stats = None
        lazy_views = 0
        for c in request['calls']:
            row = by_export[c['name']]
            row['calls'] += 1
            row['apiMs'] += c['elapsedMs']
            if c['abi']:
                assert [x['phase'] for x in c['abi']] == ['encode','invoke','decode','return']
                a,b,d,e = c['abi']
                assert c['start'] <= a['ms'] <= b['ms'] <= d['ms'] <= e['ms'] <= c['end']
                row['encodeMs'] += b['ms']-a['ms']
                row['invokeMs'] += d['ms']-b['ms']
                row['decodeMs'] += e['ms']-d['ms']
                row['wrapperMs'] += a['ms']-c['start']+c['end']-e['ms']
                row['encodedObjects'] += b['stats']['encoded']-a['stats']['encoded']
                row['unwrappedViews'] += b['stats']['unwrapped']-a['stats']['unwrapped']
                row['directDecodedViews'] += e['stats']['views']-d['stats']['views']
                if previous_stats is not None:
                    difference = a['stats']['views']-previous_stats['views']
                    assert difference >= 0
                    lazy_views += difference
                previous_stats = e['stats']
            else:
                assert data['variant'] == 'checked_parent'
                row['invokeMs'] += c['elapsedMs']
        totals = {key:sum(row[key] for row in by_export.values()) for key in next(iter(by_export.values())).keys()}
        totals['hostRemainderMs'] = request['elapsedMs']-totals['apiMs']
        totals['lazyViewsBetweenCalls'] = lazy_views
        assert totals['hostRemainderMs'] >= 0
        assert abs(totals['apiMs']-sum(totals[k] for k in ['encodeMs','invokeMs','decodeMs','wrapperMs'])) < 1e-6
        request['totals'] = totals
        request['exports'] = dict(sorted(by_export.items(), key=lambda x:-x[1]['apiMs']))
        report['requests'].append(request)
        request = None
    elif request is not None:
        if kind == 'api-enter':
            assert call is None
            call = dict(name=event['name'], start=now, abi=[])
        elif kind == 'api-leave':
            assert call is not None and call['name'] == event['name']
            call['end'] = now
            call['elapsedMs'] = now-call['start']
            if data['variant'] == 'generated_h': assert len(call['abi']) == 4
            request['calls'].append(call)
            call = None
        elif kind == 'stderr':
            matched = abi_re.search(event['text'])
            if matched:
                name, phase, stats = matched.groups()
                assert call is not None and call['name'] == name
                call['abi'].append(dict(phase=phase, ms=now, stats=json.loads(stats)))
            else:
                request['stages'].append(event)
        else:
            raise AssertionError(f'Unexpected event inside request: {event}')
assert request is None and call is None
assert len(report['requests']) == 3
report['complete'] = True
report['pass'] = True
out.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['complete','pass','variant']}))
