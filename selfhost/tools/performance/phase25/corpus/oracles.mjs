// Independent scalar specifications for corpus results, not timed benchmark code.
const u=x=>x>>>0, add=(a,b)=>u(a+b), mul=(a,b)=>Math.imul(a,b)>>>0;
const pop=n=>n<16?((n&1)+((n>>>1)&1)+((n>>>2)&1)+((n>>>3)&1)):100;
const key=n=>n===0?10:n===3000000000?20:n===4294967295?30:40;
const text=seed=>seed%2===0?'alpha.beta_0123456789':'λ雪𝄞.beta_0123456789';
export function expected(id,size,seed){
  if(!Number.isInteger(size)||size<0||size>4096||!Number.isInteger(seed)||seed<0||seed>4294967295)throw Error('Oracle domain');
  let acc=seed;
  switch(id){
    case 'host-boundary': return seed;
    case 'scalar-arithmetic': for(let n=size;n;n--)acc=add(acc,u(mul(n,3)^(acc>>>1)));return acc;
    case 'boolean-choice': case 'boolean-worker': for(let n=size;n;n--)acc=add(acc,acc%2===0?3:5);return acc;
    case 'membership-choice': case 'membership-worker': return add(seed,size>0&&seed%2===0?1:0);
    case 'list-reverse': for(let i=0;i<size;i++)acc=add(mul(acc,33),add(seed,i));return acc;
    case 'list-map-fold': for(let i=size-1;i>=0;i--)acc=add(mul(acc,33),mul(add(seed,i),2));return acc;
    case 'match-remaining-args': case 'partial-application': for(let i=0;i<size;i++)acc=add(acc,add(mul(add(seed,i),3),seed));return acc;
    case 'closure-capture': return u(seed+size*(size+1)/2);
    case 'string-hash': for(let i=0;i<size;i++)for(const ch of text(seed))acc=mul(u(acc^ch.codePointAt(0)),16777619);return acc;
    case 'string-scan': {let sum=0;for(const ch of text(seed)){const cp=ch.codePointAt(0);sum+=cp+(cp>=48&&cp<=57?1:0);}return add(seed,mul(size,sum));}
    case 'string-equality': return add(seed,seed%2===0?size:0);
    case 'tree-fold': return add(seed,mul(size,add(mul(seed,1024),496)));
    case 'tree-shared': return add(seed,mul(size,mul(add(mul(seed,1024),496),2)));
    case 'term-substitution': {const leaf=seed>=1&&seed<=size?seed:mul(add(seed,17),3);return add(u(2*size*(size+1)),leaf);}
    case 'term-freshening': return add(u(2*size*(size+1)),mul(seed,size+2));
    case 'term-normalization': return mul(add(seed,u(size*(size+1)/2)),2);
    case 'index-chain': return size===0?0:add(seed,size>>>1);
    case 'nat-reconstruction': return add(size,seed);
    case 'pinned-u32-table': {let sum=pop(seed);for(let i=0;i<size;i++)sum=add(sum,pop(i));return sum;}
    case 'pinned-u32-wide': {let sum=4;for(let i=0;i<size;i++)sum=add(sum,key(add(seed,i)));return sum;}
    default:throw Error('No oracle: '+id);
  }
}
