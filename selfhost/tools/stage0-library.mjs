// Bootstrap-only: type-check compiler modules and expose a JS testing API.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const upstream=process.env.BEND_UPSTREAM||path.resolve(import.meta.dirname,'../.bootstrap/upstream-phase23');
const B=await import(pathToFileURL(path.join(upstream,'bend2/bend.ts')));
const C=await import(pathToFileURL(path.join(upstream,'bend2/comp.ts')));
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
}catch(e){console.error(e?.$==='Err'?B.err_show(e):String(e));process.exitCode=1}
