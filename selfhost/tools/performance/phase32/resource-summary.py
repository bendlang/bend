#!/usr/bin/env python3
"""Summarize bounded-run receipts without executing work or changing raw evidence."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--release-closure-label', help='Caller-supplied label; this tool does not audit release correctness.')
parser.add_argument('--require-no-active', action='store_true', help='Reject unfinalized receipts except the preserved interrupted acquisition.')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[4]
raw = repo / 'selfhost/build/phase32'
output = repo / 'implementation/phase32/resource-summary.json'
controls_path = repo / 'implementation/phase32/supervisor-controls.json'
recovery_path = repo / 'implementation/phase32/resumption-02.json'
archive_path = repo / 'implementation/phase32/evidence/capture-run/run.json'


def identity(path, data=None):
    data = path.read_bytes() if data is None else data
    return dict(file=str(path.relative_to(repo)), bytes=len(data),
                sha256=hashlib.sha256(data).hexdigest())


controls = json.loads(controls_path.read_text())
expected = {str(Path(c['supervisorReceipt']['file']).relative_to(repo)): c
            for c in controls['cases']}
interrupted = 'selfhost/build/phase32/final-plan-03/run-frontend-broader/run.json'
classes = {key: [] for key in ['completed_successfully', 'completed_with_failure',
           'expected_supervisor_stop', 'unexpected_supervisor_stop',
           'interrupted_receipt', 'unfinished_receipt']}


def classify(path):
    data = path.read_bytes()
    receipt = json.loads(data)
    if Path(receipt.get('producer', {}).get('file', '')).name != 'bounded-run.py':
        return None
    rel = str(path.relative_to(repo))
    finalized = 'finished' in receipt and 'returncode' in receipt
    if rel in expected:
        control = expected[rel]
        assert control['pass'] and control['childAbsent'], rel
        assert control['supervisorReceipt']['sha256'] == hashlib.sha256(data).hexdigest(), rel
        assert receipt.get('stoppedFor') == control['expectedStoppedFor'], rel
        group = 'expected_supervisor_stop'
    elif rel == interrupted:
        assert not finalized, 'Previously interrupted receipt was overwritten'
        group = 'interrupted_receipt'
    elif not finalized:
        group = 'unfinished_receipt'
    elif receipt.get('stoppedFor'):
        group = 'unexpected_supervisor_stop'
    elif receipt.get('complete') is True and receipt.get('returncode') == 0:
        group = 'completed_successfully'
    else:
        group = 'completed_with_failure'
    row = identity(path, data)
    for key in ['returncode', 'stoppedFor', 'started', 'finished', 'wallSeconds',
                'rssLimitBytes', 'availableFloorBytes', 'secondsLimit']:
        row[key] = receipt.get(key)
    row.update(rawComplete=receipt.get('complete'), finalized=finalized,
               producerSha256=receipt['producer']['sha256'])
    for key in ['peakTreeRssBytes', 'minimumAvailableBytes']:
        row[key] = receipt.get(key) if finalized else None
    if finalized:
        row['withinRssBudget'] = row['peakTreeRssBytes'] <= row['rssLimitBytes']
    if group == 'expected_supervisor_stop':
        row.update(controlPass=True, childAbsent=True)
    return group, row


for path in sorted(raw.rglob('run.json')):
    classified = classify(path)
    if classified:
        group, row = classified
        classes[group].append(row)

aggregates = {}
for name, rows in classes.items():
    final = [r for r in rows if r['finalized']]
    peak = max(final, key=lambda r: r['peakTreeRssBytes'], default=None)
    aggregate = dict(count=len(rows), finalizedCount=len(final),
                     totalWallSeconds=sum(r['wallSeconds'] for r in final),
                     peakTreeRssBytes=peak['peakTreeRssBytes'] if peak else None,
                     peakReceipt=peak['file'] if peak else None,
                     minimumAvailableBytes=min((r['minimumAvailableBytes'] for r in final
                         if r['minimumAvailableBytes'] is not None), default=None))
    if name == 'completed_successfully':
        aggregate['allWithinRssBudget'] = all(r['withinRssBudget'] for r in final)
        aggregate['allAboveAvailableFloor'] = all(r['minimumAvailableBytes'] >=
                                                r['availableFloorBytes'] for r in final)
    aggregates[name] = aggregate

archive = dict(expectedFile=str(archive_path.relative_to(repo)), status='not-recorded',
               aggregation='Recorded separately; excluded from raw-tree counts and aggregates.')
if archive_path.exists():
    classified = classify(archive_path)
    assert classified, 'Archive capture receipt has a different producer'
    archive.update(status=classified[0], receipt=classified[1])
if args.require_no_active:
    assert not classes['unfinished_receipt'], 'Unfinalized raw-tree acquisitions remain'
    assert archive['status'] != 'unfinished_receipt', 'Archive capture is still active'

recovery = json.loads(recovery_path.read_text())
result = dict(
    kind='phase32-bounded-resource-receipt-summary', snapshotComplete=True,
    releaseClosure=dict(label=args.release_closure_label or 'not-assessed',
                        labelOrigin='caller' if args.release_closure_label else 'default',
                        verifiedByThisTool=False),
    observedUtc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    scope='All bounded-run.py run.json receipts under selfhost/build/phase32 at this snapshot, plus the separately reported archive capture. Historical unsupervised runs are excluded. Execution success is not an experiment promotion decision.',
    method=dict(
        enumeration='Recursive run.json filtered by producer basename bounded-run.py; each consumed receipt is SHA256-bound.',
        finalized='finished and returncode fields present; complete=false alone also describes expected supervisor termination.',
        incompleteMemory='Unfinalized receipts carry initial zeros; this summary uses null because no peak was flushed.',
        aggregation='Finalized wall-time sums describe captured acquisitions, not user elapsed time or compiler latency. Process-tree RSS can double-count shared pages; 100 ms polling can overshoot limits.',
        expectedStops='Two exact receipts validated against supervisor-controls.json, including absent-child observations.',
        releaseClosure='Optional caller label only; final-gate audit, installed artifact verification and CLI receipts establish correctness separately.'),
    inputs=dict(producer=identity(Path(__file__).resolve()), supervisorControls=identity(controls_path),
                interruptionRecovery=identity(recovery_path)),
    interruption=dict(originalBroaderReceipt=interrupted,
                      preservedPartialResponses=recovery['partialResponses'],
                      currentCgroupMemoryEvents=recovery['memoryEvents'], cause=recovery['cause'],
                      replacementBroaderReceipt='selfhost/build/phase32/final-plan-03/run-frontend-broader-resume-02/run.json'),
    counts={key: len(rows) for key, rows in classes.items()}, aggregates=aggregates,
    classes=classes, archiveCapture=archive)
output.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(dict(file=str(output), counts=result['counts'],
                     aggregates=aggregates, archiveCaptureStatus=archive['status']), indent=2))
