#!/usr/bin/env python3
"""Add live recursive-binding guards to repaired opaque-state loop bytes."""
from pathlib import Path
import hashlib,json,shutil,sys
ROOT=Path(__file__).resolve().parents[4]
base,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
design=ROOT/'design/phase30/record-loop-live-binding-guard.md'
report={'kind':'phase30-live-recursive-binding-row-loop','complete':False,
 'scope':'Generated JS only. Standard intrinsics. Preserves recursive G replacement and descriptor internals at original prefix boundary. Private-cell context still assumes immutable cell chain.',
 'inputs':[ident(Path(__file__)),ident(design),ident(base/'points.json')],'variants':{},'rewrites':[]}
save(out/'report.json',report)
shutil.copyfile(Path(__file__),out/'consumed-guard.py');shutil.copyfile(design,out/'prospective-design.md')
shutil.copyfile(base/'points.json',out/'points.json')
guard='''
const R_function_prototype=Function.prototype;
const R_function_call=Object.getOwnPropertyDescriptor(R_function_prototype,"call").value;
const R_original=G["row"];
const R_snapshot={code:R_original.code,arity:R_original.arity,bound:R_original.bound};
function R_guard(f){
 if(f!==R_original||Object.getPrototypeOf(f)!==Object.prototype)return false;
 for(const key of ["io","typeName"]){if(Object.getOwnPropertyDescriptor(f,key)||Object.getOwnPropertyDescriptor(Object.prototype,key))return false;}
 if(Object.getOwnPropertyDescriptor(R_snapshot.code,"call")||Object.getPrototypeOf(R_snapshot.code)!==R_function_prototype)return false;
 const invoke=Object.getOwnPropertyDescriptor(R_function_prototype,"call");
 if(!invoke||!Object.hasOwn(invoke,"value")||invoke.value!==R_function_call)return false;
 for(const [key,value]of [["arity",R_snapshot.arity],["code",R_snapshot.code],["env",null],["bound",R_snapshot.bound]]){const d=Object.getOwnPropertyDescriptor(f,key);if(!d||!Object.hasOwn(d,"value")||d.value!==value)return false;}
 return Object.getOwnPropertyDescriptor(R_snapshot.bound,"length").value===0;
}
'''
for side in ['unchanged','row-loop','private','private-row-loop','upstream']:
    src=base/(side+'.mjs');report['inputs'].append(ident(src));shutil.copyfile(src,out/(side+'.mjs'))
    report['variants'][side]=ident(out/(side+'.mjs'))
    if side not in ['row-loop','private-row-loop']:continue
    text=src.read_text()
    patches=[
      ('const $prefix=call(get(G,"row"),[x3529]);','const $target=get(G,"row");const $admit=R_guard($target);\nconst $prefix=call($target,[x3529]);'),
      ('return typeof x3529!=="bigint"||x3529===0n?jump($next,[$value]):jump(R_row_loop,[x3529,$j,x3531,$value]);','return !$admit||typeof x3529!=="bigint"||x3529===0n?jump($next,[$value]):jump(R_row_loop,[x3529,$j,x3531,$value]);'),
      ('const $zero=x3529===0n?call(get(G,"row"),[x3529]):null;','const $target=get(G,"row");const $ordinary=x3529===0n||!R_guard($target);\n    const $zero=$ordinary?call($target,[x3529]):null;'),
      ('const $next=$zero===null?null:call(call($zero,[$nextj]),[x3531]);','const $next=$ordinary?call(call($zero,[$nextj]),[x3531]):null;'),
      ('if(x3529===0n)return jump($next,[$value]);','if($ordinary)return jump($next,[$value]);'),
    ]
    for old,new in patches:assert text.count(old)==1,old;text=text.replace(old,new)
    text+=guard
    name=side+'-guarded';p=out/(name+'.mjs');p.write_text(text)
    report['variants'][name]=ident(p);report['rewrites'].append({'variant':name,'patches':patches,'guard':guard})
shutil.copyfile(base/'row-loop-eager-rejected.mjs',out/'row-loop-eager-rejected.mjs')
save(out/'rewrites.json',report['rewrites'])
point=next(x for x in json.loads((out/'points.json').read_text()) if x['args']==[32,17])
order=['unchanged','row-loop','row-loop-guarded','private','private-row-loop','private-row-loop-guarded','upstream']
for protocol in ['screen','confirm']:
    save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(design),ident(out/'points.json'),ident(out/'rewrites.json')],
      'cases':[{'id':'guarded-record-row32','point':point,'modules':{name:report['variants'][name]['file'] for name in order}}]})
for x in report['inputs']:assert ident(Path(x['file']))==x
report['complete']=True;save(out/'report.json',report);print(json.dumps({'complete':True,'variants':list(report['variants'])}))
