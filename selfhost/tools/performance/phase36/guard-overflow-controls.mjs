// Actual compiled pure residual source exercises Error callback reentry.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [baseArg,outArg]=process.argv.slice(2);assert(baseArg&&outArg,'usage: guard-overflow-controls.mjs COHORT_DIR/overflow NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifestFile=path.join(base,'derive.json'),meta=JSON.parse(fs.readFileSync(manifestFile));assert.equal(meta.complete,true);
const report={kind:'phase36-checked-error-scope-controls',complete:false,pass:false,inputs:[import.meta.filename,manifestFile].map(identity),oracle:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules=[];
function norm(v){return typeof v==='bigint'?v+'n':Array.isArray(v)?v.map(norm):v&&typeof v==='object'?Object.fromEntries(Object.entries(v).map(([k,x])=>[k,norm(x)])):v;}
try{
 for(const role of ['baseline','candidate']){const row=meta.variants[role],file=row.file??row.path;assert.equal(identity(file).sha256,row.sha256);report.inputs.push(identity(file));let text=fs.readFileSync(file,'utf8');
  if(role==='candidate'){const lines=text.split('\n'),at=lines.findIndex(line=>line.startsWith('G["guard.walk"]='));assert(at>=0);const marker='/* private scalar tree */';assert.equal(lines[at].split(marker).length,2);assert(lines[at].includes('regionProofOpen($guards)'),'actual guarded root must grant proof');
   lines[at]=lines[at].replace(marker,marker+'$guardEntries++;');text=lines.join('\n');
   text+='\nlet $guardEntries=0;export function guardState(){return {active:regionProof!==null,entries:$guardEntries};}\n';
  }else text+='\nexport function guardState(){return {active:false,entries:0};}\n';
  const output=path.join(out,role+'-diagnostic.mjs');fs.writeFileSync(output,text,{flag:'wx'});report.inputs.push(identity(output));modules.push(await import(pathToFileURL(output)));
 }
 for(const n of [0n,1n,2n,5n])for(const value of [0n,1n,3n,100n]){const expected=(value+3n)*(1n<<n),results=modules.map(m=>m.default['guard.walk'](n,value));for(const r of results)assert.equal(r,expected);report.oracle.push({depth:n+'n',value:value+'n',expected:expected+'n',results:results.map(norm)});}
 assert(modules[1].guardState().entries>0,'actual compiled tree proof must be active on benign calls');
 const NativeError=Error,limitDescriptor=Object.getOwnPropertyDescriptor(Error,'stackTraceLimit');
 for(const mode of ['ordinary-overflow','Error-mutation-reentry','Error-throw','stack-limit-getter']){
  const observations=modules.map(m=>{const direct=m.G['guard.direct'],oldCode=direct.code,events=[];let value,error;
   function callback(message){events.push(['Error',message,'active',m.guardState().active]);assert.equal(m.guardState().active,false,'Error host hook inherited proof');
    direct.code=function(){events.push('replacement-direct');return 20n;};
    const nested=m.default['guard.walk'](1n,1n);events.push(['nested',nested]);assert.equal(nested,44n,'reentry must observe changed private dependency');
    if(mode==='Error-throw')throw new NativeError('Error hook sentinel');return new NativeError(message);
   }
   try{
    if(mode.startsWith('Error-'))globalThis.Error=callback;
    if(mode==='stack-limit-getter')Object.defineProperty(NativeError,'stackTraceLimit',{configurable:true,get(){events.push(['stack-limit','active',m.guardState().active]);assert.equal(m.guardState().active,false);return 10;}});
    value=m.default['guard.walk'](1n,281474976710655n);
   }catch(e){error={name:e.name,message:e.message};}
   finally{globalThis.Error=NativeError;direct.code=oldCode;if(limitDescriptor)Object.defineProperty(NativeError,'stackTraceLimit',limitDescriptor);else delete NativeError.stackTraceLimit;}
   assert.equal(m.guardState().active,false,'proof leaked after actual overflow');assert(error,'must overflow');
   if(mode.startsWith('Error-'))assert(events.some(e=>Array.isArray(e)&&e[0]==='nested'),'Error callback must actually reenter');
   return norm({value,error,events});
  });assert.deepEqual(observations[1],observations[0],mode);report.boundaries.push({mode,observations});
 }
 for(const m of modules)assert.equal(m.default['guard.walk'](1n,3n),12n);
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
