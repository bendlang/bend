// Explicit checked-B1 derivative. This does not create bootstrap provenance.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';

const own=fileURLToPath(import.meta.url);
const pin='6018e28ecc67cf1fffc0c20c64b11023474c2df8';
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const read=file=>fs.readFileSync(file,'utf8');
const requireThat=(condition,message)=>{if(!condition)throw Error(message);};
const id=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const unchanged=x=>{const y=id(x.file);requireThat(y.canonicalPath===x.canonicalPath&&y.sha256===x.sha256,'Changed input: '+x.file);return y;};
const json=file=>JSON.parse(read(file));
const write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const prefixEnd='// Program\n// =======\n';
const runtimeHash='9e9845e7b08637bb46fe6ed041f641e1e9100390fbdde39701baeb021443436a';
const bodyHashes=Object.freeze({
  '$String$eq$':'07805c1bcb339824102228490203c45ebce00a7694fe5ad31ed55de02d1e4393',
  '$String$eq$fin$':'834e47b9a128487a5d38eed2b083d86629ac0ea752c5427b571f32e99b3346f5',
  '$Cmp$is_eq$':'a6c5e5a1b8fa6d808d55d58087b6a9fc2cb50ae538798959c3342b2df27242f1',
  '$String$cmp$':'e28b438f3e84976a6f506c3cbda751584e22aaa4f5950695fe675fbe9ed3b1f5',
  '$Char$cmp$':'6e2893dea9811fd8e454d6933643da92e0b6942c7ed0e42f8081166e73e136e2',
  '$String$cmp$fin$':'c05bc209c85180c26502e781988ee430b26ed189dfc1e06c615a2037d94d7a1b',
  '$String$cmp$rec$':'4fb95b7bcb33f714c98606d0ea9edd30fefe4334aec945249780df814bd7f5e0',
  run_loop:'b1f937dcb68edc1033b01d5a6055938ec2e34103bacd41b68c36f2ea66bd1c8f',
  run_jump:'477ef30b052ee03598cc5ef38fd672698836e956f0cf350393bab6e05e37adcd',
  char_new:'7a9fbfa94b70aae2289d3de7c044ae5ac902151b5a4648d9f5f60444d2573081',
  cmp_new:'8fac78c9271fde4683b81923d57f2f58107f0ed4e8cf69efb8294c381d575e2c'
});
const upstreamHashes=Object.freeze({
  'bend.ts':'461e0c5dd12789ea293daf01c1cb5b8504f8dfcf8d38b85744665a77ecc63168',
  'comp.ts':'1cf3b5ffea86697656f8ef4d6c26040f16ac512fd92485d164f8a14425871bd0',
  'base.bend':'b8c2734d45ec6b4ce70fee70ff06ef35e08fce885af8852d8eb77dbff020e946'
});
const recipeHashes=Object.freeze({
  'stage0-library.mjs':'89b07ed768b06691c5dc9e4bbdd4af96205355d0145793dfbd307924494cd8f0',
  'assemble.mjs':'f7c8feff7a0b8f8b4a302c2ca8b99b363a8d7c4c9c48bc6b7a9463aa23c58b75'
});
const guard='  if (typeof a_0 === "string" && typeof b_0 === "string" && a_0.isWellFormed() && b_0.isWellFormed()) return a_0 === b_0;\n';

// The pinned emitter produces no comments/regex/templates in program functions.
// Runtime regex literals are outside this scanner and covered by a whole-prefix hash.
function tokens(source,start) {
  const out=[];
  for(let i=start;i<source.length;) {
    if(/\s/.test(source[i])){i++;continue;}
    const at=i,c=source[i];
    if(c==='"'||c==="'") {
      let closed=false;
      for(i++;i<source.length;i++) {
        if(source[i]==='\\'){i++;continue;}
        requireThat(source[i]!=='\n'&&source[i]!=='\r','Unsupported multiline string');
        if(source[i]===c){i++;closed=true;break;}
      }
      requireThat(closed,'Unclosed string');
    } else if(/[A-Za-z_$]/.test(c)) {while(i<source.length&&/[\w$]/.test(source[i]))i++;}
    else {requireThat(c!=='`'&&!source.startsWith('//',i)&&!source.startsWith('/*',i),'Unsupported generated syntax');i++;}
    out.push({text:source.slice(at,i),start:at,end:i});
  }
  const stack=[];
  for(let i=0;i<out.length;i++) {
    const t=out[i].text;
    if(['(','[','{'].includes(t))stack.push(i);
    else if([')',']','}'].includes(t)) {
      const k=stack.pop();requireThat(k!==undefined&&'([{'.indexOf(out[k].text)===')]}'.indexOf(t),'Unbalanced generated module');out[k].close=i;
    }
  }
  requireThat(!stack.length,'Unbalanced generated module');return out;
}

export function transformEquality(source) {
  const start=source.indexOf(prefixEnd)+prefixEnd.length;
  requireThat(start>=prefixEnd.length&&sha(source.slice(0,start))===runtimeHash,'Unsupported generated runtime');
  const ts=tokens(source,start),functions=new Map();let i=0;
  while(ts[i]?.text==='function') {
    const first=i,name=ts[i+1]?.text;
    requireThat(/^\$[\w$]+\$$/.test(name??'')&&!functions.has(name),'Unsupported or duplicate top-level function: '+name);
    requireThat(ts[i+2]?.text==='('&&ts[i+2].close!==undefined,'Unsupported function parameters');
    const body=ts[i+2].close+1;requireThat(ts[body]?.text==='{'&&ts[body].close!==undefined,'Unsupported function body');
    const end=ts[body].close;functions.set(name,{start:ts[first].start,end:ts[end].end,source:source.slice(ts[first].start,ts[end].end)});i=end+1;
  }
  requireThat(ts[i]?.text==='export'&&ts[i+1]?.text==='default'&&ts[i+2]?.text==='{','Unsupported module exports');
  const exportsEnd=ts[i+2].close;requireThat(exportsEnd===ts.length-2&&ts[exportsEnd+1]?.text===';','Unexpected top-level code');
  const exports=[];
  for(let j=i+3;j<exportsEnd;) {
    const name=ts[j],fn=ts[j+4],arity=ts[j+6];
    requireThat(name?.text.startsWith('"')&&ts[j+1]?.text===':'&&ts[j+2]?.text==='run_lib'&&ts[j+3]?.text==='('&&functions.has(fn?.text)&&ts[j+5]?.text===','&&/^\d$/.test(arity?.text??'')&&ts[j+7]?.text===')'&&ts[j+8]?.text===',','Unsupported export binding');
    exports.push(JSON.parse(name.text));j+=9;
  }
  requireThat(new Set(exports).size===exports.length&&exports.length>0,'Duplicate or empty export roots');
  const protectedNames=new Set(Object.keys(bodyHashes));
  for(let j=0;j<ts.length;j++) {
    let parameters;
    if(ts[j].text==='function')parameters=ts[j+1]?.text==='('?j+1:j+2;
    else if(ts[j].text==='('&&ts[ts[j].close+1]?.text==='='&&ts[ts[j].close+2]?.text==='>')parameters=j;
    if(parameters!==undefined) {
      requireThat(ts[parameters]?.text==='('&&ts[parameters].close!==undefined,'Unsupported function binding');
      requireThat(!ts.slice(parameters+1,ts[parameters].close).some(t=>protectedNames.has(t.text)),'Shadowed equality parameter');
    }
    if(protectedNames.has(ts[j].text)&&ts[j+1]?.text==='='&&ts[j+2]?.text==='>')throw Error('Shadowed equality parameter');
  }
  for(let j=0;j<ts.length;j++)if(protectedNames.has(ts[j].text)) {
    const prev=ts[j-1]?.text,next=ts[j+1]?.text;
    requireThat(!['const','let','var'].includes(prev)&&next!=='='&&!(['+','-','*','/','&','|','^','?'].includes(next)&&['=',next].includes(ts[j+2]?.text)),'Rebound equality dependency');
    if(prev==='function')requireThat(functions.get(ts[j].text)?.start===ts[j-1].start,'Nested equality binding');
  }
  for(const [name,expected]of Object.entries(bodyHashes)) {
    const body=functions.get(name)?.source??source.slice(0,start).match(new RegExp('^function '+name+'\\([^\\n]*\\) \\{\\n[\\s\\S]*?^\\}','m'))?.[0];
    requireThat(body&&sha(body)===expected,'Unsupported equality dependency: '+name);
  }
  const target=functions.get('$String$eq$');
  const replacement=target.source.replace('{\n','{\n'+guard);
  return {source:source.slice(0,target.start)+replacement+source.slice(target.end),stats:{version:1,replacements:1,runtimeHash,bodyHashes,exports,functions:functions.size}};
}

function verifyBootstrap(apiFile,reportFile) {
  const api=id(apiFile),reportIdentity=id(reportFile),r=json(reportFile),p=r.provenance;
  requireThat(r.stage==='upstream-bootstrap'&&r.revision===pin&&r.apiSha256===api.sha256&&fs.realpathSync(r.apiPath)===api.canonicalPath,'Not a matching genuine upstream bootstrap');
  requireThat(p?.version===1&&p.verifiedAfterBuild===true&&p.upstream?.revision===pin&&p.upstream.trackedSourcesClean===true,'Incomplete bootstrap provenance');
  requireThat(fs.realpathSync(p.upstream.file)===p.upstream.canonicalPath,'Changed upstream canonical path');
  requireThat(Array.isArray(p.inputs)&&p.inputs.length>0,'Missing bootstrap inputs');
  const inputs=p.inputs.map(unchanged);
  for(const [name,expected]of Object.entries(upstreamHashes)) {
    const matches=p.inputs.filter(x=>x.role==='upstream'&&path.basename(x.file)===name);
    requireThat(matches.length===1&&matches[0].sha256===expected,'Unreviewed pinned upstream '+name);
  }
  for(const [name,expected]of Object.entries(recipeHashes)) {
    const matches=p.inputs.filter(x=>x.role==='host-tool'&&path.basename(x.file)===name);
    requireThat(matches.length===1&&matches[0].sha256===expected,'Unreviewed bootstrap recipe '+name);
  }
  requireThat(r.baseSha256===upstreamHashes['base.bend']&&sha(fs.readFileSync(r.source))===r.sourceSha256,'Changed source/Base identity');
  requireThat(Array.isArray(r.modules)&&r.modules.length>0&&new Set(r.modules.map(x=>x.file)).size===r.modules.length,'Missing/duplicate modules');
  for(const module of r.modules) {
    requireThat(typeof module.file==='string'&&!path.isAbsolute(module.file)&&!module.file.split('/').includes('..'),'Invalid module path');
    const file=path.join(path.dirname(r.source),module.file),actual=id(file);
    requireThat(actual.sha256===module.sha256&&inputs.some(x=>x.canonicalPath===actual.canonicalPath&&x.sha256===actual.sha256),'Module lineage mismatch');
  }
  requireThat(inputs.some(x=>x.canonicalPath===fs.realpathSync(r.source)&&x.sha256===r.sourceSha256),'Missing source lineage');
  const source=read(r.source);
  const imports=source.match(/^import .*$/gm)??[];
  requireThat(imports.length===1&&/^import Base\s*$/.test(imports[0]),'Unsupported source imports');
  requireThat(!/^(?:@unsafe\s+)?(?:def|law|type)\s+(?:String|Char|Cmp)(?:\.|\s|:)/m.test(source),'Compiler source replaces Base equality family');
  return {api,bootstrapReport:reportIdentity,source:id(r.source),inputs,exports:r.exports,revision:r.revision};
}

export async function deriveEquality({api,bootstrapReport,outputDirectory}) {
  const directory=path.resolve(outputDirectory);fs.mkdirSync(directory,{recursive:false});
  const reportFile=path.join(directory,'api.mjs.derivation.json'),report={kind:'bend-derived-b1-equality',version:1,complete:false,newBootstrap:false,started:new Date().toISOString(),scope:'Compiler-host data with standard unmodified JavaScript built-ins; not arbitrary reflective/proxy/monkeypatched-host equivalence.',tool:id(own),node:id(process.execPath)};
  try {
    report.original=verifyBootstrap(api,bootstrapReport);
    const transformed=transformEquality(read(api));
    requireThat(JSON.stringify(transformed.stats.exports)===JSON.stringify(report.original.exports),'Bootstrap export roots differ from actual module');
    const target=path.join(directory,'api.mjs');fs.writeFileSync(target,transformed.source,{flag:'wx'});
    report.output=id(target);report.transform=transformed.stats;
    report.original.inputs.forEach(unchanged);unchanged(report.original.api);unchanged(report.original.bootstrapReport);unchanged(report.tool);unchanged(report.node);
    fs.copyFileSync(own,path.join(directory,'equality.mjs'));
    report.toolSnapshot=id(path.join(directory,'equality.mjs'));report.complete=true;
  }catch(error){report.error=String(error?.stack??error);report.finished=new Date().toISOString();write(reportFile,report);error.derivationReport=reportFile;throw error;}
  report.finished=new Date().toISOString();write(reportFile,report);
  return {api:report.output.file,report:reportFile,metadata:report};
}

export function verifyEqualityDerivation(reportFile) {
  const r=json(reportFile);
  requireThat(r.kind==='bend-derived-b1-equality'&&r.version===1&&r.complete===true&&r.newBootstrap===false,'Incomplete/unknown equality derivation');
  unchanged(r.node);
  unchanged(r.output);unchanged(r.toolSnapshot);requireThat(r.toolSnapshot.sha256===r.tool.sha256,'Transformation snapshot mismatch');
  const original=verifyBootstrap(r.original.api.file,r.original.bootstrapReport.file);
  requireThat(original.api.sha256===r.original.api.sha256&&original.bootstrapReport.sha256===r.original.bootstrapReport.sha256,'Changed derivation lineage');
  const expected=transformEquality(read(original.api.file));
  requireThat(sha(expected.source)===r.output.sha256&&JSON.stringify(expected.stats)===JSON.stringify(r.transform),'Derived output does not replay exactly');
  return {api:r.output.file,report:path.resolve(reportFile),metadata:r};
}

if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    const [api,bootstrapReport,outputDirectory,...extra]=process.argv.slice(2);
    requireThat(api&&bootstrapReport&&outputDirectory&&!extra.length,'Usage: equality.mjs CHECKED_API BOOTSTRAP_REPORT FRESH_OUTPUT_DIRECTORY');
    console.log(JSON.stringify(await deriveEquality({api,bootstrapReport,outputDirectory})));
  } catch(error) {console.error(error?.stack??error);if(error.derivationReport)console.error('Failure report: '+error.derivationReport);process.exitCode=1;}
}
