#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[4];out=r/'selfhost/build/phase19/context-controls-01';out.mkdir(parents=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
prefix='''type A is Data:
  C{}
type Fam<T: Type> is Data:
  Mk{value: T}
def f() -> Type:
  Type
def near.f() -> Type:
  Type
def mod.f() -> Type:
  Type
def M.f() -> Type:
  Type
'''
(out/'prior.bend').write_text(prefix)
cases=[]
def add(name,text,header=')',ns='',aliases=None,supported=True):
 cases.append({'id':name,'text':text,'header':header,'namespace':ns,'aliases':aliases or {},'supported':supported,'sourceBegin':4097})
add('unbound','x')
add('global','f')
add('datatype-bare','A')
add('family-bare','Fam')
add('constructor-spelling','C')
add('bound','x','x: A)')
add('newest-shadow','x','x: A, x: Fam<A>)')
add('marked-header-binding','x','+x: A)')
add('underscore','_','_: A, x: A)')
add('missing-dotted','missing.x')
add('near-choice','f',ns='near')
add('far-choice','A',ns='near')
add('missing-near','fresh',ns='near')
add('near-dotted','missing.x',ns='near')
add('alias','N.f',aliases={'N':'mod'})
add('alias-missing','N.absent',aliases={'N':'mod'})
add('alias-far-fallback','M.f',aliases={'M':'absent'})
add('alias-ambiguous','M.f',aliases={'M':'mod'})
add('bound-alias-ambiguous','M.f','M.f: A)',aliases={'M':'mod'})
add('shadowed-constructor','C','C: A)')
add('sibling-a','x','x: A)')
add('sibling-b','x','y: A)')
add('repeated-sibling-a','x','x: A)')
add('empty','','',supported=False)
add('marked-unsupported','+x',supported=False)
add('compound-unsupported','x()',supported=False)
add('body-unsupported','x = f\n x',supported=False)
data={'stage':'private names/state primitives only','parentAttempt':str(r/'selfhost/build/phase18/cursor-build-01'),
 'priorFile':str(out/'prior.bend'),'cases':cases,
 'protocol':['parse_var','parse_open','parse_var','parse_close','parse_var','token-only rewind'],
 'futureRequiredSelections':[str(r/'selfhost/build/phase18/cursor-controls-01/selection.json')],
 'coverageLimits':['No body grammar migration','No contextual Core result','Unsupported rows are not conformance passes']}
(out/'cases.json').write_text(json.dumps(data,indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-prepare.py')
paths=[Path(__file__),r/'design/phase19/contextual-parser-slice.md',r/'design/phase19/names-state-stage1.md',out/'prior.bend',out/'cases.json']
(out/'manifest.json').write_text(json.dumps({'complete':True,'inputs':[{'file':str(p),'sha256':sha(p)}for p in paths]},indent=2)+'\n')
print(out)
