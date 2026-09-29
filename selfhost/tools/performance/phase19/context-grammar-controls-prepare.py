#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[4];out=r/'selfhost/build/phase19/context-grammar-controls-01';out.mkdir()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
shutil.copy2(r/'selfhost/build/phase19/context-controls-01/prior.bend',out/'prior.bend')
cases=[]
def add(id,text,header=')',ns='',aliases=None,supported=True):
 cases.append(dict(id=id,text=text,header=header,namespace=ns,aliases=aliases or {},supported=supported,sourceBegin=4097))
add('unbound','x');add('bound','x','x: A)');add('family-syntax','Fam');add('constructor-syntax','C')
add('unbound-empty-call','x()');add('bound-empty-call','x()','x: A)')
add('global-call','f(x)');add('bound-call','f(x)','f: A, x: A)')
add('nested-call','f(g(x), y)');add('repeated-call','f(x)(y)');add('nested-empty','f(g())')
add('near-call','f(x)',ns='near');add('far-call','A(x)',ns='near')
add('alias-call','N.f(x)',aliases={'N':'mod'});add('alias-absent','N.absent(x)',aliases={'N':'mod'})
add('alias-first-error','M.f(return)',aliases={'M':'mod'})
add('shadow-exposes-later-error','M.f(return)','M.f: A)',aliases={'M':'mod'})
add('shadow-valid-call','M.f(x)','M.f: A, x: A)',aliases={'M':'mod'})
add('nested-alias-first','f(M.f(return))',aliases={'M':'mod'})
add('syntax-before-later-alias','f(return, M.f(x))',aliases={'M':'mod'})
add('alias-before-unsupported','M.f(x => x)',aliases={'M':'mod'})
add('argument-alias-before-later-error','f(M.f, return)',aliases={'M':'mod'})
add('missing-argument','f(,x)');add('missing-close','f(x');add('empty-input','')
add('spaces','  f ( x , y )  ');add('newline-call-boundary','f\n(x)')
add('newline-argument','f(\n x,\n y\n)');add('underscore','f(_)','_: A)')
add('sibling-a','f(x)','f: A)');add('sibling-b','f(x)','x: A)');add('repeated-sibling-a','f(x)','f: A)')
for id,text in [('group','(x)'),('lambda','x => x'),('do','do M<A>: return x'),('family','Fam<A>'),('marked','+x'),('constructor','C{}'),('offload','f!(x)'),('index','x[y]'),('operator','x + y'),('literal','1'),('nested-group','f((x))'),('nested-lambda','f(x => x)'),('template','f(~x)'),('body','x = y\n x')]:
 add('unsupported-'+id,text,supported=False)
data=dict(stage='private existing-grammar names/calls',parentAttempt=str(r/'selfhost/build/phase19/context-build-02'),priorFile=str(out/'prior.bend'),cases=cases,coverageLimits=['No Core result','No public parser or loader routing','Unsupported controls are not conformance passes'])
(out/'cases.json').write_text(json.dumps(data,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-prepare.py')
files=[Path(__file__),r/'design/phase19/names-grammar-routing.md',out/'cases.json',out/'prior.bend']
(out/'manifest.json').write_text(json.dumps(dict(complete=True,inputs=[dict(file=str(p),sha256=sha(p))for p in files]),indent=2)+'\n')
print(out)
