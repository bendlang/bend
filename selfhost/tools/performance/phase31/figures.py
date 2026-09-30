#!/usr/bin/env python3
"""Render protocol-labelled measured results; never run benchmark programs."""
import hashlib, json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT = Path(__file__).resolve().parents[4]
RAW = ROOT / 'selfhost/build/phase31/local-data-ablation-transfer-01/report.json'
OUT = ROOT / 'implementation/phase31/figures'
assert not OUT.exists()
OUT.mkdir()
r = json.loads(RAW.read_text())
assert r['complete'] and r['allCasesMeasured'] and len(r['cases']) == 2
roles = ['baseline17', 'checked04', 'checked05', 'checked06', 'checked07', 'typescript']
labels = ['Previous release', 'Closed local calls', 'Completed returns', 'No redundant force', 'Direct field reads', 'Upstream TypeScript']
colors = ['#747c89', '#a0bddd', '#71a0cd', '#3c81b5', '#15735d', '#25364b']
fig, axes = plt.subplots(1, 2, figsize=(12.4, 5.2), layout='constrained')
for ax, case, title in zip(axes, r['cases'], ['Complete edit-distance pair (256 × 256)', 'Distinct array fold (4,096 steps)']):
    for i, role in enumerate(roles):
        s = case['sides'][role]
        mid, lo, hi = s['medianMs'], s['minMs'], s['maxMs']
        ax.errorbar(mid, i, xerr=[[mid-lo], [hi-mid]], fmt='o', color=colors[i], capsize=4, markersize=7)
        ax.annotate(f'{mid:.4g} ms', (hi, i), xytext=(9, 0), textcoords='offset points', va='center', fontsize=9)
    ax.set_yticks(range(len(roles)), labels)
    ax.invert_yaxis()
    ax.set_xscale('log')
    ax.set_xlim(min(case['sides'][x]['minMs'] for x in roles) / 1.7, max(case['sides'][x]['maxMs'] for x in roles) * 4)
    ax.set_title(title, fontsize=12, pad=14)
    ax.set_xlabel('Milliseconds per complete call · logarithmic scale · lower is faster')
    ax.grid(axis='x', alpha=.2)
    ax.spines[['top', 'right', 'left']].set_visible(False)
    ax.tick_params(axis='y', length=0)
fig.suptitle('Closed local data removes repeated runtime work', fontsize=17)
fig.supxlabel('Five rotating fresh processes per compiler · median and full range · Node 24.18.0, CPU3\n'
               'Transfer protocol: ≥3 calls AND 1 s warmup, 300 ms target. Fold still warms ~9% between halves.', fontsize=9)
for suffix in ['svg', 'png']:
    fig.savefig(OUT / ('local-data-ablation.' + suffix), dpi=160)
plt.close(fig)
def ident(p):
    b=p.read_bytes();return {'path':str(p.relative_to(ROOT)), 'bytes':len(b), 'sha256':hashlib.sha256(b).hexdigest()}
(OUT / 'receipt.json').write_text(json.dumps({'complete':True, 'inputs':[ident(RAW), ident(Path(__file__).resolve())], 'outputs':[ident(x) for x in sorted(OUT.iterdir())], 'scope':'Rendering of existing reported medians/ranges; no new timing.'}, indent=2)+'\n')
