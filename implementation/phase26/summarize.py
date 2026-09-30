#!/usr/bin/env python3
"""Reconcile Phase26 raw timing/counters and count canonical compiler source."""
import hashlib,json,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
RAW=ROOT/'selfhost/build/phase26';OUT=Path(__file__).resolve().parent
BASE='7199b391865f79acd38e67b44c4fdf21bfa721e9'
def save(name,value):
    (OUT/name).write_text(json.dumps(value,indent=2)+'\n')
def census(read):
    rows=[]
    for name in json.loads(read('src/compiler.json'))['modules']:
        raw=read(name);text=raw.decode();lines=text.splitlines()
        rows.append({'file':name,'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'physicalLines':len(lines),'nonblankLines':sum(bool(s.strip()) for s in lines),**{key:len(re.findall('^'+kw+r'\s+',text,re.M)) for key,kw in [('defs','def'),('laws','law'),('types','type')]}})
    return {'modules':len(rows),**{k:sum(r[k] for r in rows) for k in ['bytes','physicalLines','nonblankLines','defs','laws','types']}}
old=census(lambda n:subprocess.check_output(['git','show',BASE+':selfhost/'+n],cwd=ROOT))
new=census(lambda n:(ROOT/'selfhost'/n).read_bytes())
save('source-census.json',{'baselineCommit':BASE,'baseline':old,'current':new,'delta':{k:new[k]-old[k] for k in old},'scope':'Canonical compiler.json Bend modules only; physical lines include blanks/comments. Declaration counts are not semantic concept counts.'})
t=json.loads((RAW/'timing-01/report.json').read_text());assert t['complete']
rows=[]
for c in t['cases']:
    assert len(c['samples'])==15 and all(s['complete'] for s in c['samples'])
    rows.append({k:c[k] for k in ['id','point','medianUsPerCall','speedup','remainingRatio']}|{'sampleRangesUsPerCall':{v:[min(xs),max(xs)] for v in ['upstream','old','candidate'] for xs in [[s['result']['executionMs']*1000/s['result']['repetitions'] for s in c['samples'] if s['variant']==v]]}})
d=json.loads((RAW/'analysis-01/report.json').read_text());assert d['complete']
save('results.json',{'complete':True,'timingRawSha256':hashlib.sha256((RAW/'timing-01/report.json').read_bytes()).hexdigest(),'cases':rows,'wallSeconds':t['wallSeconds'],'countersPerBenchCall':[{'id':c['id'],'variant':c['variant'],'counts':{k:v/10 for k,v in c['counts'].items()}} for c in d['counters']],'structure':d['summary']})
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
matplotlib.rcParams['svg.hashsalt']='phase26-u32'
selected=[r for r in rows if r['id'] in ['pinned-u32-table','pinned-u32-wide','numeric-direct']]
fig,ax=plt.subplots(figsize=(9,3.8))
labels=['Dense table loop','Wide-key loop','Direct numeric decisions']
for i,(r,label) in enumerate(zip(selected,labels)):
    m=r['medianUsPerCall'];oldratio=m['old']/m['upstream'];newratio=m['candidate']/m['upstream']
    ax.barh(i+.16,oldratio,height=.29,color='#a9b4c2',label='Before' if i==0 else None)
    ax.barh(i-.16,newratio,height=.29,color='#197b75',label='After' if i==0 else None)
    ax.text(newratio*1.08,i-.16,f'{newratio:.1f}× TS  ({r["speedup"]:.1f}× faster)',va='center',fontsize=9)
ax.set_yticks(range(3),labels);ax.set_xscale('log');ax.set_xlim(.8,4500);ax.axvline(1,color='#58616b',linewidth=1)
ax.set_xlabel('Execution time relative to pinned TypeScript output (log scale; lower is better)')
ax.set_title('Native U32 decisions: remove word construction and generic matchers')
ax.legend(loc='lower right');ax.invert_yaxis();ax.spines[['top','right']].set_visible(False)
fig.text(.02,.015,'5 fresh processes/output, checked dynamic inputs. Microkernels; not whole-compiler speed.',fontsize=9)
fig.tight_layout(rect=(0,.055,1,1));fig.savefig(OUT/'speed.svg',metadata={'Date':None});plt.close(fig)
svg=OUT/'speed.svg';svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines())+'\n')
print(json.dumps({'source':new,'timings':rows,'seconds':t['wallSeconds']},indent=2))
