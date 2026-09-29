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
const inputs=['context-controls-ctor-controls-v3.mjs','context-controls-ctor-runner-v2.mjs','context-controls-ctor-cases.json','context-controls-ctor-policy.json'].map(name=>{const original=path.join(import.meta.dirname,name),copy=path.join(frozen,name);fs.copyFileSync(original,copy);return {original:identity(original),consumed:identity(copy)};});
const contractSource=path.resolve(import.meta.dirname,'../../../../design/phase22/constructor-immutable-demand.md'),contractCopy=path.join(frozen,'constructor-immutable-demand.md');fs.copyFileSync(contractSource,contractCopy);inputs.push({original:identity(contractSource),consumed:identity(contractCopy)});
const policy=JSON.parse(fs.readFileSync(path.join(frozen,'context-controls-ctor-policy.json')));
const extension='\n// Internal demand probe; original generated API prefix is unchanged.\nexport const __ctorDemandProbe = (...args) => run_loop($f_ctor_lookup$(...args));\n';
const frozenCases=path.join(frozen,'context-controls-ctor-cases.json');
const config=JSON.parse(fs.readFileSync(frozenCases,'utf8'));
const report={kind:'phase22-paired-actual-constructor-demand',complete:false,pass:false,scope:'Internal raw-data helper controls; not public run_lib ABI or language conformance.',inputs,resources:{cpu:'2',stackKb:4096,heapMb:4096,timeoutMs:120000},extension,extensionSha256:sha(extension),lanes:[]};
write(path.join(out,'frozen-harness.json'),report);
try {
  for(const [label,dir] of [['baseline',baselineArg],['candidate',candidateArg]]) {
    const attempt=path.resolve(dir),attemptFile=path.join(attempt,'attempt.json'),a=JSON.parse(fs.readFileSync(attemptFile,'utf8'));
    const verifierFile=path.join(a.snapshot.root,'tools/development/workflow.mjs');
    const {verifyAttempt}=await import(pathToFileURL(verifierFile));await verifyAttempt(attempt);
    if(label==='baseline'&&a.api.sha256!=='a80737cd74e8b3e78b07006580ed3aded060c530b3d67af032db81a17fa3f404')throw Error('Wrong frozen parent API');
    const original=fs.readFileSync(a.api.file),probe=path.join(out,label+'-probe.mjs');
    if(sha(original)!==a.api.sha256||!original.includes(Buffer.from('function $f_ctor_lookup$(')))throw Error('API/helper identity mismatch');
    fs.writeFileSync(probe,Buffer.concat([original,Buffer.from(extension)]),{flag:'wx'});
    const bytes=fs.readFileSync(probe);if(!bytes.subarray(0,original.length).equals(original)||sha(bytes.subarray(original.length))!==sha(extension))throw Error('Probe prefix changed');
    const resultFile=path.join(out,label+'-result.json');
    const args=['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(frozen,'context-controls-ctor-runner-v2.mjs'),probe,frozenCases,resultFile];
    const env={...process.env};delete env.NODE_OPTIONS;
    const child=spawnSync('taskset',args,{encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024,env});
    fs.writeFileSync(path.join(out,label+'.stdout'),child.stdout??'');fs.writeFileSync(path.join(out,label+'.stderr'),child.stderr??'');
    const execution={command:'taskset',args,exitCode:child.status,signal:child.signal,error:child.error?String(child.error):null};
    const lane={label,attempt:identity(attemptFile),api:identity(a.api.file),checkedApi:a.checkedApi,derivation:a.derivationReport,verifier:identity(verifierFile),probe:identity(probe),originalPrefixBytes:original.length,unchangedPrefix:true,execution};report.lanes.push(lane);
    if(!fs.existsSync(resultFile))throw Error('Missing child result: '+label);
    lane.result=identity(resultFile);lane.report=JSON.parse(fs.readFileSync(resultFile,'utf8'));
    if(![0,1].includes(child.status)||child.signal||child.error||!lane.report.complete||lane.report.rows.length!==config.cases.length)throw Error('Unhealthy/incomplete lane: '+label);
    if(sha(fs.readFileSync(a.api.file))!==a.api.sha256||sha(fs.readFileSync(probe))!==lane.probe.sha256)throw Error('API/probe changed during control');
  }
  report.comparisons=config.cases.map((c,i)=>({name:c.name,pass:isDeepStrictEqual(report.lanes[0].report.rows[i].actual,report.lanes[1].report.rows[i].actual)}));
  for(const x of inputs)if(identity(x.original.file).sha256!==x.original.sha256||identity(x.consumed.file).sha256!==x.consumed.sha256)throw Error('Frozen harness changed');
  report.policy=policy;
  report.rawExactPass=report.comparisons.every(x=>x.pass)&&report.lanes.every(x=>x.report.pass);
  report.semanticComparisons=config.cases.map((c,i)=>{
    if(policy.effectfulOutOfContractCases.includes(c.name))return {name:c.name,scoped:false,reason:'Explicit prospectively excluded effectful tag witness; raw outcome retained'};
    const before=report.lanes[0].report.rows[i],after=report.lanes[1].report.rows[i];
    const observations=before.actual.map((b,j)=>{const a=after.actual[j],seen=new Set(),events=[],extras=[];
      for(const event of a.events){if(event.endsWith('.$')&&seen.has(event)){extras.push(event);continue;}seen.add(event);events.push(event);}
      return {index:j,pass:isDeepStrictEqual(a.result,b.result)&&isDeepStrictEqual(events,b.events)&&a.reads===b.reads+extras.length,additionalPreviouslyDemandedTagReads:extras};
    });
    return {name:c.name,scoped:true,pass:before.pass&&after.pass&&before.actual.length===after.actual.length&&observations.every(x=>x.pass),observations};
  });
  report.complete=true;report.pass=report.semanticComparisons.filter(x=>x.scoped).every(x=>x.pass);report.passMeaning='Prospective immutable-data semantic gate; rawExactPass remains a separate unmodified verdict';
} catch(error) {report.error={name:error.name,message:error.message,stack:error.stack};}
write(path.join(out,'report.json'),report);process.stdout.write(JSON.stringify({complete:report.complete,pass:report.pass,cases:config.cases.length,error:report.error?.message})+'\n');process.exitCode=report.pass?0:1;
