// Guards, historical replay and actual Base equality behavior for profile6.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {transformEquality,verifyEqualityDerivation} from '../../development/equality.mjs';
const [attemptArg,outArg]=process.argv.slice(2),root=path.resolve(import.meta.dirname,'../../../..');
const out=path.resolve(outArg);fs.mkdirSync(out);
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const read=file=>fs.readFileSync(file,'utf8'),api=path.join(path.resolve(attemptArg),'api.mjs'),source=read(api);
const oldHelper=path.join(root,'selfhost/build/phase22/context-build-16/snapshot/tools/development/equality.mjs');
const old=await import(pathToFileURL(oldHelper)),oldApi=path.join(root,'selfhost/build/phase22/context-build-16/api.mjs');
const history=path.join(root,'selfhost/dist/release-history');
const legacy=path.join(history,fs.readdirSync(history).find(n=>n.startsWith('9826ac8f')),'release-lineage/checked-api.mjs');
const inputs=[api,oldApi,legacy,oldHelper,import.meta.filename,path.join(root,'selfhost/tools/development/equality.mjs')].map(identity);
const report={kind:'phase23-profile6-controls',complete:false,pass:false,inputs,replay:[],refusals:[],primitivePairs:0,fallback:[],scope:'Reviewed compiler-host String equality with ordinary built-ins; historical versions replay byte-for-byte. Private exposed functions are test artifacts, not checked bootstrap images.'};
try{
  for(const version of [1,2,3,4,5]){
    const text=read(version===1?legacy:oldApi),before=old.transformEquality(text,version),after=transformEquality(text,version);
    assert.deepEqual(after,before);report.replay.push({version,sha256:createHash('sha256').update(after.source).digest('hex')});
  }
  assert.deepEqual(transformEquality(read(oldApi)),old.transformEquality(read(oldApi)));
  const transformed=transformEquality(source);assert.equal(transformed.stats.version,6);assert.deepEqual(transformEquality(source,6),transformed);
  verifyEqualityDerivation(path.join(attemptArg,'equality/api.mjs.derivation.json'));
  const reject=(name,text,version)=>{assert.throws(()=>transformEquality(text,version));report.refusals.push(name);};
  reject('unknown runtime','\n'+source);reject('wrong historical profile',source,5);reject('new profile on old Base',read(oldApi),6);
  for(const name of ['$String$eq$','$String$order$','$Pair$snd$','$Cmp$is_eq$','$String$cmp$']){
    const escaped=name.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),re=new RegExp('(function '+escaped+'\\([^\\n]*\\) \\{\\n)');
    assert.ok(re.test(source));reject('changed dependency '+name,source.replace(re,'$1  void 0;\n'),6);
  }
  reject('shadowed protected binding',source.replace('function $String$eq$(_a_0, _b_0)','function $String$eq$($Pair$snd$, _b_0)'),6);
  const functions=[];
  for(const [name,text]of [['checked',source],['derived',transformed.source]]){
    const file=path.join(out,name+'-exposed.mjs');fs.writeFileSync(file,text+'\nexport const equality=(a,b)=>run_loop($String$eq$(a,b));\n',{flag:'wx'});
    functions.push((await import(pathToFileURL(file))).equality);
  }
  const compare=(a,b)=>{for(const fn of functions)assert.equal(fn(a,b),a===b);report.primitivePairs++;};
  for(let i=0;i<65536;i++){const a=String.fromCharCode(i);compare(a,a);compare(a,String.fromCharCode(i^1));}
  let seed=0x230006;const random=()=>{seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return seed>>>0;};
  for(let i=0;i<10000;i++){let a='';for(let n=random()%65;n;n--)a+=String.fromCharCode(random()&65535);compare(a,a);compare(a,a+'x');}
  for(const a of ['', 'a', '\ud800', '\udc00', '🙂', 'x🙂\ud800'.repeat(256)]){compare(a,a);compare(a,a+'x');}
  const observe=(fn,value)=>{try{return {value:fn(value,'x')}}catch(e){return {error:String(e)}}};
  for(const value of [null,undefined,0,1,true,false,{},[],new String('x')]){
    const a=observe(functions[0],value),b=observe(functions[1],value);assert.deepEqual(b,a);report.fallback.push(a);
  }
  for(const before of inputs)assert.deepEqual(identity(before.file),before);
  report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,primitivePairs:report.primitivePairs,replay:report.replay.length,refusals:report.refusals.length,error:report.error}));
