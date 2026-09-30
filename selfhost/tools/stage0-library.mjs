// Bootstrap-only: type-check compiler modules and expose a JS testing API.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const upstream=process.env.BEND_UPSTREAM||path.resolve(import.meta.dirname,'../.bootstrap/upstream-phase23');
const B=await import(pathToFileURL(path.join(upstream,'bend2/bend.ts')));
const C=await import(pathToFileURL(path.join(upstream,'bend2/comp.ts')));
// Upstream err_show strongly normalizes terms and their entire context. A
// compiler-source mistake can make formatting evaluate recursive compiler code.
// Bootstrap errors use bounded structural heads; never traverse cyclic books.
const short=(value,limit=600)=>typeof value==='string'?(value.length>limit?value.slice(0,limit)+'…':value):'';
function errorHead(value){
  if(typeof value==='string')return short(value);
  if(!value||typeof value!=='object')return 'unknown';
  const name=short(value.k,120);
  if(value.$==='Hol')return '?'+name;
  if(['Ref','Var','ADT','Ctr'].includes(value.$))return name+(value.$==='Ctr'?'{…}':'');
  if(value.$==='Lit')return short(String(value.v),120)+(value.k==='Nat'?'n':'');
  return short(value.$,120)||'unknown';
}
function bootstrapError(error){
  let text='Error: (bootstrap structural summary; terms are not normalized)\n- '+
    (error.obs===undefined?'message  : ':'expected : ')+errorHead(error.exp);
  if(error.obs!==undefined)text+='\n- observed : '+errorHead(error.obs);
  text+='\nLocation:'+ (typeof error.def==='string'?' '+short(error.def,200):'');
  const span=error.spn,source=span?.file?.str;
  if(typeof source==='string'&&Number.isSafeInteger(span.beg)&&span.beg>=0&&span.beg<=source.length){
    const start=span.beg===0?0:source.lastIndexOf('\n',span.beg-1)+1,end=source.indexOf('\n',span.beg);
    const line=source.slice(0,span.beg).split('\n').length,column=span.beg-start+1;
    const excerpt=source.slice(start,end<0?source.length:end);
    text+='\n'+short(span.file.ns||path.resolve(process.argv[2]),240)+':'+line+':'+column+
      '\n'+line+' | '+short(excerpt,400);
  }
  if(typeof error.nte==='string')text+='\n'+short(error.nte);
  return text;
}
try{
  const book=B.book_nil();await B.book_load(book,path.resolve(process.argv[2]),'',new Map());
  B.book_valid(book);
  if(!Number.isSafeInteger(book.hols)||book.hols<0)throw Error('Invalid checked-book hole count');
  if(book.hols)throw Error('Unresolved laws/holes: '+book.hols);
  const roots=process.argv.slice(4);
  const eligible=name=>{
    const d=book.tlds[name];
    return d?.$==='Def'&&d.v!==null&&d.b!==true&&d.i===undefined&&d.x===0&&C.io_base(book,d.T)===null;
  };
  const names=roots.length?roots:[...new Set(book.order)].filter(eligible);
  if(new Set(names).size!==names.length)throw Error('Duplicate requested API exports');
  for(const name of names){
    if(!Object.hasOwn(book.tlds,name))throw Error('Requested API export is absent from the checked book: '+name);
    if(!eligible(name))throw Error('Requested API export is not a filled non-Base, non-template, non-foreign, non-IO definition: '+name);
  }
  // The complete book was checked above. New upstream uses order only to select
  // module roots; keep every checked body, type, constructor and instance visible.
  // js_lib performs the upstream ownership check before emitting dependencies.
  fs.writeFileSync(process.argv[3],C.js_lib({...book,order:names},true));
  console.error(`Checked ${names.length} API exports`);
}catch(e){console.error(e?.$==='Err'?bootstrapError(e):String(e));process.exitCode=1}
