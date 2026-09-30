#!/usr/bin/env python3
"""Attribute untimed generic applications to originating global descriptors."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
HERE=Path(__file__).resolve().parent
base,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
report={'kind':'phase30-named-application-counters','complete':False,'scope':'Ten complete rows n32/seed17. Descriptor origin is inherited at fn creation and rebound to each initial global descriptor after module initialization. Counts of named generic applications, not runtime cost, allocation or a profile. Private JavaScript calls are deliberately outside generic apply counts.','inputs':[ident(Path(__file__)),ident(base/'points.json')],'variants':{}}
for side in ['unchanged','exact','private']:
 source=(base/(side+'.mjs')).read_text();report['inputs'].append(ident(base/(side+'.mjs')))
 source='const Phase30Origins=new WeakMap(),Phase30Named={};let Phase30Origin="module";\n'+source
 old='const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});'
 new='const fn=(arity,code,env=null,bound=[])=>{const f={arity,code,env,bound};Phase30Origins.set(f,Phase30Origin);return f};'
 assert source.count(old)==1;source=source.replace(old,new)
 old='function apply(f,args){';new='function apply(f,args){const previous=Phase30Origin;Phase30Origin=Phase30Origins.get(f)??"unknown";Phase30Named[Phase30Origin]=(Phase30Named[Phase30Origin]??0)+1;try{'
 assert source.count(old)==1;source=source.replace(old,new)
 old='\n}\nconst call=(f,args)=>force(apply(f,args));';new='\n}finally{Phase30Origin=previous}\n}\nconst call=(f,args)=>force(apply(f,args));'
 assert source.count(old)==1;source=source.replace(old,new)
 source+='\nfor(const [k,v]of Object.entries(G))if(v&&typeof v==="object"&&v.code)Phase30Origins.set(v,k);\nexport {Phase30Named};\n'
 path=out/(side+'.mjs');path.write_text(source);report['variants'][side]={'module':ident(path)}
script=out/'run.mjs';script.write_text('''import fs from 'node:fs';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const [root,points]=process.argv.slice(2),point=JSON.parse(fs.readFileSync(points)).find(x=>x.args[0]===32&&x.args[1]===17);
const rows={};for(const side of ['unchanged','exact','private']){const m=await import(pathToFileURL(root+'/'+side+'.mjs'));assert.equal(m.default.bench(...point.args),point.expected);for(const k in m.Phase30Named)delete m.Phase30Named[k];for(let i=0;i<10;i++)assert.equal(m.default.bench(...point.args),point.expected);rows[side]=Object.fromEntries(Object.entries(m.Phase30Named).sort((a,b)=>b[1]-a[1]));}
console.log(JSON.stringify({complete:true,rows}));
''')
node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node');report['inputs'].append(ident(node))
command=['taskset','-c','6',str(node),'--stack-size=4096','--max-old-space-size=1024',str(script),str(out),str(base/'points.json')];report['command']=command
save(out/'report.json',report)
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
with (out/'stdout').open('w') as stdout,(out/'stderr').open('w') as stderr:result=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=60,env=env)
report.update(exitCode=result.returncode,stdout=ident(out/'stdout'),stderr=ident(out/'stderr'))
if result.returncode==0:report['observation']=json.loads((out/'stdout').read_text());report['complete']=report['observation']['complete']
for p in report['inputs']:assert ident(Path(p['file']))==p
save(out/'report.json',report);print(json.dumps(report));raise SystemExit(0 if report['complete'] else 1)
