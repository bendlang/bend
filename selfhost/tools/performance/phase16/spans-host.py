#!/usr/bin/env python3
from pathlib import Path
P=Path(__file__).resolve().parents[4]/'selfhost/build/phase16/spans-origin-source-01/project'
p=P/'tools/typed-driver.mjs';s=p.read_text()
s=s.replace("if(files.includes('src/load/modules.bend'))exports.push('f_source_parsed');", "if(files.includes('src/load/modules.bend'))exports.push('f_source_parsed','f_source_located');\n  if(fs.readFileSync(path.join(project,'src/front/parser.bend'),'utf8').includes('def f_parse_indexed('))exports.push('f_parse_indexed');")
s=s.replace("FParsedSource:['name','path','text','parsed'],FResult", "FParsedSource:['name','path','text','parsed'],FLocatedSource:['source','begin','end'],FResult")
s=s.replace("DOrigin:['definition','term','source','begin','end','path'],", "DSourceOrigin:['source','begin','end'],")
a=s.index('export function discoverSources(')
s=s[:a]+'''// Source coordinates belong to one request. Base always owns interval one, so
// a checked Base cache cannot silently introduce stale or overlapping positions.
const SPAN_ABI=3,SPAN_CACHE=4,U32_MAX=0xffffffff;
function interval(begin,text) {
  const end=begin+text.length+1;
  if(!Number.isSafeInteger(begin)||begin<1||!Number.isSafeInteger(end)||end>U32_MAX)throw Error('Source interval overflow');
  return {begin,end};
}
export function validateSpanBook(book,ranges) {
  const pending=[book],seen=new WeakSet();
  while(pending.length) {
    const value=pending.pop();
    if(value===null||typeof value!=='object'||seen.has(value))continue;
    seen.add(value);
    if(value.$==='KTerm') {
      const a=value.originBegin,b=value.originEnd;
      if(!Number.isSafeInteger(a)||!Number.isSafeInteger(b)||a<0||b<0||a>U32_MAX||b>U32_MAX||
        !((a===0&&b===0)||(a>0&&b>=a&&ranges.some(r=>a>=r.begin&&b<r.end))))
        throw Error('Invalid compiler source range');
    }
    for(const child of Object.values(value))if(child!==null&&typeof child==='object')pending.push(child);
  }
  return true;
}
export function validateSpanCache(c,{compilerSha256,baseSha256,sourcePath,sourceText}) {
  const range=interval(1,sourceText);
  if(c.version!==SPAN_CACHE||c.spanAbi!==SPAN_ABI||c.compilerSha256!==compilerSha256||c.baseSha256!==baseSha256||
    c.sourcePath!==sourcePath||c.sourceBegin!==range.begin||c.sourceEnd!==range.end||c.validatedBy!=='check_book'||
    c.bookSha256!==crypto.createHash('sha256').update(JSON.stringify(c.book)).digest('hex'))throw Error('Invalid source-aware Base cache');
  validateSpanBook(c.book,[range]);return true;
}

'''+s[a:]
s=s.replace("  const sources=[],seen=new Map(),physical=new Map(),foreign=new Map(),active=new Set();", "  const sources=[],seen=new Map(),physical=new Map(),foreign=new Map(),active=new Set();\n  const located=api.compiler_span_abi?.()===SPAN_ABI;\n  if(located&&(!api.f_parse_indexed||!api.f_source_located))throw Error('Missing indexed compiler source API');\n  const baseCanonical=located?fs.realpathSync(basePath):null;\n  const baseText=located?fs.readFileSync(baseCanonical,'utf8'):null;\n  const baseRange=located?interval(1,baseText):null;\n  let next=baseRange?.end??0;")
s=s.replace("    const parsed=prior||(seeded?{book:list([]),imports:list([]),error:''}:api.f_parse(source));\n    sources.push(api.f_source_parsed&&!seeded?api.f_source_parsed(name,absolute,source,parsed):{$:'FSource',name,path:absolute,text:source});\n    if(prior)return;\n    physical.set(absolute,parsed);", """    if(prior&&prior.source!==source)throw Object.assign(Error('Source alias bytes changed'),{phase:'load'});
    if(located&&absolute===baseCanonical&&source!==baseText)throw Object.assign(Error('Base source bytes changed'),{phase:'load'});
    const range=located?(prior?.range??(absolute===baseCanonical?baseRange:interval(next,source))):null;
    if(located&&!prior&&absolute!==baseCanonical)next=range.end;
    if(seeded&&located&&(seed.spanAbi!==SPAN_ABI||seed.sourceBegin!==range.begin||seed.sourceEnd!==range.end))throw Error('Stale Base source interval');
    const parsed=prior?.parsed||(seeded?{book:list([]),imports:list([]),error:''}:located?api.f_parse_indexed(range.begin,source):api.f_parse(source));
    if(located&&!prior&&!seeded)validateSpanBook(parsed.book,[range]);
    const input=api.f_source_parsed&&!seeded?api.f_source_parsed(name,absolute,source,parsed):{$:'FSource',name,path:absolute,text:source};
    sources.push(located?api.f_source_located(input,range.begin,range.end):input);
    if(prior)return;
    physical.set(absolute,{parsed,source,range});""")
s=s.replace("  const version=api.f_load_graph_seed?2:1;", "  const version=api.compiler_span_abi?.()===SPAN_ABI?SPAN_CACHE:api.f_load_graph_seed?2:1;")
s=s.replace("${version===2?'-'+location:''}", "${version>=2?'-'+location:''}")
s=s.replace("    if(info.version===2&&(cached.sourcePath!==info.sourcePath||cached.bookSha256!==crypto.createHash('sha256').update(JSON.stringify(cached.book)).digest('hex')))return null;", "    if(info.version===2&&(cached.sourcePath!==info.sourcePath||cached.bookSha256!==crypto.createHash('sha256').update(JSON.stringify(cached.book)).digest('hex')))return null;\n    if(info.version===SPAN_CACHE)validateSpanCache(cached,info);")
s=s.replace("  const source={$:'FSource',name:'Base',path:info.sourcePath,text:info.sourceText};", "  const raw={$:'FSource',name:'Base',path:info.sourcePath,text:info.sourceText};\n  const range=info.version===SPAN_CACHE?interval(1,info.sourceText):null;\n  const source=range?api.f_source_located(raw,range.begin,range.end):raw;")
s=s.replace("bookSha256:crypto.createHash('sha256').update(JSON.stringify(loaded.book)).digest('hex'),book:loaded.book};", "bookSha256:crypto.createHash('sha256').update(JSON.stringify(loaded.book)).digest('hex'),book:loaded.book,\n    ...(range?{spanAbi:SPAN_ABI,sourceBegin:range.begin,sourceEnd:range.end}:{})};\n  if(range)validateSpanCache(cached,info);")
p.write_text(s)
p=P/'tools/development/workflow.mjs';s=p.read_text();s=s.replace("import {supervise,requireExecution} from './process.mjs';", "import {supervise,requireExecution} from './process.mjs';\nimport {validateSpanCache} from '../typed-driver.mjs';")
s=s.replace("  if(c.version!==2||c.compilerSha256", "  if(c.version===4)validateSpanCache(c,{compilerSha256:apiSha,baseSha256:baseSha,sourcePath:canonical,sourceText:fs.readFileSync(base,'utf8')});\n  else if(c.version!==2||c.compilerSha256")
p.write_text(s)
print(P)
