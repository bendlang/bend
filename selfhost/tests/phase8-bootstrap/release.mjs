#!/usr/bin/env node
// Verify relocated release packages using authentic retained artifacts. No build
// or default installation occurs; negative cases mutate only disposable packages.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {verifyRelease} from '../../tools/development/release.mjs';
const project=path.resolve(import.meta.dirname,'../..');
if(!process.argv[2])throw Error('Usage: release.mjs NEW_OUTPUT_DIRECTORY');
const output=path.resolve(process.argv[2]);fs.mkdirSync(output,{recursive:false});
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const original=read(path.join(project,'dist/release.json'));
assert.equal(original.kind,'bend-default-equality-release','This fixture reuses the retained legacy equality release');
const bootstrap=read(path.join(project,'dist/release-lineage/checked-bootstrap.json'));
const snapshot=path.dirname(path.dirname(bootstrap.provenance.inputs.find(x=>x.role==='host-tool'&&path.basename(x.file)==='typed-driver.mjs').file));
const sourceFor=item=>{
 const candidates=[path.join(project,item.path),path.join(snapshot,item.path),...bootstrap.provenance.inputs.filter(x=>x.sha256===item.sha256).map(x=>x.file)];
 const source=candidates.find(file=>fs.existsSync(file)&&sha(file)===item.sha256);
 assert.ok(source,'Historical bytes unavailable for '+item.path);return source;
};
const copy=(source,target)=>{fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(source,target);};
const legacy=path.join(output,'legacy'),checked=path.join(output,'checked');
for(const item of [...original.files,...original.checkout])copy(sourceFor(item),path.join(legacy,item.path));
copy(path.join(project,'dist/release.json'),path.join(legacy,'dist/release.json'));
const report={kind:'phase8-relocated-release-verification-controls',started:new Date().toISOString(),scope:'Authentic historical equality/checked-parent files, relocated verification and negative metadata/byte controls only; no new compiler build or installation.',releaseTool:{file:path.join(project,'tools/development/release.mjs'),sha256:sha(path.join(project,'tools/development/release.mjs'))},sourceRelease:{file:path.join(project,'dist/release.json'),sha256:sha(path.join(project,'dist/release.json'))},rows:[],complete:false,pass:false};
const save=()=>write(path.join(output,'report.json'),report);
const record=(name,fn)=>{try{fn();report.rows.push({name,pass:true});}catch(error){report.rows.push({name,pass:false,error:String(error.stack??error)});}save();};
record('historical equality release verifies after relocation',()=>assert.equal(verifyRelease(legacy).artifact,'equality-derived-b1'));
fs.cpSync(legacy,checked,{recursive:true});
copy(path.join(checked,'dist/release-lineage/checked-api.mjs'),path.join(checked,'dist/typed-api.mjs'));
for(const name of ['derivation.json','equality.mjs'])fs.rmSync(path.join(checked,'dist/release-lineage',name));
const fixture=structuredClone(original),recordFile=file=>({path:file,sha256:sha(path.join(checked,file)),bytes:fs.statSync(path.join(checked,file)).size});
fixture.kind='bend-default-checked-release';fixture.artifact='checked-b1';
fixture.files=['dist/typed-api.mjs','dist/base.bend','dist/release-lineage/checked-api.mjs','dist/release-lineage/checked-bootstrap.json'].map(recordFile);
const recipe=bootstrap.provenance.inputs.find(x=>x.role==='host-tool'&&path.basename(x.file)==='stage0-library.mjs');
copy(recipe.file,path.join(checked,'tools/stage0-library.mjs'));
fixture.checkout.push(recordFile('tools/stage0-library.mjs'));
fixture.lineage={checkedApiSha256:bootstrap.apiSha256,bootstrapSha256:sha(path.join(checked,'dist/release-lineage/checked-bootstrap.json')),upstreamRevision:bootstrap.revision};
fixture.provenanceScope='Test package of the genuine historical checked parent; no new bootstrap or default installation.';
write(path.join(checked,'dist/release.json'),fixture);
record('genuine historical checked parent verifies as relocated checked package',()=>assert.equal(verifyRelease(checked).artifact,'checked-b1'));
const manifestPath=path.join(checked,'dist/release.json');
const patchRecord=(m,file)=>{for(const list of [m.files,m.checkout]){const item=list.find(x=>x.path===file);if(item)Object.assign(item,recordFile(file));}};
const negative=(name,files,change)=>{
 const backups=files.map(file=>[file,fs.existsSync(path.join(checked,file))?fs.readFileSync(path.join(checked,file)):null]);
 const m=structuredClone(fixture);
 try{change(m);write(manifestPath,m);record(name,()=>assert.throws(()=>verifyRelease(checked)));}
 finally{for(const [file,bytes]of backups){const target=path.join(checked,file);if(bytes===null)fs.rmSync(target,{force:true});else fs.writeFileSync(target,bytes);}write(manifestPath,fixture);}
};
negative('different checked default bytes reject even with updated file identity',['dist/typed-api.mjs'],m=>{fs.appendFileSync(path.join(checked,'dist/typed-api.mjs'),'\n// changed\n');patchRecord(m,'dist/typed-api.mjs');});
negative('changed Base rejects even with updated file identity',['dist/base.bend'],m=>{fs.appendFileSync(path.join(checked,'dist/base.bend'),'\n# changed\n');patchRecord(m,'dist/base.bend');});
const module=bootstrap.modules[0].file;
negative('changed compiler module rejects even with updated checkout identity',[module],m=>{fs.appendFileSync(path.join(checked,module),'\n# changed\n');patchRecord(m,module);});
negative('missing compiler module checkout identity rejects',[],m=>{m.checkout=m.checkout.filter(x=>x.path!==module);});
negative('changed bootstrap recipe rejects even with updated checkout identity',['tools/stage0-library.mjs'],m=>{fs.appendFileSync(path.join(checked,'tools/stage0-library.mjs'),'\n// changed\n');patchRecord(m,'tools/stage0-library.mjs');});
negative('different source target rejects',['src/compiler.json'],m=>{const source=read(path.join(checked,'src/compiler.json'));source.upstream='0'.repeat(40);write(path.join(checked,'src/compiler.json'),source);patchRecord(m,'src/compiler.json');});
negative('unchecked bootstrap metadata rejects',['dist/release-lineage/checked-bootstrap.json'],m=>{const b=structuredClone(bootstrap);b.provenance.verifiedAfterBuild=false;write(path.join(checked,'dist/release-lineage/checked-bootstrap.json'),b);patchRecord(m,'dist/release-lineage/checked-bootstrap.json');m.lineage.bootstrapSha256=sha(path.join(checked,'dist/release-lineage/checked-bootstrap.json'));});
negative('missing assembled source provenance rejects',['dist/release-lineage/checked-bootstrap.json'],m=>{const b=structuredClone(bootstrap);b.provenance.inputs=b.provenance.inputs.filter(x=>x.role!=='assembled-source');write(path.join(checked,'dist/release-lineage/checked-bootstrap.json'),b);patchRecord(m,'dist/release-lineage/checked-bootstrap.json');m.lineage.bootstrapSha256=sha(path.join(checked,'dist/release-lineage/checked-bootstrap.json'));});
negative('mismatched checked API lineage rejects',[],m=>{m.lineage.checkedApiSha256='0'.repeat(64);});
negative('duplicate file identity rejects',[],m=>{m.files.push({...m.files[0]});});
negative('stale equality lineage rejects',['dist/release-lineage/derivation.json'],()=>write(path.join(checked,'dist/release-lineage/derivation.json'),{}));
negative('misplaced bootstrap sidecar rejects',['dist/typed-api.mjs.bootstrap.json'],()=>write(path.join(checked,'dist/typed-api.mjs.bootstrap.json'),bootstrap));
record('checked package still verifies after restored negative cases',()=>assert.equal(verifyRelease(checked).artifact,'checked-b1'));
record('release implementation unchanged during tests',()=>assert.equal(sha(report.releaseTool.file),report.releaseTool.sha256));
record('original installed release manifest unchanged',()=>assert.equal(sha(report.sourceRelease.file),report.sourceRelease.sha256));
report.complete=true;report.pass=report.rows.every(x=>x.pass);report.finished=new Date().toISOString();save();
console.log(JSON.stringify({output,total:report.rows.length,passed:report.rows.filter(x=>x.pass).length,pass:report.pass}));
if(!report.pass)process.exitCode=1;
