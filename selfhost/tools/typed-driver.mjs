#!/usr/bin/env node
// IO and process shell. All Bend parsing, elaboration, checking, normalization,
// specialization and JS emission execute the generated Bend API.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {assemble} from './assemble.mjs';
import {buildNative} from './native-build.mjs';
import {nodeResourceArgs} from './node-resource-args.mjs';
import {createCompilerAbi} from './compiler-abi.mjs';

export const driverPath=fileURLToPath(import.meta.url);
export const compilerAbiPath=fileURLToPath(new URL('./compiler-abi.mjs',import.meta.url));
export const nodeResourceArgsPath=fileURLToPath(new URL('./node-resource-args.mjs',import.meta.url));
export const project=path.resolve(import.meta.dirname,'..');
export const apiPath=path.resolve(process.env.BEND_TYPED_API||path.join(project,'dist/typed-api.mjs'));
export const runtimePath=path.resolve(process.env.BEND_TYPED_RUNTIME||path.join(project,'src/runtime.mjs'));
const bundledBasePath=path.join(project,'dist/base.bend');
export const basePath=path.resolve(process.env.BEND_BASE||bundledBasePath);
const roots=['f_parse','f_load','f_path_join','f_path_dir','check_book','annotate_book','j_program','j_library','j_expr','j_descriptor','j_io_type','j_modules','driver_has_main','driver_is_io','driver_interpret','driver_todos','driver_emit_owned'];
const list=values=>values.reduceRight((tail,head)=>({$: 'Con',head,tail}),{$:'Nil'});
function array(value) {
  const values=[];
  while(value?.$==='Con') {values.push(value.head);value=value.tail;}
  if(value?.$!=='Nil') throw Error('Malformed list returned by compiler API');
  return values;
}
const hash=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const trace=(message)=>{if(process.env.BEND_TYPED_TRACE)process.stderr.write(`[typed ${new Date().toISOString()}] ${message}\n`);};

const compilerTarget=JSON.parse(fs.readFileSync(path.join(project,'src/compiler.json'),'utf8'));
const bootstrapPin=compilerTarget.upstream;
// Bootstrap is synchronous, but its subprocess output need not use pipes.
// Some process supervisors report EPERM for pipe capture even after status 0.
// Retain the actual spawn error; file capture avoids that ambiguity.
function bootstrapCapture(command,args,options={}) {
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-bootstrap-capture-'));
  const stdout=path.join(directory,'stdout'),stderr=path.join(directory,'stderr');
  const a=fs.openSync(stdout,'wx'),b=fs.openSync(stderr,'wx');
  try {
    const result=spawnSync(command,args,{timeout:30000,...options,stdio:['ignore',a,b]});
    if(fs.statSync(stdout).size>2**24||fs.statSync(stderr).size>2**24)throw Error('Bootstrap subprocess output exceeded 16 MiB');
    return {...result,stdout:fs.readFileSync(stdout,'utf8'),stderr:fs.readFileSync(stderr,'utf8')};
  } finally {fs.closeSync(a);fs.closeSync(b);fs.rmSync(directory,{recursive:true,force:true});}
}
function bootstrapUpstream(upstream,expectedRevision) {
  const version=bootstrapCapture('git',['-C',upstream,'rev-parse','HEAD']);
  if(version.error||version.signal||version.status!==0)throw Error('Bootstrap upstream verification failed: '+(version.error?.message||version.signal||version.stderr));
  const revision=version.stdout.trim();
  if(revision!==expectedRevision)throw Error(`Bootstrap requires upstream ${expectedRevision}; found ${revision||'no checkout'}`);
  const clean=bootstrapCapture('git',['-C',upstream,'diff','--quiet','HEAD','--','bend2']);
  if(clean.error||clean.signal)throw Error('Bootstrap upstream verification failed: '+(clean.error?.message||clean.signal));
  if(clean.status!==0)throw Error('Bootstrap upstream tracked sources differ from pinned HEAD');
  return revision;
}
const bootstrapInput=(file,role)=>({role,file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:hash(file)});
export function captureBootstrapProvenance(upstream,{expectedRevision=bootstrapPin,tools=[driverPath,path.join(project,'tools/stage0-library.mjs'),...['assemble.mjs','compiler-abi.mjs','node-resource-args.mjs','native-build.mjs'].map(name=>path.join(path.dirname(driverPath),name))]}={}) {
  upstream=path.resolve(upstream);
  const revision=bootstrapUpstream(upstream,expectedRevision);
  return {version:1,upstream:{file:upstream,canonicalPath:fs.realpathSync(upstream),revision,trackedSourcesClean:true},
    node:{file:process.execPath,version:process.version,execArgv:process.execArgv},
    inputs:[...['bend.ts','comp.ts','base.bend'].map(name=>bootstrapInput(path.join(upstream,'bend2',name),'upstream')), ...tools.map(file=>bootstrapInput(file,'host-tool'))],verifiedAfterBuild:false};
}
export function verifyBootstrapProvenance(provenance) {
  if(fs.realpathSync(provenance.upstream.file)!==provenance.upstream.canonicalPath)throw Error('Bootstrap upstream canonical path changed');
  bootstrapUpstream(provenance.upstream.file,provenance.upstream.revision);
  for(const input of provenance.inputs)if(fs.realpathSync(input.file)!==input.canonicalPath||hash(input.file)!==input.sha256)throw Error('Bootstrap input changed: '+input.file);
  return true;
}

export function bootstrap({upstream=process.env.BEND_UPSTREAM||path.resolve(project,'.bootstrap/upstream-phase8'),timeoutMs=120000,nativeSnapshot=process.env.BEND_TYPED_NATIVE_SNAPSHOT,nativeModules}={}) {
  const provenance=captureBootstrapProvenance(upstream),revision=provenance.upstream.revision;
  const manifest=path.join(project,'src/compiler.json');
  if(!fs.existsSync(manifest))throw Error('Compiler module manifest is missing: '+manifest);
  provenance.inputs.push(bootstrapInput(manifest,'compiler-manifest'));
  let files=JSON.parse(fs.readFileSync(manifest,'utf8')).modules;
  if(nativeModules) {
    if(!nativeSnapshot||nativeModules.some(file=>!file.startsWith('src/back/native/')))throw Error('Invalid native module snapshot');
    const at=files.findIndex(file=>file.startsWith('src/back/native/'));
    files=files.filter(file=>!file.startsWith('src/back/native/'));
    files.splice(at<0?files.length:at,0,...nativeModules);
  }
  const exports=[...roots];
  if(fs.readFileSync(path.join(project,'src/core/term.bend'),'utf8').includes('def compiler_term_abi('))exports.push('compiler_term_abi');
  if(fs.readFileSync(path.join(project,'src/core/term.bend'),'utf8').includes('def compiler_span_abi('))exports.push('compiler_span_abi');
  if(fs.existsSync(path.join(project,'src/check/specialize.bend'))) {
    if(!files.includes('src/check/specialize.bend'))files.push('src/check/specialize.bend');
    exports.push('specialize_book','specialized_book','specialized_error');
    if(fs.readFileSync(path.join(project,'src/check/specialize.bend'),'utf8').includes('def specialized_diagnostic('))exports.push('specialized_diagnostic');
  }
  if(files.includes('src/back/native/book.bend')) {
    exports.push('nc_compile','nc_foreign_paths');
    if(fs.readFileSync(path.join(project,'src/back/native/book.bend'),'utf8').includes('nc_annotation_stops('))exports.push('nc_annotation_stops','nc_annotated_context');
  }
  if(files.includes('src/back/native/foreign.bend'))exports.push('nc_foreign_source','nc_foreign_scope');
  if(files.includes('src/check/prefix.bend'))exports.push('check_from_exact_prefix','exact_prefix');
  if(files.includes('src/load/graph.bend'))exports.push('f_load_graph','f_main_names','f_load_graph_trace');
  if(files.includes('src/load/modules.bend')){exports.push('f_source_parsed','f_source_located');if(fs.readFileSync(path.join(project,'src/load/modules.bend'),'utf8').includes('def compiler_load_abi('))exports.push('compiler_load_abi','f_source_header','f_complete_source','f_complete_seed','f_import_namespace_at','f_graph_trace');}
  if(fs.readFileSync(path.join(project,'src/front/declarations.bend'),'utf8').includes('def f_parse_indexed('))exports.push('f_parse_indexed');
  if(files.includes('src/load/imports.bend')&&fs.readFileSync(path.join(project,'src/load/imports.bend'),'utf8').includes('def f_import_failure('))exports.push('f_import_failure');
  if(files.includes('src/core/index.bend'))exports.push('book_context','book_cached');
  if(files.includes('src/load/seed.bend'))exports.push('f_load_graph_seed','f_load_graph_seed_trace');
  if(files.includes('src/driver/report.bend'))exports.push('driver_report','driver_bad_names');
  if(files.includes('src/diagnostic/produce.bend'))exports.push('compiler_check_result_abi','check_book_diagnostic','check_book_diagnostic_from_exact_prefix','diagnostic_render','diagnostic_result_locate');
  if(files.includes('src/driver/api.bend')&&fs.readFileSync(path.join(project,'src/driver/api.bend'),'utf8').includes('def check_program_diagnostic('))exports.push('check_program_diagnostic');
  if(files.includes('src/diagnostic/frontend.bend')){exports.push('f_load_origins_for','f_loaded_origins_for');if(fs.readFileSync(path.join(project,'src/diagnostic/frontend.bend'),'utf8').includes('def diagnostic_render_loaded('))exports.push('diagnostic_render_loaded');}
  if(files.includes('src/back/js/validate.bend')) {
    exports.push('j_compile_error');
    if(fs.readFileSync(path.join(project,'src/back/js/validate.bend'),'utf8').includes('law j_layout_error:'))exports.push('j_layout_error');
  }
  if(files.includes('src/core/reach.bend'))exports.push('reach_book','j_roots','j_stops','annotate_except','kf_source');
  if(fs.readFileSync(path.join(project,'src/check/annotate.bend'),'utf8').includes('law annotate_selected:'))exports.push('annotate_selected');
  if(fs.readFileSync(path.join(project,'src/back/js/emit.bend'),'utf8').includes('law j_program_selected:'))exports.push('j_program_selected','j_library_selected');
  if(files.includes('src/back/js/foreign.bend'))exports.push('j_foreign_paths','j_foreign_error');
  const snapshots=files.map(file=>({file,bytes:fs.readFileSync(path.join(nativeSnapshot&&file.startsWith('src/back/native/')?path.resolve(nativeSnapshot):project,file))}));
  const fingerprint=crypto.createHash('sha256');
  for(const s of snapshots)fingerprint.update(s.file).update('\0').update(s.bytes).update('\0');
  const snapshot=path.join(project,'build/typed/snapshots',fingerprint.digest('hex'));
  for(const s of snapshots) {const file=path.join(snapshot,s.file);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,s.bytes);}
  const source=path.join(snapshot,'compiler.bend');
  assemble(files,source,{root:snapshot});
  provenance.inputs.push(bootstrapInput(source,'assembled-source'),...files.map(file=>bootstrapInput(path.join(snapshot,file),'compiler-module')));
  verifyBootstrapProvenance(provenance);
  fs.mkdirSync(path.dirname(apiPath),{recursive:true});
  const staged=apiPath+'.tmp-'+process.pid;
  const result=bootstrapCapture(process.execPath,[path.join(project,'tools/stage0-library.mjs'),source,staged,...exports],
    {cwd:project,env:{...process.env,BEND_UPSTREAM:upstream},timeout:timeoutMs});
  if(result.error||result.signal||result.status!==0) {fs.rmSync(staged,{force:true});throw Error(result.error?.message||result.signal||result.stderr||'Typed API bootstrap failed');}
  try{verifyBootstrapProvenance(provenance);provenance.verifiedAfterBuild=true;}catch(error){fs.rmSync(staged,{force:true});throw error;}
  fs.renameSync(staged,apiPath);
  fs.copyFileSync(source,path.join(project,'build/typed/compiler.bend'));
  const upstreamBase=path.join(upstream,'bend2/base.bend');
  // Concurrent frozen validations protect metadata as well as bytes. Rebuilding
  // an API must not touch a shared Base file whose pinned contents are identical.
  if(!fs.existsSync(bundledBasePath)||hash(bundledBasePath)!==hash(upstreamBase))
    fs.copyFileSync(upstreamBase,bundledBasePath);
  const report={stage:'upstream-bootstrap',revision,generated:new Date().toISOString(),apiPath,apiSha256:hash(apiPath),baseSha256:hash(bundledBasePath),
    source,sourceSha256:hash(source),modules:files.map(file=>({file,sha256:hash(path.join(snapshot,file))})),exports,provenance,
    ...(nativeSnapshot?{nativeModuleSnapshot:path.resolve(nativeSnapshot)}:{})};
  const reportPath=apiPath===path.join(project,'dist/typed-api.mjs')?path.join(project,'dist/typed-bootstrap-report.json'):apiPath+'.bootstrap.json';
  fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
  return report;
}

// Iterative ABI graph copy preserves shared subtrees and handles compiler books
// whose list/string-literal depth exceeds the JavaScript call-stack limit.
export function convertCompilerAbi(value,encode,fields,ctor) {
  const memo=new WeakMap(),pending=[];
  const allocate=value=>{
    if(value===null||typeof value!=='object')return value;
    if(memo.has(value))return memo.get(value);
    let target,keys;
    if(Array.isArray(value)) {target=new Array(value.length);keys=null;}
    else {
      keys=fields[value.$];
      if(!keys)throw Error('Unknown compiler ABI constructor: '+value.$);
      target=encode?ctor(value.$,new Array(keys.length)):{$:value.$};
    }
    memo.set(value,target);pending.push({value,target,keys});return target;
  };
  const root=allocate(value);
  while(pending.length) {
    const {value,target,keys}=pending.pop();
    if(keys===null)for(let i=0;i<value.length;i++)target[i]=allocate(value[i]);
    else for(let i=0;i<keys.length;i++) {
      if(encode)target.a[i]=allocate(value[keys[i]]);
      else target[keys[i]]=allocate(value.a[i]);
    }
  }
  return root;
}

export async function loadApi() {
  return loadApiForIdentity();
}
async function loadApiForIdentity(identity=null) {
  if(!fs.existsSync(apiPath)) throw Error('Typed compiler API is missing. Run node tools/typed-driver.mjs --bootstrap once.');
  // A content identity prevents a new inspector from binding changed file bytes
  // to an older module already held by Node's URL cache.
  const url=pathToFileURL(identity?.canonicalPath??apiPath);
  if(identity)url.searchParams.set('bendApiSha256',identity.sha256);
  const module=await import(url);
  const termAbi=module.default.compiler_term_abi?.();
  if(module.default.compiler_term_abi!==undefined&&termAbi!==1)throw Error('Unknown compiler term ABI: '+termAbi);
  const spanAbi=module.default.compiler_span_abi?.();
  if(module.default.compiler_span_abi!==undefined&&spanAbi!==3)throw Error('Unknown compiler span ABI: '+spanAbi);
  const loadAbi=module.default.compiler_load_abi?.();
  if(module.default.compiler_load_abi!==undefined&&loadAbi!==1)throw Error('Unknown compiler load ABI: '+loadAbi);
  if(termAbi===1&&spanAbi!==3)throw Error('Term ABI requires source-range ABI3');
  if(!module.G) return module.default;
  // The bootstrap compiler marshals ADTs with named fields. The self-hosted
  // runtime uses positional fields. This is an ABI conversion, not elaboration.
  const fields={Nil:[],Con:['head','tail'],FSource:['name','path','text'],FParsedSource:['name','path','text','parsed'],FLocatedSource:['source','begin','end'],FHeader:['imports','error','body','line','offset'],FCompletion:['graph','parsed'],FGraph:['book','error','done'],FResult:['book','error','imports'],FLoadTrace:['result','done','sources'],
    KTerm:spanAbi===3?['tag','name','id','quant','kids','removed','originBegin','originEnd']:['tag','name','id','quant','kids','removed'],KDef:['name','kind','arity','templates','typ','value','ctors','native','unsafe'],
    ...(termAbi===1?{KLiteral:['kind','number','text','originBegin','originEnd'],KLambda:['name','id','quant','kids','removed','originBegin','originEnd','quantityPresent']}:{}),
    KSpecialized:['book','error'],NC_Result:['source','error'],KF_Source:['parts','error'],
    DText:['text'],DTerm:['term'],DNoSpan:[],DSpan:['source','begin','end'],
    DOrigin:['definition','term','source','begin','end','path'],DSourceOrigin:['source','begin','end'],
    DDiagnostic:['expected','observed','has_observed','context','definition','span','note','trail'],
    DResult:['error','book','diagnostic'],FProvenance:['result','origins']};
  return createCompilerAbi({fields,ctor:module.ctor,
    onPhase:process.env.BEND_TYPED_TRACE?event=>trace(`ABI ${event.name} ${event.phase} ${JSON.stringify(event.stats)}`):undefined}).wrap(module.default);
}

// Source coordinates belong to one request. Base always owns interval one, so
// a checked Base cache cannot silently introduce stale or overlapping positions.
const SPAN_ABI=3,SPAN_CACHE=4,TERM_CACHE=6,U32_MAX=0xffffffff;
function interval(begin,text) {
  const end=begin+text.length+1;
  if(!Number.isSafeInteger(begin)||begin<1||!Number.isSafeInteger(end)||end>U32_MAX)throw Error('Source interval overflow');
  return {begin,end};
}
export function validateSpanBook(book,ranges,termAbi=0) {
  const pending=[book],seen=new WeakSet();
  while(pending.length) {
    const value=pending.pop();
    if(value===null||typeof value!=='object'||seen.has(value))continue;
    seen.add(value);
    if(value.$==='KLiteral') {
      if(termAbi!==1||!['Nat','U32','F32','String'].includes(value.kind)||!Number.isSafeInteger(value.number)||value.number<0||value.number>U32_MAX||typeof value.text!=='string'||(value.kind==='String'?(value.number!==0||Array.from(value.text).some(c=>{const n=c.codePointAt(0);return n>=0xd800&&n<=0xdfff;})):value.text!==''))throw Error('Invalid compiler literal payload');
    }
    if(value.$==='KLambda'&&(termAbi!==1||typeof value.quantityPresent!=='boolean'))throw Error('Invalid compiler Lambda payload');
    if(value.$==='KTerm'||value.$==='KLiteral'||value.$==='KLambda') {
      const a=value.originBegin,b=value.originEnd;
      if(!Number.isSafeInteger(a)||!Number.isSafeInteger(b)||a<0||b<0||a>U32_MAX||b>U32_MAX||
        !((a===0&&b===0)||(a>0&&b>=a&&ranges.some(r=>a>=r.begin&&b<r.end))))
        throw Error('Invalid compiler source range');
    }
    for(const child of Object.values(value))if(child!==null&&typeof child==='object')pending.push(child);
  }
  return true;
}
export function validateSpanCache(c,{compilerSha256,baseSha256,sourcePath,sourceText,termAbi=0}) {
  const range=interval(1,sourceText);
  if(c.version!==(termAbi===1?TERM_CACHE:SPAN_CACHE)||(c.termAbi??0)!==termAbi||c.spanAbi!==SPAN_ABI||c.compilerSha256!==compilerSha256||c.baseSha256!==baseSha256||
    c.sourcePath!==sourcePath||c.sourceBegin!==range.begin||c.sourceEnd!==range.end||c.validatedBy!=='check_book'||
    c.bookSha256!==crypto.createHash('sha256').update(JSON.stringify(c.book)).digest('hex'))throw Error('Invalid source-aware Base cache');
  validateSpanBook(c.book,[range],termAbi);return true;
}

export function discoverSources(api,input,{seed=null}={}) {
  const sources=[],seen=new Map(),physical=new Map(),foreign=new Map(),active=new Set();
  const loadAbi=api.compiler_load_abi?.(),contextual=loadAbi===1;
  if(api.compiler_load_abi!==undefined&&!contextual)throw Error('Unknown compiler load ABI: '+loadAbi);
  if(contextual)for(const name of ['f_source_header','f_complete_source','f_complete_seed','f_import_namespace_at','f_graph_trace'])
    if(typeof api[name]!=='function')throw Error('Missing contextual compiler source API: '+name);
  const located=api.compiler_span_abi?.()===SPAN_ABI;
  if(located&&(!api.f_parse_indexed||!api.f_source_located))throw Error('Missing indexed compiler source API');
  const baseCanonical=located?fs.realpathSync(basePath):null;
  const baseText=located?fs.readFileSync(baseCanonical,'utf8'):null;
  const baseRange=located?interval(1,baseText):null;
  let next=baseRange?.end??0,root=null,completed={$:'FGraph',book:list([]),error:'',done:list([])};
  const graphMode=typeof api.f_load_graph==='function';
  const wrap=(source,range)=>located?api.f_source_located(source,range.begin,range.end):source;
  const visit=(name,file,edge=null)=>{
    const absolute=fs.realpathSync(file);
    if(root===null)root=path.dirname(absolute);
    // Finish each dependency before requesting a later sibling file.
    if(active.has(absolute)&&api.f_import_failure)
      throw Object.assign(Error('Import traversal reentry'),{code:'BEND_IMPORT_CYCLE',importPath:absolute});
    if(seen.has(name)) {
      if(seen.get(name)!==absolute) throw Object.assign(Error('Module import path collision: '+name),{phase:'load'});
      return;
    }
    seen.set(name,absolute);
    const source=fs.readFileSync(absolute,'utf8'),prior=physical.get(absolute);
    trace('parse '+absolute);
    const seeded=name==='Base'&&seed&&seed.sourcePath===absolute&&seed.sourceText===source;
    if(prior&&prior.source!==source)throw Object.assign(Error('Source alias bytes changed'),{phase:'load'});
    if(located&&absolute===baseCanonical&&source!==baseText)throw Object.assign(Error('Base source bytes changed'),{phase:'load'});
    const range=located?(prior?.range??(absolute===baseCanonical?baseRange:interval(next,source))):null;
    if(located&&!prior&&absolute!==baseCanonical)next=range.end;
    if(seeded&&located&&(seed.spanAbi!==SPAN_ABI||seed.sourceBegin!==range.begin||seed.sourceEnd!==range.end))throw Error('Stale Base source interval');
    let parsed=prior?.parsed||(seeded?{book:list([]),imports:list([]),error:''}:contextual?null:located?api.f_parse_indexed(range.begin,source):api.f_parse(source));
    const raw=wrap({$:'FSource',name,path:absolute,text:source},range),slot=sources.length;
    sources.push(raw);
    const retain=()=>{if(parsed&&api.f_source_parsed&&!seeded)sources[slot]=wrap(api.f_source_parsed(name,absolute,source,parsed),range);};
    if(prior){retain();return;}
    const record={parsed,source,range};physical.set(absolute,record);active.add(absolute);
    const header=contextual&&!seeded?api.f_source_header(raw):null;
    const imports=header?.imports??parsed.imports;
    if(located&&!contextual&&!seeded&&!parsed.error)validateSpanBook(parsed.book,[range],api.compiler_term_abi?.()??0);
    for(const item of array(imports)) {
      const imported=item.name,importedFile=imported==='Base'?basePath:path.resolve(path.dirname(absolute),imported);
      try {visit(graphMode&&imported!=='Base'?importedFile:imported,importedFile,{item,source:raw});}
      catch(error) {
        if(!error.phase&&api.f_import_failure&&(error.code==='ENOENT'||error.code==='BEND_IMPORT_CYCLE'))
          throw Object.assign(Error(api.f_import_failure(source,item,error.code==='BEND_IMPORT_CYCLE'?error.importPath:importedFile,error.code==='BEND_IMPORT_CYCLE')),{phase:'parse',sourceFile:absolute});
        throw error;
      }
    }
    if(contextual) {
      const supplied=list(sources),ns=edge?api.f_import_namespace_at(edge.item,edge.source,supplied,root):'';
      const result=seeded?api.f_complete_seed(raw,completed,seed.sourcePath,seed.sourceText,seed.book):api.f_complete_source(raw,ns,header,supplied,completed,root);
      parsed=result.parsed;completed=result.graph;record.parsed=parsed;
      if(located&&!seeded&&!parsed.error)validateSpanBook(parsed.book,[...physical.values()].map(x=>x.range),api.compiler_term_abi?.()??0);
    }
    retain();
    if(name!=='Base'&&api.f_path_join) for(const definition of array(parsed.book)) {
      if(definition.value.tag!=='Foreign')continue;
      for(const imported of array(definition.value.kids)) {
        const qualified=api.f_path_join(api.f_path_dir(absolute),imported.name);
        foreign.set(qualified,{name:qualified,path:qualified});
      }
    }
    active.delete(absolute);
    const error=contextual?completed.error:parsed.error;
    if(error)throw Object.assign(Error(error),{phase:'parse',sourceFile:absolute});
  };
  const main=graphMode?path.resolve(input):'__main__';
  visit(main,path.resolve(input));
  const supplied=list(sources);
  return {main,sources:supplied,files:[...physical.keys()],foreign:[...foreign.values()],hasBase:seen.has('Base'),
    ...(contextual?{loadTrace:api.f_graph_trace(completed,supplied)}:{})};
}

function baseCacheInfo(api) {
  const compilerSha256=hash(apiPath),baseSha256=hash(basePath);
  const sourcePath=fs.realpathSync(basePath),sourceText=fs.readFileSync(basePath,'utf8');
  const termAbi=api.compiler_term_abi?.()??0;
  const version=termAbi===1?TERM_CACHE:api.compiler_span_abi?.()===SPAN_ABI?SPAN_CACHE:api.f_load_graph_seed?2:1;
  const directory=path.join(project,'build/typed/cache');
  const location=crypto.createHash('sha256').update(sourcePath).digest('hex');
  const file=path.join(directory,`base-${compilerSha256}-${baseSha256}${version>=2?'-'+location:''}.json`);
  return {version,termAbi,compilerSha256,baseSha256,sourcePath,sourceText,directory,file};
}
// Only persistent inspectors own this bounded memo. Re-read and hash the exact
// bytes on every request; cached metadata and filesystem timestamps are not proof.
function freezeBaseBook(book) {
  const pending=[book];
  while(pending.length) {
    const value=pending.pop();
    if(value===null||typeof value!=='object'||Object.isFrozen(value))continue;
    Object.freeze(value);
    for(const child of Object.values(value))if(child!==null&&typeof child==='object')pending.push(child);
  }
  return book;
}
function readBaseCache(info,memo=null) {
  try {
    const previous=memo?.entry;
    if(memo)memo.entry=null;
    const bytes=fs.readFileSync(info.file);
    const key=memo?JSON.stringify([info.version,info.compilerSha256,info.baseSha256,info.sourcePath,info.file]):null;
    const digest=memo?crypto.createHash('sha256').update(bytes).digest('hex'):null;
    if(previous?.key===key&&previous.digest===digest) {
      memo.entry=previous;
      return {...previous.cached,sourcePath:info.sourcePath,sourceText:info.sourceText};
    }
    const cached=JSON.parse(bytes.toString('utf8'));
    if(info.version>=SPAN_CACHE)validateSpanCache(cached,info);
    if(cached.version!==info.version||cached.compilerSha256!==info.compilerSha256||cached.baseSha256!==info.baseSha256||cached.validatedBy!=='check_book')return null;
    if(info.version===2&&(cached.sourcePath!==info.sourcePath||cached.bookSha256!==crypto.createHash('sha256').update(JSON.stringify(cached.book)).digest('hex')))return null;
    if(memo) {
      freezeBaseBook(cached.book);
      Object.freeze(cached);
      memo.entry={key,digest,cached};
    }
    return {...cached,sourcePath:info.sourcePath,sourceText:info.sourceText};
  } catch(error) {if(error.code!=='ENOENT'&&!(error instanceof SyntaxError))throw error;return null;}
}
export async function prepareBase(api) {
  api??=await loadApi();
  const info=baseCacheInfo(api),prior=readBaseCache(info);
  if(prior)return prior;
  const raw={$:'FSource',name:'Base',path:info.sourcePath,text:info.sourceText};
  const range=info.version>=SPAN_CACHE?interval(1,info.sourceText):null;
  const source=range?api.f_source_located(raw,range.begin,range.end):raw;
  const loaded=(api.f_load_graph||api.f_load)('Base',list([source]));
  if(loaded.error)throw Object.assign(Error(loaded.error),{phase:'parse'});
  const error=api.check_book(loaded.book);
  if(error)throw Object.assign(Error(error),{phase:'check'});
  const {version,compilerSha256,baseSha256,sourcePath,directory,file}=info;
  const cached={version,...(info.termAbi?{termAbi:info.termAbi}:{}),compilerSha256,baseSha256,sourcePath,validatedBy:'check_book',generated:new Date().toISOString(),
    bookSha256:crypto.createHash('sha256').update(JSON.stringify(loaded.book)).digest('hex'),book:loaded.book,
    ...(range?{spanAbi:SPAN_ABI,sourceBegin:range.begin,sourceEnd:range.end}:{})};
  if(range)validateSpanCache(cached,info);
  fs.mkdirSync(directory,{recursive:true});
  const staged=file+'.tmp-'+process.pid;
  try {fs.writeFileSync(staged,JSON.stringify(cached));fs.renameSync(staged,file);} finally {fs.rmSync(staged,{force:true});}
  return {...cached,sourceText:info.sourceText};
}

function foreignSources(graph,extension,required=null,api=null,book=null,scope=book) {
  const term=(tag,name,kids=[])=>({$:'KTerm',tag,name,id:0,quant:0,kids:list(kids),removed:list([]),originBegin:0,originEnd:0});
  const files=required===null?graph.foreign.filter(f=>path.extname(f.path)===extension):[...new Set(required)].map(file=>({name:file,path:file}));
  return list(files.map(file=>{const source=fs.readFileSync(file.path,'utf8');
    if(!api?.kf_source)return term('Source',file.name,[term('Text',source)]);
    const parsed=api.kf_source(book,scope,file.name,source);if(parsed.error)throw Object.assign(Error(parsed.error),{phase:'compile'});
    return {$:'KTerm',tag:'Source',name:file.name,id:0,quant:0,kids:parsed.parts,removed:list([]),originBegin:0,originEnd:0};
  }));
}


export async function inspect(input,options={}) {
  return observation(await inspectWithMemo(input,options));
}

// An inspector owns its API and a single immutable decoded Base book. Public
// inspect/prepareBase callers cannot inject an API into this private state.
export async function createPersistentInspector() {
  const identity={canonicalPath:fs.realpathSync(apiPath),sha256:hash(apiPath)};
  const api=await loadApiForIdentity(identity);
  if(fs.realpathSync(apiPath)!==identity.canonicalPath||hash(apiPath)!==identity.sha256)
    throw Error('Compiler API changed while creating persistent inspector');
  const memo={entry:null,identity};
  return Object.freeze({async inspect(input,options={}) {
    if(!['parse','check'].includes(options.mode??'check'))throw Error('Persistent inspector supports only parse/check');
    return observation(await inspectWithMemo(input,{...options,api},memo));
  }});
}

function observation(result) {
  const validation=['load','parse','check'].includes(result.phase);
  const accepted=result.typeAccepted??(result.checked===true&&!(validation&&result.status!=='ok'));
  return {typeAccepted:accepted,proofTrust:'not-assessed',kernelChecked:false,...result,
    ...(validation&&result.status==='error'&&result.diagnostic&&!result.diagnostic.startsWith('SOME PROOFS FAIL\n')?{diagnostic:'SOME PROOFS FAIL\n'+result.diagnostic}:{})};
}

// Both checker stages carry the original result into the same rejection renderer.
function renderDiagnostic(api,detailed,diagnostic,loadTrace,graph) {
  if(detailed?.error!==diagnostic)return 'Error: '+diagnostic;
  try {
    if(api.f_load_origins_for&&api.diagnostic_result_locate) {
      const provenance=loadTrace&&api.f_loaded_origins_for?
        api.f_loaded_origins_for(loadTrace,detailed.diagnostic.definition):
        api.f_load_origins_for(graph.main,graph.sources,detailed.diagnostic.definition);
      if(!provenance.result.error){detailed=api.diagnostic_result_locate(detailed,provenance.origins);if(loadTrace&&api.diagnostic_render_loaded)return api.diagnostic_render_loaded(detailed,loadTrace);}
    }
    return api.diagnostic_render(detailed);
  } catch(error) {trace('diagnostic rendering unavailable: '+error.message);return 'Error: '+diagnostic;}
}

async function inspectWithMemo(input,{mode='check',api,args=[],timeoutMs=5000,combinedOutput=false,withReport=false,proofOnly=false}={},memo=null) {
  api??=await loadApi();
  let phase='load';
  try {
    trace('discover '+input);
    const info=api.f_load_graph_seed?baseCacheInfo(api):null;
    if(memo&&(fs.realpathSync(apiPath)!==memo.identity.canonicalPath||(info?.compilerSha256??hash(apiPath))!==memo.identity.sha256)) {
      memo.entry=null;
      throw Error('Compiler API changed during persistent inspection');
    }
    const seed=info?readBaseCache(info,memo):null;
    const graph=discoverSources(api,input,{seed});
    phase='parse';
    trace('load and elaborate graph');
    // Traces belong to this request and retain the exact parsed/source snapshots.
    const loadTrace=graph.loadTrace??(seed&&api.f_load_graph_seed_trace?api.f_load_graph_seed_trace(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book):
      !seed&&api.f_load_graph_trace?api.f_load_graph_trace(graph.main,graph.sources):null);
    const loaded=loadTrace?loadTrace.result:seed?api.f_load_graph_seed(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book):
      (api.f_load_graph||api.f_load)(graph.main,graph.sources);
    if(loaded.error) return {status:'error',phase,diagnostic:loaded.error.startsWith('Error:')?loaded.error:'Error: '+loaded.error,exitCode:1,checked:false};
    if(mode==='parse') return {status:'ok',phase,exitCode:0,checked:false,files:graph.files};
    phase='check';
    trace('check book');
    const cached=graph.hasBase&&api.check_from_exact_prefix?(seed||await prepareBase(api)):null;
    const checkAbi=typeof api.compiler_check_result_abi==='function'?api.compiler_check_result_abi():0;
    if(![0,1,2].includes(checkAbi))throw Error(`Unsupported compiler checker-result ABI: ${checkAbi}`);
    if(checkAbi===2&&typeof api.check_program_diagnostic!=='function')throw Error('Compiler checker-result ABI 2 requires check_program_diagnostic');
    const checkedResult=checkAbi===2?api.check_program_diagnostic(loaded.book,cached?cached.book:list([]),list([])):checkAbi===1?
      (cached?api.check_book_diagnostic_from_exact_prefix(loaded.book,cached.book,list([])):api.check_book_diagnostic(loaded.book,list([]))):null;
    const diagnostic=checkedResult?checkedResult.error:(cached?api.check_from_exact_prefix(loaded.book,cached.book):api.check_book(loaded.book));
    if(diagnostic) {
      let rendered='Error: '+diagnostic;
      if((checkedResult||api.check_book_diagnostic)&&api.diagnostic_render) {
        try {
          trace('render checker diagnostic');
          let detailed=checkedResult||(cached&&api.check_book_diagnostic_from_exact_prefix?
            api.check_book_diagnostic_from_exact_prefix(loaded.book,cached.book,list([])):
            api.check_book_diagnostic(loaded.book,list([])));
          if(!checkedResult&&cached&&detailed.error!==diagnostic&&api.check_book_diagnostic_from_exact_prefix)
            detailed=api.check_book_diagnostic(loaded.book,list([]));
          rendered=renderDiagnostic(api,detailed,diagnostic,loadTrace,graph);
        } catch(error) {trace('diagnostic replay unavailable: '+error.message);}
      }
      return {status:'error',phase,diagnostic:rendered,exitCode:1,checked:true};
    }
    let book=checkAbi===2?checkedResult.book:loaded.book;
    if(checkAbi!==2) {
      const todos=api.driver_todos(loaded.book);
      if(todos) return {status:'error',phase,diagnostic:`Error: ${todos} TODO${todos===1?'':'s'} found.\nThe code is incomplete, and not a valid proof yet.`,exitCode:1,checked:true};
      if(api.specialize_book) {
        trace('specialize book');
        const specialized=api.specialize_book(book),error=api.specialized_error(specialized);
        if(error) return {status:'error',phase,diagnostic:renderDiagnostic(api,api.specialized_diagnostic?.(specialized),error,loadTrace,graph),exitCode:1,checked:true};
        book=api.specialized_book(specialized);
      }
    }
    const needReport=mode==='check'||(mode==='interpreter'&&!api.driver_has_main(book))||withReport;
    if(needReport)trace('report declarations');
    const verdict=needReport&&api.driver_report?api.driver_report(loaded.book,list([])):'ALL PROOFS CHECK\nUse --verdict for mathematical validity.\n';
    const unsafeDefinitions=needReport&&api.driver_bad_names?array(api.driver_bad_names(loaded.book)):[];
    const trust={typeAccepted:true,proofTrust:needReport?(unsafeDefinitions.length?'failed':'passed'):'not-assessed',unsafeDefinitions,kernelChecked:false};
    if((proofOnly||!api.driver_has_main(book))&&['check','interpreter'].includes(mode)&&trust.proofTrust==='failed')
      return {status:'error',phase:'verdict',diagnostic:verdict,exitCode:1,checked:true,...trust};
    if(mode==='check') return {status:'ok',phase,stdout:verdict,exitCode:0,checked:true,files:graph.files,...trust};
    let interpreterIO=false;
    if(mode==='interpreter') {
      if(!api.driver_has_main(book)) return {status:'ok',phase:'runtime',stdout:verdict,exitCode:0,checked:true,...trust};
      interpreterIO=api.driver_is_io(book);
      if(!interpreterIO) {
        phase='runtime';
        trace('normalize and print main');
        return {status:'ok',phase,stdout:api.driver_interpret(loaded.book)+'\n',verdict,exitCode:0,checked:true};
      }
    }
    phase='compile';
    const emitOwned=api.driver_emit_owned?api.driver_emit_owned(book):'';
    if(emitOwned)return {status:'error',phase,diagnostic:'Error: '+emitOwned,exitCode:1,checked:true};
    if(mode!=='library'&&api.j_compile_error) {
      const error=api.j_compile_error(book);
      if(error)return {status:'error',phase,diagnostic:error.startsWith('Error:')?error:'Error: '+error,exitCode:1,checked:true};
    }
    const contextBook=mode!=='native'&&api.book_context?api.book_context(book):book;
    const roots=api.j_roots?.(contextBook,mode==='library');
    const stops=mode!=='native'?api.j_stops?.(contextBook):null;
    const selectedEmission=mode!=='native'&&api.reach_book&&api.annotate_selected&&api.j_program_selected&&api.j_library_selected;
    if(selectedEmission) {
      trace('prune reachable definitions');
      book=api.reach_book(contextBook,roots,stops);
    }
    if(mode!=='native'&&api.j_foreign_error) {
      const error=api.j_foreign_error(book);
      if(error)return {status:'error',phase,diagnostic:error.startsWith('Error:')?error:'Error: '+error,exitCode:1,checked:true};
    }
    trace('annotate book');
    let layoutDefs,layoutStops;
    if(mode==='native'&&api.nc_annotation_stops&&api.nc_annotated_context&&api.reach_book&&api.annotate_selected) {
      const stops=api.nc_annotation_stops(contextBook);
      const selected=api.reach_book(contextBook,list(['main']),stops);
      layoutDefs=api.annotate_selected(contextBook,selected,stops);layoutStops=stops;
      book=api.nc_annotated_context(contextBook,layoutDefs);
    } else book=selectedEmission?api.annotate_selected(contextBook,book,api.j_stops(contextBook)):api.annotate_book(book);
    if(api.j_layout_error) {
      trace('validate runtime layouts');
      const error=api.j_layout_error(contextBook,layoutDefs||book,roots,layoutStops||stops);
      if(error)return {status:'error',phase,diagnostic:'Error: '+error,exitCode:1,checked:true};
    }
    if(mode==='native') {
      if(!api.nc_compile)return {status:'unsupported',phase,reason:'Native emitter was not bootstrapped.',checked:true};
      trace('collect native foreign paths');
      const paths=api.nc_foreign_paths?array(api.nc_foreign_paths(book)):graph.foreign.filter(f=>path.extname(f.path)==='.c').map(f=>f.path);
      const foreignScope=api.nc_foreign_scope?api.nc_foreign_scope(book):book;
      const nativeInputs=[...graph.files,path.join(project,'src/runtime/native/runtime.c')];
      const requests=[...new Set(paths)].map(file=>{
        let resolved=path.resolve(file);
        if(path.dirname(resolved)===path.join(path.dirname(basePath),'effs'))resolved=path.join(project,'src/runtime/native/effs',path.basename(resolved));
        nativeInputs.push(resolved);
        const source=fs.readFileSync(resolved,'utf8');
        const parsed=api.kf_source?api.kf_source(book,foreignScope,file,source):null;
        if(parsed?.error)throw Object.assign(Error(parsed.error),{phase:'compile'});
        trace('marshal native foreign source '+file);
        return api.nc_foreign_source?api.nc_foreign_source(book,foreignScope,file,source,parsed):source;
      }).join('\n');
      trace('emit native');
      const native=api.nc_compile(book,fs.readFileSync(path.join(project,'src/runtime/native/runtime.c'),'utf8'),requests);
      if(native.error)return {status:'error',phase,diagnostic:'Error: '+native.error,exitCode:1,checked:true};
      return {status:'ok',phase,code:native.source,verdict,exitCode:0,checked:true,files:nativeInputs};
    }
    trace('emit '+mode);
    const jsPaths=api.j_foreign_paths?array(api.j_foreign_paths(book)):null;
    const emitted=selectedEmission?(mode==='library'?api.j_library_selected(contextBook,book):api.j_program_selected(contextBook,book)):(mode==='library'?api.j_library(book):api.j_program(book));
    const code=fs.readFileSync(runtimePath,'utf8')+'\n'+api.j_modules(book,foreignSources(graph,'.js',jsPaths,api,contextBook,book))+'\n'+emitted;
    trace('emitted '+Buffer.byteLength(code)+' bytes');
    if(interpreterIO)return {...await executeCompiled({status:'ok',code},{timeoutMs,args:['--',...args],combinedOutput,programName:path.basename(input,'.bend')}),verdict};
    return {status:'ok',phase,code,verdict,exitCode:0,checked:true,files:[...graph.files,...jsPaths||[]]};
  } catch(error) {
    trace('compiler exception: '+(error.stack||error.message));
    return {status:'error',phase:error.phase||phase,diagnostic:typeof error.message==='string'&&error.message.startsWith('Error:')?error.message:'Error: '+error.message,exitCode:1,checked:phase==='check'||phase==='compile'||phase==='runtime',sourceFile:error.sourceFile};
  }
}

export async function execute(input,{workdir,timeoutMs=5000,args=[],api,backend='js',combinedOutput=false,withReport=false}={}) {
  const compiled=await inspect(input,{mode:backend==='js'?'compile':'native',api,withReport});
  if(compiled.status!=='ok') return compiled;
  return {...await executeCompiled(compiled,{workdir,timeoutMs,args,backend,combinedOutput,programName:path.basename(input,'.bend')}),typeAccepted:true,proofTrust:compiled.proofTrust,kernelChecked:false,verdict:compiled.verdict};
}

async function executeCompiled(compiled,{workdir,timeoutMs=5000,args=[],backend='js',combinedOutput=false,programName='program'}={}) {
  const own=!workdir;
  workdir??=fs.mkdtempSync(path.join(os.tmpdir(),'bend-typed-run-'));
  try {
    const file=path.join(workdir,programName+(backend==='js'?'.mjs':'.c'));fs.writeFileSync(file,compiled.code);
    const runtimeNodeArgs=backend==='js'?nodeResourceArgs():[];
    let command=process.execPath,commandArgs=[...runtimeNodeArgs,file,...args];
    let built=null;
    if(backend!=='js') {
      const binary=path.join(workdir,programName);
      built=buildNative({source:compiled.code,file,binary,target:backend==='native'?'auto':backend,cwd:workdir,timeoutMs});
      if(built.status!=='ok')return built;
      command=binary;commandArgs=[...(backend==='metal'||backend==='cuda'?['--gpu','on']:[]),...args];
    }
    const outputFile=path.join(workdir,'runtime-output.log');
    const fd=combinedOutput?fs.openSync(outputFile,'w'):null;
    let child,output;
    try {
      child=spawnSync(command,commandArgs,{cwd:workdir,encoding:'utf8',timeout:timeoutMs,maxBuffer:2**20,
        ...(fd===null?{}:{stdio:['ignore',fd,fd]})});
    } finally {if(fd!==null)fs.closeSync(fd);}
    if(combinedOutput) {
      if(fs.statSync(outputFile).size>2**20)return {status:'crash',phase:'runtime',reason:'Execution exceeded output limit.',checked:true};
      output=fs.readFileSync(outputFile,'utf8');
    }
    if(child.error?.code==='ETIMEDOUT') return {status:'timeout',phase:'runtime',reason:'Execution exceeded timeout.',checked:true};
    return {status:child.status===0?'ok':'error',phase:'runtime',stdout:combinedOutput?output:(child.stdout||''),stderr:combinedOutput?'':(child.stderr||''),exitCode:child.status??1,signal:child.signal,checked:true,...(combinedOutput?{output}:{}),
      ...(built?{nativeBuild:{target:built.target,compiler:built.compiler,bangs:built.bangs}}:{runtimeNodeArgs}),
      ...((backend==='metal'||backend==='cuda')?{hardwareExecuted:child.status===0&&built?.bangs>0,target:built?.target}:{})};
  } finally {if(own)fs.rmSync(workdir,{recursive:true,force:true});}
}

export async function main(args) {
  if(args[0]==='--bootstrap') {const report=bootstrap();console.log('Bootstrapped checked Bend API: '+report.apiSha256);return;}
  if(args[0]==='--prepare-base') {const result=await prepareBase();console.log('Base checked by generated Bend API: '+result.baseSha256);return;}
  if(args.length===1&&['version','--version'].includes(args[0])) {console.log('Bend2 port targeting '+compilerTarget.targetVersion);return;}
  const optionArgs=args.slice(0,args.includes('--')?args.indexOf('--'):args.length);
  if(!args.length||optionArgs.includes('--help')||optionArgs.includes('-h')) {console.log('node cli.mjs FILE.bend [ARGS] [--check-only | --checkup | --interpret | --run | --library]\n  [-o OUTPUT]... [--native | --cpu | --metal | --cuda]\nDefault: check, then interpret main; .js/.mjs output emits JavaScript, .c emits C, other output builds a binary.\nnode tools/typed-driver.mjs --bootstrap');if(!args.length)process.exitCode=1;return;}
  let input,mode='interpreter',programArgs=[],library=false,backend='js',checkup=false,only=false;
  const outputs=[];
  while(args.length) {
    const arg=args.shift();
    if(arg==='--check-only') {mode='check';only=true;}
    else if(arg==='--checkup')checkup=true;
    else if(arg==='--verdict')throw Error('--verdict requires the independent BendTT kernel; this self-hosted compiler does not implement kernel validation');
    else if(arg==='--interpret') mode='interpreter';
    else if(arg==='--run') mode='run';
    else if(arg==='--library') {mode='library';library=true;}
    else if(['--native','--cpu','--metal','--cuda'].includes(arg))backend=arg.slice(2);
    else if(arg==='-o'&&args.length)outputs.push(path.resolve(args.shift()));
    else if(arg==='--') {programArgs=args;break;}
    else if(arg.startsWith('-'))throw Error('Unknown/incomplete option '+arg);
    else if(!input)input=path.resolve(arg);
    else programArgs.push(arg);
  }
  if(!input)throw Error('A Bend source file is required');
  if(only&&(outputs.length||checkup||library||mode!=='check'))throw Error('--check-only takes no other option');
  if(checkup&&(outputs.length||library))throw Error('--checkup takes no -o or --library');
  if(programArgs.length&&(outputs.length||mode==='check'||checkup||library))throw Error('Arguments go to a run');
  if(backend!=='js'&&library)throw Error('--library currently supports JavaScript only');
  if(checkup) {
    const api=await loadApi(),parsed=api.f_parse(fs.readFileSync(input,'utf8'));
    if(parsed.error)throw Error(parsed.error);
    let failed=false;
    for(const item of array(parsed.imports)) {
      if(item.name==='Base')continue;
      process.stdout.write('--- '+item.name+' ---\n');
      const result=await inspect(path.resolve(path.dirname(input),item.name),{mode:'interpreter',api,timeoutMs:120000});
      printResult(result);
      const code=result.exitCode??(result.status==='ok'?0:1);
      if(code){process.stdout.write('exit '+code+'\n');failed=true;}
    }
    process.exitCode=failed?1:0;return;
  }
  if(outputs.length) {
    const compiled=new Map();
    for(const output of outputs) {
      const extension=path.extname(output),binary=!library&&!['.js','.mjs','.c'].includes(extension);
      const emission=library?'library':backend!=='js'||extension==='.c'||binary?'native':'compile';
      let result=compiled.get(emission);
      if(!result){result=await inspect(input,{mode:emission,timeoutMs:120000,withReport:true});compiled.set(emission,result);}
      if(result.status!=='ok'){printResult(result);process.exitCode=result.exitCode??1;return;}
      const target=fs.existsSync(output)?fs.realpathSync(output):output;
      if(fs.existsSync(output)&&fs.statSync(output).isDirectory())throw Error('Output is a directory');
      if([input,...(result.files||[]),apiPath,basePath,runtimePath].some(f=>(fs.existsSync(f)?fs.realpathSync(f):path.resolve(f))===target))throw Error('Output would overwrite a compiler or program input');
      const temporary=output+'.tmp-'+process.pid;
      try {
        if(binary) {
          const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-build-'));
          try {
            const file=path.join(directory,'program.c');fs.writeFileSync(file,result.code);
            const built=buildNative({source:result.code,file,binary:temporary,target:backend==='js'||backend==='native'?'auto':backend,timeoutMs:120000});
            if(built.status!=='ok'){printResult(built);process.exitCode=1;return;}
          } finally {fs.rmSync(directory,{recursive:true,force:true});}
        } else fs.writeFileSync(temporary,result.code);
        fs.renameSync(temporary,output);
      } finally {fs.rmSync(temporary,{force:true});}
    }
    process.exitCode=0;return;
  }
  if(library)mode='library';
  const result=mode==='run'?await execute(input,{args:programArgs,timeoutMs:120000,backend,withReport:true}):await inspect(input,{mode,args:programArgs,timeoutMs:120000,withReport:true,proofOnly:only});
  if(result.status==='ok'&&mode==='library')process.stdout.write(result.code);
  else printResult(result);
  process.exitCode=result.exitCode??(result.status==='ok'?0:1);
}
function printResult(result){
  if(result.stdout)process.stdout.write(result.stdout);
  if(result.stderr)process.stderr.write(result.stderr);
  if(result.diagnostic||result.reason)process.stderr.write((result.diagnostic||result.reason)+'\n');
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) main(process.argv.slice(2)).catch(error=>{console.error(error.message);process.exitCode=1;});
