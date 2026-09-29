native('Bool.not',1,x=>!x);native('Bool.and',2,(a,b)=>a&&b);native('Bool.or',2,(a,b)=>a||b);native('Bool.xor',2,(a,b)=>a!==b);
native('Bool.pick',4,(_,c,a,b)=>c?a:b);native('Bool.to_u32',1,b=>b?1:0);native('Bool.show',1,b=>b?'True':'False');
for(const type of ['U32','Nat','F32']){
  const cast=type==='Nat'?x=>BigInt(x):type==='F32'?Math.fround:x=>Number(x)>>>0;
  const zero=cast(0);
  const ops={add:(a,b)=>cast(a+b),sub:(a,b)=>type==='Nat'?(a>b?a-b:0n):cast(a-b),mul:(a,b)=>type==='U32'?Math.imul(a,b)>>>0:cast(a*b),div:(a,b)=>b===zero?zero:cast(type==='U32'?Math.floor(a/b):a/b),mod:(a,b)=>b===zero?zero:cast(a%b),is_eq:(a,b)=>a===b,is_ne:(a,b)=>a!==b,is_lt:(a,b)=>a<b,is_le:(a,b)=>a<=b,is_gt:(a,b)=>a>b,is_ge:(a,b)=>a>=b,min:(a,b)=>a<b?a:b,max:(a,b)=>a>b?a:b};
  for(const [n,f]of Object.entries(ops))native(type+'.'+n,2,f);
  native(type+'.show',1,String);native(type+'.is_zero',1,x=>x===zero);
  native(type+'.read',1,s=>{try{return /^[0-9]+$/.test(s)?ctor('Some',[cast(s)]):ctor('None',[])}catch{return ctor('None',[])}});
}
native('U32.to_nat',1,BigInt);native('U32.from_nat',1,n=>Number(n&0xffffffffn));native('Nat.to_u32',1,n=>Number(n&0xffffffffn));
native('U32.inc',1,n=>(n+1)>>>0);native('U32.and',2,(a,b)=>(a&b)>>>0);native('U32.or',2,(a,b)=>(a|b)>>>0);native('U32.xor',2,(a,b)=>(a^b)>>>0);native('U32.not',1,a=>(~a)>>>0);
native('Char.to_u32',1,x=>typeof x==='string'?x.codePointAt(0):x);native('Char.from_u32',1,checkedChar);native('Char.is_eq',2,(a,b)=>a===b);
native('Char.is_upper',1,c=>c>=65&&c<=90);native('Char.is_lower',1,c=>c>=97&&c<=122);
native('Char.is_digit',1,c=>c>=48&&c<=57);native('Char.is_alpha',1,c=>(c>=65&&c<=90)||(c>=97&&c<=122));native('Char.is_space',1,c=>c===32||(c>=9&&c<=13));
native('Char.show',1,c=>typeof c==='string'?c:String.fromCodePoint(c));
function stringEq(a,b){if(a.isWellFormed()&&b.isWellFormed())return a===b;let i=0,j=0;while(i<a.length&&j<b.length){const x=checkedChar(a.codePointAt(i)),y=checkedChar(b.codePointAt(j));if(x!==y)return false;i+=x>65535?2:1;j+=y>65535?2:1}return i===a.length&&j===b.length}
native('String.eq',2,stringEq);native('String.append',2,(a,b)=>a+b);native('String.is_empty',1,s=>s.length===0);native('String.reverse',1,s=>Array.from(s).reverse().join(''));
native('String.length',1,s=>BigInt(Array.from(s).length));native('String.take',2,(s,n)=>Array.from(s).slice(0,Number(n)).join(''));native('String.drop',2,(s,n)=>Array.from(s).slice(Number(n)).join(''));
native('String.starts_with',2,(s,p)=>s.startsWith(p));native('String.ends_with',2,(s,p)=>s.endsWith(p));native('String.contains',2,(s,p)=>s.includes(p));native('String.join',2,(xs,sep)=>unlist(xs).join(sep));
native('String.concat',1,xs=>unlist(xs).join(''));native('String.trim',1,s=>s.replace(/^[ \t\r\n\v\f]+|[ \t\r\n\v\f]+$/g,''));native('String.split',2,(s,c)=>list(s.split(String.fromCodePoint(c))));native('String.lines',1,s=>list(s.split('\n')));
native('List.reverse',3,(_q,_t,x)=>list(unlist(x).reverse()));native('List.length',3,(_q,_t,x)=>BigInt(unlist(x).length));
// Native representations of the Base library's primitive collections.
const some=x=>ctor('Some',[x]),none=()=>ctor('None',[]);
const floatBuffer=new ArrayBuffer(4),floatView=new DataView(floatBuffer);
const floatBits=x=>{floatView.setFloat32(0,x,true);return floatView.getUint32(0,true)};
const bitsFloat=x=>{floatView.setUint32(0,x,true);return floatView.getFloat32(0,true)};
function floatShow(x){if(Number.isNaN(x))return 'nan';if(x===Infinity)return 'inf';if(x===-Infinity)return '-inf';if(Object.is(x,-0))return '-0';for(let p=1;p<=9;p++){const s=Number(x.toPrecision(p)).toString();if(Math.fround(Number(s))===x)return s}return String(x)}
native('F32.show',1,floatShow);native('F32.bits',1,floatBits);native('U32.to_f32',1,Math.fround);native('F32.to_u32',1,x=>!Number.isFinite(x)||x<=0?0:x>=4294967295?4294967295:Math.trunc(x)>>>0);
native('F32.read',1,s=>/^\s*[+-]?((\d+\.?\d*|\.\d+)(e[+-]?\d+)?|inf(inity)?|nan)$/i.test(s)?some(Math.fround(Number(s.replace(/inf\w*/i,'Infinity')))):none());
for(const k of ['sqrt','exp','log','log2','log10','sin','cos','tan','asin','acos','atan','sinh','cosh','tanh','floor','ceil','trunc','abs','round'])native('F32.'+k,1,x=>Math.fround(Math[k](x)));
native('F32.neg',1,x=>Math.fround(-x));native('F32.pow',2,(a,b)=>Math.fround(a**b));native('F32.atan2',2,(a,b)=>Math.fround(Math.atan2(a,b)));native('F32.pi',0,()=>Math.fround(Math.PI));
native('F32.square',1,x=>Math.fround(x*x));native('F32.hypot',2,(x,y)=>Math.fround(Math.sqrt(Math.fround(Math.fround(x*x)+Math.fround(y*y)))));
native('F32.from_nat',1,n=>Math.fround(Number(n&0xffffffffn)));native('F32.to_nat',1,n=>BigInt(!Number.isFinite(n)||n<0||n>=4294967296?0:Math.trunc(n)));
native('U32.shl',1,a=>(a<<1)>>>0);native('U32.shr',1,a=>a>>>1);native('U32.shln',2,(a,n)=>n>=32n?0:(a<<Number(n))>>>0);native('U32.shrn',2,(a,n)=>n>=32n?0:a>>>Number(n));
native('U32.mod',2,(a,b)=>b===0?a:a%b);native('Nat.mod',2,(a,b)=>b===0n?a:a%b);native('Nat.divmod',2,(a,b)=>b===0n?[0n,a]:[a/b,a%b]);
native('Nat.double',1,n=>n*2n);native('Nat.pow',2,(a,b)=>a**b);native('U32.pow',2,(a,b)=>{let r=1;for(;b>0n;b>>=1n,a=Math.imul(a,a)>>>0)if(b&1n)r=Math.imul(r,a)>>>0;return r});
for(const type of ['Nat','U32','Char'])native(type+'.cmp',2,(a,b)=>ctor(a<b?'LT':a>b?'GT':'EQ',[]));
for(const type of ['Nat','U32','F32'])native(type+'.clamp',3,(x,l,h)=>x<l?l:x>h?h:x);
for(const [k,f]of Object.entries({eq:x=>x===0,ne:x=>x!==0,lt:x=>x<0,le:x=>x<=0,gt:x=>x>0,ge:x=>x>=0}))native('Cmp.is_'+k,1,c=>f(c.$==='LT'?-1:c.$==='GT'?1:0));
native('U32.read',1,s=>/^\d+$/.test(s)&&BigInt(s)<=4294967295n?some(Number(s)):none());native('Nat.read',1,s=>/^\d+$/.test(s)&&BigInt(s)<=281474976710655n?some(BigInt(s)):none());
for(const [k,f]of Object.entries({lt:(a,b)=>a<b,le:(a,b)=>a<=b,gt:(a,b)=>a>b,ge:(a,b)=>a>=b}))native('String.is_'+k,2,(a,b)=>f(compareText(a,b),0));
native('String.order',2,(a,b)=>{const c=compareText(a,b);return ctor(c<0?'LT':c>0?'GT':'EQ',[])});native('String.cmp',2,(a,b)=>{const c=compareText(a,b);return [[a,b],ctor(c<0?'LT':c>0?'GT':'EQ',[])]});
native('String.get',2,(s,n)=>Number(n)<Array.from(s).length?some(s.codePointAt(Array.from(s).slice(0,Number(n)).join('').length)):none());
native('String.to_list',1,s=>list(Array.from(s,c=>c.codePointAt(0))));native('String.from_list',1,x=>unlist(x).map(c=>String.fromCodePoint(c)).join(''));
native('String.repeat',2,(s,n)=>s.repeat(Number(n)));native('String.to_upper',1,s=>s.replace(/[a-z]/g,c=>String.fromCharCode(c.charCodeAt(0)-32)));native('String.to_lower',1,s=>s.replace(/[A-Z]/g,c=>String.fromCharCode(c.charCodeAt(0)+32)));native('String.trim_start',1,s=>s.replace(/^[ \t\r\n\v\f]+/g,''));native('String.trim_end',1,s=>s.replace(/[ \t\r\n\v\f]+$/g,''));
native('Char.to_upper',1,c=>c>=97&&c<=122?c-32:c);native('Char.to_lower',1,c=>c>=65&&c<=90?c+32:c);
native('Maybe.pure',3,(_q,_t,x)=>some(x));native('Maybe.bind',6,(_q,_r,_a,_b,m,f)=>m.$==='Some'?call(f,[m.a[0]]):m);
native('Maybe.default',4,(_q,_a,m,d)=>m.$==='Some'?m.a[0]:d);native('Maybe.is_some',3,(_q,_a,m)=>m.$==='Some');native('Maybe.is_none',3,(_q,_a,m)=>m.$==='None');
native('Maybe.or',4,(_q,_a,m,n)=>m.$==='Some'?m:n);native('Maybe.map',6,(_q,_r,_a,_b,f,m)=>m.$==='Some'?some(call(f,[m.a[0]])):m);
native('Result.pure',5,(_q,_r,_e,_a,x)=>done(x));native('Result.bind',8,(_q,_r,_s,_e,_a,_b,m,f)=>m.$==='Done'?call(f,[m.a[0]]):m);
native('Result.default',6,(_q,_r,_e,_a,m,d)=>m.$==='Done'?m.a[0]:d);native('Result.is_done',5,(_q,_r,_e,_a,m)=>m.$==='Done');native('Result.is_fail',5,(_q,_r,_e,_a,m)=>m.$==='Fail');
native('List.append',4,(_q,_a,x,y)=>list([...unlist(x),...unlist(y)]));native('List.concat',3,(_q,_a,x)=>list(unlist(x).flatMap(unlist)));
native('List.is_empty',3,(_q,_a,x)=>x.$==='Nil');native('List.head',3,(_q,_a,x)=>x.$==='Con'?some(x.a[0]):none());native('List.tail',3,(_q,_a,x)=>x.$==='Con'?x.a[1]:x);native('List.last',3,(_q,_a,x)=>x.$==='Con'?some(unlist(x).at(-1)):none());
native('List.get',4,(_q,_a,x,n)=>{const a=unlist(x);return n<BigInt(a.length)?some(a[Number(n)]):none()});
native('List.set',5,(_q,_a,x,n,v)=>{const a=unlist(x);if(n<BigInt(a.length))a[Number(n)]=v;return list(a)});
native('List.take',4,(_q,_a,x,n)=>list(unlist(x).slice(0,Number(n))));native('List.drop',4,(_q,_a,x,n)=>list(unlist(x).slice(Number(n))));
native('List.range',1,n=>list(Array.from({length:Number(n)},(_,i)=>BigInt(i))));native('List.replicate',3,(_a,n,x)=>list(Array(Number(n)).fill(x)));
native('List.map',4,(_a,_b,f,x)=>list(unlist(x).map(v=>call(f,[v]))));native('List.filter',3,(_a,f,x)=>list(unlist(x).filter(v=>call(f,[v]))));
native('List.foldl',6,(_q,_a,_b,f,x,acc)=>unlist(x).reduce((a,v)=>call(f,[a,v]),acc));native('List.foldr',6,(_q,_a,_b,f,x,acc)=>unlist(x).reduceRight((a,v)=>call(f,[v,a]),acc));
native('List.any',4,(_q,_a,f,x)=>unlist(x).some(v=>call(f,[v])));native('List.all',4,(_q,_a,f,x)=>unlist(x).every(v=>call(f,[v])));
native('List.find',3,(_a,f,x)=>{for(const v of unlist(x))if(call(f,[v]))return some(v);return none()});native('List.sort',3,(_a,f,x)=>list(unlist(x).sort((a,b)=>call(f,[a,b])?-1:1)));
native('List.show',4,(_q,_a,f,x)=>'['+unlist(x).map(v=>call(f,[v])).join(', ')+']');native('Maybe.show',4,(_q,_a,f,x)=>x.$==='Some'?'Some{'+call(f,[x.a[0]])+'}':'None{}');
function arrayfill(v,n,mode){if(mode==='^'&&n>31n)bad('an array past the deepest block class 31');const size=mode==='^'?2**Number(n):Number(n);if(size<1||!Number.isSafeInteger(size)||(size&(size-1)))bad('array size must be a power of two');return {array:Array(size).fill(v)}}
function arrayget(a,i){const xs=arraydata(a);return [a,xs[Number(i)%xs.length]]}
function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;return a}
function arraydata(a){if(a.array)return a.array;if(a.$==='ALeaf')return (a.array=[a.a[0]]);if(a.$==='ANode')return (a.array=[...arraydata(a.a[0]),...arraydata(a.a[1])]);bad('expected Array')}
// One synchronous RMW step; forked handles keep the same backing array.
function arrayrmw(a,i,f){const xs=arraydata(a),at=Number(i)%xs.length,old=xs[at];xs[at]=f(old);return [a,old]}
for(const [name,op] of Object.entries({add:(x,v)=>(x+v)>>>0,min:Math.min,max:Math.max,and:(x,v)=>(x&v)>>>0,or:(x,v)=>(x|v)>>>0,xor:(x,v)=>(x^v)>>>0,exch:(_x,v)=>v,fadd:(x,v)=>Math.fround(x+v)}))native('Array.atomic.'+name,3,(a,i,v)=>arrayrmw(a,i,x=>op(x,v)));
native('Array.atomic.cas',4,(a,i,x,v)=>arrayrmw(a,i,old=>old===x?v:old));
native('Array.new',3,(_t,d,v)=>arrayfill(v,d,'^'));native('Array.get',3,(_t,a,i)=>arrayget(a,i));native('Array.set',4,(_t,a,i,v)=>arrayset(a,i,v));native('Array.swap',4,(_t,a,i,v)=>{const old=arrayget(a,i)[1];return [arrayset(a,i,v),old]});native('Array.size',2,(_t,a)=>[a,arraydata(a).length]);native('Array.clone',2,(_t,a)=>[a,{array:arraydata(a).slice()}]);native('Array.to_list',2,(_t,a)=>list(arraydata(a)));native('Array.map',4,(_t,_u,f,a)=>({array:arraydata(a).map(v=>call(f,[v]))}));
for(const k of ['Map','Set','Either','Sigma','Word','Word.Nil','Word.Con','IO.OP'])G[k]={typeName:k};
native('Map.new',2,()=>new Map());native('Map.set',5,(_q,_t,m,k,v)=>(m.set(k,v),m));native('Map.get',4,(_t,d,m,k)=>[m,m.has(k)?m.get(k):d]);native('Map.has',4,(_q,_t,m,k)=>[m,m.has(k)]);native('Map.del',4,(_q,_t,m,k)=>(m.delete(k),m));native('Map.pop',4,(_q,_t,m,k)=>{const r=m.has(k)?some(m.get(k)):none();m.delete(k);return [m,r]});native('Map.size',3,(_q,_t,m)=>BigInt(m.size));native('Map.keys',3,(_q,_t,m)=>list([...m.keys()].sort(compareText)));native('Map.values',3,(_q,_t,m)=>list([...m.keys()].sort(compareText).map(k=>m.get(k))));native('Map.to_list',3,(_q,_t,m)=>list([...m.keys()].sort(compareText).map(k=>[k,m.get(k)])));native('Map.from_list',3,(_q,_t,x)=>new Map(unlist(x)));native('Map.union',4,(_q,_t,m,n)=>new Map([...m,...n]));
native('Set.new',0,()=>new Set());native('Set.add',2,(s,k)=>(s.add(k),s));native('Set.has',2,(s,k)=>[s,s.has(k)]);native('Set.del',2,(s,k)=>(s.delete(k),s));native('Set.size',1,s=>BigInt(s.size));native('Set.to_list',1,s=>list([...s].sort(compareText)));native('Set.from_list',1,x=>new Set(unlist(x)));
native('Pair.fst',3,(_a,_b,p)=>p[0]);native('Pair.snd',3,(_a,_b,p)=>p[1]);

function decodeString(s){return s.replace(/\\(?:u\{([0-9a-fA-F]+)\}|([\s\S]))/g,(_,hex,c)=>hex?String.fromCodePoint(parseInt(hex,16)):({n:'\n',r:'\r',t:'\t','0':'\0',"'":"'",'"':'"','\\':'\\'}[c]??bad('unknown string escape '+c)))}
function matcher(name,arm,other){return fn(1,([x])=>{const a=fields(name,x);return a===null?jump(other(),[x]):a.length?jump(arm(),a):arm()})}
function monadpure(name,x){if(name==='IO'||name==='')return pure(x);const f=get(G,name+'.pure');return call(f,[...Array(f.arity-1).fill(null),x])}
function monadbind(name,m,k){if(name==='IO'||name==='')return bind(m,k);const f=get(G,name+'.bind');return call(f,[...Array(f.arity-2).fill(null),m,fn(1,a=>k(a[0]))])}
native('Maybe.bind',5,(_q,_a,_b,m,f)=>m.$==='Some'?call(f,[m.a[0]]):m);
native('Maybe.map',5,(_q,_a,_b,f,m)=>m.$==='Some'?some(call(f,[m.a[0]])):m);
native('Maybe.show',4,(_q,_a,f,x)=>x.$==='Some'?'Some('+call(f,[x.a[0]])+')':'None');
native('Result.bind',7,(_q,_r,_e,_a,_b,m,f)=>m.$==='Done'?call(f,[m.a[0]]):m);
native('Result.map',7,(_q,_r,_e,_a,_b,f,m)=>m.$==='Done'?done(call(f,[m.a[0]])):m);
native('List.zip',6,(_q,_r,_a,_b,x,y)=>{const a=unlist(x),b=unlist(y);return list(a.slice(0,b.length).map((v,i)=>[v,b[i]]))});
native('List.contains',4,(_a,eq,x,v)=>unlist(x).some(w=>call(eq,[w,v])));
native('U32.is_even',1,n=>(n&1)===0);
native('F32.div',2,(a,b)=>Math.fround(a/b));native('F32.mod',2,(a,b)=>Math.fround(a%b));
native('F32.to_u32',1,x=>!Number.isFinite(x)||x<0||x>=4294967296?0:Math.trunc(x)>>>0);
function word(n,bits=32){let w=ctor('WNil',[]);for(let i=bits-1;i>=0;i--)w=ctor('WCon',[((n>>>i)&1)===1,w]);return w}
function unword(w){let n=0,i=0;while(w.$==='WCon'){if(w.a[0])n=(n+2**i)>>>0;i++;w=w.a[1]}return n}
native('F32.lerp',3,(a,b,t)=>Math.fround(a+Math.fround(Math.fround(b-a)*t)));
native('List.for_each',4,(_q,_a,f,x)=>({io:async()=>{for(const v of unlist(x))await force(call(f,[v])).io();return unit}}));
function mapEntries(m){if(m instanceof Map)return [...m];if(m.$==='MTip')return [];if(m.$==='MLeaf')return [[m.a[0],m.a[1]]];if(m.$==='MNode')return [...mapEntries(m.a[1]),...mapEntries(m.a[2])];bad('expected Map')}
function mapTree(entries){if(!entries.length)return ctor('MTip',[]);if(entries.length===1)return ctor('MLeaf',entries[0]);let pos=0;while(entries.every(e=>mapBit(e[0],pos)===mapBit(entries[0][0],pos)))pos++;return ctor('MNode',[BigInt(pos),mapTree(entries.filter(e=>!mapBit(e[0],pos))),mapTree(entries.filter(e=>mapBit(e[0],pos)))])}
native('Map.new',2,()=>ctor('MTip',[]));native('Map.from_list',3,(_q,_t,x)=>mapTree([...new Map(unlist(x))]));
native('Map.set',5,(_q,_t,m,k,v)=>mapTree([...new Map(mapEntries(m)).set(k,v)]));
native('Map.get',4,(_t,d,m,k)=>{const n=new Map(mapEntries(m));return [m,n.has(k)?n.get(k):d]});
native('Map.has',4,(_q,_t,m,k)=>[m,new Map(mapEntries(m)).has(k)]);
native('Map.del',4,(_q,_t,m,k)=>{const n=new Map(mapEntries(m));n.delete(k);return mapTree([...n])});
native('Map.pop',4,(_q,_t,m,k)=>{const n=new Map(mapEntries(m)),r=n.has(k)?some(n.get(k)):none();n.delete(k);return [mapTree([...n]),r]});
native('Map.size',3,(_q,_t,m)=>BigInt(mapEntries(m).length));native('Map.keys',3,(_q,_t,m)=>list(mapEntries(m).map(x=>x[0]).sort(compareText)));
native('Map.values',3,(_q,_t,m)=>list(mapEntries(m).sort((a,b)=>compareText(a[0],b[0])).map(x=>x[1])));
native('Map.to_list',3,(_q,_t,m)=>list(mapEntries(m).sort((a,b)=>compareText(a[0],b[0]))));
native('Map.union',4,(_q,_t,m,n)=>mapTree([...new Map([...mapEntries(m),...mapEntries(n)])]));
native('Char.cmp',2,(a,b)=>[[a,b],ctor(a<b?'LT':a>b?'GT':'EQ',[])]);
function checkedNat(n){if(n<0n||n>281474976710655n)bad('a Nat past the largest immediate 2^48-1');return n}
native('Nat.add',2,(a,b)=>checkedNat(a+b));native('Nat.mul',2,(a,b)=>checkedNat(a*b));native('Nat.double',1,a=>checkedNat(a*2n));native('Nat.pow',2,(a,b)=>{let r=1n;while(b>0n){if(b&1n)r=checkedNat(r*a);b>>=1n;if(b>0n)a=checkedNat(a*a)}return r});

function mapBit(key,pos){const cs=Array.from(key);const i=Math.floor(pos/33),b=pos%33;return i>=cs.length?false:b===0?true:((cs[i].codePointAt(0)>>>(32-b))&1)!==0}

// round is floor(a + 0.5), with the addition rounded to binary32.
native('F32.round',1,x=>Math.fround(Math.floor(Math.fround(x+Math.fround(0.5)))));
