#!/usr/bin/env python3
"""Plot saved same-window medians; no benchmark execution."""
from pathlib import Path
import json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
HERE=Path(__file__).resolve().parent
r=json.loads((HERE/'results.json').read_text())
w=next(w for w in r['windows'] if w['name']=='transfer-timing-04')
rows=w['cases'];labels=[c['id'].replace('test-','').replace('-program','') for c in rows]
old=[c['overTypeScript']['old'] for c in rows];new=[c['overTypeScript']['candidate'] for c in rows]
fig,ax=plt.subplots(figsize=(10,6.5),layout='constrained')
ys=list(range(len(rows)))
ax.barh([y-.18 for y in ys],old,height=.34,color='#a5b4c7',label='Previous compiler')
ax.barh([y+.18 for y in ys],new,height=.34,color='#127b75',label='Phase29 compiler')
ax.set_yticks(ys,labels);ax.invert_yaxis();ax.set_xscale('log');ax.set_xlim(1,max(old+new)*2.2)
for i,c in enumerate(rows):
 gain=c['oldOverCandidate']; label=f"{gain:.2f}× faster" if gain>=1 else f"{(1/gain-1)*100:.0f}% slower"
 ax.text(max(old[i],new[i])*1.07,i,label,va='center',fontsize=9,color='#222222' if gain>=1 else '#a72e2e')
ax.axvline(1,color='#444444',linewidth=1)
ax.set_xlabel('Execution time relative to TypeScript-generated JavaScript (log scale; lower is better)')
fig.suptitle('Generated programs: same source, input and measurement window',x=.02,ha='left',fontsize=13,weight='bold')
ax.legend(loc='lower right',bbox_to_anchor=(1,1.005),ncol=2,frameon=False);ax.grid(axis='x',alpha=.18);ax.set_axisbelow(True)
fig.text(.02,-.035,'Five fresh processes per output; ≥3 calls and ≥1s warmup. First calls and longer-warm results are separate.\nSelected benchmark inputs; no production-average or whole-compiler claim.',fontsize=9,color='#444444')
for suffix in ['svg','png']:fig.savefig(HERE/('speed.'+suffix),dpi=160,bbox_inches='tight')

# Matplotlib emits trailing whitespace inside SVG path attributes.
p=HERE/'speed.svg';p.write_text('\n'.join(line.rstrip() for line in p.read_text().splitlines())+'\n')
