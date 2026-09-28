import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {identity,verifyAttempt} from '../../development/workflow.mjs';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg),m=await verifyAttempt(base);fs.mkdirSync(out,{recursive:false});
const normFile='src/core/normalize.bend',kernelFile='src/check/kernel.bend';
const oldExact='norm_cmp_loop(book, Con{KNormCmp{a, b, le, U32.add(1, norm_max(norm_book_bound(book), norm_max(norm_max_term(a), norm_max_term(b))))}, Nil{}}, Nil{})';
const newExact='norm_cmp_start(book, a, b, le, U32.add(1, norm_max(norm_book_bound(book), norm_max(norm_max_term(a), norm_max_term(b)))))';
const exactHelper=`
# The caller already established unequal syntax and computed the fresh bound.
# Keep that bound before weak evaluation; later queued pairs retain quick checks.
@unsafe
def norm_cmp_start(
  +book: List<&2, KDef>,
  +a: KTerm,
  +b: KTerm,
  +le: Bool,
  +fresh: U32,
) -> Bool:
  norm_cmp_heads(book, wnf(book, a), wnf(book, b), le, fresh, Nil{}, Nil{})
`;
const oldBody=`both(check(mat_lhs(e, nm(t), tele_fill(cb(e), dt(ctr), ks(a)), da(ctr), Con{t, Con{ty, ctx}}), ctx, kid(t, 0), dem, mat_goal(cb(e), ty, tele_fill(cb(e), dt(ctr), ks(a)), da(ctr), nm(t), Nil{})),
   check(e, ctx, mat_rest(cb(e), t, a), dem, all(qt(ty), nm(ty), ix(ty), KTerm{tg(a), nm(a), ix(a), qt(a), ks(a), Con{nm(t), rm(a)}}, kid(ty, 1))), t, ty, True{})`;
const newBody='check_mat_filled(e, ctx, t, dem, ty, a, ctr, tele_fill(cb(e), dt(ctr), ks(a)))';
const filledBody=oldBody.replaceAll('tele_fill(cb(e), dt(ctr), ks(a))','tel');
const teleHelper=`
# Reuse the same instantiated constructor telescope for the lhs and arm goal.
@unsafe
def check_mat_filled(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +t: KTerm,
  +dem: U32,
  +ty: KTerm,
  +a: KTerm,
  +ctr: KDef,
  +tel: KTerm,
) -> KChecked:
  ${filledBody}
`;
const variants=[];
for(const label of ['exact','telescope','combined']){
 const project=path.join(out,label+'-project');fs.mkdirSync(project);for(const n of ['src','tools','tests'])fs.cpSync(path.join(m.snapshot.root,n),path.join(project,n),{recursive:true});
 const edits=[];
 for(const [name,file,before,after,helper] of [['exact',normFile,oldExact,newExact,exactHelper],['telescope',kernelFile,oldBody,newBody,teleHelper]]){
  if(label!==name&&label!=='combined')continue;const p=path.join(project,file),s=fs.readFileSync(p,'utf8');assert.equal(s.split(before).length,2);fs.writeFileSync(p,s.replace(before,after)+helper);edits.push({name,file,preimage:identity(path.join(m.snapshot.root,file)),candidate:identity(p),before,after,helper});
 }
 const config=path.join(out,label+'.json');fs.writeFileSync(config,JSON.stringify({project,upstream:path.resolve('selfhost/.bootstrap/upstream-phase8'),cpu:'2',profile:'equality',jobs:1,timeoutMs:30000},null,2)+'\n');variants.push({label,project,config,edits});
}
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify({kind:'phase11-checker-source-ablations',baselineApi:m.api,inputs:[identity(import.meta.filename),identity(path.join(base,'attempt.json'))],variants},null,2)+'\n');console.log(JSON.stringify(variants.map(({label,project,config})=>({label,project,config}))));
