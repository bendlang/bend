// Actual-emission tests for arrayless Sigma markers and nested record demands.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [rootArg,outArg,candidateLabel='candidate04',extra='']=process.argv.slice(2),root=path.resolve(rootArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const cases=[{name:'tuple-markers',step:2,helper:'tweak'},{name:'nested-records',step:22,helper:'score_box'}];
if(extra==='products')cases.push({name:'nested-products',step:10,helper:'nested_total'});
const report={kind:'phase31-independent-local-fixtures',complete:false,pass:false,node:process.version,inputs:[identity(import.meta.filename)],values:[],boundaries:[],witness:null};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review.mjs'));
const force=(m,x)=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
function marker(m,key,mode){
  const old=Object.getOwnPropertyDescriptor(Array.prototype,key),original=m.G.tweak,events=[];let changed=false;
  try{
    Object.defineProperty(Array.prototype,key,{configurable:true,get(){
      if(Array.isArray(this)&&this.length===2&&typeof this[0]==='number'&&typeof this[1]==='number'){
        events.push('tuple:'+key);
        if(mode==='mutate'&&!changed){changed=true;const code=original.code;m.G.tweak={...original,code:function(a){events.push('changed:tweak');return (Reflect.apply(code,this,[a])+100)>>>0}};}
      }
      return false;
    }});
    return {value:m.default.bench(2,5),changed,events};
  }finally{m.G.tweak=original;if(old)Object.defineProperty(Array.prototype,key,old);else delete Array.prototype[key]}
}
try{
  for(const item of cases){
    const paths=['baseline17',candidateLabel].map(label=>path.join(root,'review-fixtures-'+item.name+'-'+label+'-01/module.mjs'));
    const receipts=paths.map(p=>JSON.parse(fs.readFileSync(p+'.json')));
    for(let i=0;i<paths.length;i++){assert.equal(receipts[i].complete,true);assert.equal(receipts[i].observation.checked,true);assert.equal(identity(paths[i]).sha256,receipts[i].output.sha256)}
    assert.equal(receipts[0].input.sha256,receipts[1].input.sha256);
    report.inputs.push(...paths.map(identity),...paths.map(p=>identity(p+'.json')));
    const modules=await Promise.all(paths.map(p=>import(pathToFileURL(p)))),text=fs.readFileSync(paths[1],'utf8');
    const symbol='$R'+Array.from(item.helper).map(c=>'_'+c.codePointAt(0)).join('');
    assert.ok(text.includes('function '+symbol+'('),'private helper actually admitted');
    const rootLine=text.split('\n').find(x=>x.startsWith('G["bench"]=') );assert.ok(rootLine.includes('localGuard($guards)'));
    for(const n of item.name==='nested-products'?[0,1,2,3,7,16,31,32,64,129]:[0,1,2,3,16,129])for(const seed of [0,5,0x7fffffff,0xffffffff]){
      const expected=Number((BigInt(seed)+BigInt(n)*BigInt(item.step))&0xffffffffn),actual=modules.map(m=>m.default.bench(n,seed));
      for(const value of actual)assert.equal(value,expected);report.values.push({fixture:item.name,n,seed,expected,actual});
    }
    for(const name of ['bench','walk',item.helper])for(const mode of ['replace','getter']){
      const observations=[];
      for(const m of modules){const descriptor=Object.getOwnPropertyDescriptor(m.G,name),f=m.G[name],events=[];
        try{
          if(mode==='replace')m.G[name]={...f,code:function(a){events.push('call:'+name);return Reflect.apply(f.code,this,[a])}};
          else Object.defineProperty(m.G,name,{configurable:true,get(){events.push('get:'+name);return f}});
          observations.push({value:m.default.bench(2,5),events});
        }finally{Object.defineProperty(m.G,name,descriptor)}
      }
      assert.deepEqual(observations[1],observations[0]);assert.ok(observations[0].events.length);report.boundaries.push({fixture:item.name,name,mode,observations});
    }
    for(const mode of ['raw','forged','constructed','saved-partial']){
      const observations=modules.map(m=>{const f=m.G.bench;if(mode==='saved-partial')return m.call(m.default.bench(2),[5]);return force(m,mode==='constructed'?Reflect.construct(f.code,[[2,5]]):Reflect.apply(f.code,null,[[2,5],mode==='forged']))});
      assert.deepEqual(observations,[5+2*item.step,5+2*item.step]);report.boundaries.push({fixture:item.name,mode,observations});
    }
    for(const mode of ['slot-mutation','slot-reentry','slot-throw','saved-partial-mutation']){
      const observations=[];
      for(const m of modules){const f=m.G.bench,original=m.G[item.helper],events=[];let active=false;
        const change=()=>{m.G[item.helper]={...original,code:function(a){events.push('changed:'+item.helper);return Reflect.apply(original.code,this,[a])}}};
        try{
          if(mode==='saved-partial-mutation'){const partial=m.default.bench(2);events.push('saved');change();observations.push({value:m.call(partial,[5]),events});continue}
          const frame=Array(2);Object.defineProperty(frame,'slice',{value:()=>{events.push('copy');return frame}});
          for(let k=0;k<2;k++)Object.defineProperty(frame,k,{get(){events.push('slot:'+k);
            if(k===0&&mode==='slot-mutation')change();
            if(k===0&&mode==='slot-reentry'&&!active){active=true;events.push('reentered:'+force(m,Reflect.apply(f.code,null,[[0,1]])))}
            if(k===1&&mode==='slot-throw')throw Error('slot sentinel');return k?5:2;
          }});
          observations.push({value:m.call(f,frame),events});
        }catch(error){observations.push({error:error.message,events})}
        finally{m.G[item.helper]=original}
      }
      assert.deepEqual(observations[1],observations[0]);report.boundaries.push({fixture:item.name,mode,observations});
    }
    if(item.name==='nested-records')for(const mode of ['array-getter','field-proxy']){
      const observations=modules.map(m=>{const events=[],inner={$:'PairBox',a:[10,20]},fields=[inner,7];
        const value=mode==='array-getter'?Object.defineProperty({$:'Nest'},'a',{get(){events.push('outer fields');return fields}}):{$:'Nest',a:new Proxy(fields,{get(t,k,r){events.push('field:'+String(k));return Reflect.get(t,k,r)}})};
        return {value:m.default.score_nest(3,5,value),events};
      });assert.deepEqual(observations[1],observations[0]);assert.equal(observations[0].value,45);report.boundaries.push({fixture:item.name,mode,observations});
    }
    if(item.name==='tuple-markers'){
      assert.ok(!rootLine.includes('"Array.new"')&&!rootLine.includes('"Array.get"')&&!rootLine.includes('"Array.set"'));
      for(const key of ['request','bounce','build','code'])for(const mode of ['observe','mutate']){
        const observations=modules.map(m=>marker(m,key,mode));assert.deepEqual(observations[1],observations[0]);
        if(key==='request'&&mode==='mutate')assert.equal(observations[0].changed,true);
        report.boundaries.push({fixture:item.name,key,mode,observations});
      }
      const badText=text.replaceAll('localGuard($guards)','scalarGuard($guards)');assert.notEqual(text,badText);
      const badFile=path.join(out,'expected-bad-arrayless-guard.mjs');fs.writeFileSync(badFile,badText,{flag:'wx'});
      const bad=await import(pathToFileURL(badFile));const correct=marker(modules[0],'request','mutate'),actual=marker(modules[1],'request','mutate'),wrong=marker(bad,'request','mutate');
      assert.deepEqual(actual,correct);assert.notEqual(wrong.value,correct.value);
      report.witness={expectedMismatch:true,correct,actual,wrong,artifact:identity(badFile)};
    }
  }
  for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,values:report.values.length,boundaries:report.boundaries.length,witness:!!report.witness,error:report.error}));
