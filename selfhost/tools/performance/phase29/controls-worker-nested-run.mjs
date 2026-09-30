// Focused checked-source regression; modules must have separate checked receipts.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2),config=JSON.parse(fs.readFileSync(configFile)),out=path.resolve(outArgument);
fs.mkdirSync(out,{recursive:false});
const sha=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const inputs=[configFile,import.meta.filename,...Object.values(config.modules)].map(file=>({file:fs.realpathSync(file),sha256:sha(file)}));
const report={kind:'phase29-nested-Nat-regression',complete:false,pass:false,inputs,node:process.version,args:process.execArgv,checks:0,shapes:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls-worker-nested-run.mjs'));
try{
  assert.deepEqual(Object.keys(config.modules).sort(),['baseline','candidate','upstream']);
  for(const [side,file]of Object.entries(config.modules)){
    const {default:api}=await import(pathToFileURL(file));
    for(const n of [0n,1n,2n,3n,4n,31n,4294967295n,281474976710655n]){
      for(const x of [0,1,2147483648,4294967295]){assert.equal(api.nested(n,x),(Number(n&0xffffffffn)+x)>>>0,side+' nested');report.checks++;}
      assert.equal(api.nested_nullary(n),n===0n?7:n===1n?11:(13+Number((n-2n)&0xffffffffn))>>>0,side+' nested_nullary');report.checks++;
      assert.equal(api.no_residual(n),n===0n?17:(19+Number((n-1n)&0xffffffffn))>>>0,side+' no_residual');report.checks++;
    }
    if(side==='candidate')for(const name of ['nested','nested_nullary','no_residual']){
      const lines=fs.readFileSync(file,'utf8').split('\n').filter(s=>s.startsWith('G['+JSON.stringify(name)+']='));assert.equal(lines.length,1);assert.ok(!lines[0].includes('/* private Nat loop */'),name+' fallback');report.shapes.push({name,loop:false});
    }
  }
  assert.deepEqual(inputs.filter(x=>sha(x.file)!==x.sha256),[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,checks:report.checks,error:report.error}));
