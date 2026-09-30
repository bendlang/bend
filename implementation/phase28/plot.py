#!/usr/bin/env python3
"""Show every successful selected case and each distinct timing boundary."""
from pathlib import Path
import json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT=Path(__file__).resolve().parent
r=json.loads((ROOT/'results.json').read_text());cases=r['windows'][0]['cases'];later={c['id']:c for c in r['windows'][1]['cases']}
labels={'mandelbrot':'Mandelbrot','raytrace':'Ray tracing','editdist':'Edit distance','tree-bitonic':'Tree sorting','lexer':'Lexer','symreg':'Symbolic regression',
 'test-morning-program':'Mixed strings / map','test-evening-program':'Mixed floats / collections','test-rle-roundtrip':'Compression roundtrip','test-map-set-ops':'Map / Set operations'}
groups=[[c for c in cases if c['category']==kind] for kind in ['algorithm','small-integration']]
fig,axes=plt.subplots(2,1,figsize=(10,8),layout='constrained')
for ax,group,title in zip(axes,groups,['Existing algorithms — documented small inputs','Original tiny integration tests']):
    assert all(c['status']=='measured' for c in group)
    for i,c in enumerate(group):
        ax.barh(i-.18,c['firstCallRatio'],height=.30,color='#3764a0',label='First useful call' if i==0 else None)
        ax.barh(i+.18,c['ratio'],height=.30,color='#d88335',label='After ≥3 calls and 1s warmup' if i==0 else None)
        ax.text(c['ratio']*1.08,i+.18,f"{c['ratio']:.1f}×",va='center',fontsize=9)
        if c['id'] in later:ax.scatter(later[c['id']]['ratio'],i+.18,marker='D',s=45,color='#145345',zorder=5,label='Follow-up: ≥100 calls and 3s' if c==next(x for x in group if x['id'] in later) else None)
    ax.set_yticks(range(len(group)),[labels[c['id']] for c in group]);ax.invert_yaxis();ax.set_xscale('log');ax.set_xlim(.8,3000)
    ax.set_title(title);ax.set_xlabel('Selfhost time / TypeScript-compiler output time (log scale; lower is faster)')
    ax.spines[['top','right']].set_visible(False);ax.axvline(1,color='#555555',lw=1)
handles,names=axes[0].get_legend_handles_labels();fig.legend(handles,names,loc='lower center',bbox_to_anchor=(.5,-.04),ncol=3,fontsize=8)
fig.suptitle('Broader generated-JavaScript comparison — same source, same input')
fig.savefig(ROOT/'speed.svg',bbox_inches='tight');fig.savefig('/tmp/bend-phase28-speed.png',bbox_inches='tight')
p=ROOT/'speed.svg';p.write_text('\n'.join(s.rstrip() for s in p.read_text().splitlines())+'\n')
