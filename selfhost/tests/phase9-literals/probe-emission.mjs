import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
const [driver,input,mode,output]=process.argv.slice(2);
const {inspect}=await import(pathToFileURL(driver));
const result=await inspect(input,{mode,timeoutMs:60000,withReport:true,combinedOutput:true});
if(result.code){fs.writeFileSync(output+(mode==='native'?'.c':'.js'),result.code);result.codeBytes=Buffer.byteLength(result.code);delete result.code;}
fs.writeFileSync(output,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
