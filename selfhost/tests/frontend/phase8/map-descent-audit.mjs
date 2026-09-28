// Disposable instrumentation of already checked generated JS. Never a release
// artifact or proof: only records actual arguments at the existing checker gate.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [api,base,output]=process.argv.slice(2);if(!api||!base||!output)throw Error('Usage: map-descent-audit.mjs CHECKED_API BASE NEW_DIRECTORY');
fs.mkdirSync(output,{recursive:false});
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
let source=fs.readFileSync(api,'utf8');
const marker='function $infer_ref$(_e_0, _t_0, _dem_0, _sp_0, _d_0) {';
if(source.split(marker).length!==2)throw Error('Unexpected emitter function');
source=source.replace(marker,'function $phase8_infer_ref_original$(_e_0, _t_0, _dem_0, _sp_0, _d_0) {');
source+=`\nexport const phase8DescentTraces=[];
function $infer_ref$(env,term,dem,sp,definition){
 const result=run_loop($phase8_infer_ref_original$(env,term,dem,sp,definition));
 if(env.name==='Map.put.go'&&term.name==='Map.put.go'&&dem!==0&&phase8DescentTraces.length<32){
  const cols=run_loop($unargs$(env.lhs,{$:'Nil'}));
  phase8DescentTraces.push({quantities:env.quantities,args:sp,cols,result});
 }
 return result;
}\n`;
const derived=path.join(output,'probe-api.mjs');fs.writeFileSync(derived,source);
const inputs=[api,base,import.meta.filename].map(file=>({file:fs.realpathSync(file),sha256:hash(file)}));
const mod=await import(pathToFileURL(path.resolve(derived))),K=mod.default;
const loaded=K.f_load_graph('Base',{$:'Con',head:{$:'FSource',name:'Base',path:fs.realpathSync(base),text:fs.readFileSync(base,'utf8')},tail:{$:'Nil'}});
const error=loaded.error||K.check_book(loaded.book);
const report={kind:'phase8-map-descent-instrumentation',scope:'Instrumented generated JS only; not a new checked API or performance result',inputs,derived:{file:derived,sha256:hash(derived)},error,traces:mod.phase8DescentTraces};
fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({error,traces:report.traces.length,output}));
