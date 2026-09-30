#!/usr/bin/env python3
"""Derive a closed, guarded scalar region from the existing Phase29 mit loop."""
import argparse
import hashlib
import importlib.util
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TOOL = Path(__file__).with_name('inspect-direct-lambda.py')
spec = importlib.util.spec_from_file_location('lambda_deriver', TOOL)
lambda_deriver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lambda_deriver)
SOURCE = lambda_deriver.SOURCE
PLAN = ROOT / 'design/phase30/pure-scalar-region-amendment.md'


def identity(path):
 b=path.read_bytes();return {'file':str(path.resolve()),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}


def direct_calls(line, name, count):
 prefix='call(get(G,'+json.dumps(name)+'),['
 masked=lambda_deriver.mask(line);begin=0;hits=[]
 while (start:=line.find(prefix,begin))>=0:
  first=start+len(prefix);at=first;depth=1
  while depth and at<len(line):
   if masked[at]=='[':depth+=1
   elif masked[at]==']':depth-=1
   at+=1
  if depth or line[at]!=')':raise ValueError('Unexpected call framing')
  hits.append((start,at+1,line[first:at-1]));begin=at+1
 if len(hits)!=count:raise ValueError(f'Expected {count} {name} calls, got{len(hits)}')
 for start,end,args in reversed(hits):line=line[:start]+'$p30_region_'+name.replace('.','_')+'('+args+')'+line[end:]
 return line


def derive(text):
 guarded,helpers=lambda_deriver.derive(text)
 guard=guarded[guarded.index('const $p30_function_prototype='):guarded.index('const $p30_original_asr8=')]
 lines=text.splitlines(keepends=True);ix=[i for i,line in enumerate(lines)if line.startswith('G["mit"]=')]
 if len(ix)!=1:raise ValueError('Unexpected mit declarations')
 line=lines[ix[0]];mark='/* private Nat loop */';start=line.index(mark)
 if line.count(mark)!=1 or line[start-12:start]!='function(a){':raise ValueError('Unexpected callback marker')
 mask=lambda_deriver.mask(line);at=start;depth=1
 while depth and at<len(line):
  if mask[at]=='{':depth+=1
  elif mask[at]=='}':depth-=1
  at+=1
 if depth:raise ValueError('Unterminated callback')
 body=line[start:at-1]
 prefix=mark+''.join(f'let $s{i}=a[{i}];'for i in range(7))
 if not body.startswith(prefix+'for(;;){'):raise ValueError('Unexpected loop parameter prefix')
 original_loop=body[len(prefix):]
 private=original_loop
 for name,count in [('asr8',3),('sel',2),('b2u',2)]:private=direct_calls(private,name,count)
 if 'get(G,'in private or 'call('in private or 'jump('in private:raise ValueError('Unaccounted global/application in private loop')
 asr8=direct_calls(helpers['asr8']['body'],'sel',1)
 t,x,y=helpers['sel']['params']
 expected=f'return jump(call(get(G,"sel.go"),[{x},{y},]),[(/* primitive */(({t})===0))]);'
 if helpers['sel']['body']!=expected:raise ValueError('Unexpected sel shape')
 b2u='G["b2u"]=matcher("False",()=>0,()=>matcher1("True",()=>1));'
 if b2u not in text.splitlines():raise ValueError('Unexpected b2u shape')
 m=re.search(r'^G\["sel\.go"\]=fn\(2,function\(a\)\{const (x\d+)=a\[0\];const (x\d+)=a\[1\];(.*)\}\);$',text,re.M)
 if not m or m[3]!=f'return matcher("True",()=>{m[1]},()=>matcher1("False",()=>{m[2]}));':raise ValueError('Unexpected sel.go shape')
 slots=','.join(f'$s{i}'for i in range(7))
 inserted=prefix+f'if($p30_region_inputs({slots})&&$p30_region_guard())return $p30_region_loop({slots});'+original_loop
 lines[ix[0]]=line[:start]+inserted+line[at-1:]
 declarations='\n// Phase30 disposable closed scalar region; original loop is its fallback.\n'+guard
 declarations+='const $p30_region_captured=["asr8","sel","sel.go","b2u"].map(name=>{const original=G[name];return {name,original,arity:original.arity,code:original.code,bound:original.bound};});\n'
 declarations+='''function $p30_region_guard(){
 for(const row of $p30_region_captured){
  const gd=Object.getOwnPropertyDescriptor(G,row.name);
  if(!gd||!Object.hasOwn(gd,'value')||gd.value!==row.original)return false;
  if(!$p30_fast(row.original,row.original,row.arity,row.code,row.bound))return false;
 }
 return true;
}
function $p30_region_inputs(n,a,b,c,d,e,f){
 if(typeof n!=='bigint'||n<0n||n>=281474976710655n)return false;
 return [a,b,c,d,e,f].every(x=>typeof x==='number'&&Number.isInteger(x)&&x>=0&&x<=4294967295);
}
function $p30_region_b2u(b){return b?1:0;}
function $p30_region_sel_go(x,y,z){return z?x:y;}
function $p30_region_sel(t,x,y){return $p30_region_sel_go(x,y,(/* primitive */((t)===0)));}
'''
 declarations+='function $p30_region_asr8('+','.join(helpers['asr8']['params'])+'){'+asr8+'}\n'
 declarations+='function $p30_region_loop('+slots+'){'+private+'}\n'
 joined=''.join(lines);marker='\nexport {G,call,list,ctor};'
 if joined.count(marker)!=1:raise ValueError('Unexpected export marker')
 return joined.replace(marker,declarations+marker)


def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
 if identity(SOURCE)['sha256']!=lambda_deriver.EXPECTED:raise ValueError('Source differs from frozen identity')
 generated=derive(SOURCE.read_text());args.out.mkdir(parents=True,exist_ok=False)
 for name,p in [('baseline',SOURCE),('upstream',ROOT/'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs')]:
  (args.out/(name+'.mjs')).write_bytes(p.read_bytes())
 target=args.out/'guarded.mjs';target.write_text(generated)
 for name,p in [('derive.py',Path(__file__)),('lambda-derive.py',TOOL),('plan.md',PLAN)]:
  (args.out/name).write_bytes(p.read_bytes())
 report={'kind':'phase30-generated-js-closed-pure-scalar-region','complete':True,'inputs':[identity(p)for p in [SOURCE,PLAN,Path(__file__),TOOL,lambda_deriver.PLAN,lambda_deriver.FOLLOWUP]],'output':identity(target),'compilerChanged':False,'runtimeSourceChanged':False,'scope':'Guard once after existing seven argument reads; complete four-helper scalar closure; original loop fallback. Standard intrinsics and prototype behavior.','changedCallsPerIteration':{'asr8':3,'sel':2,'b2u':2},'unchanged':'BigInt Nat,state slots,primitive arithmetic,tail loop,public descriptors/exports','correctness':'not run','measurement':'not run'}
 (args.out/'derive.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'complete':True,'output':report['output']}))


if __name__=='__main__':main()
