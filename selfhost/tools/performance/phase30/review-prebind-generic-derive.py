#!/usr/bin/env python3
"""Restore original delayed arm application in frozen actual14 outputs only."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
source,out=(Path(x).resolve() for x in sys.argv[1:]);out.mkdir(exist_ok=False)
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
receiptfile=Path(str(source)+'.json');receipt=json.loads(receiptfile.read_text())
assert receipt['complete'] and receipt['observation']['checked']
assert Path(receipt['attempt']['file']).parent.name=='attempt-14'
assert ident(source)['sha256']==receipt['output']['sha256']
design=ROOT/'design/phase30/partial-prebinding-registration-ablation.md'
inputs=[ident(p) for p in [Path(__file__),source,receiptfile,design]]
for key in ['attempt','input','api','runtime','base','driver']:
 item=ident(receipt[key]['file']);assert item['sha256']==receipt[key]['sha256'];inputs.append(item)
original='''function matcher1p(name,count,arity,make){return fn(1,exactCode(([x],entered)=>{
  const p=project(name,x),n=p.length,c=make();
  if(!entered)return n?jump(fn(arity,c),p):fn(arity,c);
  if(n!==count)return n?jump(fn(arity,c),p):fn(arity,c);
  const b=p.slice();
  if(b.length===arity)return c.call(null,b);
  if(b.length<arity)return fn(arity,c,null,b);
  let r=c.call(null,b.slice(0,arity));
  if(b.length>arity)r=jump(force(r),b.slice(arity));
  return r;
},true))}'''
replacement='''function matcher1p(name,count,arity,make){return fn(1,([x])=>{
  const p=project(name,x),n=p.length,c=make();
  return n?jump(fn(arity,c),p):fn(arity,c);
})}'''
fused='''function matcher1p(name,count,arity,make){
  const code=(0,(a)=>{
    const entry=exactEntry;
    const entered=entry!==null&&entry.code===code&&entry.args===a&&!entry.used;
    if(entered)entry.used=true;
    return (([x])=>{
  const p=project(name,x),n=p.length,c=make();
  if(!entered)return n?jump(fn(arity,c),p):fn(arity,c);
  if(n!==count)return n?jump(fn(arity,c),p):fn(arity,c);
  const b=p.slice();
  if(b.length===arity)return c.call(null,b);
  if(b.length<arity)return fn(arity,c,null,b);
  let r=c.call(null,b.slice(0,arity));
  if(b.length>arity)r=jump(force(r),b.slice(arity));
  return r;
    })(a);
  });
  exactCodes.add(code);
  return fn(1,code);
}'''
text=source.read_text();runtime=Path(receipt['runtime']['file']).read_text()
assert text.startswith(runtime) and runtime.count(original)==1 and text.count(original)==1
changed=text.replace(original,replacement);assert changed.replace(replacement,original)==text
assert changed[len(runtime)-len(original)+len(replacement):]==text[len(runtime):]
(out/'baseline.mjs').write_text(text);(out/'candidate.mjs').write_text(changed)
fusedtext=text.replace(original,fused);assert fusedtext.replace(fused,original)==text
assert fusedtext[len(runtime)-len(original)+len(fused):]==text[len(runtime):]
(out/'fused.mjs').write_text(fusedtext)
core=Path(receipt['attempt']['file']).parent/'snapshot/src/runtime/js/core.mjs';coretext=core.read_text();assert coretext.count(original)==1
(out/'core-baseline.mjs').write_text(coretext);(out/'core-candidate.mjs').write_text(coretext.replace(original,replacement));inputs.append(ident(core))
(out/'core-fused.mjs').write_text(coretext.replace(original,fused))
(out/'consumed-derive.py').write_bytes(Path(__file__).read_bytes());(out/'plan.md').write_bytes(design.read_bytes())
for row in inputs:assert ident(row['file'])==row
save(out/'derive.json',{'kind':'phase30-generic-partial-prebind-ablation','complete':True,'compilerChanged':False,'inputs':inputs,
 'edit':{'original':original,'replacement':replacement,'fused':fused},'exactReconstruction':True,'generatedSuffixUnchanged':True,
 'outputs':{side:ident(out/(side+'.mjs')) for side in ['baseline','candidate','fused']},
 'cores':{side:ident(out/('core-'+side+'.mjs')) for side in ['baseline','candidate','fused']}})
print(json.dumps({'complete':True,'out':str(out)}))
