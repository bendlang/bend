#!/usr/bin/env python3
"""Freeze all four checked local-data compiler steps on pair and distinct fold."""
from pathlib import Path
import hashlib,json,shutil,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];RAW=ROOT/'selfhost/build/phase31';out=Path(sys.argv[1]).resolve()
def ident(p):
 p=p.resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def checked(p):
 d=json.loads(p.read_text());assert d['complete']and d['pass'],str(p);return d
inputs=[Path(__file__),ROOT/'design/phase31/local-data-ablation-timing.md']
modules={'pair':{'baseline17':str(RAW/'local-data-pair-02/baseline.mjs')},'fold':{'baseline17':str(RAW/'local-data-fold-source-02/candidate.mjs')}}
for v in ['04','05','06','07']:
 source=RAW/f'local-data-actual{v}-source-01';cohort=RAW/f'local-data-pair-actual{v}-01';d=json.loads((cohort/'derive.json').read_text());assert d['complete'];assert ident(Path(d['variants']['actual']['file']))==d['variants']['actual']
 modules['pair']['checked'+v]=d['variants']['actual']['file'];modules['fold']['checked'+v]=str(source/'fold.mjs')
 for stem,sourcehash in [('candidate','3987479425f7bf0d5c9e7655bb22bae29ed0d44635fdbf50eff2bb3cd869dfb4'),('fold',ident(RAW/'local-data-fold-source-02/source.bend')['sha256'])]:
  receipt=source/(stem+'.mjs.json');r=json.loads(receipt.read_text());assert r['complete']and r['observation']['checked'];assert r['input']['sha256']==sourcehash;assert r['output']['sha256']==ident(source/(stem+'.mjs'))['sha256'];inputs.extend([receipt,source/(stem+'.mjs')])
 gates=[RAW/(f'local-data-pair-actual{v}-controls-'+('02'if v=='07'else'01'))]
 gates+=[RAW/f'local-data-pair-actual{v}-counts-01',RAW/f'local-data-fold-actual{v}-controls-01',RAW/('review-actual-pair-01'if v=='04'else f'review-actual-pair{v}-01')]
 for gate in gates:checked(gate/'report.json');inputs.append(gate/'report.json')
 inputs.append(cohort/'derive.json')
modules['pair']['typescript']=str(RAW/'local-data-pair-02/typescript.mjs');modules['fold']['typescript']=str(RAW/'local-data-fold-source-02/upstream.mjs')
fold_gate=RAW/'local-data-fold4096-controls-01/report.json';fold=checked(fold_gate);assert fold['point']==dict(args=[4096,17],expected=2339999928);assert len(fold['modules'])==6
inputs.extend([fold_gate,RAW/'local-data-pair-02/derive.json',RAW/'local-data-fold-source-02/candidate.mjs.json',RAW/'local-data-fold-source-02/upstream.mjs.json'])
cases=[dict(id='actual-compiler-full-pair0',point=dict(args=[0],expected=1866542166),modules=modules['pair']),dict(id='actual-compiler-fold4096',point=fold['point'],modules=modules['fold'])]
for case in cases:
 assert list(case['modules'])==['baseline17','checked04','checked05','checked06','checked07','typescript'];inputs.extend(map(Path,case['modules'].values()))
inputs=[ident(p)for p in dict.fromkeys(inputs)];out.mkdir(parents=True,exist_ok=False)
plan=dict(kind='phase31-general-compiler-local-data-ablation',complete=True,executed=False,inputs=inputs,cases=cases,scope='One alternating window across actual checked04/05/06/07, installed17 and pinned TypeScript. Pair is unchanged256x256 computation; fold4096 is structurally distinct modulo-indexed one-array mutation. No handwritten/diagnostic modules. Adjacent steps and absolute baselines reported separately.',protocol='Unchanged transfer:5fresh samples,min3warm calls AND1s,300ms target,serial rotatingCPU3.')
save(out/'plan.json',plan);save(out/'transfer.json',dict(protocol='transfer',inputs=[ident(out/'plan.json'),*inputs],cases=cases));shutil.copyfile(Path(__file__),out/'consumed-plan.py');print(json.dumps(dict(complete=True,out=str(out),cases=len(cases),inputs=len(inputs))))
