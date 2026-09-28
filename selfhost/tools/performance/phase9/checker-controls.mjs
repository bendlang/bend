// Private boundary controls on an independently checked component image.
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const {default:K}=await import(pathToFileURL(process.argv[2]));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',id=0,quant=0,kids=[],removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed)});
const v=id=>term('Var','x',id),lam=(id,b,q=1)=>term('Lam','x',id,q,[b]),app=(f,x)=>term('App','',0,0,[f,x]),ctr=(n,...xs)=>term('Ctr',n,0,0,xs);
const qua=q=>term('Qua','',0,q),typ=q=>term('Typ','',0,0,[qua(q)]),all=(id,q,a,b)=>term('All','x',id,q,[a,b]);
const A=ctr('A'),B=ctr('B'),bind=(id,ty)=>term('Bind','x',id,1,[ty]);
const env={$:'KEnv',book:nil,name:'',lhs:term('Absent'),pending:0,quantities:nil,unsafe:false};
const results=[];function check(name,actual,expected){assert.deepEqual(actual,expected,name);results.push({name,actual});}
// The input has distinct binder IDs; exact comparison must not demand omega.
const loop=id=>lam(id,app(v(id),v(id)),2),omega=app(loop(10),loop(11));
check('exact divergent application',K.compare(nil,omega,structuredClone(omega),false),true);
check('exact divergent field',K.compare(nil,ctr('Wrap',omega),ctr('Wrap',structuredClone(omega)),false),true);
check('different first field avoids second divergent field',K.compare(nil,ctr('Pair',A,omega),ctr('Pair',B,omega),false),false);
check('arity mismatch avoids divergent field',K.compare(nil,ctr('Pack',omega),ctr('Pack',omega,A),false),false);
check('high free IDs survive alpha opening',K.compare(nil,lam(20,ctr('Pair',v(20),v(1000000000))),lam(21,ctr('Pair',v(21),v(1000000000))),false),true);
check('high free ID cannot become bound',K.compare(nil,lam(20,v(1000000000)),lam(21,v(21)),false),false);
check('direct explicit fresh conversion remains callable',K.norm_compare(nil,lam(20,v(20)),lam(21,v(21)),false,4000000000),true);
check('removed constructors affect exact equality',K.compare(nil,term('ADT','D',0,0,[],['A']),term('ADT','D'),false),false);
check('domain quantity subtype direction',K.compare(nil,typ(1),typ(2),true),false);
check('alpha All dependent result',K.compare(nil,all(20,1,typ(1),v(20)),all(21,1,typ(1),v(21)),false),true);
const shadow=K.infer(env,list([bind(7,A),bind(7,B)]),v(7),1,nil);
check('nearest context binding',shadow.typ,A);
check('missing context binding',K.infer(env,nil,v(7),1,nil).error,'unbound variable');
const zero=K.infer(env,list([bind(7,A)]),v(7),0,nil);
check('erased inference usage retained',zero.uses.head.quant,0);
let context=nil;for(let i=0;i<128;i++)context={$:'Con',head:bind(i,A),tail:context};
check('deep context lookup',K.infer(env,context,v(0),1,nil).typ,A);
const boolType=term('ADT','Bool');
const def=(name,typ,kind='Def',ctors=[])=>({$:'KDef',name,kind,arity:0,templates:0,typ,value:term('Absent'),ctors:list(ctors),native:false,unsafe:false});
const bool=def('Bool',typ(2),'ADT',[def('True',boolType,'Ctr'),def('False',boolType,'Ctr')]);
const boolEnv={...env,book:list([bool])};
const functionType=all(40,1,boolType,boolType);
check('explicit many promotes a Data domain',K.check(boolEnv,nil,lam(42,v(42),2),1,all(41,1,boolType,boolType)).error,'');
check('ordinary affine function domain remains valid',K.check(boolEnv,nil,lam(42,ctr('True')),1,all(41,1,functionType,boolType)).error,'');
check('promotion retains safe Data wall',K.check(boolEnv,nil,lam(42,ctr('True'),2),1,all(41,1,functionType,boolType)).error,'type mismatch');
check('promotion honors unsafe context',K.check({...boolEnv,unsafe:true},nil,lam(42,ctr('True'),2),1,all(41,1,functionType,boolType)).error,'');
const invalidSignature={...def('badSignature',all(41,2,functionType,boolType)),arity:1,value:lam(42,ctr('True'))};
check('public book rejects invalid signature before ordinary lambda',K.check_book(list([bool,invalidSignature])),'badSignature: type mismatch');
// Deliberately invalid goal: private check relies on a checked function type.
// Record this boundary; equality with the old defensive implementation is not
// asserted for an unvalidated Many function domain.
const outsidePrecondition=K.check(boolEnv,nil,lam(42,ctr('True')),1,all(41,2,functionType,boolType)).error;
console.log(JSON.stringify({kind:'checker-private-controls',component:process.argv[2],passed:results.length,results,outsidePrecondition:{invalidManyFunctionDomain:outsidePrecondition}},null,2));
