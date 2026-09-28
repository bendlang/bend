import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';import {createHash} from 'node:crypto';import {spawnSync} from 'node:child_process';import {performance} from 'node:perf_hooks';
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const [mode,arg,outArg]=process.argv.slice(2);
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',id=0,kids=[])=>({$:'KTerm',tag,name,id,quant:0,kids:list(kids),removed:nil});
if(mode==='worker'){
 const file=path.resolve(arg),K=(await import(pathToFileURL(file))).default,rows=[];let consume=0;
 const run=(name,size,fn,expected)=>{assert.deepEqual(fn(),expected);const startWarm=performance.now();let warm=0;do{consume+=fn()===expected?1:0;warm++}while(performance.now()-startWarm<100);const samples=[];for(let j=0;j<3;j++){const start=performance.now();let calls=0;do{consume+=fn()===expected?1:0;calls++}while(performance.now()-start<40);samples.push({ms:performance.now()-start,calls})}assert.deepEqual(fn(),expected);rows.push({name,size,warm,samples});};
 for(const depth of [16,128,512]){let a=term('Ctr','Left'),b=term('Ctr','Right');for(let i=0;i<depth;i++){a=term('Ctr','Wrap',0,[a]);b=term('Ctr','Wrap',0,[b]);}a=term('App','',0,[term('Ref','opaque'),a]);b=term('App','',0,[term('Ref','opaque'),b]);run('unequal-application',depth,()=>K.compare(nil,a,b,false),false);}
 for(const n of [1,4,16]){
  const params=Array.from({length:n},(_,i)=>'-T'+i+': Data').join(', '),args=Array.from({length:n},()=> 'Bit').join(', ');
  const source='type Bit is Data:\n  Off{}\n  On{}\n\ntype Box<'+params+'> is Data:\n  Make{value: T'+(n-1)+'}\n\ndef unwrap(box: Box<'+args+'>) -> Bit:\n  match box:\n    case Make{x}:\n      x\n';
  const loaded=K.f_load_graph('Main',list([{$:'FSource',name:'Main',path:'/phase11/micro.bend',text:source}]));assert.equal(loaded.error,'');assert.equal(K.check_book(loaded.book),'');
  let d;for(let xs=loaded.book;xs.$==='Con';xs=xs.tail)if(xs.head.name==='unwrap')d=xs.head;assert.ok(d);
  const e={$:'KEnv',book:loaded.book,name:d.name,lhs:term('Ref',d.name),pending:d.arity,quantities:nil,unsafe:false};
  run('validated-matcher-body',n,()=>K.check(e,nil,d.value,1,d.typ).error,'');
  run('complete-book',n,()=>K.check_book(loaded.book),'');
 }
 console.log(JSON.stringify({api:identity(file),rows,consume}));
}else if(mode==='run'){
 const root=path.resolve(arg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});const node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';const apis=Object.fromEntries(['baseline','exact','telescope','combined'].map(x=>[x,path.join(root,'checker-component-'+x+'-02/component.mjs')]));
 const frozen=path.join(out,'worker.mjs');fs.copyFileSync(import.meta.filename,frozen);const inputs=[identity(import.meta.filename),identity(node),...Object.values(apis).map(identity)],runs=[];
 for(const label of ['baseline','exact','telescope','combined','combined','telescope','exact','baseline']){const command=['taskset','-c','2',node,'--stack-size=4096',frozen,'worker',apis[label]];const r=spawnSync(command[0],command.slice(1),{encoding:'utf8',timeout:20000,maxBuffer:4*1024*1024});const stem=runs.length+'-'+label;fs.writeFileSync(path.join(out,stem+'.stdout'),r.stdout??'');fs.writeFileSync(path.join(out,stem+'.stderr'),r.stderr??'');const record={label,command,status:r.status,signal:r.signal,error:r.error?.message};if(r.status===0)record.result=JSON.parse(r.stdout);runs.push(record);if(r.status!==0)break;}
 const median=a=>{a=[...a].sort((a,b)=>a-b);return a.length%2?a[(a.length-1)/2]:(a[a.length/2-1]+a[a.length/2])/2};
 const summary=[];for(const row of runs[0]?.result?.rows??[]){const values=Object.fromEntries(Object.keys(apis).map(label=>[label,runs.filter(x=>x.label===label&&x.result).map(x=>median(x.result.rows.find(y=>y.name===row.name&&y.size===row.size).samples.map(z=>z.ms/z.calls)))]));summary.push({name:row.name,size:row.size,msPerCall:values,speedup:Object.fromEntries(Object.keys(apis).filter(x=>x!=='baseline').map(x=>[x,median(values.baseline)/median(values[x])]))});}
 const changed=inputs.filter(x=>identity(x.file).sha256!==x.sha256);const report={kind:'phase11-concurrent-checker-component-screen',scope:'Actual checked components, serial forward/reverse fresh workers CPU2; other compiler work may run elsewhere. 100ms warmup, three40ms samples, two processes pervariant. Not whole-compiler timing.',inputs,changed,runs,summary,pass:runs.length===8&&runs.every(x=>x.status===0)&&!changed.length};fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,summary}));if(!report.pass)process.exitCode=1;
}else throw Error('worker API or run PHASE11_BUILD OUT');
