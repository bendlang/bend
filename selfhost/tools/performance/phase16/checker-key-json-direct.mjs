import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../../../..'),build=path.resolve(process.argv[2]),out=path.resolve(process.argv[3]);fs.mkdirSync(out);const w=await import(pathToFileURL(path.join(build,'snapshot/tools/development/workflow.mjs'))),m=await w.verifyAttempt(build),tsFile=path.join(root,'selfhost/.bootstrap/upstream-phase8/bend2/bend.ts'),B=await import(pathToFileURL(tsFile)),a=(await import(pathToFileURL(m.api.file))).default;const inputs=[import.meta.filename,m.api.file,tsFile,path.join(root,'design/phase16/checker-canonical-memo-json.md')].map(w.identity);const report={kind:'phase16-canonical-memo-json-direct',complete:false,inputs,rows:[]};const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil),k=(tag,name='',id=0,quant=0,kids=[],removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0}),lit=(kind,number=0,text='')=>({$:'KLiteral',kind,number,text,originBegin:0,originEnd:0}),lam=(name,id,quant,present,body)=>({$:'KLambda',name,id,quant,kids:list([body]),removed:nil,originBegin:0,originEnd:0,quantityPresent:present}),qty=q=>q===0?B.None():q===2?B.Many():B.Lone(),ktype=k('Typ','',0,0,[k('Qua','',0,1)]),btype=B.Typ(B.Qua(B.Lone()));
const cases=[];const add=(name,core,ts)=>cases.push({name,core,ts});
add('ref-token-position',k('Ref','test',120,1),B.Ref('test'));add('ref-offload',k('Ref','test',120,3),B.Ref('test',undefined,true));
for(const q of [0,1,2])add('quantity'+q,k('Qua','',99,q),B.Qua(qty(q)));
add('type',ktype,btype);add('min',k('Min','',0,0,[k('Qua','',0,1),k('Qua','',0,2)]),B.Min(B.Qua(B.Lone()),B.Qua(B.Many())));
for(const [kind,n,text] of [['Nat',4294967295,''],['U32',4294967295,''],['F32',2147483648,''],['F32',2143289344,''],['String',0,'a\0\b\t\n\f\r\u0001"\\😃\u2028']])add('literal/'+kind+'/'+n,lit(kind,n,text),B.Lit(kind,kind==='String'?text:n));
add('ctr',k('Ctr','C',444,1,[lit('U32',4)]),B.Ctr('C',[B.Lit('U32',4)]));add('adt-removed',k('ADT','D',555,2,[k('Qua','',0,2)],['One','Two']),B.ADT('D',[B.Qua(B.Many())],undefined,['One','Two']));
for(const present of [false,true])for(const q of [0,1,2])add('lambda/'+present+'/'+q,lam('x',17,q,present,k('Var','original-name',17)),B.Lam('x',17,B.Var('original-name',17),undefined,present?qty(q):undefined));
add('nested-shadow',lam('x',17,1,true,lam('x',21,1,false,k('App','',0,0,[k('Var','wrong',17),k('Var','wrong',21)]))),B.Lam('x',17,B.Lam('x',21,B.App(B.Var('wrong',17),B.Var('wrong',21))),undefined,B.Lone()));
add('all',k('All','A',17,0,[btype?ktype:null,k('Var','not-A',17)]),B.All(B.None(),'A',17,btype,B.Var('not-A',17)));
add('app',k('App','',0,0,[k('Ref','f',9),lit('Nat',1)]),B.App(B.Ref('f'),B.Lit('Nat',1)));
add('ann',k('Ann','',0,0,[lit('U32',4),k('ADT','U32')]),B.Ann(B.Lit('U32',4),B.ADT('U32',[])));
add('mat',k('Mat','C',999,1,[lam('x',9,1,true,k('Var','x',9)),k('Efq')]),B.Mat('C',B.Lam('x',9,B.Var('x',9),undefined,B.Lone()),B.Efq()));
add('eql',k('Eql','',0,0,[lit('Nat',1),lit('Nat',2),k('ADT','Nat')]),B.Eql(B.Lit('Nat',1),B.Lit('Nat',2),B.ADT('Nat',[])));
add('rwt',k('Rwt','',0,0,[k('Rfl'),lam('_',9,1,false,lam('proof',10,1,false,ktype)),k('ADT','Nat')]),B.Rwt(B.Rfl(),B.Lam('_',9,B.Lam('proof',10,btype)),B.ADT('Nat',[])));
for(const tag of ['Qnt','Efq','Rfl'])add(tag,k(tag),B[tag]());add('hole',k('Hol','TODO'),B.Hol('TODO'));
add('parallel-let',k('Let','',0,0,[k('Bind','x',17,0,[lit('Nat',3)]),k('Bind','y',21,2,[lit('Nat',4)]),k('App','',0,0,[k('Var','bad',17),k('Var','bad',21)])]),B.Let(['x','y'],[17,21],[B.Lit('Nat',3),B.Lit('Nat',4)],B.App(B.Var('bad',17),B.Var('bad',21)),undefined,[B.None(),B.Many()]));
add('let-outer-value',lam('outer',7,1,true,k('Let','',0,0,[k('Bind','x',17,1,[k('Var','outer',7)]),k('Var','x',17)])),B.Lam('outer',7,B.Let(['x'],[17],[B.Var('outer',7)],B.Var('x',17)),undefined,B.Lone()));
add('free-variable-negative-sentinel',k('Var','unbound',4294967295),B.Var('unbound',-1));
add('force-cell',k('Var','cell',4294967295,0,[lit('U32',4)]),B.Var('cell',-1,undefined,B.Lit('U32',4)));
add('substitution',k('Sub','',17,0,[k('Ctr','C'),k('Var','x',17)]),B.Sub(17,{$:'PCtr',k:'C',x:[]},B.Var('x',17)));
try{
 for(const c of cases){const ref=B.term_key(B.term_lower(B.term_higher(c.ts))),key=a.term_key(c.core);report.rows.push({name:c.name,reference:ref,candidate:key,exact:key===ref});assert.equal(key,ref,c.name);assert.equal(a.sp_len(key),ref.length,c.name+'/length');}
 for(const text of ['\0\b\t\n\f\r\u0001\u001f"\\','😃\u2028\u2029','\ud800','\udfff']){const ref=JSON.stringify(text),key=a.sk_quote(text);report.rows.push({name:'quote/'+JSON.stringify(text),reference:ref,candidate:key,exact:key===ref});assert.equal(key,ref);}
 const args=[lit('U32',1),lit('String',0,'x')],ref=[B.Lit('U32',1),B.Lit('String','x')].map(B.term_key).join('\n');assert.equal(a.sp_keys(list(args)),ref);report.rows.push({name:'multi-argument-newline',exact:true});
 for(const [name,unit] of [['ascii','a'],['quote','"'],['backslash','\\'],['control','\u0001'],['astral','😃']]){const n=Math.floor((32768-B.term_key(B.Lit('String','')).length)/(B.term_key(B.Lit('String',unit)).length-B.term_key(B.Lit('String','')).length));for(const delta of [-1,0,1,2]){const text=unit.repeat(n+delta),ref=B.term_key(B.Lit('String',text)),key=a.term_key(lit('String',0,text));assert.equal(key,ref);assert.equal(a.sp_len(key),ref.length);report.rows.push({name:'boundary/'+name+'/'+delta,exact:true,length:ref.length,reject:ref.length>32768});}}
 inputs.forEach(w.verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack??String(e);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
