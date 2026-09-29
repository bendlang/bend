import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyAttempt} from '../../development/workflow.mjs';
const [baselineArg,outArg]=process.argv.slice(2),baseline=path.resolve(baselineArg),out=path.resolve(outArg);
assert.equal(process.version,'v24.18.0');const m=await verifyAttempt(baseline);
fs.mkdirSync(out);const project=path.join(out,'project');fs.mkdirSync(project);
for(const name of ['src','tools','tests'])fs.cpSync(path.join(m.snapshot.root,name),path.join(project,name),{recursive:true});
const file=path.join(project,'src/core/term.bend'),before=fs.readFileSync(file,'utf8');
const old='      kc(KDef, String.eq(dk(d), "BookCache"), u => index_lookup(d, name), u => kc(KDef, String.eq(dn(d), name), u => d, u => lookup(rest, name)))';
const replacement=`      lookup_cached(d, rest, name, String.eq(dk(d), "BookCache"))

@unsafe
def lookup_cached(
  +d: KDef,
  +rest: List<&2, KDef>,
  +name: String,
  +cached: Bool,
) -> KDef:
  match cached:
    case True{}: index_lookup(d, name)
    case False{}: lookup_named(d, rest, name, String.eq(dn(d), name))

@unsafe
def lookup_named(
  +d: KDef,
  +rest: List<&2, KDef>,
  +name: String,
  +same: Bool,
) -> KDef:
  match same:
    case True{}: d
    case False{}: lookup(rest, name)`;
assert.equal(before.split(old).length,2);const after=before.replace(old,replacement);fs.writeFileSync(file,after);fs.writeFileSync(path.join(out,'before-term.bend'),before);fs.writeFileSync(path.join(out,'replacement.bend'),replacement);
const config=path.join(out,'workflow.json');fs.writeFileSync(config,JSON.stringify({project,upstream:m.config.upstream,jobs:1,cpu:'3',profile:'equality',timeoutMs:30000},null,2)+'\n');
const measure=s=>({physical:s.split('\n').length-Number(s.endsWith('\n')),nonblank:s.split('\n').filter(x=>x.trim()).length,bytes:Buffer.byteLength(s),defs:(s.match(/^def /gm)||[]).length,laws:(s.match(/^law /gm)||[]).length});
const manifest={kind:'phase15-lookup-source-workers-candidate',started:new Date().toISOString(),baselineAttempt:identity(path.join(baseline,'attempt.json')),baselineApi:m.api,baselineSourceRoot:m.snapshot.root,inputs:[identity(import.meta.filename),identity(process.execPath)],modified:identity(file),before:identity(path.join(out,'before-term.bend')),edits:[{before:old,after:replacement}],cost:{before:measure(before),after:measure(after),addedHelpers:2,maintainedJsDelta:0},config:identity(config)};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');console.log(JSON.stringify({project,config,file,cost:manifest.cost}));
