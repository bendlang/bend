#!/usr/bin/env python3
"""Summarize retained Phase30 execution evidence and render scientific figures."""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import math
import os
import platform
import shutil
import statistics
import sys
import traceback

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DESIGN = ROOT / 'design/phase30/final-evidence-figures.md'
ORIGINALS = ['mandelbrot', 'editdist', 'tree-bitonic', 'lexer', 'symreg',
             'test-morning-program', 'test-evening-program', 'test-rle-roundtrip',
             'test-map-set-ops', 'raytrace']
SIDES = ['typescript', 'phase29', 'candidate']
LABELS = {'typescript': 'Pinned TypeScript output', 'phase29': 'Phase29 output', 'candidate': 'Final candidate output'}
COLORS = {'typescript': '#4c566a', 'phase29': '#c45d32', 'candidate': '#2478a4'}
PHASE29_API = '10510efda268bac1f31cc8fed87a9315e8f9edfa15aad6b90b0d96756c217b11'
PINNED_NODE_SHA = '41a74efb34cbde5c7632cdac0cf8bd1a14d0b8d73dc1e82755014d9a9ce70f5c'
PINNED_NODE_VERSION = 'v24.18.0'
PINNED_NODE_ARGS = ['--stack-size=4096', '--max-old-space-size=1024']


def identity(file):
    file = Path(file).resolve()
    raw = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def read(file):
    return json.loads(Path(file).read_text())


def save(file, value):
    Path(file).write_text(json.dumps(value, indent=2, allow_nan=False) + '\n')


def near(a, b):
    assert math.isclose(a, b, rel_tol=1e-10, abs_tol=1e-12), (a, b)


def compact(value):
    return json.dumps(value, separators=(',', ':'), allow_nan=False)


class Evidence:
    def __init__(self):
        self.inputs = {}

    def retain(self, file, expected=None):
        item = identity(file)
        if expected is not None:
            assert item['sha256'] == expected['sha256'], 'Changed input: ' + str(file)
            if 'bytes' in expected:
                assert item['bytes'] == expected['bytes']
        previous = self.inputs.get(item['file'])
        assert previous is None or previous == item
        self.inputs[item['file']] = item
        return item

    def verify(self):
        for item in self.inputs.values():
            assert identity(item['file']) == item, item['file']

    def receipt(self, file, module_hash, manifest=None):
        item = self.retain(file)
        data = read(file)
        assert data['complete'] and (data.get('checked') or data.get('observation', {}).get('checked'))
        assert data['output']['sha256'] == module_hash
        self.retain(data['input']['file'], data['input'])
        if manifest is not None:
            assert data['attempt']['sha256'] == manifest['identity']['sha256']
            for key in ['api', 'runtime', 'base']:
                assert data[key]['sha256'] == manifest[key]['sha256']
        for key in ['attempt', 'api', 'runtime', 'base', 'driver']:
            if key in data:
                self.retain(data[key]['file'], data[key])
        return {'receipt': item, 'source': data['input'],
                'attempt': data.get('attempt'), 'api': data.get('api'), 'variant': data.get('variant'), 'moduleSha256': module_hash}

    def window(self, report_file, scope, label, expected_sides=None):
        report_file = Path(report_file).resolve()
        report_identity = self.retain(report_file)
        report = read(report_file)
        assert report['kind'] == 'phase29-paired-generated-execution'
        assert report['complete'] and report['allCasesMeasured']
        assert any(item['sha256'] == PINNED_NODE_SHA for item in report['inputs']), 'Missing pinned Node identity'
        config_file = Path(report['inputs'][0]['file'])
        config_identity = self.retain(config_file, report['inputs'][0])
        config = read(config_file)
        for item in report['inputs']:
            self.retain(item['file'], item)
        configured = {case['id']: case for case in config['cases']}
        assert len(configured) == len(config['cases'])
        result = []
        for case in report['cases']:
            assert case['complete'] and case['status'] == 'measured'
            definition = configured[case['id']]
            sides = list(definition['modules'])
            if expected_sides is not None:
                assert set(sides) == set(expected_sides)
            assert set(case['sides']) == set(sides)
            for key, value in definition['point'].items():
                assert case['point'][key] == value
            row = {'scope': scope, 'window': label, 'report': report_identity, 'configuration': config_identity,
                   'case': case['id'], 'point': case['point'], 'protocol': report['protocol'],
                   'protocolName': config['protocol'], 'scopeDescription': report['scope'], 'sides': {}}
            for side in sides:
                module = self.retain(definition['modules'][side])
                samples = [sample for sample in case['samples'] if sample['variant'] == side]
                assert len(samples) == report['protocol']['samples']
                assert {sample['repetition'] for sample in samples} == set(range(len(samples)))
                observations = []
                for sample in samples:
                    observed = sample['result']
                    assert sample['complete'] and observed['complete'] and observed['mode'] == 'time'
                    assert observed['module']['sha256'] == module['sha256']
                    assert observed['firstResult'] == case['point']['expected']
                    assert observed['node'] == PINNED_NODE_VERSION
                    assert observed['args'] == PINNED_NODE_ARGS
                    assert observed['affinity'].split(':')[1].strip() == '3'
                    repetitions = observed['repetitions']
                    assert isinstance(repetitions, int) and repetitions > 0
                    cost = observed['executionMs'] / repetitions
                    assert math.isfinite(cost) and cost > 0
                    halves = observed['halves']
                    assert len(halves) in [1, 2] and sum(h['calls'] for h in halves) == repetitions
                    half_costs = [h['ms'] / h['calls'] for h in halves]
                    assert all(math.isfinite(x) and x > 0 for x in half_costs)
                    drift = (half_costs[1] / half_costs[0] - 1) * 100 if len(half_costs) == 2 else None
                    observations.append({'sample': sample['repetition'], 'repetitions': repetitions,
                        'perCallMs': cost, 'executionMs': observed['executionMs'],
                        'firstCallMs': observed['firstCallMs'], 'importMs': observed['importMs'],
                        'peakRssKiB': observed['peakRssKiB'], 'halves': halves, 'halfCostMs': half_costs,
                        'halfDriftPercent': drift, 'node': observed['node'], 'nodeArgs': observed['args'],
                        'affinity': observed['affinity'], 'warmupCalls': observed['warmup'], 'warmupMs': observed['warmupMs']})
                costs = [x['perCallMs'] for x in observations]
                first = [x['firstCallMs'] for x in observations]
                drifts = [x['halfDriftPercent'] for x in observations if x['halfDriftPercent'] is not None]
                stats = {'module': module, 'medianMs': statistics.median(costs), 'minMs': min(costs), 'maxMs': max(costs),
                         'samplesMs': costs, 'firstCallMedianMs': statistics.median(first),
                         'firstCallMinMs': min(first), 'firstCallMaxMs': max(first), 'firstCallSamplesMs': first,
                         'halfDriftPercent': drifts, 'halfDriftMinPercent': min(drifts) if drifts else None,
                         'halfDriftMaxPercent': max(drifts) if drifts else None,
                         'maxAbsoluteHalfDriftPercent': max(map(abs, drifts)) if drifts else None,
                         'singleCallSamples': sum(len(x['halves']) == 1 for x in observations), 'samples': observations}
                for key in ['medianMs', 'minMs', 'maxMs', 'firstCallMedianMs']:
                    near(stats[key], case['sides'][side][key])
                assert len(costs) == len(case['sides'][side]['samplesMs'])
                for a, b in zip(costs, case['sides'][side]['samplesMs']):
                    near(a, b)
                assert len(first) == len(case['sides'][side]['firstCallSamplesMs'])
                for a, b in zip(first, case['sides'][side]['firstCallSamplesMs']):
                    near(a, b)
                row['sides'][side] = stats
            row['ratios'] = {a + '_over_' + b: row['sides'][a]['medianMs'] / row['sides'][b]['medianMs']
                             for a in sides for b in sides}
            row['warnings'] = [side + ': absolute half drift exceeds10%' for side, data in row['sides'].items()
                               if data['maxAbsoluteHalfDriftPercent'] is not None and data['maxAbsoluteHalfDriftPercent'] > 10]
            row['warnings'] += [side + ': some timed samples contain only one call; within-sample drift unavailable'
                                for side, data in row['sides'].items() if data['singleCallSamples']]
            result.append(row)
        return result


def csv_outputs(out, windows):
    side_rows, sample_rows = [], []
    for window in windows:
        for side, data in window['sides'].items():
            shared = {'scope': window['scope'], 'window': window['window'], 'case': window['case'], 'side': side,
                      'report': window['report']['file'], 'report_sha256': window['report']['sha256'],
                      'module_sha256': data['module']['sha256'], 'point': compact(window['point']),
                      'protocol': window['protocolName']}
            side_rows.append({**shared, **{k: data[k] for k in ['medianMs', 'minMs', 'maxMs', 'firstCallMedianMs',
                'firstCallMinMs', 'firstCallMaxMs', 'halfDriftMinPercent', 'halfDriftMaxPercent',
                'maxAbsoluteHalfDriftPercent', 'singleCallSamples']},
                'samplesMs': compact(data['samplesMs']), 'firstCallSamplesMs': compact(data['firstCallSamplesMs']),
                'halfDriftPercent': compact(data['halfDriftPercent']),
                'over_typescript': window['ratios'].get(side + '_over_typescript'),
                'phase29_over_side': window['ratios'].get('phase29_over_' + side),
                'warnings': '; '.join(window['warnings'])})
            for sample in data['samples']:
                sample_rows.append({**shared, **{k: sample[k] for k in ['sample', 'repetitions', 'perCallMs',
                    'executionMs', 'firstCallMs', 'importMs', 'peakRssKiB', 'halfDriftPercent', 'warmupCalls', 'warmupMs']},
                    'halves': compact(sample['halves']), 'halfCostMs': compact(sample['halfCostMs'])})
    for name, rows in [('summary.csv', side_rows), ('samples.csv', sample_rows)]:
        with (out / name).open('w', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)


def render(out, summary):
    # This import is intentionally delayed until after all input validation.
    os.environ['MPLCONFIGDIR'] = str(out / 'matplotlib-cache')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.ticker import ScalarFormatter
    plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10, 'svg.fonttype': 'none',
                         'axes.spines.top': False, 'axes.spines.right': False, 'figure.dpi': 120})
    artifacts = []

    def finish(fig, name):
        for extension in ['svg', 'png']:
            target = out / (name + '.' + extension)
            fig.savefig(target, dpi=200, bbox_inches='tight', metadata={'Creator': 'Phase30 retained-evidence plotting tool'})
            artifacts.append(identity(target))
        plt.close(fig)

    windows = summary['originalPrograms']
    fig, ax = plt.subplots(figsize=(14, 6))
    for offset, side in [(-0.19, 'phase29'), (0.19, 'candidate')]:
        x = [i + offset for i in range(len(windows))]
        values, lower, upper = [], [], []
        for row in windows:
            a, b = row['sides'][side], row['sides']['typescript']
            ratio = a['medianMs'] / b['medianMs']
            values.append(ratio)
            lower.append(ratio - a['minMs'] / b['maxMs'])
            upper.append(a['maxMs'] / b['minMs'] - ratio)
        ax.bar(x, values, width=0.35, color=COLORS[side], label=LABELS[side], yerr=[lower, upper], capsize=2,
               error_kw={'linewidth': 0.8, 'ecolor': '#293241'})
        for position, value in zip(x, values):
            ax.annotate(f'{value:.2g}×', (position, value), xytext=(0, 5), textcoords='offset points', ha='center', fontsize=8)
    labels = [row['case'].replace('test-', '').replace('-program', '').replace('-', '\n') +
              (' †' if any('exceeds10%' in warning for warning in row['warnings']) else '') for row in windows]
    ax.set_xticks(range(len(windows)), labels)
    ax.set_yscale('log')
    ax.set_ylabel('Execution time / same-window TypeScript time (log scale)')
    ax.axhline(1, color=COLORS['typescript'], linestyle='--', linewidth=1, label='TypeScript 1×')
    ax.margins(y=0.18)
    ax.set_title('Complete original-program points: Phase29 and ' + summary['candidate']['label'])
    ax.grid(axis='y', which='major', alpha=0.2)
    ax.legend(loc='upper right', fontsize=9)
    fig.text(0.01, -0.025, 'Sample-extrema ratio envelopes, not confidence intervals. † At least one side has >10% timed-half drift.\n'
             'Each program uses its own rotating CPU3 window. Selected inputs are not a production-workload distribution.', fontsize=9)
    finish(fig, 'original-program-slowdown')

    windows = sorted(summary['scalarScaling'], key=lambda row: row['point']['args'][0])
    fig, ax = plt.subplots(figsize=(9, 5.5))
    x = [row['point']['args'][0] for row in windows]
    for side in SIDES:
        data = [row['sides'][side] for row in windows]
        costs = [d['medianMs'] * 1000 for d in data]
        errors = [[(d['medianMs'] - d['minMs']) * 1000 for d in data],
                  [(d['maxMs'] - d['medianMs']) * 1000 for d in data]]
        ax.errorbar(x, costs, yerr=errors, color=COLORS[side], marker='o', linestyle='--', linewidth=1.2,
                    capsize=3, label=LABELS[side])
    ax.set_xscale('symlog', linthresh=128)
    ax.set_xticks(x)
    ax.xaxis.set_major_formatter(ScalarFormatter())
    ax.set_yscale('log')
    ax.set_xlabel('Requested iterations (symmetric log axis; linear through128)')
    ax.set_ylabel('Complete scalar helper call (µs, log scale)')
    ax.set_title('Scalar fixture only: seed524800, measured window ' + summary['scalingWindowLabel'])
    ax.grid(which='major', alpha=0.2)
    ax.legend(fontsize=9)
    fig.text(0.01, -0.025, 'Bars show sample min/max, not confidence intervals. Connecting lines are guides only.\n'
             'The zero branch is different; no common intercept or compiler-throughput model is implied.', fontsize=9)
    finish(fig, 'scalar-helper-scaling')

    if summary.get('historicalTreeCounts'):
        data = summary['historicalTreeCounts']
        keys = ['apply', 'fn', 'partial', 'jump', 'force', 'project', 'guards']
        fig, ax = plt.subplots(figsize=(10, 5))
        for offset, side, label in [(-0.19, 'baseline', 'Actual11'), (0.19, 'candidate', 'Actual12')]:
            values = [data['counts'][side][key] for key in keys]
            ax.bar([i + offset for i in range(len(keys))], values, width=0.35, label=label,
                   color=COLORS['phase29' if side == 'baseline' else 'candidate'])
        ax.set_xticks(range(len(keys)), keys)
        ax.set_yscale('symlog', linthresh=1)
        ax.set_ylabel('Named events per complete call (symmetric log axis)')
        ax.set_title('Historical mechanism diagnostic: actual11 → actual12, bench(2,0)')
        ax.legend()
        ax.grid(axis='y', alpha=0.2)
        fig.text(0.01, -0.025, 'Instrumented named-site counts. Guards aggregate the recorded guard dictionary.\n'
                 'These are not CPU shares, total allocations or final-image counts.', fontsize=9)
        finish(fig, 'historical-tree-operation-counts')
    from matplotlib.font_manager import findfont
    return {'matplotlib': matplotlib.__version__, 'matplotlibFile': identity(matplotlib.__file__),
            'font': identity(findfont('DejaVu Sans')), 'artifacts': artifacts}


def markdown(out, summary):
    rows = ['# Retained Phase30 execution figures', '',
            'Selected compiler: **' + summary['candidate']['label'] + '**; API `' + summary['candidate']['api']['sha256'] + '`.', '',
            'Ratios below use only sides measured within the same case/window. Raw sample ranges are not confidence intervals.', '',
            '![Original-program slowdown](original-program-slowdown.svg)', '',
            '| Program | Phase29 ms | Candidate ms | TypeScript ms | Phase29 / candidate | Candidate / TS |',
            '| --- | ---: | ---: | ---: | ---: | ---: |']
    for window in summary['originalPrograms']:
        s = window['sides']
        rows.append('| ' + window['case'] + ' | ' + ' | '.join(f'{s[k]["medianMs"]:.6g}' for k in ['phase29', 'candidate', 'typescript']) +
                    f' | {window["ratios"]["phase29_over_candidate"]:.4g}× | {window["ratios"]["candidate_over_typescript"]:.4g}× |')
    measured_images = sorted({Path(r['attempt']['file']).parent.name for r in summary['scalingMeasuredEmissions']['candidate'] if r.get('attempt')})
    rows += ['', '![Scalar helper scaling](scalar-helper-scaling.svg)', '',
             'Measured helper acquisition image(s): **' + ', '.join(measured_images) + '**. The selected final-image checked receipt separately proves exact emitted-byte equality.', '',
             'Helper scaling is a separate source/input scope. Zero follows its real zero branch; the1024→8192 median finite differences are estimates, not a fitted model.', '',
             '| Side | Estimated ms / added iteration |', '| --- | ---: |']
    for side, value in summary['finiteDifferenceMsPerIteration'].items():
        rows.append(f'| {side} | {value:.8g} |')
    if summary.get('historicalTreeCounts'):
        rows += ['', '![Historical operation counts](historical-tree-operation-counts.svg)', '',
                 'Historical actual11→12 instrumented named events; not CPU shares or final-image counts.']
    rows += ['', 'Full first-call, min/max, timed-half, repetition, import and RSS observations are retained in',
             '[summary.json](summary.json), [summary.csv](summary.csv) and [samples.csv](samples.csv).', '', 'Warnings:', '']
    warnings = [(w['scope'], w['window'], w['case'], warning) for w in summary['originalPrograms'] + summary['scalarScaling'] for warning in w['warnings']]
    rows += ['- ' + ' / '.join(row) for row in warnings] if warnings else ['No timed-half drift above10% or single-call timed samples were observed in these final windows.']
    if summary['historicalWindows']:
        rows += ['', 'Separate historical windows (not included in final plots or multiplied into their ratios):', '']
        rows += ['- ' + w['window'] + ' / ' + w['case'] + ': `' + w['report']['sha256'] + '`.' for w in summary['historicalWindows']]
    (out / 'report.md').write_text('\n'.join(rows) + '\n')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('config', type=Path)
    ap.add_argument('out', type=Path)
    args = ap.parse_args()
    config_file, out = args.config.resolve(), args.out.resolve()
    config = read(config_file)
    resolve = lambda value: (config_file.parent / value).resolve()
    out.mkdir(parents=True, exist_ok=False)
    evidence = Evidence()
    for p in [Path(__file__), DESIGN, config_file, Path(sys.executable)]:
        evidence.retain(p)
    shutil.copyfile(Path(__file__), out / 'consumed-tool.py')
    shutil.copyfile(config_file, out / 'consumed-config.json')
    generation = {'kind': 'phase30-retained-evidence-figures', 'complete': False, 'pass': False,
                  'python': platform.python_version(), 'platform': platform.platform(), 'inputs': [], 'outputs': []}
    try:
        manifest_file = resolve(config['candidateManifest'])
        manifest = read(manifest_file)
        assert manifest['checked']
        selected = {'identity': evidence.retain(manifest_file), 'label': manifest_file.parent.name,
                    **{key: evidence.retain(manifest[key]['file'], manifest[key]) for key in ['api', 'runtime', 'base']}}
        originals = []
        for value in config['originalReports']:
            file = resolve(value)
            originals += evidence.window(file, 'original-program', file.parent.name, SIDES)
        assert len(originals) == len(ORIGINALS) and {row['case'] for row in originals} == set(ORIGINALS)
        originals.sort(key=lambda row: ORIGINALS.index(row['case']))
        for window in originals:
            receipts = {}
            for side, stats in window['sides'].items():
                receipts[side] = evidence.receipt(stats['module']['file'] + '.json', stats['module']['sha256'], selected if side == 'candidate' else None)
            assert len({row['source']['sha256'] for row in receipts.values()}) == 1
            assert receipts['typescript']['variant'] == 'upstream'
            assert receipts['phase29']['api']['sha256'] == PHASE29_API
            window['emissions'] = receipts
        scaling_file = resolve(config['scalingReport'])
        scaling = evidence.window(scaling_file, 'scalar-helper', scaling_file.parent.name, SIDES)
        assert len(scaling) == 4 and sorted(row['point']['args'][0] for row in scaling) == [0, 128, 1024, 8192]
        assert all(row['point']['args'][1] == 524800 and row['point']['expected'] == row['point']['args'][0] for row in scaling)
        for side in SIDES:
            assert len({row['sides'][side]['module']['sha256'] for row in scaling}) == 1
        measured_emissions = {}
        # Locate receipts only among the inputs actually consumed by this scaling
        # window; the later final-image receipt must not relabel its acquisition.
        raw_scaling = read(scaling_file)
        for side in SIDES:
            digest = scaling[0]['sides'][side]['module']['sha256']
            matches = []
            for item in raw_scaling['inputs']:
                if not item['file'].endswith('.mjs.json'):
                    continue
                data = read(item['file'])
                if data.get('complete') and data.get('output', {}).get('sha256') == digest:
                    row = evidence.receipt(item['file'], digest)
                    if row not in matches:
                        matches.append(row)
            assert matches, 'Missing consumed scaling emission receipt: ' + side
            if side == 'typescript':
                assert all(row['variant'] == 'upstream' for row in matches)
            if side == 'phase29':
                assert all(row['api']['sha256'] == PHASE29_API for row in matches)
            measured_emissions[side] = matches
        receipt = evidence.receipt(resolve(config['scalingCandidateReceipt']), scaling[0]['sides']['candidate']['module']['sha256'], selected)
        assert all(row['source']['sha256'] == receipt['source']['sha256'] for rows in measured_emissions.values() for row in rows)
        by_count = {row['point']['args'][0]: row for row in scaling}
        slopes = {side: (by_count[8192]['sides'][side]['medianMs'] - by_count[1024]['sides'][side]['medianMs']) / (8192 - 1024) for side in SIDES}
        summary = {'kind': 'phase30-final-execution-evidence-summary', 'complete': True, 'candidate': selected,
                   'originalPrograms': originals, 'scalarScaling': scaling, 'scalingWindowLabel': scaling_file.parent.name,
                   'scalingMeasuredEmissions': measured_emissions, 'scalingFinalImageByteEquality': receipt, 'finiteDifferenceMsPerIteration': slopes,
                   'historicalWindows': [], 'limitations': ['Selected input points, not a production average.',
                   'Same-window ratios only; no multiplied historical gains.', 'Sample extrema are not confidence intervals.',
                   'Zero helper branch differs; finite differences are estimates only.']}
        for historical in config.get('historicalReports', []):
            summary['historicalWindows'] += evidence.window(resolve(historical['report']), 'historical-separate', historical['label'])
        if config.get('treeCounts'):
            file = resolve(config['treeCounts'])
            count_report = read(file)
            assert count_report['complete'] and count_report['pass']
            assert count_report['kind'] == 'phase30-actual-scalar-tree-counts'
            count_identity = evidence.retain(file)
            for item in count_report['inputs']:
                evidence.retain(item['file'], item)
            observed_hashes = {item['sha256'] for item in count_report['inputs']}
            assert {'87a451969d5c2a6f073f41fc8f5dda58cde08a381cc200b51d69a62597b47b8c',
                    'dbd065e8888b757edbfe49cb707682f4d7c0924ab37a6d4f1e94022e84ea3b3e'} <= observed_hashes, 'Historical counter image mismatch'
            rows = [row for row in count_report['rows'] if row['name'] == 'original-bench' and row['args'] == [2, 0]]
            assert len(rows) == 2 and {row['variant'] for row in rows} == {'baseline', 'candidate'}
            assert all(row['result'] == 887240761 for row in rows)
            summary['historicalTreeCounts'] = {'report': count_identity, 'scope': count_report['scope'],
                'labels': {'baseline': 'actual11', 'candidate': 'actual12'},
                'counts': {row['variant']: {**row['counts'], 'guards': sum(row['counts']['guards'].values())} for row in rows},
                'rawRows': rows}
        evidence.verify()
        windows = originals + scaling + summary['historicalWindows']
        csv_outputs(out, windows)
        generation['rendering'] = render(out, summary)
        markdown(out, summary)
        summary['inputs'] = list(evidence.inputs.values())
        save(out / 'summary.json', summary)
        evidence.verify()
        generation['outputs'] = [identity(p) for p in sorted(out.iterdir()) if p.is_file()]
        generation.update({'complete': True, 'pass': True})
    except Exception:
        generation['error'] = traceback.format_exc()
        raise
    finally:
        generation['inputs'] = list(evidence.inputs.values())
        save(out / 'generation.json', generation)
    print(compact({'complete': True, 'pass': True, 'out': str(out), 'outputs': len(generation['outputs'])}))


if __name__ == '__main__':
    main()
