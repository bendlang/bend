// Compound first-error controls for two genuinely checked B1 APIs.
// Usage: node tests/structured-checker.mjs BASELINE_API CANDIDATE_API NEW_REPORT
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';
const [baseline,candidate,output]=process.argv.slice(2);
assert.ok(baseline&&candidate&&output,'Expected BASELINE_API CANDIDATE_API NEW_REPORT');
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identities=[baseline,candidate,fileURLToPath(import.meta.url)].map(file=>({file:fs.realpathSync(file),sha256:hash(file)}));
const B=(await import(pathToFileURL(identities[0].file))).default,C=(await import(pathToFileURL(identities[1].file))).default;
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',kids=[],quant=0)=>({$:'KTerm',tag,name,id:0,quant,kids:list(kids),removed:nil});
const ref=name=>term('Ref',name),adt=name=>term('ADT',name),typ=()=>term('Typ','',[term('Qua','',[],2)]);
const def=(name,type,value=term('Absent'),kind='Def',ctors=[])=>({$:'KDef',name,kind,arity:0,templates:0,typ:type,value,ctors:list(ctors),native:false,unsafe:false});
const flag=def('Flag',typ(),term('Absent'),'ADT',[def('On',adt('Flag'),term('Absent'),'Ctr')]);
const value=name=>def(name,adt('Flag'),term('Ctr','On'));
const cases=[
  {id:'type-before-body',book:[flag,def('broken',ref('missing_type'),ref('missing_body'))],error:'broken: undefined name',visible:'missing_type',hidden:'missing_body'},
  {id:'duplicate-before-type-and-body',book:[flag,value('same'),def('same',ref('missing_type'),ref('missing_body'))],error:'same: duplicate declaration'},
  {id:'law-signature-before-body',book:[flag,def('claim',adt('Flag')),def('claim',typ(),ref('missing_body'))],error:'claim: definition does not match prior law signature'},
  {id:'actual-error-before-final-todo',book:[flag,def('unfilled',adt('Flag')),def('broken',adt('Flag'),ref('missing_body'))],error:'broken: undefined name',visible:'missing_body',hidden:'TODO'},
];
const report={kind:'structured-checker-first-error',complete:false,pass:false,identities,node:process.version,checks:0,rows:[],
  scope:'Finite complete-result preservation and explicit competing-error oracles; no general soundness or performance claim.'};
const reportPath=path.resolve(output);fs.mkdirSync(path.dirname(reportPath),{recursive:true});fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
const save=()=>fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
const eq=(actual,wanted,label)=>{report.checks++;assert.deepEqual(actual,wanted,label);};
for(const item of cases){
  const row={id:item.id,complete:false,pass:false};report.rows.push(row);
  try{
    const book=list(item.book),before=B.check_book_diagnostic(book,nil),after=C.check_book_diagnostic(book,nil);
    eq(before.error,item.error,'independent baseline first-error oracle');eq(after,before,'complete original failure and book');
    eq(C.check_book(book),item.error,'String projection');eq(B.check_book(book),item.error,'baseline String verdict');
    const rendered=C.diagnostic_render(after);eq(rendered,B.diagnostic_render(before),'complete rendered first error');
    if(item.visible)assert.ok(rendered.includes(item.visible),'selected error must show '+item.visible);
    if(item.hidden)assert.ok(!rendered.includes(item.hidden),'later/unselected error must not show '+item.hidden);
    // The valid prefix consists only of the already accepted datatype.
    const prefix=list([flag]);eq(B.check_book(prefix),'','prefix actually valid');eq(C.exact_prefix(book,prefix),true,'exact prefix');
    eq(C.check_book_diagnostic_from_exact_prefix(book,prefix,nil),before,'prefix preserves the same complete first error');
    eq(C.check_from_exact_prefix(book,prefix),item.error,'prefix String projection');
    row.result=after;row.rendered=rendered;row.complete=true;row.pass=true;
  }catch(error){row.error=error.stack;}
  save();
}
try{for(const item of identities)eq(hash(item.file),item.sha256,'input artifact unchanged');}
catch(error){report.identityError=error.stack;}
report.complete=!report.identityError&&report.rows.every(row=>row.complete);report.pass=report.complete&&report.rows.every(row=>row.pass);save();
console.log(JSON.stringify({report:reportPath,complete:report.complete,pass:report.pass,checks:report.checks,rows:report.rows.map(({id,pass,error})=>({id,pass,error}))}));
if(!report.pass)process.exitCode=1;
