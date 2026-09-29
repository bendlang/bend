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
test('supported checker capabilities own verdicts and unknown values fail closed',async()=>{
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-checker-capability-')),file=path.join(directory,'main.bend');
  fs.writeFileSync(file,'# host protocol fixture\n');
  const nil={$:'Nil'},loaded={$:'FResult',book:nil,error:'',imports:nil};
  try{
    for(const version of [undefined,0,1,2,'1',3]){
      let stringChecks=0,structuredChecks=0,programChecks=0,renders=0;
      const authoritative=version===1||version===2,unsupported=version==='1'||version===3;
      const api={compiler_load_abi:()=>2,f_load_graph:()=>loaded,
        f_source_header:()=>({imports:nil,error:'',body:'',line:1,offset:0}),
        f_complete_source:()=>({parsed:loaded,graph:{$:'FGraph',book:nil,error:'',done:nil}}),
        f_complete_seed:()=>assert.fail('fixture has no seeded Base import'),
        f_import_namespace_at:()=>assert.fail('fixture has no imported namespace'),
        f_graph_trace:()=>({result:loaded,done:nil,sources:nil}),
        f_source_located:(source,begin,end)=>({$:'FLocatedSource',source,begin,end}),
        f_source_completed:(name,path,text,parsed)=>({$:'FCompletedSource',name,path,text,parsed}),
        check_book:()=>{stringChecks++;assert.ok(!authoritative,'advertised structured checker must own the verdict');return 'legacy rejection';},
        // A legacy presentation result saying success must never erase rejection.
        check_book_diagnostic:()=>{structuredChecks++;return {error:version===1?'structured rejection':'',book:nil,diagnostic:{definition:''}};},
        check_program_diagnostic:()=>{programChecks++;return {error:'program rejection',book:nil,diagnostic:{definition:''}};},
        diagnostic_render:result=>{renders++;return 'Error: '+result.error;}};
      if(version!==undefined)api.compiler_check_result_abi=()=>version;
      const result=await inspect(file,{api,mode:'check'});
      assert.deepEqual({status:result.status,phase:result.phase,checked:result.checked,exitCode:result.exitCode},
        {status:'error',phase:'check',checked:true,exitCode:1},String(version));
      const message=unsupported?'Unsupported compiler checker-result ABI: '+version:version===2?'program rejection':version===1?'structured rejection':'legacy rejection';
      assert.equal(result.diagnostic,'SOME PROOFS FAIL\nError: '+message,String(version));
      assert.equal(stringChecks,authoritative||unsupported?0:1);
      assert.equal(structuredChecks,unsupported||version===2?0:1);
      assert.equal(programChecks,version===2?1:0);assert.equal(renders,authoritative?1:0);
    }
  }finally{fs.rmSync(directory,{recursive:true,force:true});}
});
