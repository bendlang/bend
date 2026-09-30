// Corpus identity and workload definitions; no compilation or benchmark on import.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const directory=import.meta.dirname;
export const upstreamPin='018751270e800bc222a93dad7f257083ee53a5f7';
export const exportContract={name:'bench',arguments:['U32','U32'],result:'U32',runtimeInputs:true};
export const cases=JSON.parse(fs.readFileSync(path.join(directory,'corpus/metadata.json'),'utf8')).map(row=>{
  const file=path.join(directory,row.relativeFile);
  const sha256=createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  return Object.freeze({...row,file,sha256});
});
export default cases;

if(process.argv[1] && path.resolve(process.argv[1])===import.meta.filename) console.log(JSON.stringify(cases,null,2));
