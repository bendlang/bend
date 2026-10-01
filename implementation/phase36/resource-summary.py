#!/usr/bin/env python3
"""Summarize finalized resource receipts without rerunning any experiment."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('out', type=Path)
args = parser.parse_args()
rows = []
for path in sorted((ROOT/'selfhost/build/phase36').rglob('*.json')):
    if path.name not in {'run.json', 'process.json'}:
        continue
    raw = path.read_bytes()
    data = json.loads(raw)
    if not {'rssLimitBytes', 'availableFloorBytes', 'peakTreeRssBytes'} <= data.keys():
        continue
    status = ('resource-stop' if data.get('stoppedFor') else
              'passed' if data.get('complete') else
              'failed' if data.get('returncode') is not None else 'unfinished')
    rows.append(dict(path=str(path.relative_to(ROOT)), sha256=hashlib.sha256(raw).hexdigest(),
                     status=status, **{key: data.get(key) for key in
                     ['complete', 'returncode', 'wallSeconds', 'peakTreeRssBytes',
                      'rssLimitBytes', 'minimumAvailableBytes', 'availableFloorBytes', 'stoppedFor']}))
summary = {}
for status in ['passed', 'failed', 'resource-stop', 'unfinished']:
    selected = [row for row in rows if row['status'] == status]
    peak = max(selected, key=lambda row: row['peakTreeRssBytes'] or 0) if selected else None
    summary[status] = dict(count=len(selected), peakTreeRssBytes=peak['peakTreeRssBytes'] if peak else None,
                           peakReceipt=peak['path'] if peak else None)
passed = [row for row in rows if row['status'] == 'passed']
report = dict(kind='phase36-resource-receipt-summary', created=datetime.now(timezone.utc).isoformat(),
              scope='Bounded-run and ExecutionGuard receipts at this cutoff. Nested receipts overlap; counts are not unique tests or summed CPU usage. Archive capture is recorded separately.',
              summary=summary, allPassedWithinRssBudget=all(row['peakTreeRssBytes'] <= row['rssLimitBytes'] for row in passed),
              allPassedAboveFreeMemoryFloor=all(row['minimumAvailableBytes'] >= row['availableFloorBytes'] for row in passed), rows=rows)
with args.out.open('x') as stream:
    json.dump(report, stream, indent=2)
    stream.write('\n')
print(json.dumps({key: value for key, value in report.items() if key != 'rows'}))
