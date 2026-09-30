#!/usr/bin/env python3
"""Export actual retained samples and figures; never invent aggregate speedups."""
from pathlib import Path
import csv, json, os, sys
ROOT=Path(__file__).resolve().parents[4]
os.environ.setdefault('MPLCONFIGDIR',str(ROOT/'selfhost/build/phase25/matplotlib-cache'))
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

timing,out=[Path(p).resolve() for p in sys.argv[1:]];out.mkdir(exist_ok=True)
d=json.loads((timing/'report.json').read_text());assert d['complete']
summary={'complete':True,'sampleCount':len(d['samples']),'benchmarkPoints':len(d['summary']),
         'samplesPerSide':5,'processSeconds':sum(s['processSeconds'] for s in d['samples']),
         'minimumMeasuredBlockMs':min(s['result']['executionMs'] for s in d['samples']),
         'maximumMeasuredBlockMs':max(s['result']['executionMs'] for s in d['samples']),
         'rows':d['summary'],'scope':d['scope']}
(out/'timing-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
with (out/'timing.csv').open('w') as f:
    writer=csv.writer(f,lineterminator='\n');writer.writerow(['case','size','seed','upstream_median_us','selfhost_median_us','selfhost_over_upstream','upstream_repetitions','selfhost_repetitions'])
    for r in d['summary']:writer.writerow([r['id'],r['config']['size'],r['config']['seed'],*[r['sides'][s]['medianMsPerCall']*1000 for s in ['upstream','selfhost']],r['selfhostOverUpstream'],*[r['sides'][s]['repetitions'] for s in ['upstream','selfhost']]])
large={r['id']:r for r in d['summary']};rows=sorted(large.values(),key=lambda r:r['selfhostOverUpstream'])
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'svg.fonttype':'none'})
fig,ax=plt.subplots(figsize=(10,9))
ys=list(range(len(rows)));ratios=[r['selfhostOverUpstream'] for r in rows]
ax.barh(ys,ratios,color=['#8093a0' if r['id']=='host-boundary' else '#287d8e' for r in rows])
ax.set_yticks(ys,[r['id'] for r in rows]);ax.set_xscale('log');ax.set_xlim(.8,3500);ax.axvline(1,color='#444',linewidth=1)
for y,value in zip(ys,ratios):ax.text(value*1.08,y,f'{value:,.2f}×',va='center',fontsize=9)
ax.set_xlabel('Our emitted JS / upstream-emitted JS — median time per call (log scale)')
ax.set_title('Generated-program costs vary sharply by mechanism',loc='left',weight='bold',pad=15)
ax.grid(axis='x',alpha=.2);ax.set_axisbelow(True)
fig.text(.015,.014,'Largest selected input per case; sizes 256 or 1,024, except the zero-work control.\nFive fresh-process samples per output; Node 24.18.0, core 3. These are microkernels, not whole-compiler ratios.',fontsize=9)
fig.tight_layout(rect=(0,.065,1,1))
for ext in ['png','svg','pdf']:fig.savefig(out/('runtime-ratios.'+ext),dpi=160)
plt.close(fig)
fig,axes=plt.subplots(1,2,figsize=(9,3.4),sharey=True)
for ax,side,title in zip(axes,['upstream','selfhost'],['Upstream-emitted JS','Our emitted JS']):
    names=['boolean-choice','boolean-worker'];values=[large[n]['sides'][side]['medianMsPerCall']*1000 for n in names]
    ax.bar([0,1],values,color=['#287d8e','#d98b42']);ax.set_xticks([0,1],['Branch closures','Boolean worker'])
    ax.set_yscale('log');ax.set_ylim(1,6000);ax.set_title(title)
    for x,v in enumerate(values):ax.text(x,v*1.14,f'{v:,.1f} μs',ha='center',fontsize=10)
axes[0].set_ylabel('Median time per call (log scale)')
fig.suptitle('Source-shape sensitivity: identical recurrence, size 1,024 / seed 18',weight='bold',fontsize=11)
fig.tight_layout()
for ext in ['png','svg','pdf']:fig.savefig(out/('source-shape.'+ext),dpi=160)
plt.close(fig)
for name in ['runtime-ratios.svg','source-shape.svg']:
    file=out/name;file.write_text('\n'.join(line.rstrip() for line in file.read_text().splitlines())+'\n')
print(json.dumps({k:summary[k] for k in ['sampleCount','benchmarkPoints','processSeconds','minimumMeasuredBlockMs','maximumMeasuredBlockMs']}))
