import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyAttempt} from '../../development/workflow.mjs';

const [baselineArg,outputArg]=process.argv.slice(2);
const baseline=path.resolve(baselineArg), output=path.resolve(outputArg);
const prior=await verifyAttempt(baseline);
assert.equal(prior.api.sha256,'63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f');
fs.mkdirSync(output,{recursive:false});
const project=path.join(output,'project'); fs.mkdirSync(project);
for(const part of ['src','tools','tests'])fs.cpSync(path.join(prior.snapshot.root,part),path.join(project,part),{recursive:true});
const relative='src/core/normalize.bend', file=path.join(project,relative);
const preimage=fs.readFileSync(file,'utf8'), edits=[];
let source=preimage;
function change(before,after,count=1){
  assert.equal(source.split(before).length,count+1,before);
  source=source.split(before).join(after); edits.push({before,after,count});
}
change('norm_eval(book, t, Nil{}, 0, atom("Absent"))','norm_eval(book, t, Nil{}, 0, Nil{})');
for(const name of ['norm_eval','norm_args','norm_match','norm_var']){
  const start=source.indexOf('law '+name+':\n'), end=source.indexOf('\n@unsafe',start);
  assert.ok(start>=0&&end>start);
  const before=source.slice(start,end),after=before.replace('for +fallback: KTerm','for +fallback: List<&2, KTerm>');
  assert.notEqual(before,after); change(before,after);
}
const start=source.indexOf('def norm_eval_node(\n'),end=source.indexOf('\n) -> KTerm:',start);
assert.ok(start>=0&&end>start);
const before=source.slice(start,end),after=before.replace('+fallback: KTerm,','+fallback: List<&2, KTerm>,');
assert.notEqual(before,after);change(before,after);
change('norm_eval(book, dv(d), args, da(d), norm_apply(t, args))','norm_eval(book, dv(d), args, da(d), Con{t, args})');
change('u => fallback, u => norm_apply(t, args)','u => norm_restore(left, fallback), u => norm_apply(t, args)');
change('norm_stuck(original, raw, args, left, fallback)','norm_stuck(original, raw, args, left, norm_restore(left, fallback))',2);
assert.ok(!source.includes('def norm_restore('));
const helper=`
# A pending fallback is its original reference followed by the shared arguments.
# Keep graph.bend's materialized norm_stuck interface; restore only if demanded.
@unsafe
def norm_restore(
  +left: U32,
  +fallback: List<&2, KTerm>,
) -> KTerm:
  match fallback:
    case Nil{}:
      atom("Absent")
    case Con{head, args}:
      kc(KTerm, U32.is_eq(left, 0), u => atom("Absent"), u => norm_apply(head, args))
`;
source+=helper;fs.writeFileSync(file,source);
const config=path.join(output,'config.json');
fs.writeFileSync(config,JSON.stringify({project,upstream:path.resolve('selfhost/.bootstrap/upstream-phase8'),cpu:'2',profile:'equality',jobs:1,timeoutMs:30000},null,2)+'\n');
const count=text=>({physical:text.split('\n').length-1,nonblank:text.split('\n').filter(x=>x.trim()).length,bytes:Buffer.byteLength(text),defs:(text.match(/^def /gm)||[]).length,laws:(text.match(/^law /gm)||[]).length,types:(text.match(/^type /gm)||[]).length});
const manifest={kind:'phase12-delayed-normalizer-fallback-source',baselineApi:prior.api,
  inputs:[identity(import.meta.filename),identity(path.join(baseline,'attempt.json'))],
  project,config,source:{file:relative,preimage:identity(path.join(prior.snapshot.root,relative)),candidate:identity(file),edits,helper,before:count(preimage),after:count(source)},
  invariant:'Finite immutable head/argument spine. Preserve graph norm_stuck KTerm interface and reconstruct through existing norm_apply only when pending arity is nonzero.'};
fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify({project,config,before:manifest.source.before,after:manifest.source.after,candidate:manifest.source.candidate}));
