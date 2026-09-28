// Prepare source-level lazy-control ablations without modifying live source.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {identity,verifyAttempt} from '../../development/workflow.mjs';
const [baselineArg,outArg]=process.argv.slice(2);const m=await verifyAttempt(path.resolve(baselineArg));const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const upstream=path.resolve('selfhost/.bootstrap/upstream-phase8');
const edits={alias:{file:'src/load/graph.bend',before:'Bool.not(String.eq(name, nm(t))) && f_declared(name, scope) && f_declared(nm(t), scope)',after:'f_choose(Bool, Bool.not(String.eq(name, nm(t))), u => f_declared(name, scope) && f_declared(nm(t), scope), u => False{})'},scanner:{file:'src/load/modules.bend',before:'f_eq(name, dn(d)) || f_declared(name, dc(d)) || f_declared(name, ds)',after:'f_choose(Bool, f_eq(name, dn(d)), u => True{}, u => f_choose(Bool, f_declared(name, dc(d)), u => True{}, u => f_declared(name, ds)))'}};
const variants=[];
for(const variant of ['alias','combined']){
 const project=path.join(out,variant+'-project');fs.mkdirSync(project);
 for(const name of ['src','tools','tests'])fs.cpSync(path.join(m.snapshot.root,name),path.join(project,name),{recursive:true});
 const changes=variant==='combined'?['alias','scanner']:['alias'];
 for(const name of changes){const e=edits[name],file=path.join(project,e.file),s=fs.readFileSync(file,'utf8');assert.equal(s.split(e.before).length,2);fs.writeFileSync(file,s.replace(e.before,e.after));}
 const config=path.join(out,variant+'.json');fs.writeFileSync(config,JSON.stringify({project,upstream,jobs:1,cpu:'1',profile:'equality',timeoutMs:30000},null,2)+'\n');
 variants.push({variant,project,changes,config:identity(config),modified:changes.map(n=>identity(path.join(project,edits[n].file)))});
}
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify({kind:'phase10-loader-lazy-ablations',inputs:[identity(import.meta.filename),identity(path.join(baselineArg,'attempt.json'))],baselineApi:m.api,baselineSource:m.bootstrapReport,edits,variants},null,2)+'\n');console.log(JSON.stringify(variants));
