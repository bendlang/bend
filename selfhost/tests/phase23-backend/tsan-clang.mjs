// Bounded ThreadSanitizer attempt on identical saved emitted sources.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const run=path.resolve(process.argv[2]),out=path.resolve(process.argv[3]);if(fs.existsSync(out))throw Error('Use a fresh output directory');fs.mkdirSync(out,{recursive:true});
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const environment=JSON.parse(fs.readFileSync(new URL('../../build/phase16/wave6-backend-environment-01.json',import.meta.url))).environment;
const report={kind:'phase23-paired-clang-gcc-tsan-attempt',complete:false,pass:false,compiler:environment.CC,linker:'/usr/bin/gcc',environment,rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));save();
for(const side of ['reference','candidate']){
 const artifacts=path.join(run,'selected',side+'.json.artifacts');let source;
 for(const child of fs.readdirSync(artifacts)){const file=path.join(artifacts,child,'request.json');if(!fs.existsSync(file))continue;const r=JSON.parse(fs.readFileSync(file));if(r.lane==='native'&&r.test.id==='run/array_redirect_race.bend')source=path.join(artifacts,child,'array_redirect_race.c');}
 if(!source)throw Error('Missing race source '+side);
 const binary=path.join(out,side),object=binary+'.o',args=['-O1','-g','-fsanitize=thread','-fno-omit-frame-pointer','-pthread','-c',source,'-o',object];
 const cc=spawnSync(environment.CC,args,{encoding:'utf8',timeout:30000,maxBuffer:1<<20,env:{...process.env,...environment}});
 const row={side,source:{file:source,sha256:sha(source)},command:[environment.CC,...args],compile:{status:cc.status,signal:cc.signal,error:cc.error?.message??null,stdout:cc.stdout,stderr:cc.stderr},pass:false};
 if(cc.status===0){const linkArgs=[object,'-fsanitize=thread','-pthread','-lm','-o',binary],link=spawnSync('/usr/bin/gcc',linkArgs,{encoding:'utf8',timeout:30000,maxBuffer:1<<20});row.link={command:['/usr/bin/gcc',...linkArgs],status:link.status,signal:link.signal,error:link.error?.message??null,stdout:link.stdout,stderr:link.stderr};
 if(link.status===0){row.binarySha256=sha(binary);const r=spawnSync('taskset',['-c','3,4,5,6',binary,'--threads','4','--gpu','off'],{encoding:'utf8',timeout:10000,maxBuffer:1<<20,env:{...process.env,TSAN_OPTIONS:'halt_on_error=1:exitcode=66'}});row.run={status:r.status,signal:r.signal,error:r.error?.message??null,stdout:r.stdout,stderr:r.stderr};row.pass=r.status===0&&r.stdout==='256\n'&&r.stderr==='';}}
 report.rows.push(row);save();
}
report.complete=true;report.pass=report.rows.every(x=>x.pass);save();console.log(JSON.stringify({complete:true,pass:report.pass,rows:report.rows.map(r=>({side:r.side,compile:r.compile.status,link:r.link?.status,run:r.run?.status,pass:r.pass,stderr:(r.run?.stderr||r.link?.stderr||r.compile.stderr).slice(0,800)}))}));process.exitCode=report.pass?0:1;
