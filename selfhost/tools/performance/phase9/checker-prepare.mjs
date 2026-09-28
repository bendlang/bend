// Freeze independently reproducible checker ablations; never edits live source.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const project=path.resolve(import.meta.dirname,'../../..');
const output=path.resolve(process.argv[2]);
fs.mkdirSync(output,{recursive:false});
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const baseline=path.join(output,'baseline-project');
fs.mkdirSync(baseline);
for(const dir of ['src','tools','tests'])fs.cpSync(path.join(project,dir),path.join(baseline,dir),{recursive:true});
const kernel='src/check/kernel.bend',normalizer='src/core/normalize.bend';
const modifications={
  lambda:{file:kernel,before:'both(check(e, ctx, kid(ty, 0), 0, typ(kindq(e, q))), check(lhs_step',after:'both(kc(KChecked, U32.is_eq(qt(t), 2) && U32.is_eq(qt(ty), 1), u => check(e, ctx, kid(ty, 0), 0, typ(kindq(e, q))), u => ok(t, ty, Nil{})), check(lhs_step'},
  exact:{file:normalizer,before:'  norm_compare(book, a, b, le, U32.add(1, norm_max(norm_book_bound(book), norm_max(norm_max_term(a), norm_max_term(b)))))',after:'  kc(Bool, norm_exact(a, b), u => True{}, u => norm_cmp_loop(book, Con{KNormCmp{a, b, le, U32.add(1, norm_max(norm_book_bound(book), norm_max(norm_max_term(a), norm_max_term(b))))}, Nil{}}, Nil{}))'},
  lookup:{file:kernel,before:'  kc(KChecked, String.eq(tg(ctx_get(ctx, ix(t))), "Absent"), u => bad("unbound variable"), u => ok(t, kid(ctx_get(ctx, ix(t)), 0), Con{kt("Use", "", ix(t), dem, Nil{}), Nil{}}))',after:'  +bound = ctx_get(ctx, ix(t))\n  kc(KChecked, String.eq(tg(bound), "Absent"), u => bad("unbound variable"), u => ok(t, kid(bound, 0), Con{kt("Use", "", ix(t), dem, Nil{}), Nil{}}))'},
};
const upstream=fs.realpathSync(path.join(project,'.bootstrap/upstream-phase8'));
const maintained=JSON.parse(fs.readFileSync(path.join(baseline,'tests/frontend/phase2-rules/cases.json')));
const cases=maintained.map(c=>({...c,file:path.join(baseline,'tests/frontend/phase2-rules',c.file)}));
const chosen=['lambda_single_use','let_lambda_twice','kind_none_lone_binder','unsafe_many','unsafe_forward_safe','unsafe_relies','erased_binder_use','erased_local_live_use','erased_type_quantifier','type_family_lambda','beta_ann_lambda','beta_ann_body','beta_ann_match','ref_eta_conversion','no_eta_conversion','eta_long_sides','dead_default_residual','mutual_type_def','do_header_quantity_span'];
for(const name of chosen){const file=path.join(upstream,'tests/check',name+'.bend');const accept=!fs.readFileSync(file,'utf8').includes('#|exit 1');cases.push({id:'phase9/'+name,file,accept,rejectPhase:accept?null:'check',lanes:['check']});}
const selection=path.join(output,'selection.json');fs.writeFileSync(selection,JSON.stringify({cases},null,2)+'\n');
const variants=[];
for(const name of ['lambda','exact','lookup','combined']){
  const directory=path.join(output,name+'-project');fs.cpSync(baseline,directory,{recursive:true});
  const changes=name==='combined'?Object.keys(modifications):[name];
  for(const key of changes){const m=modifications[key],file=path.join(directory,m.file),text=fs.readFileSync(file,'utf8');if(text.split(m.before).length!==2)throw Error('Nonunique edit: '+key);fs.writeFileSync(file,text.replace(m.before,m.after));}
  const config=path.join(output,name+'.json');fs.writeFileSync(config,JSON.stringify({project:directory,upstream,selection,jobs:1,cpu:'1'},null,2)+'\n');
  variants.push({name,directory,config,changes,modules:[kernel,normalizer].map(file=>({file,sha256:hash(path.join(directory,file))}))});
}
const modules=JSON.parse(fs.readFileSync(path.join(baseline,'src/compiler.json'))).modules.map(file=>({file,sha256:hash(path.join(baseline,file))}));
const report={kind:'checker-source-ablations',created:new Date().toISOString(),baseline,upstream,modules,modifications,selection:{file:selection,sha256:hash(selection)},variants,script:{file:import.meta.filename,sha256:hash(import.meta.filename)}};
fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({baseline,variants:variants.map(v=>({name:v.name,config:v.config})),selected:cases.length}));
