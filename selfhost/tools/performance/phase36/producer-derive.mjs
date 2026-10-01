// Uncertified saved-output mechanism. Root owns execution and measurement.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [inputArg,outArg]=process.argv.slice(2);
assert(inputArg&&outArg,'usage: producer-derive.mjs PHASE35_SYMREG.mjs NEW_OUT');
const input=fs.realpathSync(inputArg),out=path.resolve(outArg);
assert(!fs.existsSync(out),'output must be new');
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const source=fs.readFileSync(input,'utf8');
assert.equal(hash(source),'dd400df33dc3acbf50c781778a85eb8960bdd065d40a5bf6cffde0009bb3ad26','frozen checked09 symreg required');
const old='callOwned(callOwned(get(G,"gen"),[5n]),[$R_112_114_110_103(x3515,)])';
assert.equal(source.split(old).length,2,'unique private cand call');
const cand=source.split('\n').find(x=>x.startsWith('G["cand"]='));
const names=JSON.parse(cand.match(/const \$guards=(\[[^;]+\]);/)[1]);
assert(names.includes('gen')&&names.includes('node')&&names.includes('gen.leaf')&&names.includes('prng'));
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
assert.equal(parserModule.exports.version,'8.16.0');
const parse=s=>parserModule.exports.parse(s,{ecmaVersion:'latest',sourceType:'module'});
function helper(full){return `
let $producerEntries=0;
function $producerPrng(h){h=(h^(h<<13))>>>0;h=(h^(h>>>17))>>>0;return (h^(h<<5))>>>0;}
function $producerGen(d,h){++$producerEntries;const frames=[];let top=0,value;
 visit:for(;;){if(d!==0n){const p=d-1n;let frame=top<frames.length?frames[top]:null;
  if(!frame)frame=frames[top]={d:0n,h:0,phase:0,left:null};
  frame.d=p;frame.h=h;frame.phase=0;frame.left=null;++top;
  d=p;h=$producerPrng((h^2654435761)>>>0);continue visit;
 }
 value=${full?`((h>>>8)&1)===0?{$:'Var',a:[]}:{$:'Lit',a:[h&255]}`:`callOwned(callOwned(get(G,'gen.leaf'),[h]),[((h>>>8)&1)===0])`};
 while(top){const frame=frames[top-1];if(frame.phase===0){frame.left=value;frame.phase=1;
  d=frame.d;h=$producerPrng((frame.h+340573321)>>>0);continue visit;}
  value=${full?`{$:frame.h%4===0?'Add':frame.h%4===1?'Sub':frame.h%4===2?'Mul':'Xor',a:[frame.left,value]}`:`callOwned(callOwned(callOwned(get(G,'node'),[BigInt(frame.h%4)]),[frame.left]),[value])`};
  --top;
 }return value;}}
export function producerEntryCount(){return $producerEntries;}
export function producerPoint(depth,seed){
 if(regionHostGuard()&&typeof depth==='bigint'&&depth>=0n&&depth<=281474976710655n&&typeof seed==='number'&&Number.isInteger(seed)&&seed>=0&&seed<=4294967295&&localGuard(${JSON.stringify(names)}))return $producerGen(depth,seed);
 return call(get(G,'gen'),[depth,seed]);}
`;}
const common=`
export function sumCandidatePoint(count,seed,pts=16n){let sum=0;for(let i=0;i<count;i++){
 const r=call(get(G,'cand'),[(seed+i)>>>0,pts]);if(r?.$!=='Sel'||r.a.length!==3)throw Error('expected complete Sel');sum=(sum+r.a[0]+r.a[1]+r.a[2])>>>0;
 }return sum;}
`;
const baselineExtra=`export function producerEntryCount(){return 0;}\nexport function producerPoint(d,h){return call(get(G,'gen'),[d,h]);}\n`;
fs.mkdirSync(out,{recursive:false});
const report={kind:'phase36-private-producer-prototype',complete:false,checked:false,certified:false,node:process.version,
 producer:identity(import.meta.filename),parent:identity(input),parserSha256:hash(parserSource),dependencies:names,modules:[],
 scope:'Only the existing guarded cand gen call changes. Public producers, consumers, ABI and fallback remain. Generator mode retains generic node/gen.leaf; producer mode lowers both. Dynamic Nat depth, original tagged trees, explicit reusable frames, left-before-right child order. Diagnostic producerPoint is supplemental.'};
for(const variant of ['original','baseline','generator','producer']){
 const text=variant==='original'?source:variant==='baseline'?source+common+baselineExtra:source.replace(old,'$producerGen(5n,$R_112_114_110_103(x3515,))')+common+helper(variant==='producer');
 parse(text);const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});
 report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});
}
assert.deepEqual(identity(input),report.parent);report.complete=true;
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
const controls=fs.readFileSync(path.join(import.meta.dirname,'../phase35/sum-controls.mjs'),'utf8')
 .replaceAll('phase35-private-sum-prototype','phase36-private-producer-prototype')
 .replaceAll('phase35-private-sum-controls','phase36-private-producer-controls')
 .replace("['original','baseline','loop','sums']","['original','baseline','generator','producer']")
 .replace(' for(const row of report.inputs)',` for(const seed of [0,1,42,255,256,2147483648,4294967295])for(const depth of [0,1,2,5,8]){
  const expected=modelTree(depth,seed),results=modules.slice(1).map(m=>canonicalTree(m.producerPoint(BigInt(depth),seed)));
  for(const r of results)assert.deepEqual(r,expected);report.oracle.push({kind:'private-producer-point',seed,depth,expected,results});
 }
 for(const m of modules.slice(2)){const before=m.producerEntryCount();m.default.cand(42,1n);assert.equal(m.producerEntryCount(),before+1,'actual cand producer admission');
  const restore=snapshot(m);try{changed(m,[],'gen');const blocked=m.producerEntryCount();m.default.cand(42,1n);assert.equal(m.producerEntryCount(),blocked,'mutated gen must refuse producer');}finally{restore();}}
 for(const row of report.inputs)`);
fs.writeFileSync(path.join(out,'controls.mjs'),controls,{flag:'wx'});
console.log(JSON.stringify({complete:true,certified:false,out,modules:report.modules}));
