import fs from 'node:fs';
import path from 'node:path';
import {describeFixture,expectation,probes,sha256} from './inventory.mjs';
export const successful = row => ['pass','not-applicable'].includes(row.status)||(row.lane==='parse'&&row.status==='observed');
export const probeKey = row => row.id+'\0'+row.lane;
export function selectProbes(manifest,{selection='',rerun='',filter='',lanes=[]}={}) {
  const known=new Map(manifest.tests.map(test=>[test.id,test])),external=[];
  let requested,previous;
  if(selection){
    const document=JSON.parse(fs.readFileSync(selection,'utf8')),entries=Array.isArray(document)?document:document.cases;
    if(!Array.isArray(entries)||!entries.length)throw Error('Selection must contain a nonempty cases array');
    requested=[];
    for(const entry of entries){
      if(!entry||typeof entry!=='object')throw Error('Invalid selection entry');
      if(entry.file){
        const file=fs.realpathSync(path.resolve(path.dirname(selection),entry.file)),id=entry.id||'local/'+path.basename(file);
        if(known.has(id)&&known.get(id).file!==file)throw Error('Fixture ID collision: '+id);
        if(!known.has(id)){
          const test=describeFixture(file,id);
          if(entry.expected!==undefined){if(typeof entry.expected!=='string')throw Error('Expected oracle must be text');Object.assign(test,expectation(entry.expected));test.hasExpectation=true;}
          if(!test.hasExpectation&&typeof entry.accept==='boolean'){test.oracle='acceptance';test.accept=entry.accept;test.rejectPhase=entry.rejectPhase??null;test.negative=!entry.accept;}
          else if(!test.hasExpectation)throw Error('External fixture requires #| oracle, explicit expected, or explicit accept/rejectPhase: '+file);
          known.set(id,test);external.push(test);
        }
      }
      const id=entry.id||(entry.file?'local/'+path.basename(entry.file):undefined),test=known.get(id);
      if(!test)throw Error('Unknown fixture: '+id);
      const wanted=entry.lanes||(entry.lane?[entry.lane]:lanes);
      if(!Array.isArray(wanted)||!wanted.length)throw Error('Selection entry needs lane(s): '+id);
      for(const lane of wanted){
        if(!probes(test).some(probe=>probe.lane===lane))throw Error('Ineligible or unknown probe: '+id+' '+lane);
        requested.push({test,lane});
      }
    }
  }
  if(rerun){
    const text=fs.readFileSync(rerun,'utf8'),prior=JSON.parse(text);
    if(!Array.isArray(prior.results))throw Error('Rerun requires a conformance report');
    if(prior.inventory?.revision!==manifest.revision)throw Error('Rerun upstream pin differs');
    previous={file:path.resolve(rerun),sha256:sha256(text)};
    const priorFixtures=new Map((prior.inventory.tests||[]).map(test=>[test.id,test]));
    for(const row of prior.results){const priorTest=priorFixtures.get(row.id),current=known.get(row.id);if(!priorTest)throw Error('Rerun fixture absent from prior inventory: '+row.id);if(current&&(current.file!==priorTest.file||current.sha256!==priorTest.sha256))throw Error('Rerun fixture identity differs: '+row.id);}
    const failures=prior.results.filter(row=>!successful(row)),failed=new Set(failures.map(probeKey));
    if(!requested)requested=failures.map(row=>{
      const test=known.get(row.id)||prior.inventory.tests.find(test=>test.id===row.id);
      if(!test||sha256(fs.readFileSync(test.file))!==test.sha256)throw Error('Rerun fixture missing or changed: '+row.id);
      if(!known.has(test.id)){known.set(test.id,test);external.push(test);}
      return {test,lane:row.lane};
    });
    requested=requested.map((job,index)=>({...job,index})).sort((a,b)=>Number(failed.has(probeKey({id:b.test.id,lane:b.lane})))-Number(failed.has(probeKey({id:a.test.id,lane:a.lane})))||a.index-b.index).map(({index,...job})=>job);
  }
  if(!requested){const matches=new RegExp(filter);requested=manifest.tests.filter(test=>matches.test(test.id)).flatMap(test=>probes(test).filter(p=>lanes.includes(p.lane)).map(p=>({test,...p})));}
  if(!requested.length)throw Error('No probes selected');
  const seen=new Set();for(const job of requested){if(!probes(job.test).some(probe=>probe.lane===job.lane))throw Error('Ineligible rerun probe: '+job.test.id+' '+job.lane);const key=probeKey({id:job.test.id,lane:job.lane});if(seen.has(key))throw Error('Duplicate selected probe: '+job.test.id+' '+job.lane);seen.add(key);}
  return {jobs:requested,tests:[...new Map(requested.map(job=>[job.test.id,job.test])).values()],external,previous};
}
