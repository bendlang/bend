// Focused current-fragment controls; diagnostic acquisition, never timing data.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [coreFile, baseFile, outArg] = process.argv.slice(2);
const out = path.resolve(outArg);
fs.mkdirSync(out);
const id = file => ({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const inputs = [id(coreFile),id(baseFile),id(import.meta.filename)];
const report = {kind:'phase31-local-runtime-controls',complete:false,pass:false,inputs,cases:[]};
const save = () => fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
save();
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const moduleFile = path.join(out,'runtime-fragments.mjs');
fs.writeFileSync(moduleFile,fs.readFileSync(coreFile,'utf8')+'\n'+fs.readFileSync(baseFile,'utf8')+'\nexport {G,fn,call,localGuard,scalarGuard};\n');
report.derivedModule=id(moduleFile);
const R = await import(pathToFileURL(moduleFile));
const names = ['Array.new','Array.get','Array.set'];
function check(name, f) {report.active=name;save();f();report.cases.push({name,pass:true});delete report.active;save()}
function mutation(object,key,descriptor,run) {
  const old=Object.getOwnPropertyDescriptor(object,key);
  try {Object.defineProperty(object,key,descriptor);run()}
  finally {if(old)Object.defineProperty(object,key,old);else delete object[key]}
}
try {
  check('canonical native snapshots retain actual arities',()=>{
    assert.deepEqual(names.map(name=>R.G[name].arity),[3,3,4]);
    assert.equal(R.localGuard(names),true);
    assert.equal(R.scalarGuard(names),true);
    assert.equal(R.localGuard(['Array.clone']),false);
  });
  check('ordinary native calls preserve storage and alias identity',()=>{
    const a=R.call(R.G['Array.new'],[null,2n,7]);
    assert.deepEqual(a.array,[7,7,7,7]);
    assert.equal(R.call(R.G['Array.set'],[null,a,5n,11]),a);
    const [alias,value]=R.call(R.G['Array.get'],[null,a,1n]);
    assert.equal(alias,a);assert.equal(value,11);assert.deepEqual(a.array,[7,11,7,7]);
  });
  for(const name of names) {
    const native=R.G[name];
    check(name+' replacement refused',()=>mutation(R.G,name,{value:R.fn(native.arity,native.code),configurable:true,writable:true},()=>assert.equal(R.localGuard(names),false)));
    check(name+' global accessor refused without invocation',()=>{
      let calls=0;mutation(R.G,name,{get(){calls++;return native},configurable:true},()=>assert.equal(R.localGuard(names),false));assert.equal(calls,0);
    });
    for(const key of ['arity','code','env','bound']) {
      const replacement={arity:native.arity+1,code:a=>a[0],env:{},bound:[]}[key];
      check(name+' saved '+key+' mutation refused',()=>mutation(native,key,{value:replacement,configurable:true,writable:true},()=>assert.equal(R.localGuard(names),false)));
      check(name+' saved '+key+' getter refused without invocation',()=>{
        let calls=0;mutation(native,key,{get(){calls++;return replacement},configurable:true},()=>assert.equal(R.localGuard(names),false));assert.equal(calls,0);
      });
    }
    check(name+' saved bound length mutation refused',()=>{
      native.bound.push(1);try{assert.equal(R.localGuard(names),false)}finally{native.bound.pop()}
    });
    check(name+' own code.call getter refused without invocation',()=>{
      let calls=0;mutation(native.code,'call',{get(){calls++;return Function.prototype.call},configurable:true},()=>assert.equal(R.localGuard(names),false));assert.equal(calls,0);
    });
    check(name+' descriptor prototype mutation refused',()=>{
      const old=Object.getPrototypeOf(native);try{Object.setPrototypeOf(native,{});assert.equal(R.localGuard(names),false)}finally{Object.setPrototypeOf(native,old)}
    });
    check(name+' restored native accepted',()=>assert.equal(R.localGuard(names),true));
  }
  for(const key of ['request','bounce','build','code']) {
    check('Array prototype '+key+' value refused',()=>mutation(Array.prototype,key,{value:false,configurable:true},()=>assert.equal(R.localGuard(names),false)));
    check('Array prototype '+key+' accessor refused without invocation',()=>{
      let calls=0;mutation(Array.prototype,key,{get(){calls++;return false},configurable:true},()=>assert.equal(R.localGuard(names),false));assert.equal(calls,0);
    });
  }
  check('Array prototype changed parent refused',()=>{
    const old=Object.getPrototypeOf(Array.prototype);
    try{Object.setPrototypeOf(Array.prototype,{});assert.equal(R.localGuard(names),false)}finally{Object.setPrototypeOf(Array.prototype,old)}
  });
  check('scalar primitive marker checks remain active',()=>mutation(Number.prototype,'bounce',{value:false,configurable:true},()=>assert.equal(R.localGuard(names),false)));
  check('fully restored environment accepted',()=>assert.equal(R.localGuard(names),true));
  for(const input of inputs)assert.equal(id(input.file).sha256,input.sha256);
  report.complete=report.pass=true;
} catch(error) {report.error=String(error.stack??error);process.exitCode=1}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:report.cases.length,error:report.error}));
