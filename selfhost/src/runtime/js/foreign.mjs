// Native JS effect boundary. Field names and descriptors are compiler output.
// Answers are trusted, matching upstream JS: conversion changes layout only.
const foreignModules=Object.create(null);
const foreignOrigins=new WeakMap();
function descriptor(d){return d?.[0]==='Named'?showSchemas[d[1]]?.(d[2])??d:d}
// Upstream validates tags only in aggregate layouts that marshal Nat values.
// Primitive foreign values stay trusted, including their native JS shapes.
function foreignHasNat(type){
  const todo=[type],seen=new Set();
  while(todo.length){
    const d=todo.pop();if(!d)continue;
    if(d[0]==='Named'){
      if(d[1]==='Nat')return true;
      todo.push(...d[2]??[]);
      if(!seen.has(d[1])){seen.add(d[1]);const t=descriptor(d);if(t!==d)todo.push(t)}
    }else if(d[0]==='ADT')todo.push(...Object.values(d[1]).flat());
    else if(d[0]==='Fun')todo.push(d[2],d[3]);
    else if(['Tuple','List','Array'].includes(d[0]))todo.push(...d.slice(1));
  }
  return false;
}
function foreignOut(x,d=null){return foreignConvert(x,d,true)}
function foreignIn(x,d=null){return foreignConvert(x,d,false)}
function foreignConvert(root,type,outgoing){
  const result={value:null},work=[[result,'value',root,type]];
  while(work.length){
    const [parent,key,x,d]=work.pop();
    const desc=descriptor(d);
    if(!outgoing&&desc?.[0]==='ADT'&&d?.[1]!=='Nat'&&foreignHasNat(d)){
      const tags=Object.keys(desc[1]);
      if(!tags.some(k=>k===x?.$||constructorOwn[k]===x?.$))
        bad((d?.[0]==='Named'?d[1]:'datatype')+' has no tag '+String(x?.$)+' (its tags: '+tags.map(k=>constructorOwn[k]??k).join(', ')+'); a tag names its constructor as the loading file sees it, which a later version will make the same everywhere (#1105)');
    }
    if(outgoing&&x!==null&&typeof x==='object'&&foreignOrigins.has(x)){parent[key]=foreignOrigins.get(x);continue}
    if(outgoing&&(x===null||x?.proof||x?.typeName)||d?.[0]==='Erased'){parent[key]=null;continue}
    if(d?.[0]==='Char'){parent[key]=outgoing&&typeof x!=='string'?String.fromCodePoint(x):x;continue}
    if(d?.[0]==='Fun'){
      parent[key]=outgoing?(d[1]===0?foreignOut(call(x,[null]),d[3]):a=>foreignOut(call(x,[foreignIn(a,d[2])]),d[3])):fn(1,a=>d[1]===0?foreignIn(x,d[3]):foreignIn(x(foreignOut(a[0],d[2])),d[3]));
      continue;
    }
    if(outgoing&&x?.code){parent[key]=a=>foreignOut(call(x,[foreignIn(a)]));continue}
    if(!outgoing&&typeof x==='function'){parent[key]=fn(1,a=>foreignIn(x(foreignOut(a[0]))));continue}
    if(x===null||typeof x!=='object'){parent[key]=x;continue}
    if(outgoing&&Array.isArray(x)){
      const node={$:'Tuple'};parent[key]=node;work.push([node,'fst',x[0],d?.[1]],[node,'snd',x[1],d?.[2]]);continue;
    }
    if(!outgoing&&x.$==='Tuple'&&(d?.[0]==='Tuple'||d==null&&constructorNative.Tuple!==false)){
      const node=[];parent[key]=node;work.push([node,0,x.fst,d?.[1]],[node,1,x.snd,d?.[2]]);continue;
    }
    if(outgoing&&x.array||!outgoing&&Array.isArray(x)){
      const values=outgoing?arraydata(x):x,node=[];parent[key]=outgoing?node:{array:node};
      for(let i=values.length-1;i>=0;i--)work.push([node,i,values[i],d?.[1]]);
      continue;
    }
    if(!x.$){parent[key]=x;continue}
    const tag=outgoing?x.$:desc?.[0]==='ADT'?(Object.keys(desc[1]).find(k=>k===x.$||constructorOwn[k]===x.$)??x.$):x.$;
    const ds=d?.[0]==='List'&&tag==='Con'?[d[1],d]:desc?.[0]==='ADT'?desc[1]?.[tag]:null;
    const keys=constructors[tag]??({Con:['head','tail'],Some:['value'],Done:['value'],Fail:['error']}[x.$])??(outgoing?x.a.map((_,i)=>String(i)):Object.keys(x).filter(k=>k!=='$'));
    if(outgoing){
      const node={$:constructorOwn[tag]??tag};parent[key]=node;
      for(let i=keys.length-1;i>=0;i--)if(ds?.[i]?.[0]!=='Erased')work.push([node,keys[i],x.a[i],ds?.[i]]);
    }else{
      const node={$:tag,a:[]};parent[key]=node;
      foreignOrigins.set(node,x);
      for(let i=keys.length-1;i>=0;i--)work.push([node.a,i,ds?.[i]?.[0]==='Erased'?null:x[keys[i]],ds?.[i]]);
    }
  }
  return result.value;
}
function foreignCall(path,name,args,types,ret){
  const f=foreignModules[path]?.[name];
  if(typeof f!=='function')bad('missing JavaScript foreign implementation: '+name+' ('+path+')');
  const live=args.flatMap((x,i)=>types[i]?.[0]===0?[]:[foreignOut(x,types[i]?.[1])]);
  const result=f(...live);
  return result?.then?result.then(x=>foreignIn(x,ret)):foreignIn(result,ret);
}
// Public effect helpers use the native, named-field foreign representation.
const io_done=value=>({$:'Done',value});
const io_fail=code=>foreignOut(fail(code));
const io_tup=(...xs)=>xs.reduceRight((snd,fst)=>({$:'Tuple',fst,snd}));
const io_bytes=text=>new TextEncoder().encode(text);
const io_text=(bytes,n)=>new TextDecoder().decode(bytes.subarray(0,n));
const io_out=(fd,bytes)=>{let at=0;while(at<bytes.length)at+=fs.writeSync(fd,bytes,at,bytes.length-at)};
