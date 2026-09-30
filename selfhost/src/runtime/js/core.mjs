// Runtime support for generated programs. No Bend parser, checker, emitter,
// source loading or compiler delegation is implemented here.
import fs from 'node:fs';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
import {getSystemErrorMap} from 'node:util';
import {randomBytes} from 'node:crypto';
import net from 'node:net';
import dgram from 'node:dgram';
import {spawn} from 'node:child_process';
import {constants as hostConstants} from 'node:os';
const G=Object.create(null), constructors=Object.create(null), showSchemas=Object.create(null), constructorOwn=Object.create(null), constructorNative=Object.create(null);
const scope=p=>Object.create(p);
const bad=m=>{throw Error(m)};
const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});
const jump=(f,args)=>({bounce:true,f,args});
const build=(name,fields)=>({build:true,name,fields});
// Only apply's exact-saturation branch may grant an eager callback entry.
// Consume permission before reading any argument: a getter can reenter code
// with the same vector, but cannot reuse this token or forge one with extra args.
const exactCodes=new WeakSet(), exactPrototype=Function.prototype;
const exactCall=Function.prototype.call;
let exactEntry=null;
function enterExact(code,inner,a){
  const entry=exactEntry;
  const entered=entry!==null&&entry.code===code&&entry.args===a&&!entry.used;
  if(entered)entry.used=true;
  return inner(a,entered);
}
function exactCode(inner,arrow=false){
  const code=arrow?(0,(a)=>enterExact(code,inner,a)):
    (0,function(a){return enterExact(code,inner,a)});
  exactCodes.add(code);
  return code;
}
function invokeExact(f,all){
  const code=f.code;
  if(!exactCodes.has(code)||Object.getPrototypeOf(code)!==exactPrototype||
      Object.getOwnPropertyDescriptor(code,'call'))return code.call(f.env,all);
  const callProperty=Object.getOwnPropertyDescriptor(exactPrototype,'call');
  if(!callProperty||!Object.hasOwn(callProperty,'value')||callProperty.value!==exactCall)
    return code.call(f.env,all);
  // Resolve .call before env, as the original invocation does. Environment
  // getters may reenter; permission is installed only after they have returned.
  const invoke=code.call,env=f.env,previous=exactEntry;
  exactEntry={code,args:all,used:false};
  try{return Reflect.apply(code,env,[all]);}
  finally{exactEntry=previous;}
}
function force(x){
  let pending;
  for(;;){
    if(x?.bounce){x=apply(x.f,x.args);continue}
    if(x?.build){
      if(!x.fields.length){x=ctor(x.name,[]);continue}
      (pending??=[]).push({node:x,values:[]});x=x.fields[0]();continue;
    }
    if(!pending?.length)return x;
    const frame=pending[pending.length-1];frame.values.push(x);
    if(frame.values.length<frame.node.fields.length)x=frame.node.fields[frame.values.length]();
    else{pending.pop();x=ctor(frame.node.name,frame.values)}
  }
}
function apply(f,args,owned=false){
  if(f===null)return null;
  if(f?.io&&args.length===0)return f;
  if(f?.io)return apply(fn(2,a=>Object.hasOwn(f,'pureValue')?call(a[1],[f.pureValue]):{request:true,action:f,k:a[1]}),args);
  if(f?.typeName)return {typeName:f.typeName,typeArgs:[...(f.typeArgs||[]),...args]};
  if(!f?.code){if(!args.length)return f;bad('attempt to call non-function '+String(f));}
  const all=f.bound.length?f.bound.concat(args):owned?args:args.slice();
  if(all.length===f.arity)return invokeExact(f,all);
  if(all.length<f.arity)return fn(f.arity,f.code,f.env,all);
  let r=f.code.call(f.env,all.slice(0,f.arity));
  if(all.length>f.arity)r=jump(force(r),all.slice(f.arity));
  return r;
}
const call=(f,args)=>force(apply(f,args));
// Only emitted non-tail calls pass a fresh, unshared literal argument vector.
// Public calls, matcher field vectors and reusable tail messages still copy.
const callOwned=(f,args)=>force(apply(f,args,true));
// Scalar regions capture only newly constructed compiler wrappers. Snapshots
// stay private; replacement/accessor metadata is inspected without invoking it.
const scalarSnapshots=Object.create(null), scalarObjectPrototype=Object.prototype;
const scalarFunctionPrototype=Function.prototype, scalarFunctionCall=Function.prototype.call;
const scalarPrimitivePrototypes=[Boolean.prototype,Number.prototype,BigInt.prototype];
function scalarCapture(name,f){
  const a=Object.getOwnPropertyDescriptor(f,'arity'),c=Object.getOwnPropertyDescriptor(f,'code');
  const e=Object.getOwnPropertyDescriptor(f,'env'),b=Object.getOwnPropertyDescriptor(f,'bound');
  if(a&&c&&e&&b&&[a,c,e,b].every(d=>Object.hasOwn(d,'value'))&&
      Number.isInteger(a.value)&&a.value>0&&typeof c.value==='function'&&e.value===null&&
      Array.isArray(b.value)&&Object.getOwnPropertyDescriptor(b.value,'length').value===0){
    scalarSnapshots[name]={original:f,arity:a.value,code:c.value,bound:b.value};
  }else delete scalarSnapshots[name];
  return f;
}
function scalarGuard(names){
  // Generic forcing/matching observes these hooks even on primitive values.
  if(Object.getPrototypeOf(scalarObjectPrototype)!==null||
      Object.getPrototypeOf(scalarFunctionPrototype)!==scalarObjectPrototype)return false;
  for(const p of [scalarObjectPrototype,...scalarPrimitivePrototypes]){
    if(p!==scalarObjectPrototype&&Object.getPrototypeOf(p)!==scalarObjectPrototype)return false;
    for(const k of ['request','bounce','build','code'])if(Object.getOwnPropertyDescriptor(p,k))return false;
  }
  for(const k of ['io','typeName'])if(Object.getOwnPropertyDescriptor(scalarObjectPrototype,k))return false;
  const invoke=Object.getOwnPropertyDescriptor(scalarFunctionPrototype,'call');
  if(!invoke||!Object.hasOwn(invoke,'value')||invoke.value!==scalarFunctionCall)return false;
  for(const name of names){
    const s=scalarSnapshots[name],g=Object.getOwnPropertyDescriptor(G,name);
    if(!s||!g||!Object.hasOwn(g,'value')||g.value!==s.original)return false;
    const f=s.original;
    if(Object.getPrototypeOf(f)!==scalarObjectPrototype||
        Object.getPrototypeOf(s.code)!==scalarFunctionPrototype||
        Object.getOwnPropertyDescriptor(s.code,'call'))return false;
    for(const k of ['io','typeName'])if(Object.getOwnPropertyDescriptor(f,k))return false;
    const a=Object.getOwnPropertyDescriptor(f,'arity'),c=Object.getOwnPropertyDescriptor(f,'code');
    const e=Object.getOwnPropertyDescriptor(f,'env'),b=Object.getOwnPropertyDescriptor(f,'bound');
    if(!a||!c||!e||!b||![a,c,e,b].every(d=>Object.hasOwn(d,'value'))||
        a.value!==s.arity||c.value!==s.code||e.value!==null||b.value!==s.bound||
        Object.getOwnPropertyDescriptor(s.bound,'length').value!==0)return false;
  }
  return true;
}
const native=(name,n,f)=>G[name]=fn(n,a=>f(...a));
function get(v,k){if(k in v){const x=v[k];return x?.code&&x.arity===0?call(x,[]):x;}bad('unbound name: '+k)}
function ctor(k,a){
  if(constructorNative[k]===false)return {$:k,a};
  switch(k){
    case 'True': return true; case 'False': return false;
    case 'Zero': return 0n; case 'Succ':return checkedNat(a[0]+1n);
    case 'SNil':return '';case 'SCon':return (typeof a[0]==='string'?a[0]:String.fromCodePoint(a[0]))+a[1];
    case 'Chr':return checkedChar(a[0]);case 'U32':return unword(a[0]);case 'F32':return bitsFloat(unword(a[0]));
    case 'Tuple':return a.length===2?a:[a[0],ctor('Tuple',a.slice(1))];
    default:return {$:k,a};
  }
}
const list=a=>a.reduceRight((t,h)=>ctor('Con',[h,t]),ctor('Nil',[]));
function unlist(x){const a=[];while(x?.$==='Con'){a.push(x.a[0]);x=x.a[1]}if(x?.$!=='Nil')bad('expected List');return a}
function fields(k,x){
  if(constructorNative[k]===false)return x?.$===k?x.a:null;
  if(x?.request)bad('runtime fail-stop');
  if(k==='True')return x?[]:null;
  if(k==='False')return !x?[]:null;
  if(k==='SNil')return x===''?[]:null;
  if(k==='SCon')return typeof x==='string'&&x.length?[x.codePointAt(0),x.slice(x.codePointAt(0)>65535?2:1)]:null;
  if(k==='U32')return typeof x==='number'?[word(x)]:null;
  if(k==='F32')return typeof x==='number'?[word(floatBits(x))]:null;
  if(k==='ALeaf'){const a=arraydata(x);return a.length===1?[a[0]]:null}
  if(k==='ANode'){const a=arraydata(x);return a.length>1?[{array:a.slice(0,a.length/2)},{array:a.slice(a.length/2)}]:null}
  if(k==='Chr')return typeof x==='number'?[x]:typeof x==='string'?[x.codePointAt(0)]:null;
  if(k==='Zero')return x===0n?[]:null;
  if(k==='Succ')return typeof x==='bigint'&&x!==0n?[x-1n]:null;
  if(k==='Tuple')return Array.isArray(x)?x:null;
  return x?.$===k?x.a:null;
}
function project(k,x){
  if(constructorNative[k]===false)return x?.a??(constructors[k]??[]).map(name=>x[name]);
  if(x?.request)bad('runtime fail-stop');
  if(['True','False','Zero','SNil'].includes(k))return [];
  if(k==='Succ')return [x-1n];
  if(k==='Chr')return [typeof x==='string'?x.codePointAt(0):x];
  if(k==='U32')return [word(x)];
  if(k==='F32')return [word(floatBits(x))];
  if(k==='SCon')return [x.codePointAt(0),x.slice(x.codePointAt(0)>65535?2:1)];
  if(k==='ALeaf')return [arraydata(x)[0]];
  if(k==='ANode'){const a=arraydata(x);return [{array:a.slice(0,a.length/2)},{array:a.slice(a.length/2)}]}
  if(k==='Tuple')return [x[0],x[1]];
  if(x?.a)return x.a;
  return (constructors[k]??[]).map(name=>x[name]);
}
function matcher1(name,arm){return fn(1,([x])=>{const a=project(name,x);return a.length?jump(arm(),a):arm()})}
// Prebind a selected literal arm while preserving apply's field-copy behavior.
function matcher1p(name,count,arity,make){return fn(1,exactCode(([x],entered)=>{
  const p=project(name,x),n=p.length,c=make();
  if(!entered)return n?jump(fn(arity,c),p):fn(arity,c);
  if(n!==count)return n?jump(fn(arity,c),p):fn(arity,c);
  const b=p.slice();
  if(b.length===arity)return c.call(null,b);
  if(b.length<arity)return fn(arity,c,null,b);
  let r=c.call(null,b.slice(0,arity));
  if(b.length>arity)r=jump(force(r),b.slice(arity));
  return r;
},true))}
function literal(s){
  if(s==='null')return null;
  if(s[0]==='"')return decodeString(s.slice(1,-1));
  if(s[0]==="'"){
    const inner=s.slice(1,-1);
    const escapes={'\\0':0,'\\n':10,'\\r':13,'\\t':9,"\\'":39,'\\\\':92,'\\"':34};
    return inner in escapes?escapes[inner]:decodeString(inner).codePointAt(0);
  }
  if(s.endsWith('n'))return checkedNat(BigInt(s.slice(0,-1)));
  return /[.eE]/.test(s)&&!/^0[xX]/.test(s)?Math.fround(Number(s)):Number(s);
}
function matchpat(v,p,x){
  const [tag,s,kids]=p;
  if(tag==='var'){if(s!=='_')v[s]=x;return true}
  if(tag==='ann')return matchpat(v,kids[0],x);
  if(tag==='lit')return x===literal(s);
  if(tag==='list')return matchpat(v,kids.reduceRight((t,h)=>['ctor','Con',[h,t]],['ctor','Nil',[]]),x);
  if(tag==='op'&&s==='+'){
    const n=literal(kids[0][1]);return typeof x===typeof n&&x>=n&&matchpat(v,kids[1],x-n);
  }
  if(tag==='op'&&s==='<>')return matchpat(v,['ctor','Con',kids],x);
  if(tag==='ctor'){
    if(s==='Tuple'&&kids.length>2)return matchpat(v,['ctor','Tuple',[kids[0],['ctor','Tuple',kids.slice(1)]]],x);
    const a=fields(s,x);return a!==null&&a.length===kids.length&&kids.every((k,i)=>matchpat(v,k,a[i]));
  }
  bad('unsupported pattern: '+JSON.stringify(p));
}
function matchpats(v,ps,xs){return ps.length===xs.length&&ps.every((p,i)=>matchpat(v,p,xs[i]))}
function bindpat(v,p,x){if(!matchpat(v,p,x))bad('destructuring pattern mismatch')}
function op(k,ns,a,b){
  if(k==='++')return a+b;if(k==='<>')return ctor('Con',[a,b]);
  if(k==='&&')return a&&b;if(k==='||')return a||b;
  if(k==='->'||k==='&'||k==='|')return null;
  const method={'+':'add','-':'sub','*':'mul','/':'div','%':'mod','.&.':'and','.|.':'or','.^.':'xor','<<':'shln','>>':'shrn','<':'is_lt','>':'is_gt','<=':'is_le','>=':'is_ge','==':'is_eq','!=':'is_ne'}[k];
  return call(get(G,ns+'.'+method),[a,b]);
}
const pure=x=>({pureValue:x,io:()=>x});
const bind=(m,k)=>{const action={ioBind:true,m,k};action.io=()=>runAction(action);return action};
const effect=(k,n,f)=>native(k,n,(...args)=>({io:()=>f(...args)}));
const done=x=>ctor('Done',[x]);
const fail=e=>{const code=typeof e==='number'?e:Math.abs(e?.errno??5);const row=getSystemErrorMap().get(-code);const raw=row?.[1]??'Input/output error';return ctor('Fail',[[code,raw[0].toUpperCase()+raw.slice(1)]]);};
const result=f=>{try{return done(f())}catch(e){return fail(e)}};
const unit=ctor('Unit',[]);
function checkedChar(n){if(n>0x10ffff||(n>=0xd800&&n<=0xdfff))bad(n+' is not a Unicode scalar value');return n}
// Compare UTF-16 strings without allocating code-point arrays. A malformed
// code unit is decoded only when it is reached: an earlier mismatch or an
// already exhausted operand determines the order without touching its suffix.
function textCodePoint(s,at){
  // Base's Char.cmp rebuilds Chr in left-to-right order. Reuse the same scalar
  // check (including its diagnostic), only for the demanded pair of heads.
  const point=checkedChar(s.codePointAt(at));
  return [point,point>0xffff?2:1];
}
function compareText(a,b){
  let i=0,j=0;
  while(i<a.length&&j<b.length){
    const [x,xi]=textCodePoint(a,i),[y,yj]=textCodePoint(b,j);
    if(x!==y)return x<y?-1:1;
    i+=xi;j+=yj;
  }
  return i===a.length?(j===b.length?0:-1):1;
}
for(const k of ['Type','Data','Quant','Unit','Bool','Cmp','Nat','U32','F32','Char','String','List','Maybe','Result','Token','Node','Parsed','Scanned','File','IO','Array','Pair','Kind','Empty','Chan','Socket','Listener','Window','Audio','App','Image','Event','Exists','Or'])G[k]={typeName:k};
