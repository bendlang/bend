#!/usr/bin/env node
// Focused structural formatter boundaries; no compiler or generated code timing.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const root=path.resolve(import.meta.dirname,'../../../..'),out=path.resolve(process.argv[2]);
fs.mkdirSync(out,{recursive:false});
const file=path.join(root,'selfhost/tools/stage0-library.mjs'),text=fs.readFileSync(file,'utf8');
const begin=text.indexOf('const short='),end=text.indexOf('\ntry{',begin);
assert.ok(begin>=0&&end>begin);
const context={path,process:{argv:['node','adapter','input.bend']}};
vm.runInNewContext(text.slice(begin,end)+'\nthis.format=bootstrapError;',context,{timeout:1000});
const rows=[],check=(name,error,pattern)=>{const result=context.format(error);assert.match(result,pattern);assert.ok(result.length<2400);rows.push({name,result});};
check('zero position with leading newline',{exp:'message',spn:{file:{str:'\n',ns:'leading'},beg:0,end:0}},/leading:1:1\n1 \| /);
check('named hole and definition',{exp:'a value',obs:{$:'Hol',k:'missing'},def:'test'},/observed : \?missing\nLocation: test/);
check('source line and column',{exp:'message',spn:{file:{str:'first\n  bad\n',ns:'fixture'},beg:8,end:11}},/fixture:2:3\n2 \|   bad/);
const term={$:'Ctr',k:'KDef'},book={};term.cycle=term;book.self=book;
check('cyclic context and source metadata are not traversed',{exp:'x'.repeat(10000),obs:term,ctx:book,bok:book,spn:{file:{str:'x'.repeat(10000),book},beg:0,end:9999},nte:'n'.repeat(10000)},/observed : KDef\{…\}/);
const ident=p=>({file:fs.realpathSync(p),sha256:crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')});
const report={kind:'phase30-bootstrap-format-boundaries',complete:true,pass:true,inputs:[ident(import.meta.filename),ident(file)],observations:rows};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));fs.copyFileSync(file,path.join(out,'stage0-library.mjs'));
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:true,pass:true,checks:rows.length}));
