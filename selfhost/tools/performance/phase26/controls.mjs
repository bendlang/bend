#!/usr/bin/env node
// Bounded generated-JS semantic controls, not a performance benchmark.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const write=(file,data)=>fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n',{flag:'wx'});
const u=n=>n>>>0,add=(a,b)=>u(a+b),mul=(a,b)=>Math.imul(a,b)>>>0;
const boundary=[0,1,2,3,4,7,15,16,255,256,65535,65536,65537,2147483647,2147483648,2147483649,2999999999,3000000000,3000000001,4294967294,4294967295];
const seeds=[0,1,2147483648,4294967295];
const positive=['numeric-decisions','captures-and-arguments','partial-higher-order','structural-fallback','structural-view','multiple-columns','branch-demand'];
const refusal=['own-u32','own-u32-constructor','own-u32-literal-refusal','shadow-base-refusal'];
const supplemental=['constant-bit-arms'];
const refusalPolicy={
  'own-u32':{phases:['emit','compile'],diagnostic:'U32 is a name the compiler encodes itself'},
  'own-u32-constructor':{phases:['emit','compile'],diagnostic:'U32 is a name the compiler encodes itself'},
  'own-u32-literal-refusal':{phases:['check'],diagnostic:'declared constructor'},
  'shadow-base-refusal':{phases:['load','parse'],diagnostic:'duplicate declaration: U32'},
};
const expectedRefusal=(id,stage,message)=>refusalPolicy[id]?.phases.includes(stage)&&String(message).includes(refusalPolicy[id].diagnostic);
const dense=n=>({0:11,1:13,2:17,4:19,7:23,15:29}[n]??31);
const sparse=n=>({4294967295:37,0:41,3000000000:43,2147483648:47,65536:53,2147483647:59}[n]??61);
function expected(id,n,s){
  switch(id){
    case 'numeric-decisions':return add(add(mul(dense(n),67),sparse(n)),s);
    case 'captures-and-arguments':{const b=u(s^12345);return n===0?add(s,b):n===2147483648?add(s===0?5:s===4294967295?7:mul(s,3),b):n===4294967295?u(s-b):add(mul(s,11),b);}
    case 'partial-higher-order':{const v=add(s,17);return n===0?add(s,v):n===3000000000?u(s^v):n===4294967295?u(s-v):add(mul(s,3),v);}
    case 'structural-fallback':return add(n===0?100:n===1?101:(n&1)?u(n-1):103,n===0?add(s,107):n===1?add(s,109):add(n,s));
    case 'structural-view':return u(n^s);
    case 'constant-bit-arms':{const odd=n===0?10:n===1?11:(n&1)?12:13,catchAll=n===0?10:n===1?11:12,low=n===0?179:(n&3)===1?163:(n&3)===2?167:173;return add(add(mul(odd,257),mul(catchAll,17)),add(low,s));}
    case 'multiple-columns':return n===0?(s===0?127:add(s,131)):n===2147483648&&s===4294967295?137:n===4294967295?u(s^139):s===0?add(n,149):add(mul(n,3),s);
    case 'branch-demand':assert.ok(n===0||n===4294967295);return add(s,n===0?151:157);
    default:throw Error('Missing independent oracle '+id);
  }
}
function points(id){
  if(refusal.includes(id))return [];
  const pairs=[];
  if(id==='branch-demand')for(const n of [0,4294967295])for(const s of seeds)pairs.push([n,s]);
  else{
    // Exhaust all byte values, then boundary cross product and fixed full-width LCG.
    for(let n=0;n<256;n++)pairs.push([n,u(n*16777619)]);
    for(const n of boundary)for(const s of seeds)pairs.push([n,s]);
    let r=0x26c0ffee;
    for(let i=0;i<128;i++){r=add(mul(r,1664525),1013904223);const n=r;r=add(mul(r,1664525),1013904223);pairs.push([n,r]);}
  }
  return pairs.map(([n,s])=>({export:'bench',args:[n,s],expected:expected(id,n,s)}));
}

async function worker(config){
  const report={kind:'phase26-generated-control',id:config.id,variant:config.variant,expectedRefusal:config.refusal,source:identity(config.source),pass:false,checked:false,stage:'load',observations:[]};
  let B,code;
  try{
    if(config.variant==='upstream'){
      B=await import(pathToFileURL(path.join(config.reference,'bend2/bend.ts')));
      const C=await import(pathToFileURL(path.join(config.reference,'bend2/comp.ts')));
      const book=B.book_nil();await B.book_load(book,config.source,'',new Map());
      report.stage='check';B.book_valid(book);assert.equal(book.hols,0);report.checked=true;
      report.stage='emit';code=C.js_lib(book,true);
    }else{
      process.env.BEND_TYPED_API=config.candidate.api;
      process.env.BEND_TYPED_RUNTIME=config.candidate.runtime;
      process.env.BEND_BASE=config.candidate.base;
      const D=await import(pathToFileURL(config.candidate.driver));
      report.stage='inspect';const result=await D.inspect(config.source,{mode:'library'});
      ({code,...report.inspect}=result);report.checked=result.status==='ok'||result.phase==='compile';
      if(result.status!=='ok'){
        report.refused=true;
        report.pass=config.refusal&&expectedRefusal(config.id,result.phase,result.diagnostic);
        return report;
      }
      assert.equal(result.checked,true);report.stage='emit';
    }
    assert.ok(!config.refusal,'Expected source refusal, but checked emission succeeded');
    fs.writeFileSync(config.module,code,{flag:'wx'});report.module=identity(config.module);
    report.stage='execute';const exports=(await import(pathToFileURL(config.module))).default;
    for(const point of config.points){
      assert.equal(typeof exports[point.export],'function','Missing export '+point.export);
      const actual=exports[point.export](...point.args);
      report.observations.push({...point,actual:typeof actual==='bigint'?String(actual)+'n':actual});
      assert.deepEqual(actual,point.expected,`${config.id}: ${point.export}(${point.args})`);
    }
    report.pass=true;
  }catch(error){
    report.error=error?.$==='Err'&&B?B.err_show(error):String(error.stack??error);
    report.refused=config.refusal&&expectedRefusal(config.id,report.stage,report.error);
    report.pass=report.refused;
  }finally{
    report.sourceStable=identity(config.source).sha256===report.source.sha256;
    report.pass=report.pass&&report.sourceStable;
    write(config.report,report);
  }
  return report;
}

async function acquire(configFile,output){
  const config=JSON.parse(fs.readFileSync(configFile,'utf8'));
  const repo=path.resolve(import.meta.dirname,'../../../..');
  const reference=fs.realpathSync(config.reference??path.join(repo,'selfhost/.bootstrap/upstream-phase23'));
  const candidate=config.candidate?Object.fromEntries(Object.entries(config.candidate).map(([k,v])=>[k,fs.realpathSync(v)])):null;
  if(candidate)for(const key of ['api','runtime','base','driver'])assert.ok(candidate[key],'Missing candidate.'+key);
  const cpu=String(config.cpu??'6');assert.match(cpu,/^\d+$/);
  const selected=config.cases??[...positive,...refusal];assert.ok(selected.length);
  for(const id of selected)assert.ok([...positive,...refusal,...supplemental].includes(id),'Unknown fixture '+id);
  fs.mkdirSync(output);fs.mkdirSync(path.join(output,'sources'));
  fs.copyFileSync(configFile,path.join(output,'consumed-config.json'));
  fs.copyFileSync(import.meta.filename,path.join(output,'consumed-controls.mjs'));
  const inputs=[identity(import.meta.filename),identity(process.execPath),identity(path.join(reference,'bend2/bend.ts')),identity(path.join(reference,'bend2/comp.ts')),identity(path.join(reference,'bend2/base.bend')),...candidate?Object.values(candidate).map(identity):[]];
  const report={kind:'phase26-paired-generated-controls',performanceMeasurement:false,oracleScope:'Independent scalar outputs; finite inputs, not universal correctness. Refusal controls compare phase/success scope, not exact diagnostic text.',node:process.version,cpu,inputs,rows:[],complete:false,pass:false};
  const flush=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');
  for(const id of selected){
    const source=path.join(output,'sources',id+'.bend');fs.copyFileSync(path.join(import.meta.dirname,'fixtures',id+'.bend'),source);inputs.push(identity(source));
    for(const variant of candidate?['upstream','candidate']:['upstream']){
      const name=id+'-'+variant,dir=path.join(output,name);fs.mkdirSync(dir);
      const task={id,source,variant,reference,candidate,refusal:refusal.includes(id),points:points(id),module:path.join(dir,'module.mjs'),report:path.join(dir,'observation.json')};
      const taskFile=path.join(dir,'config.json');write(taskFile,task);
      const env={...process.env};for(const k of Object.keys(env))if(k.startsWith('BEND_')||k==='NODE_OPTIONS')delete env[k];
      const args=['-c',cpu,process.execPath,'--stack-size=4096','--max-old-space-size=1024',path.join(output,'consumed-controls.mjs'),'--worker',taskFile];
      const start=performance.now();const result=spawnSync('taskset',args,{env,encoding:'utf8',timeout:config.timeoutMs??30000,maxBuffer:8*1024*1024});
      fs.writeFileSync(path.join(dir,'stdout.txt'),result.stdout??'',{flag:'wx'});fs.writeFileSync(path.join(dir,'stderr.txt'),result.stderr??'',{flag:'wx'});
      const observation=fs.existsSync(task.report)?JSON.parse(fs.readFileSync(task.report,'utf8')):null;
      const row={id,variant,command:['taskset',...args],exitCode:result.status,signal:result.signal,error:result.error?.message??null,elapsedMs:performance.now()-start,observation,pass:result.status===0&&observation?.pass===true};
      report.rows.push(row);flush();console.log(id,variant,row.pass?'PASS':'FAIL');
    }
  }
  report.changedInputs=inputs.filter(item=>identity(item.file).sha256!==item.sha256);report.complete=report.rows.length===selected.length*(candidate?2:1)&&report.changedInputs.length===0;
  report.pass=report.complete&&report.rows.every(row=>row.pass);flush();
  if(!report.pass)process.exitCode=1;
}

if(process.argv[2]==='--worker'){
  const result=await worker(JSON.parse(fs.readFileSync(process.argv[3],'utf8')));if(!result.pass)process.exitCode=1;
}else{
  assert.equal(process.argv.length,4,'Usage: node controls.mjs CONFIG.json NEW_OUTPUT');
  await acquire(fs.realpathSync(process.argv[2]),path.resolve(process.argv[3]));
}
