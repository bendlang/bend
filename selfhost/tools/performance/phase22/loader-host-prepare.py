"""Apply the agreed ABI2 host-only delta to the private Phase21 copy."""
from pathlib import Path
import difflib,hashlib,json
r=Path(__file__).resolve().parents[4]
out=r/'selfhost/build/phase22/loader-host-source-01';project=out/'project'
parent=r/'selfhost/build/phase21/group-range-build-02/attempt.json';m=json.loads(parent.read_text())
file=project/'tools/typed-driver.mjs';before=file.read_text();s=before
edits=[]
def replace(a,b):
 global s
 assert s.count(a)==1,a
 s=s.replace(a,b);edits.append({'before':a,'after':b})
replace("const roots=['f_parse','f_load','f_path_join'", "const roots=['f_path_join'")
replace("exports.push('f_source_parsed','f_source_located')", "exports.push('f_source_completed','f_source_located')")
replace("  if(fs.readFileSync(path.join(project,'src/front/declarations.bend'),'utf8').includes('def f_parse_indexed('))exports.push('f_parse_indexed');\n", '')
replace("export async function loadApi() {", """const loaderEntries=['f_source_header','f_complete_source','f_complete_seed','f_import_namespace_at','f_graph_trace','f_load_graph','f_source_located','f_source_completed'];
function requireLoaderApi(api) {
  const version=typeof api.compiler_load_abi==='function'?api.compiler_load_abi():undefined;
  if(version!==2)throw Error('Unsupported compiler load ABI: '+String(version));
  for(const name of loaderEntries)if(typeof api[name]!=='function')throw Error('Missing contextual compiler source API: '+name);
}

export async function loadApi() {""")
replace("  const loadAbi=module.default.compiler_load_abi?.();\n  if(module.default.compiler_load_abi!==undefined&&loadAbi!==1)throw Error('Unknown compiler load ABI: '+loadAbi);", "  requireLoaderApi(module.default);")
replace("FParsedSource:['name','path','text','parsed']", "FCompletedSource:['name','path','text','parsed']")
replace("  const loadAbi=api.compiler_load_abi?.(),contextual=loadAbi===1;\n  if(api.compiler_load_abi!==undefined&&!contextual)throw Error('Unknown compiler load ABI: '+loadAbi);\n  if(contextual)for(const name of ['f_source_header','f_complete_source','f_complete_seed','f_import_namespace_at','f_graph_trace'])\n    if(typeof api[name]!=='function')throw Error('Missing contextual compiler source API: '+name);", "  requireLoaderApi(api);")
replace("  if(located&&(!api.f_parse_indexed||!api.f_source_located))throw Error('Missing indexed compiler source API');\n", '')
replace("  const graphMode=typeof api.f_load_graph==='function';\n", '')
replace("    let parsed=prior?.parsed||(seeded?{book:list([]),imports:list([]),error:''}:contextual?null:located?api.f_parse_indexed(range.begin,source):api.f_parse(source));", "    let parsed=prior?.parsed??(seeded?{book:list([]),imports:list([]),error:''}:null);")
replace("    const retain=()=>{if(parsed&&api.f_source_parsed&&!seeded)sources[slot]=wrap(api.f_source_parsed(name,absolute,source,parsed),range);};", "    const retain=()=>{if(parsed&&!seeded)sources[slot]=wrap(api.f_source_completed(name,absolute,source,parsed),range);};")
replace("    const header=contextual&&!seeded?api.f_source_header(raw):null;", "    const header=!seeded?api.f_source_header(raw):null;")
replace("    if(located&&!contextual&&!seeded&&!parsed.error)validateSpanBook(parsed.book,[range],api.compiler_term_abi?.()??0);\n", '')
replace("visit(graphMode&&imported!=='Base'?importedFile:imported,importedFile", "visit(imported!=='Base'?importedFile:imported,importedFile")
replace("    if(contextual) {\n      const supplied=list(sources),ns=edge?", "    {\n      const supplied=list(sources),ns=edge?")
replace("    const error=contextual?completed.error:parsed.error;", "    const error=completed.error;")
replace("  const main=graphMode?path.resolve(input):'__main__';", "  const main=path.resolve(input);")
replace("    ...(contextual?{loadTrace:api.f_graph_trace(completed,supplied)}:{})};", "    loadTrace:api.f_graph_trace(completed,supplied)};")
replace("  api??=await loadApi();\n  const info=baseCacheInfo(api),prior=readBaseCache(info);", "  api??=await loadApi();\n  requireLoaderApi(api);\n  const info=baseCacheInfo(api),prior=readBaseCache(info);")
replace("  const loaded=(api.f_load_graph||api.f_load)('Base',list([source]));", "  const loaded=api.f_load_graph('Base',list([source]));")
replace("    const info=api.f_load_graph_seed?baseCacheInfo(api):null;", "    requireLoaderApi(api);\n    const info=baseCacheInfo(api);")
replace("    const loadTrace=graph.loadTrace??(seed&&api.f_load_graph_seed_trace?api.f_load_graph_seed_trace(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book):\n      !seed&&api.f_load_graph_trace?api.f_load_graph_trace(graph.main,graph.sources):null);\n    const loaded=loadTrace?loadTrace.result:seed?api.f_load_graph_seed(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book):\n      (api.f_load_graph||api.f_load)(graph.main,graph.sources);", "    const loadTrace=graph.loadTrace,loaded=loadTrace.result;")
replace("    const api=await loadApi(),parsed=api.f_parse(fs.readFileSync(input,'utf8'));\n    if(parsed.error)throw Error(parsed.error);\n    let failed=false;\n    for(const item of array(parsed.imports)) {\n      if(item.name==='Base')continue;\n      process.stdout.write('--- '+item.name+' ---\\n');\n      const result=await inspect(path.resolve(path.dirname(input),item.name),{mode:'interpreter',api,timeoutMs:120000});", """    const api=await loadApi();
    await prepareBase(api);
    let failed=false;
    for(const line of fs.readFileSync(input,'utf8').split('\\n')) {
      const match=/^import\\s+(\\S+)\\s+as\\s+[A-Za-z_][A-Za-z0-9_]*\\s*$/.exec(line.trim());
      if(!match)continue;
      const name=match[1];
      process.stdout.write('--- '+name+' ---\\n');
      const result=await inspect(path.resolve(path.dirname(input),name),{mode:'interpreter',api,timeoutMs:120000});""")
assert 'api.f_parse' not in s and 'api.f_load)' not in s and 'FParsedSource' not in s
file.write_text(s)
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
members=[];changes=[]
for row in m['snapshot']['sources']:
 p=Path(row['frozen']['file']);relative=p.relative_to(m['snapshot']['root']);q=project/relative
 assert ident(p)['sha256']==row['frozen']['sha256'];current=ident(q);members.append({'relative':str(relative),'before':row['frozen'],'after':current})
 if current['sha256']!=row['frozen']['sha256']:changes.append(str(relative))
assert changes==['tools/typed-driver.mjs'] and len(members)==214
patch=out/'host.patch';patch.write_text(''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='a/tools/typed-driver.mjs',tofile='b/tools/typed-driver.mjs')))
manifest={'kind':'phase22-loader-abi2-host-preparation','complete':True,'installed':False,'compilerBuilt':False,'parent':ident(parent),'plan':ident(r/'design/phase22/loader-host-abi2.md'),'tool':ident(Path(__file__)),'members':members,'changes':changes,'patch':ident(patch),'edits':edits,'delta':{'physicalLines':len(s.splitlines())-len(before.splitlines()),'bytes':len(s.encode())-len(before.encode())},'contract':{'loaderAbi':2,'completedFactory':'f_source_completed(name,path,text,parsed)','completedTag':'FCompletedSource','completedFields':['name','path','text','parsed'],'oldLoaderVersionsRejected':True}}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps({'changes':changes,'delta':manifest['delta']}))
