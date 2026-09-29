#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[4];out=r/'selfhost/build/phase19/context-flatten-controls-02';out.mkdir();nil={'$':'Nil'}
def ls(xs):
 t=nil
 for x in reversed(xs):t={'$':'Con','head':x,'tail':t}
 return t
def term(tag,name='',id=0,kids=[]):return dict(zip(['$','tag','name','id','quant','kids','removed','originBegin','originEnd'],['KTerm',tag,name,id,1,ls(kids),nil,10,11]))
e=term('Error','selected first failure');v=term('Var','n');result={'$':'FFlatten','term':e,'next':17};row=term('Row',kids=[term('Patterns',kids=[term('Var','x',1)]),term('Ref','value')]);local=term('Local',kids=[v,term('Ref','rhs'),term('Ref','continuation')]);parallel=term('Parallel',kids=[term('Patterns',kids=[v]),term('Values',kids=[term('Ref','rhs')]),term('Ref','continuation')]);ctor=term('Ctr','Zero');origin=term('Match')
cases=[dict(id=n,function=f,args=a,expected=result)for n,f,a in[
 ('flat-direct-error','ff_flat',[e,ls([v]),17]),('lambda-child-error','ff_lam',[v,result]),('local-child-error','ff_let',[local,ls([v]),result]),('parallel-child-error','ff_parallel',[parallel,ls([v]),result]),('hit-error-stops-miss','ff_hit_done',[v,nil,ls([row]),v,nil,ctor,result,origin]),('miss-error-stops-mat','ff_miss_done',[ctor,term('Ref','hit'),result])]]
cases.extend([dict(id='legacy-'+tag+'-named-diagnostic',function='f_match_error',args=[term(tag,'global'),origin],expectedNamed=True)for tag in ['Var','Ref']]);cases.append(dict(id='legacy-qualified-ref-diagnostic',function='f_match_error',args=[term('Ref','Foo.bar'),origin],expectedNamed=True,knownPinnedDifference=True))
(out/'cases.json').write_text(json.dumps(dict(cases=cases,contract='Shallow internal Error-result and unchanged legacy classifier contracts; independent real-source TS controls in context-row-oracle-02'),indent=2)+'\n');shutil.copy2(__file__,out/'consumed-prepare.py');sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();(out/'manifest.json').write_text(json.dumps(dict(complete=True,inputs=[dict(file=str(p),sha256=sha(p))for p in [Path(__file__),out/'cases.json',r/'design/phase19/shared-flatten-checkpoints.md']]),indent=2)+'\n');print(out)
