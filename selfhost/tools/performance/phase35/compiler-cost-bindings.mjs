// Read-only binding of normal checked attempts and their existing Base caches.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [attemptArg,outArg]=process.argv.slice(2),attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg);
assert(!fs.existsSync(out));
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const raw=JSON.parse(fs.readFileSync(path.join(attempt,'attempt.json'))),verifier=path.join(raw.snapshot.root,'tools/development/workflow.mjs');
const helper=await import(pathToFileURL(verifier)),m=await helper.verifyAttempt(attempt);
assert(m.checked&&m.config.strictExact);assert.equal(m.config.jobs,1);assert(m.config.heapMb<=1024);
const cache=helper.validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
const driver=path.join(m.snapshot.root,'tools/typed-driver.mjs');
const inputs=[import.meta.filename,process.execPath,path.join(attempt,'attempt.json'),verifier,driver,
 ...[m.node,m.api,m.runtime,m.base,m.bootstrapReport,...m.artifacts,...m.snapshot.sources.map(x=>x.frozen),...(cache?[cache]:[])].map(x=>x.file)].map(identity);
const data={complete:true,attempt,manifest:identity(path.join(attempt,'attempt.json')),verifier:identity(verifier),
 api:m.api,runtime:m.runtime,base:m.base,driver:identity(driver),upstream:m.config.upstream,cache,inputs};
fs.writeFileSync(out,JSON.stringify(data,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,api:m.api.sha256,cache:cache?.sha256??null,output:out}));
