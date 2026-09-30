// Independent ordinary constructor graphs, not compiler-generated expected values.
export const ctr=($,...a)=>({$,a});
export const nil=()=>ctr('Nil');
export const list=xs=>xs.reduceRight((r,h)=>ctr('Con',h,r),nil());
export const term=(tag='Absent',name='',id=0,quant=0,kids=[])=>ctr('KTerm',tag,name,id,quant,list(kids),nil(),0,0);
export const definition=(name,kind='Def',arity=0,templates=0,typ=term('Set'),value=term('U32'),children=[],native=false,unsafe=false)=>ctr('KDef',name,kind,arity,templates,typ,value,list(children),native,unsafe);
export const missing=()=>definition('','Absent',0,0,term(),term());
export function freezeGraph(x,seen=new WeakSet()){if(x===null||typeof x!=='object'||seen.has(x))return x;seen.add(x);for(const v of Object.values(x))freezeGraph(v,seen);return Object.freeze(x)}
export function fnv(name){let x=2166136261n;for(const c of name)x=((x^BigInt(c.codePointAt(0)))*16777619n)&0xffffffffn;return Number(x)}
export function makeFixtures(m,size=64){
 const names=['','x','xx','prefix','prefix.deep','λ','😀','costarring','liquid',...Array.from({length:size},(_,i)=>'symbol.'+i)];
 const ds=names.map((n,i)=>definition(n,i%3===0?'ADT':'Def',i%4,0,term(i%2?'U32':'Set'),term('U32','',i),i%7===0?[definition(n+'.child')]:[]));
 ds.splice(5,0,definition('x','Def',17,0,term('Bool'),term('False')));
 ds.push(definition('','Def',99));
 const book=freezeGraph(list(ds));const cached=freezeGraph(m.default.book_cached(book,1729));
 const queries=[...new Set([...names,'missing','symbol.999999','prefix.deeper','😁','λ.x'])];
 const expected=queries.map(n=>ds.find(d=>d.a[0]===n)??missing());
 const caller=definition('caller');const world=freezeGraph(ctr('KWorld',list([caller]),nil(),ctr('KFreshKnown',17),nil()));
 const env=(unsafe=false)=>ctr('KEnv',world,'caller',term('Ref','caller'),0,nil(),unsafe,0);
 const inputs=[];
 const add=(name,d,dem=1,t=term('Ref','target'),unsafe=false,error='')=>{
  const e=env(unsafe),args=[e,nil(),t,dem,nil(),d];
  const expected=error?ctr('KChecking',term('Error'),term('Error'),nil(),error,world,0):ctr('KChecking',t,d.a[4],nil(),'',world,0);
  inputs.push(freezeGraph({name,args,expected,world}));
 };
 add('missing',missing(),1,term('Ref','target'),false,'undefined name');
 add('family',definition('Family','ADT',1),0,term('Ref','target'),false,'a family requires angle-bracket parameters');
 for(const dem of [0,1,2])for(const native of [false,true]){
  add('filled:'+dem+':'+native,definition('target','Def',0,0,term('U32'),term('U32','',17),[],native),dem);
 }
 for(const t of [term('Ref','target'),ctr('KLambda','v',17,2,nil(),nil(),1,3,true),ctr('KLiteral','U32',42,'',3,5)])
  add('zero-shape:'+t.$,definition('target'),0,t);
 add('unfilled-refusal',definition('target','Def',0,0,term('U32'),term()),1,term('Ref','target'),false,'live use of an unfilled law');
 add('unfilled-native',definition('target','Def',0,0,term('U32'),term(),[],true),1);
 add('unfilled-unsafe',definition('target','Def',0,0,term('U32'),term()),1,term('Ref','target'),true);
 add('nullary-family',definition('Nullary','ADT',0),1);
 return {book,cached,queries,expected,definitions:ds,infer:inputs};
}
