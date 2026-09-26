// Tiny S4-A syntax/semantics controls. No compiler build or generated-code edit.
// node --stack-size=4096 --max-old-space-size=4096 declaration-controls.mjs S3_API UPSTREAM NEW_DIR [BEFORE_SOURCE AFTER_SOURCE]
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
const [apiFile,upstreamArg,outArg,beforeFile,afterFile]=process.argv.slice(2);
assert.ok(apiFile&&upstreamArg&&outArg&&!!beforeFile===!!afterFile,'Expected S3_API UPSTREAM NEW_DIR [BEFORE_SOURCE AFTER_SOURCE]');
const out=path.resolve(outArg),upstream=fs.realpathSync(upstreamArg),pin='6018e28ecc67cf1fffc0c20c64b11023474c2df8';
assert.ok(!fs.existsSync(out),'Refusing to overwrite an existing experiment directory');fs.mkdirSync(out,{recursive:true});
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:hash(file)});
const report={kind:'s4-declaration-controls',complete:false,pass:false,node:process.version,rows:[],identities:[],scope:'Pinned TypeScript and frozen checked B1 parse/check controls; normalized signatures compare source forms, not raw event streams. No runtime, performance or fixed-point claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
function git(args,name){
  const output=path.join(out,name+'.stdout'),error=path.join(out,name+'.stderr'),a=fs.openSync(output,'wx'),b=fs.openSync(error,'wx');let result;
  try{result=spawnSync('git',['-C',upstream,...args],{stdio:['ignore',a,b],timeout:10000});}finally{fs.closeSync(a);fs.closeSync(b);}
  assert.ifError(result.error);assert.equal(result.signal,null);assert.equal(result.status,0,fs.readFileSync(error,'utf8'));
  return fs.readFileSync(output,'utf8');
}
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const array=value=>{const xs=[];for(;value.$==='Con';value=value.tail)xs.push(value.head);assert.equal(value.$,'Nil');return xs;};
const prelude='type Flag is Data:\n  Flag{}\n\n';
const pair=(name,parameters,result,body,{unsafe=true,pre=prelude}={})=>{
  const marker=unsafe?'@unsafe\n':'',names=parameters.map(x=>x.replace(/^[-+]/,'').split(':')[0].trim());
  return {before:pre+`law ${name}:\n`+parameters.map(x=>`  for ${x}\n`).join('')+`  ${result}\n\n${marker}def ${name}(${names.join(', ')}):\n${body}\n`,
    after:pre+`${marker}def ${name}(\n`+parameters.map((x,i)=>`  ${x}${i+1<parameters.length?',':''}\n`).join('')+`) -> ${result}:\n${body}\n`};
};
const fixtures=[
  {id:'multiline-erased-dependent',...pair('identity',['-A: Type','value: A'],'A','  value'),expected:'ok'},
  {id:'unsafe-fill-kind',...pair('use',['f: @+g: (Flag -> Flag) -> Flag'],'Flag','  f(x => x)'),expected:'ok'},
  {id:'safe-kind-wall',...pair('use',['f: @+g: (Flag -> Flag) -> Flag'],'Flag','  f(x => x)',{unsafe:false}),expected:'check-error'},
  {id:'unrestricted-parameter',...pair('twice',['+f: Flag -> Flag','x: Flag'],'Flag','  f(f(x))'),expected:'ok'},
  {id:'affine-parameter-rejected',...pair('twice',['f: Flag -> Flag','x: Flag'],'Flag','  f(f(x))'),expected:'check-error'},
  {id:'self-recursive-decreasing',...pair('fold',['n: Count'],'Flag','  match n:\n    case Zero{}:\n      Flag{}\n    case Next{rest}:\n      fold(rest)',{unsafe:false,pre:prelude+'type Count is Data:\n  Zero{}\n  Next{rest: Count}\n\n'}),expected:'ok'},
  {id:'unsafe-self-recursion',...pair('loop',['x: Flag'],'Flag','  loop(x)'),expected:'ok'},
];
const commas=pair('commas',['-A: Type','value: A'],'A','  value');
fixtures.push({id:'multiline-final-comma',...commas,after:commas.after.replace('\n) ->',',\n) ->'),expected:'ok'});
const mutual='law left:\n  for x: Flag\n  Flag\n\nlaw right:\n  for x: Flag\n  Flag\n\n';
const leaf=pair('leaf',['x: Flag'],'Flag','  x',{pre:prelude+mutual});
const fills='\n@unsafe\ndef left(x):\n  right(leaf(x))\n\n@unsafe\ndef right(x):\n  left(x)\n';
fixtures.push({id:'retained-mutual-laws',before:leaf.before+fills,after:leaf.after+fills,expected:'ok'});
const forward=pair('early',['x: Flag'],'Flag','  later(x)');
const later='\n@unsafe\ndef later(x: Flag) -> Flag:\n  x\n';
fixtures.push({id:'missing-forward-law',before:forward.before+later,after:forward.after+later,expected:'check-error'});
for(const [id,text] of [
  ['marked-parameter-needs-type',prelude+'@unsafe\ndef broken(\n  +x\n) -> Flag:\n  Flag{}\n'],
  ['typed-fill-cannot-repeat-law',prelude+'law identity:\n  for x: Flag\n  Flag\n\n@unsafe\ndef identity(\n  x: Flag\n) -> Flag:\n  x\n'],
])fixtures.push({id,before:text,after:text,expected:'parse-error'});
if(beforeFile)fixtures.push({id:'supplied-source-pair',before:fs.readFileSync(beforeFile,'utf8'),after:fs.readFileSync(afterFile,'utf8'),expected:'ok',sourceFiles:[beforeFile,afterFile]});
// Alpha-normalize bound IDs only; keep names, quantities, free IDs and field order.
function signature(term,env=new Map(),next={id:0}){
  const kids=array(term.kids),out={tag:term.tag,name:term.name,quant:term.quant,removed:array(term.removed)};
  if(term.tag==='Var')out.id=env.has(term.id)?env.get(term.id):'free:'+term.id;
  if(term.tag==='All'){
    const domain=signature(kids[0],env,next),id=next.id++,bound=new Map(env);bound.set(term.id,id);
    return {...out,id,kids:[domain,signature(kids[1],bound,next)]};
  }
  return {...out,kids:kids.map(x=>signature(x,env,next))};
}
function signatures(book){
  const latest=new Map();for(const def of array(book))latest.set(def.name,def);
  return [...latest].map(([name,d])=>({name,kind:d.kind,arity:d.arity,templates:d.templates,native:d.native,unsafe:d.unsafe,type:signature(d.typ)})).sort((a,b)=>a.name<b.name?-1:a.name>b.name?1:0);
}
try{
  assert.equal(git(['rev-parse','HEAD'],'git-revision').trim(),pin);
  git(['diff','--quiet','HEAD','--','bend2'],'git-clean');
  const metadataFile=apiFile+'.bootstrap.json',metadata=JSON.parse(fs.readFileSync(metadataFile,'utf8'));
  assert.equal(metadata.revision,pin);assert.equal(metadata.apiSha256,hash(apiFile));assert.equal(metadata.stage,'upstream-bootstrap');
  const base=path.join(upstream,'bend2/base.bend');
  report.identities=[apiFile,metadataFile,base,path.join(upstream,'bend2/bend.ts'),fileURLToPath(import.meta.url),...(beforeFile?[beforeFile,afterFile]:[])].map(identity);save();
  const module=await import(pathToFileURL(fs.realpathSync(apiFile)));assert.equal(module.G,undefined,'Controls require the genuine named-field checked B1');
  const A=module.default,U=await import(pathToFileURL(path.join(upstream,'bend2/bend.ts')));
  for(const fixture of fixtures){
    const row={id:fixture.id,expected:fixture.expected,complete:false,pass:false,versions:{}};report.rows.push(row);save();
    try{
      for(const version of ['before','after']){
        const source=fixture[version],file=path.join(out,fixture.id+'-'+version+'.bend');fs.writeFileSync(file,source,{flag:'wx'});
        const observation={input:identity(file)};row.versions[version]=observation;
        let phase='parse';const book=U.book_nil();
        try{await U.book_load(book,file,'',new Map());phase='check';U.book_valid(book);assert.equal(book.open+book.hols,0,'Unexpected upstream TODO');observation.upstream={status:'ok'};}
        catch(error){if(error?.$!=='Err'&&typeof error!=='string')throw error;observation.upstream={status:phase+'-error',diagnostic:error?.$==='Err'?U.err_show(error):error};}
        const sources=[{$:'FSource',name:file,path:file,text:source},{$:'FSource',name:'Base',path:fs.realpathSync(base),text:fs.readFileSync(base,'utf8')}];
        const parsed=A.f_parse(source),loaded=A.f_load_graph(file,list(sources));
        observation.bend={parseError:parsed.error,loadError:loaded.error};
        observation.bend.status=loaded.error?'parse-error':(observation.bend.checkError=A.check_book(loaded.book))?'check-error':'ok';
        if(!loaded.error)observation.bend.signatures=signatures(loaded.book);
        assert.equal(observation.upstream.status,fixture.expected,'TypeScript '+version);
        assert.equal(observation.bend.status,fixture.expected,'Bend '+version);
      }
      if(fixture.expected==='ok')assert.deepEqual(row.versions.after.bend.signatures,row.versions.before.bend.signatures,'Normalized final signatures, quantities and unsafe flags');
      row.complete=true;row.pass=true;
    }catch(error){row.error=error.stack;}
    save();
  }
  for(const item of report.identities)assert.deepEqual(identity(item.file),item,'Input changed during controls');
  report.complete=report.rows.every(row=>row.complete);report.pass=report.complete&&report.rows.every(row=>row.pass);
}catch(error){report.error=error.stack;}
save();console.log(JSON.stringify({report:path.join(out,'report.json'),complete:report.complete,pass:report.pass,rows:report.rows.map(({id,pass,error})=>({id,pass,error}))}));
if(!report.pass)process.exitCode=1;
