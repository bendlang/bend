#!/usr/bin/env node
// Reproducible component validation. This is explicitly a stage-0 test build,
// separate from self-hosting and whole-upstream compatibility gates.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {assemble} from './assemble.mjs';
const root=path.resolve(import.meta.dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'src/compiler.json'),'utf8'));
const upstream=process.env.BEND_UPSTREAM||path.join(root,'.bootstrap/upstream-phase8');
const dir=process.env.BEND_COMPONENT_DIR?path.resolve(process.env.BEND_COMPONENT_DIR):path.join(root,'build/verify');
if(process.env.BEND_COMPONENT_DIR&&fs.existsSync(dir))throw Error('Use a fresh BEND_COMPONENT_DIR to preserve component evidence');
const source=path.join(dir,'compiler.bend'),api=path.join(dir,'api.mjs');
const results=[];
const digest=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const captured=manifest.modules.map(file=>({file,bytes:fs.readFileSync(path.join(root,file))}));
function run(name,args,{env={}}={}) {
  const start=performance.now();
  const child=spawnSync(process.execPath,args,{cwd:root,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024,env:{...process.env,...env}});
  const result={name,pass:!child.error&&child.status===0,exitCode:child.status,seconds:(performance.now()-start)/1000,stdout:child.stdout,stderr:child.stderr,error:child.error?.message};
  results.push(result);
  process.stdout.write(`${result.pass?'PASS':'FAIL'} ${name}\n`);
  if(!result.pass)throw Error(child.error?.message||child.stderr||child.stdout||name);
}
try{
  const revision=spawnSync('git',['-C',upstream,'rev-parse','HEAD'],{encoding:'utf8'});
  if(revision.status!==0||revision.stdout.trim()!==manifest.upstream)throw Error('BEND_UPSTREAM must point to the pinned checkout '+manifest.upstream);
  const snapshot=path.join(dir,'sources');
  for(const {file,bytes} of captured) {
    const target=path.join(snapshot,file);
    fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,bytes);
  }
  assemble(manifest.modules,source,{root:snapshot});
  const roots=['check_book','check','infer','annotate_book','kp_show','specialize_book','specialized_book','specialized_error','strong','wnf','compare','exact_prefix','check_from_exact_prefix','reach_book','lookup','book_cached','book_context','book_put','f_parse','f_source_parsed','f_load_graph','f_load_graph_seed','f_main_names','f_fresh_term','f_fresh_defs','check_book_diagnostic','diagnostic_render','diagnostic_result_locate','dg_render','diagnostic_locate','f_load_origins','f_load_origins_for','nc_ctor_identity','nc_ctor_display','nc_ctor_encode','nc_ctor_owned'];
  run('upstream checks all compiler modules',['tools/stage0-library.mjs',source,api,...roots],{env:{BEND_UPSTREAM:upstream}});
  const env={BEND_UPSTREAM:upstream,BEND_KERNEL_API:api,BEND_ANNOTATE_API:api,BEND_PRETTY_API:api,BEND_TEMPLATE_API:api,BEND_NORMALIZE_API:api,BEND_PREFIX_API:api,BEND_REACH_API:api,BEND_INDEX_API:api,BEND_FRONT_API:api,BEND_DIAGNOSTIC_API:api,BEND_NATIVE_IDENTITY_API:api};
  run('dependent checker and annotation',['tests/kernel.mjs'],{env});
  run('structured diagnostic rendering and legacy fallback',['tests/diagnostic.mjs'],{env});
  run('diagnostic source parity against pinned upstream',['tests/diagnostic-source.mjs'],{env});
  run('final-core source provenance',['tests/frontend/origins.mjs'],{env});
  run('native constructor identity and provenance',['tests/native-identity.mjs'],{env});
  run('persistent book index',['tests/index.mjs'],{env});
  run('dependency closure',['tests/reach.mjs'],{env});
  run('validated prefix reuse',['tests/prefix.mjs'],{env});
  run('parsed source handoff',['tests/frontend/parsed-source.mjs'],{env});
  run('seeded loader equivalence',['tests/frontend/seed-cache.mjs'],{env});
  run('stack-safe binder freshening',['tests/frontend/fresh-work.mjs'],{env});
  run('stack-safe declaration freshening',['tests/frontend/fresh-book.mjs'],{env});
  run('main-module reporting boundary',['tests/frontend/main-names.mjs'],{env});
  run('term readback',['tests/pretty.mjs'],{env});
  run('normalization and conversion',['tests/normalize.mjs'],{env});
  run('template specialization',['tests/specialize.mjs'],{env});
  run('JavaScript primitive ABI',['src/runtime/js/test.mjs']);
  run('conformance harness and host ABI safeguards',['--test','tests/conformance/inventory.test.mjs','tests/conformance/judge.test.mjs','tests/conformance/abi.test.mjs','tests/conformance/selection.test.mjs','tests/conformance/targeted.test.mjs','tests/conformance/native-adapter.test.mjs','tests/conformance/selfhost-provenance.test.mjs','tests/conformance/bootstrap-provenance.test.mjs','tests/node-resource-args.test.mjs','tests/native-build.test.mjs']);
} catch(error){process.stderr.write(error.message+'\n');process.exitCode=1}
finally{
  const reportFile=process.env.BEND_COMPONENT_REPORT||(process.env.BEND_COMPONENT_DIR?path.join(dir,'report.json'):path.join(root,'dist/component-report.json'));
  fs.mkdirSync(path.dirname(reportFile),{recursive:true});
  fs.writeFileSync(reportFile,JSON.stringify({upstream:manifest.upstream,node:process.version,generated:new Date().toISOString(),scope:'component verification, not whole-language conformance or self-hosting',pass:process.exitCode!==1,modules:captured.map(({file,bytes})=>({file,sha256:digest(bytes)})),results},null,2)+'\n');
}
