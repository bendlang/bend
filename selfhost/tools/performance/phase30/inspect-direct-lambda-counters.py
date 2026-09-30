#!/usr/bin/env python3
"""Derive separate instrumented copies for guarded lambda mechanism counts."""
import argparse
import hashlib
import json
import re
from pathlib import Path


def ident(p):
 b=p.read_bytes();return {'file':str(p.resolve()),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}


def instrument(text):
 counters=['apply','call','fn','bound','jump','build','project','ctor','copiedSlots','force','forcedJumps','directAttempts','directSuccesses','regionChecks','regionAccepted','privateAsr8','privateSel','privateSelGo','privateB2u']
 text='const $p30_counts='+json.dumps(dict.fromkeys(counters,0))+';\n'+text
 replacements={
  'const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});': 'const fn=(arity,code,env=null,bound=[])=>{$p30_counts.fn++;if(bound.length)$p30_counts.bound++;return {arity,code,env,bound}};',
  'function apply(f,args){':'function apply(f,args){$p30_counts.apply++;',
  'const call=(f,args)=>force(apply(f,args));':'const call=(f,args)=>{$p30_counts.call++;return force(apply(f,args))};',
  'const jump=(f,args)=>({bounce:true,f,args});':'const jump=(f,args)=>{$p30_counts.jump++;return {bounce:true,f,args}};',
  'const build=(name,fields)=>({build:true,name,fields});':'const build=(name,fields)=>{$p30_counts.build++;return {build:true,name,fields}};',
  'function project(k,x){':'function project(k,x){$p30_counts.project++;',
  'function ctor(k,a){':'function ctor(k,a){$p30_counts.ctor++;',
  'function force(x){':'function force(x){$p30_counts.force++;',
  'if(x?.bounce){x=apply(x.f,x.args);continue}':'if(x?.bounce){$p30_counts.forcedJumps++;x=apply(x.f,x.args);continue}',
  'const all=f.bound.length?f.bound.concat(args):args.slice();':'const all=f.bound.length?f.bound.concat(args):args.slice();$p30_counts.copiedSlots+=all.length;',
 }
 for before,after in replacements.items():
  if text.count(before)!=1:raise ValueError('Runtime site identity mismatch: '+before)
  text=text.replace(before,after)
 if 'function $p30_fast(' in text:
  text=text.replace('function $p30_fast(f, original, arity, code, bound) {','function $p30_fast(f, original, arity, code, bound) {$p30_counts.directAttempts++;')
  before="return Object.getOwnPropertyDescriptor(bound, 'length').value === 0;"
  if text.count(before)!=1:raise ValueError('Guard site identity mismatch')
  text=text.replace(before,"const okay=Object.getOwnPropertyDescriptor(bound, 'length').value === 0;if(okay)$p30_counts.directSuccesses++;return okay;")
 if 'function $p30_region_guard(){' in text:
  text=text.replace('function $p30_region_guard(){','function $p30_region_guard(){$p30_counts.regionChecks++;')
  before=' }\n return true;\n}\nfunction $p30_region_inputs'
  if text.count(before)!=1:raise ValueError('Region guard site mismatch')
  text=text.replace(before,' }\n $p30_counts.regionAccepted++;return true;\n}\nfunction $p30_region_inputs')
  for name,key in [('asr8','privateAsr8'),('sel','privateSel'),('sel_go','privateSelGo'),('b2u','privateB2u')]:
   pattern=r'(function \$p30_region_'+name+r'\([^)]*\)\{)'
   text,n=re.subn(pattern,lambda m:m[0]+'$p30_counts.'+key+'++;',text)
   if n!=1:raise ValueError('Private helper count site mismatch')
 text+='\nexport function phase30_counters(reset=false){const result={...$p30_counts};if(reset)for(const k of Object.keys($p30_counts))$p30_counts[k]=0;return result;}\n'
 return text


def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('directory',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();args.out.mkdir(parents=True,exist_ok=False)
 inputs=[];outputs=[]
 for side in ['baseline','guarded']:
  p=args.directory/(side+'.mjs');inputs.append(ident(p));target=args.out/(side+'.mjs');target.write_text(instrument(p.read_text()));outputs.append(ident(target))
 (args.out/'derive.json').write_text(json.dumps({'kind':'phase30-separate-counter-derivation','complete':True,'inputs':inputs+[ident(Path(__file__))],'outputs':outputs,'timing':'instrumented modules are not clean timing inputs'},indent=2)+'\n')
 (args.out/'derive.py').write_bytes(Path(__file__).read_bytes())
 (args.out/'run.mjs').write_text('''import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
const directory=path.dirname(import.meta.filename),rows=[];
for(const side of ['baseline','guarded']){
 const mod=await import(pathToFileURL(path.join(directory,side+'.mjs')));
 mod.phase30_counters(true);const results=[];for(let i=0;i<10;i++)results.push(mod.default.bench(0,0));
 if(!results.every(x=>x===2747870681))throw Error('Result mismatch');
 rows.push({side,results,counts:mod.phase30_counters()});
}
const r={kind:'phase30-guarded-lambda-named-site-counts',complete:true,scope:'10 original bench(0,0) calls; counters reset after import; not total allocations and not timings',rows};
fs.writeFileSync(path.join(directory,'report.json'),JSON.stringify(r,null,2)+'\\n');console.log(JSON.stringify(r));
''')
 print(json.dumps({'complete':True,'out':str(args.out)}))


if __name__=='__main__':main()
