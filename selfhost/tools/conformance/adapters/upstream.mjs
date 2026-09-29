// Live pinned reference. Only IO/report orchestration is implemented here;
// parsing, checking, normalization and emission call unmodified upstream APIs.
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {buildNative} from '../../native-build.mjs';
import {nodeResourceArgs} from '../../node-resource-args.mjs';
const root=path.resolve(process.env.BEND_UPSTREAM||path.join(import.meta.dirname,'../../../.bootstrap/upstream-phase23'));
export const name='pinned-typescript-reference';
export const capabilities={parse:true,check:true,interpreter:true,js:true,native:true,metal:false,cuda:false,modules:true,foreign:true,dependentTypes:true,affine:true,termination:true,proofs:true,proofKernel:false,checkOracle:'validation-plus-declaration-verdict'};
export const artifacts=Object.fromEntries(['bend.ts','comp.ts','base.bend','main.ts','safe.ts','bendtt.lean'].map(file=>[file,path.join(root,'bend2',file)]));
artifacts.nativeBuild=path.resolve(import.meta.dirname,'../../native-build.mjs');artifacts.nodeResources=path.resolve(import.meta.dirname,'../../node-resource-args.mjs');
// main.ts book_promises / cli_verdict(false). This reports trust after ordinary
// checking; it never invokes safe_check or claims independent kernel validation.
export function declarationReport(B,book){
  const own=[...new Set(book.order)].filter(k=>book.tlds[k].b!==true),bad=new Set(Object.keys(book.tlds).filter(k=>{const t=book.tlds[k];return t.u===true||(t.i!==undefined&&t.b!==true)})),uses=Object.create(null),seen=new Set();
  const refs=(term,out)=>{if(term&&typeof term==='object'){if((term.$==='Ref'||term.$==='ADT')&&term.k!==undefined)out.add(term.k);for(const [key,value] of Object.entries(term))if(key!=='s')refs(value,out)}};
  for(const queue=bad.size?own.slice():[];queue.length;){const key=queue.pop(),term=book.tlds[key];if(term&&!seen.has(key)){seen.add(key);const names=new Set();for(const constructor of term.$==='ADT'?term.c:[term])refs(B.term_lower(constructor.T),names);refs(term.$==='Def'?term.e:undefined,names);for(const target of names){(uses[target]??=[]).push(key);queue.push(target)}}}
  for(const key of bad)uses[key]?.forEach(name=>bad.add(name));const list=own.filter(key=>bad.has(key));
  const text=list.length?`SOME PROOFS FAIL\nError: ${list.length} def${list.length===1?' relies':'s rely'} on unsafe or foreign code:\n`+list.map(key=>'- '+key+'\n').join(''):'ALL PROOFS CHECK\nUse --verdict for mathematical validity.\n';
  return {text,proofTrust:list.length?'failed':'passed',unsafeDefinitions:list,kernelChecked:false};
}
const format=(B,error)=>error instanceof RangeError?'Error: the machine stack overflowed (a deep recursion, or a literal too large to expand)':error?.$==='Err'?B.err_show(error):String(error);
export async function probeWithModules({test,lane,workdir,timeoutMs,upstream},B,C){
  if(path.resolve(upstream)!==root)throw Error('Reference adapter and request upstream differ');
  if(!capabilities[lane])return {status:'unsupported',reason:'Reference adapter does not execute '+lane};
  let phase='parse',checked=false,typeAccepted=false,trust={proofTrust:'not-assessed',kernelChecked:false};
  try{
    const book=B.book_nil(),seen=new Map();await B.book_load(book,test.file,'',seen);
    if(lane==='parse')return {status:'ok',phase,checked:false,typeAccepted:false,...trust,exitCode:0};
    const laws=path.join(path.dirname(test.file),'LAWS.bend');
    if(path.basename(test.file)==='PROOF.bend'&&fs.existsSync(laws)&&!seen.has(fs.realpathSync(laws)))return {status:'error',phase:'load',checked:false,typeAccepted:false,...trust,diagnostic:'SOME PROOFS FAIL\nError: PROOF.bend must import ./LAWS.bend',exitCode:1};
    phase='check';checked=true;B.book_valid(book);
    const holes=book.hols;if(holes)throw `Error: ${holes} TODO${holes===1?'':'s'} found.\nThe code is incomplete, and not a valid proof yet.`;
    typeAccepted=true;
    const main=book.tlds.main,isMain=main?.$==='Def'&&(main.v!==null||main.i!==undefined);
    let verdict='';
    if(lane==='check'||lane==='interpreter'&&!isMain){const {text,...assessment}=declarationReport(B,book);verdict=text;trust=assessment;}
    // The fixture gate runs main after validation. Its check lane is not the
    // CLI's --check-only proof-trust gate: unsafe executable programs may run.
    if((lane==='check'||lane==='interpreter')&&!isMain&&trust.proofTrust==='failed')return {status:'error',phase:'verdict',checked,typeAccepted,...trust,diagnostic:verdict,exitCode:1};
    if(lane==='check')return {status:'ok',phase,checked,typeAccepted,...trust,stdout:verdict,exitCode:0};
    if(lane==='interpreter'&&!isMain)return {status:'ok',phase:'runtime',checked,typeAccepted,...trust,stdout:verdict,exitCode:0};
    phase='compile'; // IO main eligibility can fail after successful checking.
    if(lane==='interpreter'&&C.io_type(book)===null){phase='runtime';return {status:'ok',phase,checked,typeAccepted,...trust,stdout:B.term_show(B.term_lower(B.term_snf(book,main.v)))+'\n',exitCode:0};}
    let command,args,executionArgs=[];
    if(lane==='native'){
      const stem=path.basename(test.file,'.bend'),source=C.compile_book(book),file=path.join(workdir,stem+'.c'),binary=path.join(workdir,stem);fs.writeFileSync(file,source);
      const build=await buildNative({source,file,binary,target:'cpu',cwd:workdir,timeoutMs:Math.max(100,timeoutMs-250)});fs.writeFileSync(path.join(workdir,'native-build.json'),JSON.stringify(build,null,2));
      if(build.status!=='ok')return {...build,phase,checked,typeAccepted,...trust};command=binary;args=[];
    }else{
      const source=C.js_book(book),file=path.join(workdir,path.basename(test.file,'.bend')+'.cjs');fs.writeFileSync(file,source);
      command=process.execPath;executionArgs=nodeResourceArgs();args=[...executionArgs,file];
    }
    phase='runtime';const log=path.join(workdir,'program.output'),fd=fs.openSync(log,'w');let child;
    try{child=spawnSync(command,args,{cwd:workdir,stdio:['ignore',fd,fd],timeout:Math.max(100,timeoutMs-250)})}finally{fs.closeSync(fd)}
    const outputBytes=fs.statSync(log).size;
    if(outputBytes>2**20){fs.truncateSync(log,2**20);return {status:'crash',phase,checked,typeAccepted,...trust,reason:'Program exceeded output limit.',output:fs.readFileSync(log,'utf8'),outputBytes,executionArgs};}
    const output=fs.readFileSync(log,'utf8');
    if(child.error)return {status:child.error.code==='ETIMEDOUT'?'timeout':'crash',phase,checked,typeAccepted,...trust,reason:child.error.message,output,executionArgs};
    if(child.status!==0&&/Cannot find module ['\"]bun:|No such built-in module: bun:|ERR_UNKNOWN_BUILTIN_MODULE.*bun:/s.test(output))return {status:'unsupported',phase,checked,typeAccepted,...trust,reason:'Pinned upstream foreign JavaScript requires unavailable Bun runtime.',output,exitCode:child.status,executionArgs};
    if(child.signal)return {status:'crash',phase,checked,typeAccepted,...trust,reason:'Program terminated by '+child.signal,output,signal:child.signal,executionArgs};
    return {status:child.status===0?'ok':'error',phase,checked,typeAccepted,...trust,output,stdout:output,stderr:'',exitCode:child.status,executionArgs,executionMode:lane==='interpreter'?'upstream-js-io':lane};
  }catch(error){return {status:'error',phase,checked,typeAccepted,...trust,diagnostic:(!typeAccepted?'SOME PROOFS FAIL\n':'')+format(B,error),exitCode:1};}
}
export async function probe(request){
  const B=await import(pathToFileURL(path.join(root,'bend2/bend.ts'))),C=await import(pathToFileURL(path.join(root,'bend2/comp.ts')));
  return probeWithModules(request,B,C);
}
// Parse/check requests are safe to reuse with one immutable module pair. The
// probe still allocates a new upstream book and `seen` map for every request;
// no checker graph or mutable compiler result crosses the request boundary.
export const persistentLanes=['parse','check'];
export async function createPersistentSession(){
  const B=await import(pathToFileURL(path.join(root,'bend2/bend.ts'))),C=await import(pathToFileURL(path.join(root,'bend2/comp.ts')));
  return {probe:request=>probeWithModules(request,B,C)};
}
