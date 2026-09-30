// Extend the frozen original guard suite with the newly discovered refusal edge.
// The derived file and exact parent/derivation identities remain in the run tree.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
const [config,outArgument]=process.argv.slice(2),out=path.resolve(outArgument);
const parent=path.join(import.meta.dirname,'controls-worker-guards.mjs');
const source=fs.readFileSync(parent,'utf8'),needle="  no('non-predecessor-first',";
assert.equal(source.split(needle).length,2,'exact frozen insertion point');
const addition=`  {
    const def=definition(),succ=array(def.value.kids)[1];
    succ.kids=list([mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,v(11))))),t('Efq')]);
    no('zero-successor-lambda-prefix-nested-match',def);
  }
  {
    const def=definition(),succ=array(def.value.kids)[1];
    succ.kids=list([lit(0),t('Efq')]);
    no('zero-successor-lambda-prefix-literal',def);
  }
  {
    const def=definition(),succ=array(def.value.kids)[1];
    succ.kids=list([lam(10,lit(0)),t('Efq')]);
    no('one-successor-lambda-prefix',def);
  }
  {
    const def=definition(),succ=array(def.value.kids)[1];let body=lit(0);
    for(let i=80;i>=10;i--)body=lam(i,body);
    succ.kids=list([body,t('Efq')]);
    no('oversize-successor-lambda-prefix',def);
  }
`;
const derived=out+'.guards.mjs',text=source.replace(needle,addition+needle),sha=x=>createHash('sha256').update(x).digest('hex');
fs.writeFileSync(derived,text,{flag:'wx'});
fs.writeFileSync(out+'.derivation.json',JSON.stringify({kind:'phase29-independent-worker-guard-frontier',parent:{file:parent,sha256:sha(source)},tool:{file:import.meta.filename,sha256:sha(fs.readFileSync(import.meta.filename))},derived:{file:derived,sha256:sha(text)},needle,addition},null,2)+'\n',{flag:'wx'});
const child=spawnSync(process.execPath,[...process.execArgv,derived,path.resolve(config),out],{stdio:'inherit',timeout:120000});
assert.equal(sha(fs.readFileSync(parent)),sha(source),'parent remains unchanged');
if(child.error)throw child.error;process.exitCode=child.status??1;
