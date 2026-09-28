import fs from 'node:fs';import {pathToFileURL} from 'node:url';
const [driver,file,out]=process.argv.slice(2);const {loadApi,inspect}=await import(pathToFileURL(driver));const api=await loadApi();const original=api.j_layout_error;let layout;
api.j_layout_error=(...args)=>{globalThis.__layoutCounts={};const start=performance.now();const error=original(...args);layout={ms:performance.now()-start,error,counts:{...globalThis.__layoutCounts}};throw Error('P10_DIAGNOSTIC_STOP_AFTER_LAYOUT');};
const observation=await inspect(file,{api,mode:'compile'});fs.writeFileSync(out,JSON.stringify({layout,observation},null,2)+'\n');if(!layout)process.exitCode=1;
