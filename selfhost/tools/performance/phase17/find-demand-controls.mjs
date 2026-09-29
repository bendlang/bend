// Freeze original tools, bind authentic APIs, append one internal probe export.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {isDeepStrictEqual} from 'node:util';
const [baselineArg,candidateArg,outputArg]=process.argv.slice(2);
const out=path.resolve(outputArg);fs.mkdirSync(out);
const sha=b=>createHash('sha256').update(b).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:sha(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const write=(file,data)=>fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n',{flag:'wx'});
const frozen=path.join(out,'consumed');fs.mkdirSync(frozen);
const inputs=['find-demand-controls.mjs','find-demand-runner.mjs','find-demand-cases.json'].map(name=>{const original=path.join(import.meta.dirname,name),copy=path.join(frozen,name);fs.copyFileSync(original,copy);return {original:identity(original),consumed:identity(copy)};});
const extension='\n// Internal demand probe; original generated API prefix is unchanged.\nexport const __findDemandProbe = (...args) => run_loop($f_find$(...args));\n';
const frozenCases=path.join(frozen,'find-demand-cases.json');
const config=JSON.parse(fs.readFileSync(frozenCases,'utf8'));
const report={kind:'phase17-paired-actual-find-demand',complete:false,pass:false,scope:'Internal raw-data helper controls; not public run_lib ABI or language conformance.',inputs,resources:{cpu:'2',stackKb:4096,heapMb:4096,timeoutMs:120000},extension,extensionSha256:sha(extension),lanes:[]};
write(path.join(out,'frozen-harness.json'),report);
try {
  for(const [label,dir] of [['baseline',baselineArg],['candidate',candidateArg]]) {
    const attempt=path.resolve(dir),attemptFile=path.join(attempt,'attempt.json'),a=JSON.parse(fs.readFileSync(attemptFile,'utf8'));
    const verifierFile=path.join(a.snapshot.root,'tools/development/workflow.mjs');
    const {verifyAttempt}=await import(pathToFileURL(verifierFile));await verifyAttempt(attempt);
    if(label==='baseline'&&a.api.sha256!=='35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315')throw Error('Wrong installed baseline API');
    const original=fs.readFileSync(a.api.file),probe=path.join(out,label+'-probe.mjs');
    if(sha(original)!==a.api.sha256||!original.includes(Buffer.from('function $f_find$(')))throw Error('API/helper identity mismatch');
    fs.writeFileSync(probe,Buffer.concat([original,Buffer.from(extension)]),{flag:'wx'});
    const bytes=fs.readFileSync(probe);if(!bytes.subarray(0,original.length).equals(original)||sha(bytes.subarray(original.length))!==sha(extension))throw Error('Probe prefix changed');
    const resultFile=path.join(out,label+'-result.json');
    const args=['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(frozen,'find-demand-runner.mjs'),probe,frozenCases,resultFile];
    const env={...process.env};delete env.NODE_OPTIONS;
    const child=spawnSync('taskset',args,{encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024,env});
    fs.writeFileSync(path.join(out,label+'.stdout'),child.stdout??'');fs.writeFileSync(path.join(out,label+'.stderr'),child.stderr??'');
    const execution={command:'taskset',args,exitCode:child.status,signal:child.signal,error:child.error?String(child.error):null};
    const lane={label,attempt:identity(attemptFile),api:identity(a.api.file),checkedApi:a.checkedApi,derivation:a.derivationReport,verifier:identity(verifierFile),probe:identity(probe),originalPrefixBytes:original.length,unchangedPrefix:true,execution};report.lanes.push(lane);
    if(!fs.existsSync(resultFile))throw Error('Missing child result: '+label);
    lane.result=identity(resultFile);lane.report=JSON.parse(fs.readFileSync(resultFile,'utf8'));
    if(child.status!==0||child.signal||child.error||!lane.report.complete||!lane.report.pass||lane.report.rows.length!==config.cases.length)throw Error('Unhealthy/failed lane: '+label);
    if(sha(fs.readFileSync(a.api.file))!==a.api.sha256||sha(fs.readFileSync(probe))!==lane.probe.sha256)throw Error('API/probe changed during control');
  }
  report.comparisons=config.cases.map((c,i)=>({name:c.name,pass:isDeepStrictEqual(report.lanes[0].report.rows[i].actual,report.lanes[1].report.rows[i].actual)}));
  for(const x of inputs)if(identity(x.original.file).sha256!==x.original.sha256||identity(x.consumed.file).sha256!==x.consumed.sha256)throw Error('Frozen harness changed');
  report.complete=true;report.pass=report.comparisons.every(x=>x.pass);
} catch(error) {report.error={name:error.name,message:error.message,stack:error.stack};}
write(path.join(out,'report.json'),report);process.stdout.write(JSON.stringify({complete:report.complete,pass:report.pass,cases:config.cases.length,error:report.error?.message})+'\n');process.exitCode=report.pass?0:1;
