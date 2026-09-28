import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyAttempt} from '../../development/workflow.mjs';
const [baselineArg,outArg]=process.argv.slice(2),baseline=path.resolve(baselineArg),out=path.resolve(outArg);
assert.equal(process.version,'v24.18.0');const m=await verifyAttempt(baseline);
fs.mkdirSync(out);const project=path.join(out,'project');fs.mkdirSync(project);
for(const name of ['src','tools','tests'])fs.cpSync(path.join(m.snapshot.root,name),path.join(project,name),{recursive:true});
const file=path.join(project,'src/core/normalize.bend'),before=fs.readFileSync(file,'utf8');
const start=before.indexOf('  kc(KTerm, String.eq(tg(t), "App"),'),end=before.indexOf('\nlaw norm_ref:',start);
assert.ok(start>0&&end>start);const old=before.slice(start,end);
const cases=[['app','App','norm_eval(book, kid(t, 0), Con{kid(t, 1), args}, left, fallback)'],['ann','Ann','norm_eval(book, kid(t, 0), args, left, fallback)'],['let','Let','norm_eval(book, norm_let(ks(t)), args, left, fallback)'],['ref','Ref','norm_ref(book, t, args, lookup(book, nm(t)))'],['min','Min','norm_apply(norm_min(book, kid(t, 0), kid(t, 1)), args)'],['rwt','Rwt','kc(KTerm, String.eq(tg(wnf(book, kid(t, 0))), "Rfl"), u => norm_eval(book, kid(t, 2), args, left, fallback), u => norm_apply(t, args))']];
let replacement='  norm_node_app(book, t, args, left, fallback, String.eq(tg(t), "App"))\n';
for(const [i,[name,tag,yes]] of cases.entries()){
 const next=cases[i+1];
 replacement+=`\n@unsafe\ndef norm_node_${name}(\n  +book: List<&2, KDef>,\n  +t: KTerm,\n  +args: List<&2, KTerm>,\n  +left: U32,\n  +fallback: KTerm,\n  +selected: Bool,\n) -> KTerm:\n  match selected:\n    case True{}:\n      ${yes}\n    case False{}:\n      ${next?`norm_node_${next[0]}(book, t, args, left, fallback, String.eq(tg(t), "${next[1]}"))`:'norm_args(book, t, args, left, fallback)'}\n`;
}
const after=before.slice(0,start)+replacement+before.slice(end);fs.writeFileSync(file,after);fs.writeFileSync(path.join(out,'before-normalize.bend'),before);fs.writeFileSync(path.join(out,'replacement.bend'),replacement);
const config=path.join(out,'workflow.json');fs.writeFileSync(config,JSON.stringify({project,upstream:m.config.upstream,jobs:1,cpu:'3',profile:'equality',timeoutMs:30000},null,2)+'\n');
const measure=s=>({physical:s.split('\n').length-Number(s.endsWith('\n')),nonblank:s.split('\n').filter(x=>x.trim()).length,bytes:Buffer.byteLength(s),defs:(s.match(/^def /gm)||[]).length,laws:(s.match(/^law /gm)||[]).length});
const manifest={kind:'phase14-normalizer-source-dispatch-candidate',started:new Date().toISOString(),baselineAttempt:identity(path.join(baseline,'attempt.json')),baselineApi:m.api,baselineSourceRoot:m.snapshot.root,inputs:[identity(import.meta.filename),identity(process.execPath)],modified:identity(file),before:identity(path.join(out,'before-normalize.bend')),edits:[{before:old,after:replacement}],cost:{before:measure(before),after:measure(after),addedHelpers:6,maintainedJsDelta:0},config:identity(config)};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');console.log(JSON.stringify({project,config,file,cost:manifest.cost}));
