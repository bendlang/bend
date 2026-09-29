import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../../../..'),build=path.join(root,'selfhost/build/phase16/checker-literal-build-05'),out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const {identity,verifyIdentity,verifyAttempt}=await import(pathToFileURL(path.join(build,'snapshot/tools/development/workflow.mjs')));await verifyAttempt(build);
const apiFile=path.join(build,'equality/api.mjs'),tsFile=path.join(root,'selfhost/.bootstrap/upstream-phase8/bend2/bend.ts');const inputs=[import.meta.filename,apiFile,tsFile].map(identity);
const report={kind:'phase16-compact-literal-direct-boundaries',complete:false,inputs,rows:[]};
const record=(name,actual,expected)=>{assert.deepEqual(actual,expected,name);report.rows.push({name,pass:true});};
try{
 const a=(await import(pathToFileURL(apiFile))).default,B=await import(pathToFileURL(tsFile));const nil={$:'Nil'};
 const arr=x=>{const out=[];for(;x.$==='Con';x=x.tail)out.push(x.head);assert.equal(x.$,'Nil');return out;};
 const lower=t=>t.$==='KLiteral'?{$:'Lit',k:t.kind,v:t.kind==='String'?t.text:t.number}:t.tag==='Ctr'?{$:'Ctr',k:t.name,x:arr(t.kids).map(lower)}:assert.fail('Unexpected term '+JSON.stringify(t));
 const strip=t=>JSON.parse(B.term_key(t));
 const cases=['0','4294967295','0n','19n','1.5','0.0','""','"abc"','"a\\n\\t\\0\\\\\\\"b"','"😃é"','"a\\u{D800}z"','"a\\u{110000}z"',"'a'","'😃'","'\\u{D800}'"];
 for(const text of cases){
  const p={book:B.book_nil(),dir:'.',str:text,pos:0,stk:[],frs:0,ns:'',al:{}},ref=B.parse_term(p),term=a.f_literal(text);
  record(text+'/literal',lower(term),strip(ref));
  record(text+'/pretty',a.kp_show(term),B.term_show(ref));
  record(text+'/self-equality',a.norm_exact(term,term),true);
  record(text+'/range-invisible',a.norm_exact(a.k_with_span(term,2,4),a.k_with_span(term,9,11)),true);
  if(term.$==='KLiteral'){
   const stepped=a.core_literal_step(a.k_with_span(term,5,9));record(text+'/step',lower(stepped),strip(B.lit_step(ref)));
   record(text+'/step-origin',[stepped.originBegin,stepped.originEnd],[5,9]);
   record(text+'/comparison',a.compare(nil,term,stepped,false),B.term_compare('EQ',B.book_nil(),ref,B.lit_step(ref)));
   record(text+'/memo-spans',a.term_key(a.k_with_span(term,2,4)),a.term_key(a.k_with_span(term,90,99)));
   record(text+'/constructor-key-distinct',a.term_key(term)!==a.term_key(stepped),B.term_key(ref)!==B.term_key(B.lit_step(ref)));
   record(text+'/graph-leaf',a.graph_strong(nil,term),term);
  }
 }
 for(const [kind,value,text,nextValue,nextText] of [['Nat',3,'',4,''],['U32',3,'',4,''],['F32',0,'',2147483648,''],['String',0,'a',0,'b']]){
  const x=a.kl_make(kind,value,text),y=a.kl_make(kind,nextValue,nextText);
  record(kind+'/different-values',a.norm_exact(x,y),false);record(kind+'/different-compare',a.compare(nil,x,y,false),false);record(kind+'/different-keys',a.term_key(x)!==a.term_key(y),true);
 }
 for(const [kind,value] of [['F32',0x7fc00000],['F32',0xff800000],['U32',4294967295],['Nat',0]]){
  const t=a.kl_make(kind,value,'');record(kind+value+'/bit-exact',lower(a.core_literal_step(t)),strip(B.lit_step({$:'Lit',k:kind,v:value})));record(kind+value+'/native',a.nc_compact(t).name,String(value));
 }
 record('js-u32',a.j_literal(a.kl_make('U32',4294967295,'')),'4294967295');record('js-f32-bits',a.j_literal(a.kl_make('F32',2147483648,'')),'bitsFloat(2147483648)');record('js-nat',a.j_literal(a.kl_make('Nat',42,'')),'42n');
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
