#!/usr/bin/env python3
"""Derive one guarded F32 root from immutable checked attempt08 JavaScript."""
from pathlib import Path
import hashlib, importlib.util, json, sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / 'selfhost/build/phase30/transfer-08/raytrace/candidate.mjs'
PLAN = ROOT / 'design/phase30/f32-ordinary-root-ablation.md'
PARSER = HERE / 'inspect-terminal-region.py'
FRAMING = HERE / 'prototype-lambda-region-derive.py'
EXPECTED = 'fc22762988a5f28ffced35a47abc124d5716061e8a737caeabc8d10fe8b360a5'
NAMES = ['fl', 'isect.t2', 'isect.t', 'isect.go2', 'isect.go', 'isect5']
ARITIES = {'fl': 2, 'isect.t2': 2, 'isect.t': 1, 'isect.go2': 3, 'isect.go': 2, 'isect5': 10}
LEADING = {'fl': 2, 'isect.t2': 1, 'isect.t': 1, 'isect.go2': 2, 'isect.go': 2, 'isect5': 10}

def identity(p):
    p=Path(p).resolve();raw=p.read_bytes()
    return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}

spec=importlib.util.spec_from_file_location('phase30_frozen_generated_parser',PARSER)
parser=importlib.util.module_from_spec(spec);spec.loader.exec_module(parser)
parser.ARITIES=ARITIES
lexical=lambda name:'$F'+''.join('_'+str(ord(c)) for c in name)

def private(expr):
    out=parser.private_calls(expr,set(NAMES)-{'isect5'})
    for name in NAMES:out=out.replace('$H['+json.dumps(name)+']',lexical(name))
    assert not any(t in out for t in ['get(G,','callOwned(','jump(','$H[']),out
    return out

def boolean(expr):
    assert expr.startswith('matcher(') and parser.close(expr,7)==len(expr)-1
    parts=parser.split(expr[8:-1]);assert len(parts)==3 and parts[1].startswith('()=>')
    first=json.loads(parts[0]);rest=parts[2]
    assert rest.startswith('()=>matcher1(')
    rest=rest[len('()=>'):];assert parser.close(rest,8)==len(rest)-1
    other=parser.split(rest[9:-1]);assert len(other)==2 and other[1].startswith('()=>')
    second=json.loads(other[0]);assert {first,second}=={'True','False'}
    branches={first:parts[1][4:],second:other[1][4:]}
    return '($f32Choice?'+private(branches['True'])+':'+private(branches['False'])+')'

out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
inputs=[identity(p) for p in [SOURCE,Path(str(SOURCE)+'.json'),PLAN,PARSER,FRAMING,Path(__file__)]]
assert identity(SOURCE)['sha256']==EXPECTED
checked=json.loads(Path(str(SOURCE)+'.json').read_text())
assert checked['complete'] and checked['observation']['checked'] and checked['output']['sha256']==EXPECTED
assert Path(checked['attempt']['file']).parent.name=='attempt-08'
assert identity(checked['attempt']['file'])['sha256']==checked['attempt']['sha256']
source=SOURCE.read_text();definitions={};proof=[];declarations=''
for name in NAMES:
    prefix='G['+json.dumps(name)+']='
    rows=[line for line in source.splitlines() if line.startswith(prefix)]
    assert len(rows)==1;line=rows[0];definitions[name]=line
    body=parser.callback(line,'fn('+str(LEADING[name])+',function(a){')
    assert len(body['params'])==LEADING[name]
    if LEADING[name]!=ARITIES[name]:
        assert ARITIES[name]==LEADING[name]+1
        params=body['params']+['$f32Choice'];expr=boolean(body['expr'])
    else:params=body['params'];expr=private(body['expr'])
    proof.append({'name':name,'leadingArity':LEADING[name],'scalarArity':ARITIES[name],
                  'originalBody':body,'privateParameters':params,'privateExpression':expr})
    if name!='isect5':declarations+='function '+lexical(name)+'('+','.join(params)+'){return '+expr+';}'
    else:root=body;fast=expr
checks=['(typeof '+p+'==="number"&&(Math.fround('+p+')==='+p+'||Number.isNaN('+p+')))' for p in root['params']]
changed='G["isect5"]=scalarCapture("isect5",(()=>{'+declarations
changed+='const $f32Guards='+json.dumps(NAMES,separators=(',',':'))+';'
changed+='return fn(10,exactCode(function(a,$entered){'+root['prefix']
changed+='if($entered&&'+'&&'.join(checks)+'&&scalarGuard($f32Guards))return '+fast+';'
changed+='return '+root['expr']+';}));})());'
candidate=source
for name in NAMES:
    line=definitions[name];prefix='G['+json.dumps(name)+']='
    replacement=changed if name=='isect5' else prefix+'scalarCapture('+json.dumps(name)+','+line[len(prefix):-1]+');'
    assert candidate.count(line+'\n')==1;candidate=candidate.replace(line+'\n',replacement+'\n')
baseline=out/'baseline.mjs';baseline.write_text(source)
target=out/'f32-root.mjs';target.write_text(candidate)
adapter='''const originalExports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));
function fixture(z,offset){return originalExports.isect5(Math.fround(offset),0,Math.fround(z),1,0,0,0,0,0,1)}
export default {...originalExports,bench:fixture};
'''
export='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));\n'
for name in ['baseline','f32-root']:
    text=(out/(name+'.mjs')).read_text();assert text.count(export)==1
    (out/(name+'-leaf.mjs')).write_text(text.replace(export,adapter))
(out/'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
(out/'plan.md').write_bytes(PLAN.read_bytes())
report={'kind':'phase30-closed-f32-ordinary-root','complete':True,'inputs':inputs,
        'outputs':[identity(out/(name+'.mjs')) for name in ['baseline','f32-root','baseline-leaf','f32-root-leaf']],
        'closure':NAMES,'derivation':proof,'replacement':changed,'leafAdapter':adapter,
        'scope':'Stable host intrinsics; exact entry; complete primitive scalar closure guard; unchanged F32 arithmetic and public fallback.',
        'compilerChanged':False,'maintainedRuntimeChanged':False,'correctness':'pending','timing':'pending'}
(out/'derive.json').write_text(json.dumps(report,indent=2)+'\n')
for protocol in ['screen','confirm']:
    cfg={'protocol':protocol,'inputs':[identity(out/'derive.json'),*inputs],
         'cases':[{'id':'f32-isect5-'+label,'point':{'args':args,'expected':expected},
                   'modules':{'baseline':str(out/'baseline-leaf.mjs'),'f32_root':str(out/'f32-root-leaf.mjs')}}
                  for label,args,expected in [('hit',[5,0],4),('miss',[5,3],1000000000)]]}
    (out/(protocol+'.json')).write_text(json.dumps(cfg,indent=2)+'\n')
print(json.dumps({'complete':True,'out':str(out),'closure':NAMES}))
