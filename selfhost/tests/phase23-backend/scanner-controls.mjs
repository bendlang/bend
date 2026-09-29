// Differential lexical shielding against the exact pinned emitter regex.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../..');
const apiFile=path.resolve(process.argv[2]),out=path.resolve(process.argv[3]);
if(fs.existsSync(out))throw Error('Use a fresh report path');
const source=path.join(root,'.bootstrap/upstream-phase23/bend2/comp.ts');
const upstream=fs.readFileSync(source,'utf8');
const line=upstream.split('\n').find(x=>x.startsWith('  return src.replace('));
const expression=line.slice('  return src.replace('.length).split(', (t, p, k) => {')[0];
const re=Function('return ('+expression+')')();
const api=(await import(pathToFileURL(apiFile))).default;
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const a=[];for(;xs.$==='Con';xs=xs.tail)a.push(xs.head);return a};
const t=(tag,name='',kids=[])=>({$:'KTerm',tag,name,kids:list(kids),id:0,quant:1,removed:list([]),originBegin:0,originEnd:0});
const def=(name,value=t('Absent'))=>({$:'KDef',name,kind:'Def',typ:t('Typ'),value,arity:0,templates:0,ctors:list([]),native:false,unsafe:true});
const names=['good','other','M.good','M.answer'];
const book=list(names.map(name=>def(name)));
const scope=list([def('M.answer',t('Foreign','answer',[t('Path','fixture.js')]))]);
const mark=(prefix,name)=>'«'+prefix+':'+name+'»';
function reference(input,ns){try{return {text:input.replace(re,(text,p,k)=>{
 if(!p)return text;
 const n=[ns+k,k].find(k=>names.includes(k)||p==='FID'&&['EXIT','ENTER'].includes(k));
 if(n===undefined)throw Error(p+'('+k+') names no constructor or def');
 return mark(p,n);
}),error:''}}catch(error){return {text:null,error:error.message}}}
function candidate(input,ns){const got=api.kf_source(book,ns?scope:list([]),'fixture.js',input);return {text:got.error?null:array(got.parts).map(p=>p.tag==='Text'?p.name:mark(p.tag,p.name)).join(''),error:got.error}}
const cases=[];
const add=(label,input)=>cases.push({label,input});
const ids=['CID(good)','FID(other)','CID(unknown)','FID(unknown)','FID(ENTER)','CID()','CID(good','CID(good!)','CID(good.more)'];
for(const id of ids){
 for(const left of ['', 'x','_', '0','é','中',' ','.','/', '$'])add('boundary',left+id+' CID(good)');
 for(const [open,close] of [['//','\n'],['//','\r'],['//','\u2028'],['//','\u2029'],['/*','*/'],['"','"'],["'","'"],['`','`']]){
  add('closed',open+id+close+' CID(good)');
  add('unterminated',open+id);
  add('escape',open+'\\'+close+id+close+' CID(good)');
  add('double-backslash',open+'\\\\'+close+id+close+' CID(good)');
  add('raw-newline',open+'x\n'+id+close+' CID(good)');
  add('raw-return',open+'x\r'+id+close+' CID(good)');
 }
 add('line-continuation','// x\\\n'+id+'\nCID(good)');
 add('line-crlf','// x\\\r\n'+id+'\nCID(good)');
 add('template-interpolation','`x ${'+id+'}` CID(good)');
 add('nested-looking','/* " // '+id+' */ CID(good)');
}
// Deterministic token compositions cover shield transitions and malformed text.
const tokens=['CID(good)','FID(unknown)','/*','*/','//','\n','\\','"',"'",'`','x','\r','\\\n','FID(ENTER)'];
let seed=230918;for(let i=0;i<1500;i++){let s='';for(let j=0;j<8;j++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;s+=tokens[seed%tokens.length]}add('generated-'+i,s)}
const rows=[];for(const ns of ['', 'M.'])for(const test of cases){const expected=reference(test.input,ns),actual=candidate(test.input,ns);rows.push({...test,ns,expected,actual,pass:JSON.stringify(actual)===JSON.stringify(expected)})}
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const report={kind:'phase23-foreign-scanner-regex-differential',node:process.version,api:{file:apiFile,sha256:sha(apiFile)},reference:{file:source,sha256:sha(source),expression},complete:true,pass:rows.every(x=>x.pass),rows};
fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({cases:rows.length,pass:report.pass,failures:rows.filter(x=>!x.pass).slice(0,10)}));
process.exitCode=report.pass?0:1;
