import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
const [api,output]=process.argv.slice(2);const K=(await import(pathToFileURL(api))).p9;
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const t=(tag,name='',id=0,quant=0,kids=[],removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed)});
const lit=n=>t('LitNat','',0,n),c=(name,...kids)=>t('Ctr',name,0,1,kids),v=n=>t('Var','x',n),lam=(n,b)=>t('Lam','x',n,1,[b]),app=(f,x)=>t('App','',0,0,[f,x]),ty=t('ADT','Nat'),typ=t('Typ','',0,0,[t('Qua','',0,2)]);
const def=(name,kind,type,value=t('Absent'),ctors=[],native=false)=>({$:'KDef',name,kind,arity:0,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
const ctor0=def('Zero','Ctr',ty),ctor1={...def('Succ','Ctr',t('All','pred',9,1,[ty,ty])),arity:1};
const custom=list([def('Nat','ADT',typ,t('Absent'),[ctor0,ctor1])]);
const native=list([def('Nat','ADT',typ,t('Absent'),[ctor0,ctor1],true)]);
const env=book=>({$:'KEnv',book,name:'test',lhs:t('Ref','test'),pending:0,quantities:nil,unsafe:false});
const strip=x=>x.tag==='Ann'?strip(x.kids.head):x;
const contains=(x,tag)=>{if(x.tag===tag)return true;for(let p=x.kids;p.$==='Con';p=p.tail)if(contains(p.head,tag))return true;return false};
const rows=[];function check(id,actual,expected){rows.push({id,actual,expected,pass:JSON.stringify(actual)===JSON.stringify(expected)})}
for(const n of [0,1,255,256,257,300,4294967294,4294967295]){
 check('atomic-wnf-'+n,K.wnf(nil,lit(n)),lit(n));check('atomic-strong-'+n,K.strong(nil,lit(n)),lit(n));
 check('fresh-bound-'+n,K.max(lit(n)),0);check('pretty-'+n,K.pretty(lit(n)),n+'n');
 check('equal-'+n,K.compare(nil,lit(n),lit(n),false),true);
 check('different-'+n,K.compare(nil,lit(n),lit(n===0?1:n-1),false),false);
 const step=n===0?c('Zero'):c('Succ',lit(n-1));check('one-step-'+n,K.compare(nil,lit(n),step,false),true);check('reverse-one-step-'+n,K.compare(nil,step,lit(n),false),true);
 check('native-check-'+n,K.check(env(native),nil,lit(n),1,ty).error,'');check('native-annotation-'+n,strip(K.annotate(env(native),nil,lit(n),ty)),lit(n));
 check('native-immediate-'+n,K.compact(lit(n)),t('NWord',String(n)));
}
const pred=t('Mat','Zero',0,0,[lit(0),t('Mat','Succ',0,0,[lam(42,v(42)),t('Efq')])]);
for(const n of [0,1,256,257,300,4294967295])for(const f of ['wnf','strong'])check(f+'-match-'+n,K[f](nil,app(pred,lit(n))),lit(Math.max(0,n-1)));
check('custom-check',K.check(env(custom),nil,lit(3),1,ty).error,'');
const annotated=K.annotate(env(custom),nil,lit(3),ty);check('custom-no-literal',contains(annotated,'LitNat'),false);check('custom-root',strip(annotated).name,'Succ');
const wrong=list([def('Nat','ADT',typ,t('Absent'),[def('Foo','Ctr',ty)])]);check('custom-wrong-constructor',K.check(env(wrong),nil,lit(3),1,ty).error.length>0,true);
check('removed-zero',K.check(env(native),nil,lit(0),1,t('ADT','Nat',0,0,[],['Zero'])).error.length>0,true);
for(const [id,x] of [['name',{...lit(3),name:'Nat'}],['binder',{...lit(3),id:4294967295}],['children',{...lit(3),kids:list([v(7)])}],['removed',{...lit(3),removed:list(['Zero'])}]]){
 check('malformed-'+id+'-predicate',K.isNat(x),false);check('malformed-'+id+'-check',K.check(env(native),nil,x,1,ty).error.length>0,true);
}
// Host-forged payloads are outside the typed U32 input domain; the local
// literal certificate still fails closed so they cannot enter a literal fast path.
const outside=[-1,0.5,4294967296,NaN].map(quant=>({quant:String(quant),acceptedByInternalPredicate:K.isNat({...lit(0),quant})}));
for(const row of outside)check('malformed-payload-'+row.quant,row.acceptedByInternalPredicate,false);
check('payload-does-not-capture',K.strong(nil,app(lam(9,lam(10,c('Pair',v(9),v(10)))),lit(4294967295))).kids.head.kids.head.quant,4294967295);
check('readback-larger-than-u32',K.pretty(c('Succ',lit(4294967295))),'1n+4294967295n');
check('native-larger-than-u32-preserves-Succ',K.compact(c('Succ',lit(4294967295))).tag,'Ctr');
const report={purpose:'Direct view of checked image; helper exports are not a release artifact',count:rows.length,pass:rows.every(r=>r.pass),rows,outsideTypedDomain:outside};fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({count:report.count,pass:report.pass,failures:rows.filter(r=>!r.pass),outsideTypedDomain:outside}));if(!report.pass)process.exitCode=1;
