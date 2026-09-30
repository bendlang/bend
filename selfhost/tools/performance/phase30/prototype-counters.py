#!/usr/bin/env python3
"""Instrument immutable ablation bytes; counters are never used for timing."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
base=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
report={'kind':'phase30-call-plumbing-counters','complete':False,'scope':'Named runtime sites only, not total allocation or instrumented timing. Ten complete rows (n32,seed17) after one output validation.','inputs':[ident(Path(__file__)),ident(base/'points.json')],'variants':{}}
sides=sys.argv[3:] or ['unchanged','private']
for side in sides:
    p=base/(side+'.mjs');source=p.read_text();report['inputs'].append(ident(p))
    patches=[
      ('const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});','const fn=(arity,code,env=null,bound=[])=>{C.fn++;if(bound.length)C.bound++;return {arity,code,env,bound}};'),
      ('const jump=(f,args)=>({bounce:true,f,args});','const jump=(f,args)=>{C.jump++;return {bounce:true,f,args}};'),
      ('const build=(name,fields)=>({build:true,name,fields});','const build=(name,fields)=>{C.build++;return {build:true,name,fields}};'),
      ('function apply(f,args){','function apply(f,args){C.apply++;if(f===G["Array.get"])C.arrayGet++;if(f===G["Array.set"])C.arraySet++;'),
      ('const all=f.bound.length?f.bound.concat(args):args.slice();','const all=f.bound.length?f.bound.concat(args):args.slice();C.copiedSlots+=all.length;'),
      ('const call=(f,args)=>force(apply(f,args));','const call=(f,args)=>{C.call++;return force(apply(f,args))};'),
      ('function project(k,x){','function project(k,x){C.project++;')]
    source='const C={fn:0,bound:0,jump:0,build:0,apply:0,call:0,project:0,copiedSlots:0,arrayGet:0,arraySet:0,privateCopiedSlots:0,prebindCopiedSlots:0};\n'+source
    for before,after in patches:assert source.count(before)==1,before;source=source.replace(before,after)
    source=source.replace('const all=p.slice();','const all=p.slice();C.privateCopiedSlots+=all.length;')
    source=source.replace('const b=p.slice();','const b=p.slice();C.prebindCopiedSlots+=b.length;')
    source+='\nexport {C};\n';path=out/(side+'.mjs');path.write_text(source)
    report['variants'][side]={'module':ident(path)}
script=out/'run.mjs';script.write_text('''import fs from 'node:fs';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const [root,points,sides]=process.argv.slice(2),point=JSON.parse(fs.readFileSync(points)).find(x=>x.args[0]===32&&x.args[1]===17);
const rows={};for(const side of JSON.parse(sides)){const m=await import(pathToFileURL(root+'/'+side+'.mjs'));assert.equal(m.default.bench(...point.args),point.expected);for(const k in m.C)m.C[k]=0;for(let i=0;i<10;i++)assert.equal(m.default.bench(...point.args),point.expected);rows[side]={...m.C};}
console.log(JSON.stringify({complete:true,rows}));
''')
node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node');report['inputs'].append(ident(node))
command=['taskset','-c','6',str(node),'--stack-size=4096','--max-old-space-size=1024',str(script),str(out),str(base/'points.json'),json.dumps(sides)];report['command']=command
save(out/'report.json',report)
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
with (out/'stdout').open('w') as stdout,(out/'stderr').open('w') as stderr:
    result=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=60,env=env)
report.update(exitCode=result.returncode,stdout=ident(out/'stdout'),stderr=ident(out/'stderr'))
if result.returncode==0:report['observation']=json.loads((out/'stdout').read_text());report['complete']=report['observation']['complete']
for p in report['inputs']:assert ident(Path(p['file']))==p
save(out/'report.json',report);print(json.dumps(report))
raise SystemExit(0 if report['complete'] else 1)
