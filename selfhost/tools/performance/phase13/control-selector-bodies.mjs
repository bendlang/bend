// Supplementary byte identity gate for actual selected normalizer branch bodies.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
const out=path.resolve(process.argv[2]),root=path.resolve(import.meta.dirname,'../../..');
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const dependency=path.join(import.meta.dirname,'rewriter-structure.mjs'),copy=path.join(out,'consumed-structure.mjs');fs.copyFileSync(dependency,copy);
const {moduleView,sha}=await import(pathToFileURL(copy));
const baseline=path.join(root,'build/phase12/integrated-03/api.mjs'),candidate=path.join(root,'build/phase13/selector-norm-eval-02/api.mjs');
const report={kind:'phase13-independent-actual-selector-body-identity',complete:false,pass:false,inputs:[import.meta.filename,process.execPath,dependency,copy,baseline,candidate].map(identity)};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
function arrows(file){const source=fs.readFileSync(file,'utf8'),view=moduleView(source),owner=view.functions.get('$norm_eval_node$'),result=[];assert.ok(owner);for(let i=owner.body+1;i<owner.end;i++){if(view.ts[i].text!=='(')continue;const body=view.ts[i].close+3;if(view.ts[body]?.text!=='{')continue;const arrow=view.arrow([i,view.ts[body].close+1]);if(arrow){const bytes=source.slice(view.ts[arrow.range[0]].start,view.ts[arrow.range[1]-1].end);result.push({param:arrow.param,start:view.ts[i].start,end:view.ts[arrow.end].end,sha256:sha(bytes),source:bytes});}}return result;}
try{report.baseline=arrows(baseline);report.candidate=arrows(candidate);assert.equal(report.baseline.length,14);assert.equal(report.candidate.length,9);const remaining=[...report.baseline];report.matches=[];for(const candidate of report.candidate){const i=remaining.findIndex(original=>original.source===candidate.source);assert.ok(i>=0,'Actual surviving arrow changed: '+candidate.param);report.matches.push({candidate:candidate.start,baseline:remaining[i].start,sha256:candidate.sha256});remaining.splice(i,1);}report.removed=remaining;assert.equal(remaining.length,5);report.inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;report.pass=true;}catch(e){report.error=e.stack;process.exitCode=1;}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,baseline:report.baseline?.length,candidate:report.candidate?.length,matches:report.matches?.length,error:report.error}));
