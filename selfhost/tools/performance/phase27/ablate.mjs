// Diagnostic derivatives only: isolate the two Phase27 term-substitution edits.
// Usage: node ablate.mjs OLD_MODULE CANDIDATE_MODULE NEW_OUTPUT_DIRECTORY
import {readFileSync, writeFileSync, mkdirSync, realpathSync} from 'node:fs';
import {resolve, join} from 'node:path';
import {createHash} from 'node:crypto';

const fail = message => { throw new Error(message); };
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const args = process.argv.slice(2);
if (args.length !== 3) fail('Usage: node ablate.mjs OLD_MODULE CANDIDATE_MODULE NEW_OUTPUT_DIRECTORY');
const [oldPath, candidatePath] = args.slice(0, 2).map(path => realpathSync(path));
const out = resolve(args[2]);
const oldBytes = readFileSync(oldPath), candidateBytes = readFileSync(candidatePath);
const oldText = oldBytes.toString('utf8'), candidateText = candidateBytes.toString('utf8');
if (!Buffer.from(oldText).equals(oldBytes) || !Buffer.from(candidateText).equals(candidateBytes)) fail('Inputs must be valid UTF-8');
const oldLines = oldText.split('\n'), candidateLines = candidateText.split('\n');
if (oldLines.length !== candidateLines.length) fail('Expected identical line structure');
const changes = [];
for (let i = 0; i < oldLines.length; ++i) {
  if (oldLines[i] === candidateLines[i]) continue;
  const names = ['gen', 'subst'].filter(name => oldLines[i].startsWith(`G["${name}"]=`) && candidateLines[i].startsWith(`G["${name}"]=`));
  if (names.length !== 1 || !oldLines[i].endsWith(';') || !candidateLines[i].endsWith(';')) fail(`Unexpected difference at line ${i + 1}`);
  if (oldLines[i].includes('/* prebind-arm */') || candidateLines[i].split('/* prebind-arm */').length !== 2) fail(`Expected exactly one new prebind marker at line ${i + 1}`);
  changes.push({name: names[0], index: i, line: i + 1, oldSha256: hash(oldLines[i]), candidateSha256: hash(candidateLines[i])});
}
if (changes.length !== 2 || new Set(changes.map(x => x.name)).size !== 2) fail('Expected exactly the gen and subst registration edits');
for (const {name} of changes) {
  if (oldLines.filter(line => line.startsWith(`G["${name}"]=`)).length !== 1) fail(`Nonunique ${name} registration`);
}
const reconstructed = [...oldLines];
for (const {index} of changes) reconstructed[index] = candidateLines[index];
if (reconstructed.join('\n') !== candidateText) fail('Combined replacements do not reconstruct candidate byte-for-byte');
mkdirSync(out);
const scope = 'Diagnostic-only byte substitution into saved emitted libraries; not a checked compiler build, source optimization, or release artifact.';
const variants = changes.map(change => {
  const lines = [...oldLines];
  lines[change.index] = candidateLines[change.index];
  const bytes = Buffer.from(lines.join('\n'));
  const file = join(out, `${change.name}-only.mjs`);
  writeFileSync(file, bytes, {flag: 'wx'});
  return {id: `${change.name}-only`, file, sha256: hash(bytes), bytes: bytes.length, changedRegistration: change.name, changedLine: change.line};
});
const report = {
  kind: 'phase27-term-substitution-diagnostic-ablation', scope,
  generatedAt: new Date().toISOString(), command: process.argv,
  script: {path: realpathSync(process.argv[1]), sha256: hash(readFileSync(process.argv[1]))},
  inputs: [
    {id: 'old', path: oldPath, sha256: hash(oldBytes), bytes: oldBytes.length},
    {id: 'candidate', path: candidatePath, sha256: hash(candidateBytes), bytes: candidateBytes.length}
  ],
  guards: {exactlyTwoChangedRegistrations: true, outsideRegistrationBytesEqual: true, combinedReconstructsCandidate: true},
  changes, variants, execution: 'No modules executed or timed by this script.'
};
writeFileSync(join(out, 'receipt.json'), JSON.stringify(report, null, 2) + '\n', {flag: 'wx'});
writeFileSync(join(out, 'README.md'), `# Phase27 diagnostic ablations\n\n${scope}\n\nOnly the named registration is replaced with its exact candidate bytes. The script rejects any other input difference and verifies that both replacements reconstruct the candidate byte-for-byte. Input/output/script hashes and changed lines are in receipt.json. No execution or timing is performed.\n`, {flag: 'wx'});
process.stdout.write(JSON.stringify({out, variants, scope}) + '\n');
