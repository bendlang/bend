// Native backend semantic regression tests. The compiler API is generated from
// Bend source before any C is emitted; no upstream C emitter is used.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {assemble} from '../../../tools/assemble.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const out=path.join(root,'build/native-tests');fs.mkdirSync(out,{recursive:true});
const mods=fs.readFileSync(path.join(root,'src/back/native/manifest.txt'),'utf8').trim().split('\n').map(n=>'src/back/native/'+n);
const source=path.join(out,'compiler.bend'),apiFile=path.join(out,'api.mjs');
assemble(['src/core/term.bend','src/core/index.bend','src/core/normalize.bend','src/core/graph.bend','src/core/reach.bend',...mods],source,{root});
const boot=spawnSync(process.env.BEND_BOOTSTRAP||process.execPath,[path.join(root,'tools/stage0-library.mjs'),source,apiFile,'nc_compile','nc_foreign_paths','nc_foreign_source','np_collect','np_can_match'],{cwd:root,encoding:'utf8',timeout:120000});
assert.equal(boot.status,0,boot.stderr||boot.error?.message);
const {default:api}=await import(pathToFileURL(apiFile));
const list=a=>a.reduceRight((tail,head)=>({$: 'Con',head,tail}),{$:'Nil'});
const t=(tag,name='',kids=[],id=0,quant=1)=>({$: 'KTerm',tag,name,kids:list(kids),id,quant,removed:list([])});
const ref=k=>t('Ref',k),vr=i=>t('Var','',[],i),app=(f,x)=>t('App','',[f,x]),ctr=(k,...a)=>t('Ctr',k,a);
const nat=n=>n===0?ctr('Zero'):ctr('Succ',nat(n-1));
const lam=(id,b)=>t('Lam','',[b],id,1),all=(id,a,b)=>t('All','',[a,b],id,1);
const nty=t('ADT','Nat'),aty=t('ADT','Array',[nty]);
const def=(name,value,typ=nty)=>({$: 'KDef',name,kind:'Def',arity:0,templates:0,typ,value,ctors:list([]),native:value.tag==='Absent',unsafe:true});
const add=(a,b)=>app(app(ref('Nat.add'),a),b),apply=(k,...xs)=>xs.reduce(app,ref(k));
const bind=(id,value,body)=>t('Let','',[t('Bind','',[value],id),body]);
const prim=def('Nat.add',t('Absent'));
const boxTy=t('ADT','Box'),boxCtr={...def('Box',t('Absent'),all(11,nty,boxTy)),kind:'Ctr',arity:1};
const boxDef={...def('Box',t('Absent'),t('Typ')),kind:'ADT',native:false,ctors:list([boxCtr])};
const extract=def('extract',lam(1,app(t('Mat','Box',[lam(2,vr(2)),t('Efq')]),vr(1))));
const treeTy=t('ADT','Tree');
const leaf={...def('Leaf',t('Absent'),all(11,nty,treeTy)),kind:'Ctr',arity:1};
const node={...def('Node',t('Absent'),all(12,treeTy,all(13,treeTy,treeTy))),kind:'Ctr',arity:2};
const treeDef={...def('Tree',t('Absent'),t('Typ')),kind:'ADT',native:false,ctors:list([leaf,node])};
const tree=ctr('Node',ctr('Leaf',nat(2)),ctr('Node',ctr('Leaf',nat(3)),ctr('Leaf',nat(4))));
const sum=def('sum',lam(30,app(t('Mat','Leaf',[lam(31,vr(31)),t('Mat','Node',[lam(32,lam(33,add(app(ref('sum'),vr(32)),app(ref('sum'),vr(33))))),t('Efq')])]),vr(30))));
const ary=ctr('ANode',ctr('ALeaf',nat(1)),ctr('ALeaf',nat(2)));
const snd=lam(1,app(t('Mat','Tuple',[lam(2,lam(3,vr(3))),t('Efq')],3),vr(1)));
const baseCtor=(name,arity,typ)=>({...def(name,t('Absent'),typ),kind:'Ctr',arity});
const baseADT=(name,ctors)=>({...def(name,t('Absent'),t('Typ')),kind:'ADT',ctors:list(ctors),native:true});
const lty=t('ADT','List',[t('ADT','U32')]);
const baseParents=[baseADT('List',[baseCtor('Nil',0,lty),baseCtor('Con',2,all(78,t('ADT','U32'),all(79,lty,lty)))]),baseADT('Nat',[baseCtor('Zero',0,nty),baseCtor('Succ',1,all(80,nty,nty))]),baseADT('Array',[baseCtor('ALeaf',1,all(81,nty,aty)),baseCtor('ANode',2,all(82,aty,all(83,aty,aty)))]),baseADT('Sigma',[baseCtor('Tuple',2,all(84,nty,all(85,nty,t('ADT','Sigma'))))])];
const fooTy=t('ADT','Foo');
const foo={...baseADT('Foo',[baseCtor('True',1,all(86,nty,fooTy)),baseCtor('False',1,all(87,nty,fooTy))]),native:false};
const matched=t('Mat','Zero',[lam(101,lam(102,add(vr(101),vr(102)))),t('Mat','Succ',[lam(103,lam(104,lam(105,apply('matched',vr(103),vr(104),vr(105))))),t('Efq')])]);
const cases=[
 ['user_scalar_ctor',[def('main',ctr('True',nat(7)),fooTy),foo],'True{7n}'],
 ['user_scalar_match',[def('main',app(t('Mat','True',[lam(88,vr(88)),t('Mat','False',[lam(89,vr(89)),t('Efq')])]),ctr('True',nat(7)))) ,foo],'7n'],
 ['matcher_partial_application',[def('main',add(apply('matched',nat(3),nat(2),nat(4)),bind(109,app(ref('matched'),nat(0)),app(app(vr(109),nat(2)),nat(4))))),def('matched',matched),prim],'12n'],
 ['nat',[def('main',nat(5))],'5n'],
 ['closure',[def('main',app(lam(1,vr(1)),nat(4)))],'4n'],
 ['add',[def('main',add(nat(2),nat(3))),prim],'5n'],
 ['override_add',[def('main',add(nat(2),nat(3))),def('Nat.add',lam(91,lam(92,nat(9))))],'9n'],
 ['let',[def('main',bind(1,nat(7),vr(1)))],'7n'],
 ['match',[def('main',app(t('Mat','Zero',[nat(9),t('Mat','Succ',[lam(2,vr(2)),t('Efq')])]),nat(4)))],'3n'],
 ['shared_box',[def('main',bind(50,ctr('Box',nat(7)),add(app(ref('extract'),vr(50)),app(ref('extract'),vr(50))))),extract,prim,boxDef],'14n'],
 ['drop_box',[def('main',bind(50,ctr('Box',nat(7)),nat(1))),boxDef],'1n'],
 ['show_box',[def('main',ctr('Box',nat(7)),boxTy),boxDef],'Box{7n}'],
 ['shared_tree',[def('main',bind(60,tree,add(app(ref('sum'),vr(60)),app(ref('sum'),vr(60))))),sum,prim,treeDef],'18n'],
 ['show_tree',[def('main',tree,treeTy),treeDef],'Node{Leaf{2n}, Node{Leaf{3n}, Leaf{4n}}}'],
 ['parallel',[def('main',bind(50,ctr('Box',nat(7)),t('Let','',[t('Bind','',[app(ref('extract'),vr(50))],70),t('Bind','',[app(ref('extract'),vr(50))],71),add(vr(70),vr(71))]))),extract,prim,boxDef],'14n'],
 ['array_new',[def('main',apply('Array.new',nat(2),nat(3)),aty),def('Array.new',t('Absent'))],'[3n, 3n, 3n, 3n]'],
 ['array_set',[def('main',apply('Array.set',ary,nat(0),nat(8)),aty),def('Array.set',t('Absent'))],'[8n, 2n]'],
 ['array_get',[def('main',app(snd,apply('Array.get',ary,nat(1)))),def('Array.get',t('Absent'))],'2n'],
 ['array_clone',[def('main',app(snd,apply('Array.clone',ary)),aty),def('Array.clone',t('Absent'))],'[1n, 2n]'],
 ['array_swap',[def('main',app(snd,apply('Array.swap',ary,nat(0),nat(9)))),def('Array.swap',t('Absent'))],'1n'],
 ['bang_cpu',[def('main',app(app(t('Ref','Nat.add',[],0,3),nat(2)),nat(3))),prim],'5n'],
 ['function_names_apart',[def('main',add(add(ref('a.b'),ref('a_b')),add(ref('A.b'),ref('IO_EMIT')))),def('a.b',nat(1)),def('a_b',nat(2)),def('A.b',nat(4)),def('IO_EMIT',nat(8)),prim],'15n'],
];
const runtime=fs.readFileSync(path.join(root,'src/runtime/native/runtime.c'),'utf8');
for(const [name,book,expected] of cases){
 const result=api.nc_compile(list([...book,...baseParents]),runtime,'');assert.equal(result.error,'',name+': '+result.error);
 const cfile=path.join(out,name+'.c'),binary=path.join(out,name);fs.writeFileSync(cfile,result.source);
 const cc=spawnSync(process.env.CC||'clang',['-O1','-Wno-parentheses-equality','-pthread',cfile,'-lm','-o',binary],{encoding:'utf8',timeout:30000});assert.equal(cc.status,0,name+': '+cc.stderr);
 for(const threads of [1,4]){const run=spawnSync(binary,['--threads',String(threads)],{encoding:'utf8',timeout:10000});assert.equal(run.status,0,name+': '+run.stderr);assert.equal(run.stdout.trim(),expected,name+' threads='+threads);}
 console.log('PASS',name);
}
assert.match(api.nc_compile(list([def('main',vr(77))]),runtime,'').error,/unbound variable/);
console.log('PASS unbound variable diagnostic');
assert.equal(api.nc_compile(list([]),runtime,'').error,'no main to run');
console.log('PASS missing main diagnostic');
const io={...def('IO',lam(91,nty),all(91,t('Typ'),t('Typ'))),native:true};
const alias=def('Effect',app(ref('IO'),ref('Unit')),t('Typ'));
assert.equal(api.nc_compile(list([def('main',t('Foreign'),ref('Effect')),alias,io]),runtime,'').error,'main must be a filled def: a foreign main cannot anchor IO');
console.log('PASS aliased IO foreign-main diagnostic');
assert.match(api.nc_compile(list([def('main',nat(1)),def('Bool',t('Typ'))]),runtime,'').error,/Bool is a name the compiler encodes itself/);
console.log('PASS reserved runtime type diagnostic');
// Even Base provenance cannot replace a Foreign declaration with an intrinsic.
// The IO type is the actual erased-result/continuation encoding used by Base.
const unit=t('ADT','Unit'),op=t('ADT','IO.OP'),ioTy=app(ref('IO'),unit);
const effectIO={...def('IO',t('Lam','',[t('All','',[t('Typ'),all(93,all(94,unit,op),op)],92,0)],91,0),t('All','',[t('Typ'),t('Typ')],91,0)),native:true};
const effect={...def('U32.add',t('Foreign','U32.add'),ioTy),native:true};
const foreignBook=list([def('main',ref('U32.add'),ioTy),effect,effectIO,...baseParents]);
const requests='Term custom_add_run(Env e, Term* f, IoWork* w) { puts("foreign"); return term_pak(CID_UNIT, 0); }\nstatic void __attribute__((constructor)) custom_add_use(void) { io_eff(CID_U32_ADD, custom_add_run, 0); }';
const foreign=api.nc_compile(foreignBook,runtime,requests);assert.equal(foreign.error,'');
const foreignSource=path.join(out,'foreign_intrinsic.c'),foreignBinary=path.join(out,'foreign_intrinsic');fs.writeFileSync(foreignSource,foreign.source);
const foreignCC=spawnSync(process.env.CC||'clang',['-O1','-pthread',foreignSource,'-lm','-o',foreignBinary],{encoding:'utf8',timeout:30000});assert.equal(foreignCC.status,0,foreignCC.stderr);
const foreignRun=spawnSync(foreignBinary,[],{encoding:'utf8',timeout:10000});assert.equal(foreignRun.status,0,foreignRun.stderr);assert.equal(foreignRun.stdout,'foreign\n');
console.log('PASS foreign intrinsic-name C effect dispatch');
console.log(`${cases.length+5} native regression cases passed`);

// Compare the native Nat row collector with independent tree interpretation.
const array=xs=>{const out=[];for(;xs.$==='Con';xs=xs.tail)out.push(xs.head);return out;};
const rowLeaf=name=>t('Leaf',name), rowDefault=name=>t('Default',name);
const rowMat=(name,hit,miss)=>t('Mat',name,[hit,miss],name==='Zero'?1:2);
function evalTree(term,n){
 if(term.tag==='Mat'){
  const [hit,miss]=array(term.kids);
  return term.name==='Zero'?(n===0?hit.name:evalTree(miss,n)):(n>0?evalTree(hit,n-1):evalTree(miss,n));
 }
 return term.tag==='Default'?term.name+':'+n:term.name;
}
function evalRows(term,n){
 const rows=array(api.np_collect(term,0,list([])));
 const row=rows.find(row=>row.last||row.index===n);
 return row.apply?evalTree(row.body,n-row.residual):row.body.name;
}
const trees=[rowMat('Zero',rowLeaf('zero'),rowDefault('else')),rowMat('Succ',rowDefault('succ'),rowDefault('zero'))];
for(let mode=0;mode<4;mode++){
 let tree=rowDefault('last');
 for(let n=49;n>=0;n--){
  const zero=rowLeaf('z'+n),fallback=rowDefault('d'+n);
  tree=mode===0?rowMat('Zero',zero,rowMat('Succ',tree,fallback)):
   mode===1?rowMat('Succ',tree,rowMat('Zero',zero,fallback)):
   mode===2?rowMat('Succ',tree,fallback):
   n%3?rowMat('Succ',tree,fallback):rowMat('Zero',zero,rowMat('Succ',tree,fallback));
 }
 trees.push(tree);
}
for(const tree of trees){
 assert.equal(api.np_can_match(tree),true);
 for(let n=0;n<1001;n++)assert.equal(evalRows(tree,n),evalTree(tree,n));
}
assert.equal(api.np_can_match(rowMat('Zero',rowLeaf('z'),rowMat('Zero',rowLeaf('dup'),rowDefault('d')))),false);
assert.equal(api.np_can_match(t('Mat','Box',[rowLeaf('x'),rowDefault('d')],2)),false);
console.log('6006 Nat decision-chain evaluations agree with direct tree interpretation');
