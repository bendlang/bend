// P13-006 inventory: narrow constant scope extension; no compiler timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity, verifyIdentity} from '../../development/workflow.mjs';
import {moduleView, sha} from './rewriter-structure.mjs';

const [manifestArg, profileArg, outArg] = process.argv.slice(2), out = path.resolve(outArg);
assert.equal(process.version, 'v24.18.0'); fs.mkdirSync(out);
const manifest = JSON.parse(fs.readFileSync(manifestArg));
assert.ok(manifest.complete && manifest.inputsVerified);
const extensionHelper = path.join(import.meta.dirname, 'rewriter-selector-const.mjs');
const inputs = [import.meta.filename, process.execPath, manifestArg, profileArg, extensionHelper,
  path.resolve('experiments/phase13/P13-006-constant-scope-selectors.md'),
  manifest.checkedApi.file, manifest.baselineApi.file].map(identity);
const verify = () => [...inputs, ...manifest.helperInputs].forEach(verifyIdentity);
verify();
const consumed = path.join(out, 'consumed'); fs.mkdirSync(consumed);
for (const row of [...manifest.helperInputs, identity(extensionHelper), inputs[0]]) fs.copyFileSync(row.file, path.join(consumed, path.basename(row.file)));
const profile = JSON.parse(fs.readFileSync(profileArg)); assert.ok(profile.complete);
const original = await import(pathToFileURL(manifest.helper.file));
const selector = await import(pathToFileURL(extensionHelper));
const checked = fs.readFileSync(manifest.checkedApi.file, 'utf8');
const baseline = fs.readFileSync(manifest.baselineApi.file, 'utf8');
// Replaying the known candidate first binds the complete checked-image entry.
const replay = original.transform(checked, manifest.options);
assert.equal(sha(replay.source), manifest.api.sha256);
assert.deepEqual(replay.report, manifest.transformReport);
const extendedReplay = selector.transform(checked, manifest.options);
assert.equal(extendedReplay.source, replay.source, 'Unchanged initial owner output');
const view = moduleView(baseline), {ts} = view;
const lexical = new Map(profile.owners.map(row => [row.owner, row]));
const report = {kind: 'phase13-constant-scope-selector-opportunity-inventory', complete: false,
  inputs, helperInputs: [...manifest.helperInputs, identity(extensionHelper)],
  scope: 'Static opportunity only. Every syntactically filtered owner is passed to the frozen P13-006 lowerSelectors implementation after complete checked-image replay. Refusals retained; profile self samples are not inclusive attribution or a speed estimate.',
  prospectiveFilter: 'Any returned Unit choice whose false literal block is exactly another returned Unit choice. This is only a superset prefilter, never an acceptance rule.',
  baseline: manifest.baselineApi, replayedCandidate: manifest.api,
  ownerCount: view.functions.size, syntactic: [], rows: [],
  runtimeOwners: profile.owners.filter(row => ['run_loop', '(garbage collector)'].includes(row.owner))};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  for (const owner of view.functions.values()) {
    const sites = [];
    for (let i = owner.body + 1; i < owner.end; i++) {
      const parent = view.returnedChoice(i); if (!parent) continue;
      const no = view.arrow(parent.no, {unwrap: true}); if (!no) continue;
      const child = view.returnedChoice(no.body + 1);
      if (child && child.end === no.end) sites.push({at: ts[i].start, childAt: ts[child.first].start});
    }
    if (sites.length) report.syntactic.push({owner: owner.name, sites});
  }
  save();
  for (const item of report.syntactic) {
    const measured = lexical.get(item.owner);
    const row = {owner: item.owner, syntacticSelectors: item.sites.length,
      profile: measured ? {samples: measured.samples, selfUs: measured.selfUs, selfPercent: measured.selfPercent} : {samples: 0, selfUs: 0, selfPercent: 0}};
    try {
      const result = selector.lowerSelectors(baseline, {families: [item.owner]});
      row.accepted = true; row.report = result.report;
      assert.equal(result.report.outputSha256, sha(result.source));
    } catch (error) {row.accepted = false; row.refusal = String(error.stack ?? error);}
    report.rows.push(row); save();
  }
  const accepted = report.rows.filter(row => row.accepted);
  report.summary = {filteredOwners: report.syntactic.length, acceptedOwners: accepted.length,
    refusedOwners: report.rows.length - accepted.length,
    acceptedSelectors: accepted.reduce((n, row) => n + row.report.removedIntermediateSelectors, 0),
    ranked: [...accepted].sort((a, b) => b.profile.selfUs - a.profile.selfUs).map(row => ({owner: row.owner, selectors: row.report.removedIntermediateSelectors, ...row.profile}))};
  const planned = ['$norm_eval_node$', '$check_node$', '$core_subst_stable$', '$norm_match$', '$norm_args$', '$ffw_walk$', '$infer_node$'];
  report.plannedCheckingOwners = planned.map(owner => ({owner, accepted: accepted.some(row => row.owner === owner)}));
  report.selectedCheckingOwners = planned.filter(owner => accepted.some(row => row.owner === owner));
  verify(); report.inputsVerified = true; report.complete = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
report.finished = new Date().toISOString(); save(); console.log(JSON.stringify({complete: report.complete, summary: report.summary, error: report.error}));
