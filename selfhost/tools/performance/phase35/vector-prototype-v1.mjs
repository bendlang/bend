#!/usr/bin/env node
// Saved-output ablation. It changes private copies only; it is not compiler output.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const [input, output, fixture, mode='scalar'] = process.argv.slice(2);
assert(input && output && ['pair','fold'].includes(fixture) && ['inline','scalar'].includes(mode),
  'usage: node vector-prototype.mjs INPUT NEW_OUTPUT pair|fold inline|scalar');
assert(!fs.existsSync(output), 'output already exists');
const source=fs.readFileSync(input,'utf8');
const hash=s=>crypto.createHash('sha256').update(s).digest('hex');
const privateName=n=>'$R_'+Array.from(n,c=>c.codePointAt(0)).join('_');
const target=privateName(fixture==='pair'?'row':'fold.loop');
const acornSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}}; new Function('module','exports',acornSource)(parserModule,parserModule.exports);
assert.equal(parserModule.exports.version,'8.16.0');
const parse=s=>parserModule.exports.parse(s,{ecmaVersion:'latest',sourceType:'module'});
const matches=[];
function walk(n) {if(!n||typeof n!=='object')return;if(n.type==='FunctionDeclaration'&&n.id.name===target)matches.push(n);for(const [k,v] of Object.entries(n)){if(k==='loc')continue;if(Array.isArray(v))v.forEach(walk);else if(v&&typeof v==='object')walk(v);}}
walk(parse(source)); assert(matches.length>0,'private target missing');
const read=(a,i)=>`arraydata(${a})[Number(${i})%arraydata(${a}).length]`;
// Capture arraydata once per original logical read, retaining each read in order.
const get=(d,v,a,i)=>`const ${d}=arraydata(${a});const ${v}=${d}[Number(${i})%${d}.length];`;
const cell=get('$bd','$bv','$b','$i')+get('$pd','$dg','$prev','$i')+
  get('$ud','$up','$prev','(($i+1)>>>0)')+get('$cd','$lf','$curr','$i')+
  'const $diag=($dg+($av!==$bv?1:0))>>>0;const $left=($lf+1)>>>0;const $above=($up+1)>>>0;'+
  'const $best=$above<$left?$above:$left;const $value=$best<$diag?$best:$diag;'+
  '$curr=arrayset($curr,($i+1)>>>0,$value);';
let body;
if(fixture==='pair') {
  const head='function '+target+'($p0,$p1,$p2,$p3){';
  if(mode==='scalar') body=head+'let $a=$p3[0],$b=$p3[1],$prev=$p3[2],$curr=$p3[3];let $n=$p0,$i=$p1;const $av=$p2;while($n!==0n){'+cell+'$n=$n-1n;$i=($i+1)>>>0;}return [$a,$b,$curr,$prev];}';
  else body=head+'let $st=$p3,$n=$p0,$i=$p1;const $av=$p2;while($n!==0n){let $a=$st[0],$b=$st[1],$prev=$st[2],$curr=$st[3];'+cell+'$st=[$a,$b,$prev,$curr];$n=$n-1n;$i=($i+1)>>>0;}return [$st[0],$st[1],$st[3],$st[2]];}';
} else {
  const head='function '+target+'($p0,$p1,$p2){if($p0===0n)return $p2;';
  const step=get('$data','$v','$a','$i')+'const $next=($acc+$v)>>>0;$a=arrayset($a,$i,($next^$i)>>>0);';
  if(mode==='scalar') body=head+'let $n=$p0,$i=$p1,$a=$p2[0],$acc=$p2[1];while($n!==0n){'+step+'$acc=$next;$i=($i+1)>>>0;$n=$n-1n;}return [$a,$acc];}';
  else body=head+'let $n=$p0,$i=$p1,$st=$p2;while($n!==0n){let $a=$st[0],$acc=$st[1];'+step+'$st=[$a,$next];$i=($i+1)>>>0;$n=$n-1n;}return $st;}';
}
let result=source;
for(const n of matches.sort((a,b)=>b.start-a.start)) result=result.slice(0,n.start)+body+result.slice(n.end);
parse(result); fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,result);
fs.writeFileSync(output+'.json',JSON.stringify({kind:'phase35-private-vector-prototype',checked:false,
  scope:'Explicit saved-output mechanism ablation, not a reusable compiler transformation. Public implementations, admission guards and native primitives are unchanged.',
  fixture,mode,replacements:matches.length,input:{path:path.resolve(input),sha256:hash(source)},
  output:{path:path.resolve(output),sha256:hash(result)},producer:{path:path.resolve(process.argv[1]),sha256:hash(fs.readFileSync(process.argv[1]))},
  parserSha256:hash(acornSource),node:process.version},null,2)+'\n');
console.log(JSON.stringify({fixture,mode,replacements:matches.length,output,sha256:hash(result)}));
