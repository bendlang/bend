// Independent primitive arithmetic oracle plus paired checked-source execution.
// Arguments: CONFIG NEW_OUT. CONFIG.modules names upstream/baseline/candidate paths.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);
assert.ok(configFile&&outArgument,'usage: controls-run.mjs CONFIG NEW_OUT');
const config=JSON.parse(fs.readFileSync(configFile)),out=path.resolve(outArgument);
fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const encode=x=>typeof x==='bigint'?{$bigint:String(x)}:typeof x==='number'&&!Number.isFinite(x)?{$number:String(x)}:Object.is(x,-0)?{$number:'-0'}:x;
const save=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,(_,x)=>encode(x),2)+'\n',{flag:'wx'});
const manifestFile=path.join(import.meta.dirname,'controls-operations.json');
const report={kind:'phase29-independent-checked-primitive-controls',complete:false,pass:false,node:process.version,args:process.execArgv,
  affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),
  inputs:[identity(configFile),identity(import.meta.filename),identity(manifestFile),...Object.values(config.modules).map(identity)],
  scope:'Same checked Bend source compiled separately; mathematical scalar oracle and complete value equality, including signed zero/NaN. Not timing.',observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls-run.mjs'));save(path.join(out,'config.json'),config);
try{
  const modules={};for(const [name,file]of Object.entries(config.modules))modules[name]=(await import(pathToFileURL(file))).default;
  assert.deepEqual(Object.keys(modules).sort(),['baseline','candidate','upstream']);
  const u=[0,1,2,31,32,255,65535,65536,16777215,16777216,2147483647,2147483648,4294967294,4294967295];
  let seed=0x50e929;for(let i=0;i<16;i++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;u.push(seed);}
  const n=[0n,1n,2n,30n,31n,32n,33n,63n,64n,4294967295n,281474976710655n];
  const f=[-Infinity,-3.4e38,-16777216,-65536,-3.5,-1,-0.5,-(2**-126),-(2**-149),-0,0,2**-149,2**-126,0.5,1,3.5,65536,16777216,3.4e38,Infinity,NaN].map(Math.fround);
  const oracle=(name,a,b)=>{
    const [ns,op]=name.split('.');
    if(op.startsWith('is_'))return ({eq:()=>a===b,ne:()=>a!==b,lt:()=>a<b,le:()=>a<=b,gt:()=>a>b,ge:()=>a>=b,zero:()=>a===0})[op.slice(3)]();
    if(ns==='U32')return ({add:()=>(a+b)>>>0,sub:()=>(a-b)>>>0,mul:()=>Math.imul(a,b)>>>0,div:()=>b===0?0:Math.floor(a/b)>>>0,mod:()=>b===0?a:a%b,and:()=>(a&b)>>>0,or:()=>(a|b)>>>0,xor:()=>(a^b)>>>0,inc:()=>(a+1)>>>0,not:()=>(~a)>>>0,shl:()=>(a<<1)>>>0,shr:()=>a>>>1,shln:()=>b>=32n?0:(a<<Number(b))>>>0,shrn:()=>b>=32n?0:a>>>Number(b),to_nat:()=>BigInt(a),from_nat:()=>Number(a&0xffffffffn),to_f32:()=>Math.fround(a)})[op]();
    if(['add','sub','mul','div','mod','neg'].includes(op))return Math.fround(({add:()=>a+b,sub:()=>a-b,mul:()=>a*b,div:()=>a/b,mod:()=>a%b,neg:()=>-a})[op]());
    return Math.fround(Math[op](a));
  };
  const values=type=>({U32:u,Nat:n,F32:f})[type];
  for(const operation of JSON.parse(fs.readFileSync(manifestFile)).operations){
    const points=operation.domains.length===1?values(operation.domains[0]).map(a=>[a]):values(operation.domains[0]).flatMap(a=>values(operation.domains[1]).map(b=>[a,b]));
    const row={operation:operation.name,export:operation.export,points:points.length,checks:0,pass:false};report.observations.push(row);
    for(const args of points){
      const expected=oracle(operation.name,...args);
      for(const [side,api]of Object.entries(modules)){
        assert.equal(typeof api[operation.export],'function',side+' exports '+operation.export);
        const got=api[operation.export](...args);
        assert.ok(Object.is(got,expected),operation.name+' '+side+' '+JSON.stringify(args.map(encode))+' actual '+JSON.stringify(encode(got))+' expected '+JSON.stringify(encode(expected)));
        row.checks++;
      }
    }
    row.pass=true;
  }
  for(const [name,args,expected]of [
    ['partial_add',[4294967295,2],1],['partial_shift',[2147483649,32n],0],
    ['higher_order_add',[2147483649,4294967295],1],['tail_count',[50000,4294942295],24999],
  ]){
    const row={export:name,args,expected,pass:false};report.observations.push(row);
    for(const [side,api]of Object.entries(modules))assert.equal(api[name](...args),expected,side+' '+name);
    row.pass=true;
  }
  report.totalScalarChecks=report.observations.reduce((sum,x)=>sum+(x.checks??3),0);
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save(path.join(out,'report.json'),report);
console.log(JSON.stringify({complete:report.complete,pass:report.pass,totalScalarChecks:report.totalScalarChecks,error:report.error}));
