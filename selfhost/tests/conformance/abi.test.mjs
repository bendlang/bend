import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {convertCompilerAbi,inspect} from '../../tools/typed-driver.mjs';
test('compiler ABI conversion handles deeply nested shared graphs without recursion',()=>{
  const fields={Con:['head','tail'],Nil:[],Pair:['left','right']};
  const ctor=($,a)=>({$,a});
  let value={$:'Nil'};
  for(let i=0;i<50000;i++)value={$:'Con',head:i,tail:value};
  const graph={$:'Pair',left:value,right:value};
  const encoded=convertCompilerAbi(graph,true,fields,ctor);
  assert.equal(encoded.a[0],encoded.a[1]);
  const decoded=convertCompilerAbi(encoded,false,fields,ctor);
  assert.equal(decoded.left,decoded.right);
  let count=0;
  for(let node=decoded.left;node.$==='Con';node=node.tail)count++;
  assert.equal(count,50000);
});
test('typed adapter artifacts identify helpers beside the consumed frozen driver',async()=>{
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-frozen-adapter-')),file=name=>path.join(directory,name);
  const keys=['BEND_TYPED_API','BEND_TYPED_RUNTIME','BEND_BASE','BEND_TYPED_TRACE'],previous=Object.fromEntries(keys.map(key=>[key,process.env[key]]));
  try{
    fs.mkdirSync(file('src/runtime/native/effs'),{recursive:true});
    for(const name of ['api.mjs','base.bend','runtime.mjs','compiler-abi.mjs','node-resource-args.mjs','native-build.mjs','assemble.mjs'])fs.writeFileSync(file(name),'fixture');
    fs.writeFileSync(file('typed-driver.mjs'),`import {fileURLToPath} from 'node:url';
export const project=${JSON.stringify(directory)};
export const driverPath=fileURLToPath(import.meta.url);
export const apiPath=project+'/api.mjs',basePath=project+'/base.bend',runtimePath=project+'/runtime.mjs',compilerAbiPath=project+'/compiler-abi.mjs',nodeResourceArgsPath=project+'/node-resource-args.mjs';
export const inspect=()=>{},execute=()=>{},loadApi=async()=>({});
export const createPersistentInspector=()=>{throw Error('artifact fixture must not create a persistent inspector');};
`);
    const source=fs.readFileSync(new URL('../../tools/conformance/adapters/typed.mjs',import.meta.url),'utf8').replace("from '../../typed-driver.mjs'","from './typed-driver.mjs'");
    fs.writeFileSync(file('typed.mjs'),source);
    const {artifacts}=await import(pathToFileURL(file('typed.mjs')));
    assert.equal(artifacts.driver,file('typed-driver.mjs'));assert.equal(artifacts.nativeBuild,file('native-build.mjs'));assert.equal(artifacts.assemble,file('assemble.mjs'));
    for(const name of ['nativeBuild','assemble'])assert.equal(fs.readFileSync(artifacts[name],'utf8'),'fixture');
  }finally{
    for(const key of keys)if(previous[key]===undefined)delete process.env[key];else process.env[key]=previous[key];
    fs.rmSync(directory,{recursive:true,force:true});
  }
});
test('only the exact structured-checker capability replaces the legacy verdict',async()=>{
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-checker-capability-')),file=path.join(directory,'main.bend');
  fs.writeFileSync(file,'# host protocol fixture\n');
  const nil={$:'Nil'},loaded={$:'FResult',book:nil,error:'',imports:nil};
  try{
    for(const version of [undefined,0,2,'1',1]){
      let stringChecks=0,renders=0;
      const authoritative=version===1;
      const api={f_parse:()=>loaded,f_load_graph:()=>loaded,
        check_book:()=>{stringChecks++;assert.ok(!authoritative,'advertised structured checker must own the verdict');return 'legacy rejection';},
        // A legacy presentation result saying success must never erase rejection.
        check_book_diagnostic:()=>({error:authoritative?'structured rejection':'',book:nil,diagnostic:{definition:''}}),
        diagnostic_render:result=>{renders++;return 'Error: '+result.error;}};
      if(version!==undefined)api.compiler_check_result_abi=()=>version;
      const result=await inspect(file,{api,mode:'check'});
      assert.deepEqual({status:result.status,phase:result.phase,checked:result.checked,exitCode:result.exitCode},
        {status:'error',phase:'check',checked:true,exitCode:1},String(version));
      assert.equal(result.diagnostic,authoritative?'Error: structured rejection':'Error: legacy rejection',String(version));
      assert.equal(stringChecks,authoritative?0:1);assert.equal(renders,authoritative?1:0);
    }
  }finally{fs.rmSync(directory,{recursive:true,force:true});}
});
