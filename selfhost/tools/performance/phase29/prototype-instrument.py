#!/usr/bin/env python3
"""Derive separate untimed counter copies; never use these for speed claims.

Counters cover named runtime operations, not all JavaScript allocations or bytes.
They include apply's copies even when a rewrite moves allocation to another
descriptor path. Array literals, matcher projection arrays and closures remain
explicitly outside this accounting; use heap sampling for a complete profile.
"""
from pathlib import Path
import hashlib,json,sys
source=Path(sys.argv[1]).resolve();target=Path(sys.argv[2]).resolve()
text=source.read_text()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
fields=['fnCreates','boundFnCreates','applyCalls','callCalls','jumps','forceEntries','forceIterations','builds','argumentCopies','copiedArgumentSlots']
counter='const p29Counters='+json.dumps({k:0 for k in fields})+';\n'
replacements=[
 ('const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});',counter+'const fn=(arity,code,env=null,bound=[])=>{p29Counters.fnCreates++;if(bound.length)p29Counters.boundFnCreates++;return {arity,code,env,bound}};'),
 ('const jump=(f,args)=>({bounce:true,f,args});','const jump=(f,args)=>{p29Counters.jumps++;return {bounce:true,f,args}};'),
 ('const build=(name,fields)=>({build:true,name,fields});','const build=(name,fields)=>{p29Counters.builds++;return {build:true,name,fields}};'),
 ('function force(x){\n  let pending;\n  for(;;){','function force(x){\n  p29Counters.forceEntries++;let pending;\n  for(;;){p29Counters.forceIterations++;'),
 ('function apply(f,args){','function apply(f,args){p29Counters.applyCalls++;'),
 ('const all=f.bound.length?f.bound.concat(args):args.slice();','p29Counters.argumentCopies++;p29Counters.copiedArgumentSlots+=f.bound.length+args.length;const all=f.bound.length?f.bound.concat(args):args.slice();'),
 ('let r=f.code.call(f.env,all.slice(0,f.arity));','p29Counters.argumentCopies++;p29Counters.copiedArgumentSlots+=f.arity;let r=f.code.call(f.env,all.slice(0,f.arity));'),
 ('if(all.length>f.arity)r=jump(force(r),all.slice(f.arity));','if(all.length>f.arity){p29Counters.argumentCopies++;p29Counters.copiedArgumentSlots+=all.length-f.arity;r=jump(force(r),all.slice(f.arity));}'),
 ('const call=(f,args)=>force(apply(f,args));','const call=(f,args)=>{p29Counters.callCalls++;return force(apply(f,args))};'),
]
for before,after in replacements:
    assert text.count(before)==1,(before,text.count(before))
    text=text.replace(before,after)
text+='\nexport function prototypeCounters(reset=false){const result={...p29Counters};if(reset)for(const k of Object.keys(p29Counters))p29Counters[k]=0;return result;}\n'
target.write_text(text)
report={'kind':'phase29-untimed-runtime-counter-derivation','source':ident(source),'output':ident(target),'tool':ident(Path(__file__)),'counterScope':fields,'excluded':'Array literals, projection arrays, arbitrary closures, allocation bytes and host JIT/GC. Do not interpret as total allocation counts.','replacements':len(replacements)}
target.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n')
