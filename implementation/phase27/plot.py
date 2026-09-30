#!/usr/bin/env python3
"""Plot separately measured protocols, never pooled samples."""
from pathlib import Path
import json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT=Path(__file__).resolve().parent
r=json.loads((ROOT/'results.json').read_text())
ids=['term-substitution','compiler-membership','boolean-worker']
labels=['Term substitution','Compiler membership','Boolean traversal']
fig,axes=plt.subplots(1,2,figsize=(10,3.8),sharey=True,layout='constrained')
for ax,n,title in zip(axes,[0,2],['Inline candidate — rejected','Shared helper — selected']):
    for offset,w,color,label in [(-.17,r['windows'][n],'#3764a0','100 ms / 8-call warmup'),(.17,r['windows'][n+1],'#19977a','500 ms / 200-call warmup')]:
        values=[next(c['speedup'] for c in w['cases'] if c['id']==k) for k in ids]
        positions=[i+offset for i in range(3)]
        ax.barh(positions,values,height=.28,color=color,label=label)
        for y,v in zip(positions,values):ax.text(v+.01,y,f'{v:.3f}×',va='center',fontsize=9)
    ax.axvline(1,color='#555555',linewidth=1);ax.set_xlim(0,1.36)
    ax.set_yticks(range(3),labels);ax.set_title(title)
    ax.set_xlabel('Before / candidate median time (higher is faster)')
    ax.spines[['top','right']].set_visible(False)
axes[0].invert_yaxis()
fig.legend(*axes[1].get_legend_handles_labels(),loc='lower center',bbox_to_anchor=(.5,-.08),ncol=2,fontsize=8)
fig.suptitle('Generated JavaScript: warmup policy changes the observed gain')
fig.savefig(ROOT/'speed.svg',bbox_inches='tight')
fig.savefig('/tmp/bend-phase27-speed.png',bbox_inches='tight')
p=ROOT/'speed.svg';p.write_text('\n'.join(s.rstrip() for s in p.read_text().splitlines())+'\n')
