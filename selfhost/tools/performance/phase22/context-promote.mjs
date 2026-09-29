// Install the frozen contextual compiler after independently acquired gates.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';

const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const [manifestArg, outArg] = process.argv.slice(2);
const manifestFile = fs.realpathSync(manifestArg), out = path.resolve(outArg);
const read = p => JSON.parse(fs.readFileSync(p));
const manifest = read(manifestFile);
fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind:'phase22-context-installation', complete:false, pass:false,
  started:new Date().toISOString(), copies:[], inputs:[identity(import.meta.filename), identity(manifestFile)]};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2)+'\n');
const inventory = m => new Map(m.snapshot.sources.map(({frozen}) => [path.relative(m.snapshot.root, frozen.file), frozen]));
const gate = (item, passField='pass') => {
  verifyIdentity(item); const r = read(item.file);
  assert.ok(r.complete && r[passField], item.file);
  report.inputs.push(identity(item.file)); return r;
};
save();
try {
  const old = await verifyAttempt(path.join(project,'build/phase21/group-range-build-02'));
  const current = await verifyAttempt(manifest.attempt);
  assert.equal(old.api.sha256,'44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0');
  assert.match(manifest.expectedApi,/^[0-9a-f]{64}$/);
  assert.equal(current.api.sha256,manifest.expectedApi);
  assert.equal(current.base.sha256,old.base.sha256);
  assert.equal(current.runtime.sha256,old.runtime.sha256);
  assert.equal(current.config.upstream,old.config.upstream);
  const before = inventory(old), after = inventory(current);
  assert.equal(before.size,214); assert.equal(after.size,215);
  const oldHosts = [...before.keys()].filter(name=>name.startsWith('tools/')).sort();
  const newHosts = [...after.keys()].filter(name=>name.startsWith('tools/')).sort();
  assert.equal(oldHosts.length,35); assert.deepEqual(oldHosts,newHosts);
  assert.deepEqual(oldHosts.filter(name=>before.get(name).sha256!==after.get(name).sha256),['tools/typed-driver.mjs']);
  const review = gate(manifest.hostReview,'readOnlyScopeApproved');
  assert.equal(review.sameCompiledApi,true);
  assert.deepEqual(review.latestChangedMembers,['tools/typed-driver.mjs']);
  assert.equal(review.reviewed[0].after.sha256,after.get('tools/typed-driver.mjs').sha256);
  verifyIdentity(review.reviewed[0].latestPatch);
  const main = gate(manifest.frontend);
  assert.equal(main.api.sha256,current.api.sha256); assert.equal(main.observations,2996);
  assert.equal(main.exact.after,0); assert.equal(main.primitiveDifferences,0);
  const parser = gate(manifest.parser,'ownedCorrectnessPass');
  assert.equal(parser.api.sha256,current.api.sha256);
  assert.equal(parser.original196Delta.candidateExact,196); assert.equal(parser.original196Delta.lost,0);
  const publicControls = gate(manifest.publicControls);
  assert.equal(publicControls.api.sha256,current.api.sha256);
  assert.equal(publicControls.totals.parseCheck.candidateExact,154);
  assert.equal(publicControls.totals.execution.candidateExact,36);
  const supplemental = gate(manifest.supplemental);
  assert.equal(supplemental.api.sha256,current.api.sha256); assert.equal(supplemental.candidateExact,22);
  const completion = gate(manifest.completion);
  assert.equal(completion.api.sha256,current.api.sha256); assert.equal(completion.matched,17);
  const checkup = gate(manifest.checkup);
  assert.equal(checkup.api.sha256,current.api.sha256);
  assert.equal(checkup.rows.length,4); assert.ok(checkup.rows.every(x=>x.exact));
  for (const item of manifest.additionalGates) {
    const r = gate(item);
    assert.ok(Array.isArray(item.candidateApiPath) && item.candidateApiPath.length>0);
    assert.equal(item.candidateApiPath.reduce((value,key)=>value?.[key],r),current.api.sha256,'Wrong candidate API: '+item.file);
  }
  const validation = gate(manifest.validation);
  assert.equal(validation.api.sha256,current.api.sha256); assert.equal(validation.strictExact,true);
  assert.equal(validation.selected.selectedComplete,true);
  assert.equal(validation.selected.exactDifferences,0); assert.equal(validation.selected.discrepancies,0);
  assert.equal(validation.selected.candidate.probes,36); assert.equal(validation.selected.reference.probes,36);
  verifyIdentity(manifest.matrix); const matrix = read(manifest.matrix.file);
  assert.ok(matrix.complete && !matrix.error && matrix.unsafeDefinitionSetsAgree);
  assert.equal(matrix.variants.baseline.api.sha256,old.api.sha256);
  assert.equal(matrix.variants.candidate.api.sha256,current.api.sha256);
  for (const [label,directory] of [['baseline',path.join(project,'build/phase21/group-range-build-02')],['candidate',manifest.attempt]]) {
    const item=matrix.variants[label].attempt; verifyIdentity(item);
    assert.deepEqual(item,identity(path.join(directory,'attempt.json')));
  }
  assert.equal(matrix.rows.length,6);
  const order=['typescript','baseline','candidate','candidate','baseline','typescript'];
  assert.deepEqual(matrix.order,order); assert.equal(matrix.cpu,'0');
  matrix.rows.forEach((row,index)=>{
    assert.equal(row.index,index); assert.equal(row.variant,order[index]);
    assert.equal(row.observation.variant,order[index]);
    assert.equal(row.observation.pass,true); assert.equal(row.observation.inputsVerified,true);
    assert.deepEqual(row.observation.node.args,['--stack-size=4096','--max-old-space-size=4096']);
    assert.equal(row.observation.affinity.trim(),'Cpus_allowed_list:\t0');
    assert.equal(row.execution.exitCode,0); assert.equal(row.execution.signal,null);
    assert.equal(row.execution.error,null); assert.equal(row.execution.timedOut,false); assert.equal(row.execution.overflow,false);
  });
  assert.ok(Number.isFinite(matrix.ratios.candidateProcessReduction));
  assert.ok(Number.isFinite(matrix.ratios.candidateRequestReduction));
  assert.ok(matrix.ratios.candidateProcessReduction >= -0.03,'Investigate slowdown above3%');
  assert.ok(matrix.ratios.candidateRequestReduction >= -0.03,'Investigate request slowdown above3%');
  report.inputs.push(identity(manifest.matrix.file));
  const protectedState=identity(path.join(project,'build/phase16/start-state.json'));
  report.inputs.push(protectedState);
  const protectedFiles = read(protectedState.file).unrelatedPhase6;
  assert.equal(protectedFiles.length,75);
  const checkProtected = () => protectedFiles.forEach(x => {
    assert.equal(identity(path.join(repo,x.path)).sha256,x.sha256);
    assert.equal(execFileSync('git',['status','--porcelain=v1','--untracked-files=all','--',x.path],
      {cwd:repo,encoding:'utf8'}).slice(0,2),x.status);
  });
  checkProtected(); report.protectedFiles = protectedFiles.length;
  report.previous = verifyRelease(project);
  assert.equal(report.previous.files.find(x=>x.path==='dist/typed-api.mjs').sha256,old.api.sha256);
  for (const [name,item] of before) assert.equal(identity(path.join(project,name)).sha256,item.sha256,name);
  assert.deepEqual([...after.keys()].filter(name=>!before.has(name)),['src/front/contextual.bend']);
  const changes = [...after].filter(([name,item])=>before.get(name)?.sha256 !== item.sha256);
  assert.deepEqual(changes.map(([name])=>name).sort(),manifest.changedPaths.slice().sort());
  report.finalApi = current.api;
  report.checkedApi = current.checkedApi; report.artifactKind = current.artifactKind;
  report.hostReview = manifest.hostReview;
  for (const [relative,source] of changes) {
    const live = path.join(project,relative), backup = path.join(out,'source-before',relative);
    let original = null;
    if (before.has(relative)) {
      fs.mkdirSync(path.dirname(backup),{recursive:true}); fs.copyFileSync(live,backup); original = identity(backup);
    } else assert.equal(fs.existsSync(live),false);
    fs.mkdirSync(path.dirname(live),{recursive:true}); fs.copyFileSync(source.file,live);
    report.copies.push({relative,before:before.get(relative)??null,source,backup:original,after:identity(live)});
  }
  save();
  report.installed = await installAttempt(manifest.attempt);
  report.release = verifyRelease(project);
  assert.equal(report.release.files.find(x=>x.path==='dist/typed-api.mjs').sha256,current.api.sha256);
  for (const [name,item] of after) assert.equal(identity(path.join(project,name)).sha256,item.sha256,name);
  checkProtected(); report.inputs.forEach(verifyIdentity);
  report.complete = report.pass = true;
} catch(error) { report.error = String(error.stack??error); process.exitCode=1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,copies:report.copies.length,error:report.error}));
