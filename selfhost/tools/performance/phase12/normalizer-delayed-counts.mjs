import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';import {createHash} from 'node:crypto';
const [apiArg,inputArg,outArg]=process.argv.slice(2),api=path.resolve(apiArg),inputsDir=path.resolve(inputArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs=[import.meta.filename,process.execPath,api,...[0,1,4,16,64].flatMap(n=>[path.join(inputsDir,'raw-'+n+'.json'),path.join(inputsDir,'public-'+n+'.bend')]),...['stuck','efq'].map(n=>path.join(inputsDir,n+'.json'))].map(identity);
assert.equal(inputs[2].sha256,'bb7c19dcacb1ec55c3fe380ec87b53206e2330753d0f85a23f6b5fcbb5e94e24');
const report={kind:'phase12-delayed-normalizer-counts',complete:false,pass:false,inputs,hooks:[],rows:[],scope:'Disposable counters on actual checked candidate; helper entries/spine lengths, not allocations or timing.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 let source=fs.readFileSync(api,'utf8');
 function replaceIn(name,before,after){const a=source.indexOf('function $'+name+'$('),b=source.indexOf('\nfunction ',a+1);assert.ok(a>=0&&b>a);const p=source.slice(a,b);assert.equal(p.split(before).length,2);source=source.slice(0,a)+p.replace(before,()=>after)+source.slice(b);report.hooks.push({name,before,after});}
 replaceIn('norm_ref','{$: "Con", "head": _t_0, "tail": _args_0}','p12Make(_t_0,_args_0)');
 replaceIn('norm_restore','function $norm_restore$(_left_0, _fallback_0) {','function $norm_restore$(_left_0, _fallback_0) { p12.restoreCalls++;if(_left_0===0)p12.zeroPending++;');
 replaceIn('norm_restore','return $norm_apply$(_head_0, _args_0);','return p12Force(_head_0,_args_0);');
 source+=`\nlet p12;export function reset(){p12={built:0,restoreCalls:0,zeroPending:0,reconstructed:0,spineEntries:0};}export function counts(){return structuredClone(p12);}function p12Make(head,tail){p12.built++;return {$:"Con",head,tail};}function p12Force(t,args){p12.reconstructed++;for(let a=args;a.$==="Con";a=a.tail)p12.spineEntries++;return $norm_apply$(t,args);}export function weak(book,t){return run_loop($wnf$(book,t));}reset();\n`;
 const view=path.join(out,'instrumented.mjs');fs.writeFileSync(view,source);report.view=identity(view);save();const M=await import(pathToFileURL(view)),K=M.default;
 const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
 for(const n of [0,1,4,16,64]){
  const input=JSON.parse(fs.readFileSync(path.join(inputsDir,'raw-'+n+'.json')));M.reset();const value=M.weak(input.book,input.term),counts=M.counts();assert.equal(value.name,'Result');assert.equal(counts.built,1);assert.equal(counts.reconstructed,0);assert.equal(counts.spineEntries,0);report.rows.push({kind:'raw-constant',n,counts});
  const file=path.join(inputsDir,'public-'+n+'.bend'),text=fs.readFileSync(file,'utf8');const loaded=K.f_load_graph('Main',list([{$:'FSource',name:'Main',path:file,text}]));assert.equal(loaded.error,'');M.reset();const error=K.check_book(loaded.book),publicCounts=M.counts();assert.equal(error,'');assert.equal(publicCounts.built,1);assert.equal(publicCounts.reconstructed,0);report.rows.push({kind:'public-proof',n,counts:publicCounts});save();
 }
 for(const name of ['stuck','efq']){
  const input=JSON.parse(fs.readFileSync(path.join(inputsDir,name+'.json')));M.reset();const value=M.weak(input.book,input.term),counts=M.counts();assert.deepEqual(value,input.term);assert.equal(counts.built,1);assert.equal(counts.reconstructed,1);assert.equal(counts.spineEntries,1);report.rows.push({kind:'raw-needed',name,counts});
 }
 const t=(tag,name='',id=0,kids=[])=>({$:'KTerm',tag,name,id,quant:0,kids:list(kids),removed:nil}),app=(f,x)=>t('App','',0,[f,x]),a=t('Ctr','A'),x=t('Var','x',90),matcher=t('Mat','A',0,[a,t('Efq')]);
 const d={$:'KDef',name:'f',kind:'Def',arity:1,templates:0,typ:t('Absent'),value:t('Lam','x',1,[matcher]),ctors:nil,native:false,unsafe:true};
 const input={book:list([d]),term:app(app(t('Ref','f'),a),x)},file=path.join(out,'zero-pending.json');fs.writeFileSync(file,JSON.stringify(input)+'\n');M.reset();const value=M.weak(input.book,input.term),counts=M.counts();assert.deepEqual(value,app(matcher,x));assert.equal(counts.built,1);assert.equal(counts.restoreCalls,1);assert.equal(counts.zeroPending,1);assert.equal(counts.reconstructed,0);report.rows.push({kind:'zero-pending',input:identity(file),counts});
 report.changedInputs=inputs.filter(i=>identity(i.file).sha256!==i.sha256);report.complete=true;report.pass=report.changedInputs.length===0;
}catch(error){report.error=String(error.stack??error);}
save();console.log(JSON.stringify({pass:report.pass,error:report.error,rows:report.rows}));if(!report.pass)process.exitCode=1;
