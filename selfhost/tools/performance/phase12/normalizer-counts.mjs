// Disposable operation counters on the exact Phase11 image; no source candidate.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';

const [apiArg, outArg] = process.argv.slice(2);
const api = path.resolve(apiArg), out = path.resolve(outArg);
fs.mkdirSync(out, {recursive: false});
const identity = file => ({file: fs.realpathSync(file), sha256: createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs = [import.meta.filename, process.execPath, api].map(identity);
assert.equal(inputs[2].sha256, '63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f');
const report = {kind: 'phase12-normalizer-fallback-counts', complete: false, pass: false,
  scope: 'Actual emitted-helper counts on known finite raw terms and valid public source. Not B1, timing, allocations or semantic proof.',
  cpu: 2, inputs, hooks: [], rows: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();

try {
  let source = fs.readFileSync(api, 'utf8');
  function replaceIn(name, before, after) {
    const start = source.indexOf('function $' + name + '$(');
    const end = source.indexOf('\nfunction ', start + 1);
    assert.ok(start >= 0 && end > start);
    const part = source.slice(start, end);
    assert.equal(part.split(before).length, 2, name + ' exact hook');
    source = source.slice(0, start) + part.replace(before, () => after) + source.slice(end);
    report.hooks.push({name, before, after});
  }
  replaceIn('norm_ref', '($norm_apply$(_t_0, _args_0))', 'p12Fallback(_t_0, _args_0)');
  replaceIn('norm_args', 'return _fallback_0;', 'p12.efqUses++; return _fallback_0;');
  replaceIn('norm_stuck', 'return _fallback_0;', 'p12.stuckUses++; return _fallback_0;');
  source += `
let p12;
export function reset(){p12={built:0,spineEntries:0,efqUses:0,stuckUses:0,arities:{}};}
export function counts(){return structuredClone(p12);}
function p12Fallback(t,args){let n=0;for(let a=args;a.$==="Con";a=a.tail)n++;p12.built++;p12.spineEntries+=n;p12.arities[n]=(p12.arities[n]??0)+1;return $norm_apply$(t,args);}
export function weak(book,t){return run_loop($wnf$(book,t));}
reset();
`;
  const view = path.join(out, 'instrumented.mjs');
  fs.writeFileSync(view, source);
  report.instrumented = identity(view); save();
  const M = await import(pathToFileURL(view)), K = M.default;
  const nil = {$:'Nil'}, list = xs => xs.reduceRight((tail, head) => ({$:'Con',head,tail}), nil);
  const t = (tag,name='',id=0,kids=[]) => ({$:'KTerm',tag,name,id,quant:0,kids:list(kids),removed:nil});
  const app = (f,x) => t('App','',0,[f,x]);
  const def = (name,arity,value) => ({$:'KDef',name,kind:'Def',arity,templates:0,typ:t('Absent'),value,ctors:nil,native:false,unsafe:true});
  for (const n of [0,1,4,16,64]) {
    const value = t('Ctr','Result'); let body = value, term = t('Ref','f');
    for (let i=n; i>0; i--) body=t('Lam','x',i,[body]);
    for (let i=0; i<n; i++) term=app(term,t('Ctr','Arg'));
    const book=list([def('f',n,body)]), file=path.join(out,'raw-'+n+'.json');
    fs.writeFileSync(file,JSON.stringify({book,term})+'\n');
    M.reset(); const observed=M.weak(book,term), counts=M.counts();
    assert.deepEqual(observed,value); assert.equal(counts.built,1);
    assert.equal(counts.spineEntries,n); assert.equal(counts.efqUses+counts.stuckUses,0);
    report.rows.push({kind:'raw-constant',n,input:identity(file),observed,counts}); save();
  }
  for (const n of [0,1,4,16,64]) {
    const params=Array.from({length:n},(_,i)=>'+x'+i+': Bit').join(', ');
    const args=Array.from({length:n},(_,i)=>'x'+i).join(', ');
    const result=n?'x0':'Off{}';
    const text='type Bit is Data:\n  Off{}\n  On{}\n\n'+
      'def pick('+params+') -> Bit:\n  '+result+'\n\n'+
      'def proof('+params+') -> {pick('+args+') == '+result+' : Bit}:\n  {==}\n';
    const file=path.join(out,'public-'+n+'.bend'); fs.writeFileSync(file,text);
    const loaded=K.f_load_graph('Main',list([{$:'FSource',name:'Main',path:file,text}]));
    assert.equal(loaded.error,''); M.reset();
    const error=K.check_book(loaded.book), counts=M.counts();
    report.rows.push({kind:'public-proof',n,input:identity(file),error,counts}); save();
    assert.equal(error,''); assert.ok(counts.built>0);
  }
  const unknown=t('Var','x',900), match=t('Mat','A',0,[t('Ctr','B'),t('Efq')]);
  for (const [name,body] of [['stuck',match],['efq',t('Efq')]]) {
    const book=list([def('f',1,body)]), term=app(t('Ref','f'),unknown);
    const file=path.join(out,name+'.json');fs.writeFileSync(file,JSON.stringify({book,term})+'\n');
    M.reset();const observed=M.weak(book,term),counts=M.counts();
    assert.deepEqual(observed,term);assert.equal(counts.built,1);
    assert.equal(counts.efqUses+counts.stuckUses,1);
    report.rows.push({kind:'raw-needed',name,input:identity(file),observed,counts});save();
  }
  report.changedInputs=inputs.filter(i=>identity(i.file).sha256!==i.sha256);
  report.complete=true; report.pass=report.changedInputs.length===0;
} catch (error) { report.error=String(error.stack??error); }
save();
console.log(JSON.stringify({pass:report.pass,error:report.error,rows:report.rows.map(({kind,n,name,counts})=>({kind,n,name,counts}))}));
if(!report.pass)process.exitCode=1;
