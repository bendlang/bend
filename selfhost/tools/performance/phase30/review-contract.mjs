// Independent runtime contract controls. No compiler candidate and no timing.
// Usage: node review-contract.mjs RUNTIME NEW_OUTPUT_DIRECTORY
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [runtimeArgument, outArgument] = process.argv.slice(2);
assert.ok(runtimeArgument && outArgument, 'usage: review-contract.mjs RUNTIME NEW_OUT');
const runtime = path.resolve(runtimeArgument), out = path.resolve(outArgument);
fs.mkdirSync(out, {recursive: false});
const sha = x => createHash('sha256').update(x).digest('hex');
const identity = file => ({file: fs.realpathSync(file), sha256: sha(fs.readFileSync(file))});
const json = x => JSON.stringify(x, (_, v) => typeof v === 'bigint' ? {$bigint: String(v)} : v, 2) + '\n';
const save = (name, x) => fs.writeFileSync(path.join(out, name), json(x), {flag: 'wx'});
const report = {kind: 'phase30-independent-runtime-contract', complete: false, pass: false,
  scope: 'Counterexamples and runtime-level matcher mechanism only; no frontend or candidate admission and no timing.',
  node: process.version, inputs: [identity(runtime), identity(import.meta.filename)], observations: [], counterexamples: []};
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-review-contract.mjs'));
try {
  const moduleFile = path.join(out, 'runtime.mjs');
  fs.writeFileSync(moduleFile, fs.readFileSync(runtime, 'utf8') + '\nexport {fn, jump, call, force, project, matcher1, G, constructors, constructorNative};\n', {flag: 'wx'});
  report.diagnostic = {...identity(moduleFile), appendOnly: true, originalPrefixSha256: sha(fs.readFileSync(runtime))};
  const {fn, jump, call, force, project, matcher1, G, constructors, constructorNative} = await import(pathToFileURL(moduleFile));
  constructors.ReviewPair = ['left', 'right']; constructorNative.ReviewPair = false;
  const observe = run => {const events=[];try{return {events, result:run(events)}}catch(e){return {events,error:{name:e.name,message:e.message}}}};
  const matchBody = (events, a) => {const x=a[0],y=a[1];events.push(['body',x,y]);return x+y;};
  const original = (value, events) => call(matcher1('ReviewPair', () => fn(2, a => matchBody(events,a))), [value]);
  // This shortcut deliberately reproduces apply's observable decision order.
  // It is the mechanism oracle, not proposed production source or an IR.
  const shortcut = (value, events) => {
    const p=project('ReviewPair',value);
    if(!p.length)return fn(2,a=>matchBody(events,a));
    const a=p.slice();
    if(a.length===2)return matchBody(events,a);
    if(a.length<2)return fn(2,a=>matchBody(events,a),null,a);
    let r=matchBody(events,a.slice(0,2));
    if(a.length>2)r=jump(force(r),a.slice(2));
    return force(r);
  };
  const normalize = value => value?.code ? {arity:value.arity,env:value.env,bound:[...value.bound]} : value;
  const evaluate=(run,make)=>observe(events=>normalize(run(make(events),events)));
  const modes = {
    plain: () => ({a:[3,5]}),
    frozen: () => ({a:Object.freeze([3,5])}),
    sparse: () => {const a=[];a.length=2;a[1]=5;return {a};},
    named: events => ({get left(){events.push('left');return 3},get right(){events.push('right');return 5}}),
    'a-getter': events => ({get a(){events.push('a');return [3,5]}}),
    proxy: events => ({a:new Proxy([3,5],{get(t,k,r){events.push(['get',String(k)]);return Reflect.get(t,k,r)},has(t,k){events.push(['has',String(k)]);return Reflect.has(t,k)}})}),
    'slice-throws': events => ({a:{length:2,slice(){events.push('slice');throw Error('slice sentinel')}}}),
    'first-field-throws': events => {const a=[];Object.defineProperty(a,0,{get(){events.push(0);throw Error('field sentinel')}});Object.defineProperty(a,1,{get(){events.push(1);return 5}});return {a}},
    'zero-no-slice': events => ({a:{get length(){events.push('length');return 0},get slice(){throw Error('unexpected slice')}}}),
    'changing-source-length': events => {let n=0;return {a:{0:3,1:5,get length(){const v=++n===1?2:1;events.push(['length',v]);return v},slice:Array.prototype.slice}}},
  };
  for(const size of [0,1,2,3,4])modes['slice-size-'+size]=events=>({a:{get length(){events.push('source.length');return 2},get slice(){events.push('source.slice');return function(){events.push(['slice receiver',this.length===2]);return Array.from({length:size},(_,i)=>i+3)}}}});
  modes['changing-copied-length']=events=>{const ns=[3,4,4,1];return {a:{length:2,slice(){return new Proxy([3,5,7,9],{get(t,k,r){if(k==='length'){const v=ns.shift()??4;events.push(['copied.length',v]);return v}return Reflect.get(t,k,r)}})}}}};
  for(const [name,make]of Object.entries(modes)){
    const a=evaluate(original,make),b=evaluate(shortcut,make);assert.deepEqual(b,a,name);report.observations.push({name,transcript:a});
  }
  // A fully saturated source expression still contains sequential demand.
  const demand=direct=>observe(events=>{
    const value={get a(){events.push('projection');throw Error('projection sentinel')}};
    const later=()=>{events.push('later');return 7};
    const matched=matcher1('ReviewPair',()=>fn(3,a=>a[0]+a[1]+a[2]));
    return direct?((v,y)=>call(matched,[v,y]))(value,later()):call(call(matched,[value]),[later()]);
  });
  const ordered=demand(false),eager=demand(true);assert.notDeepEqual(eager,ordered);assert.deepEqual(ordered.events,['projection']);assert.deepEqual(eager.events,['later','projection']);
  report.counterexamples.push({name:'eager-saturation-changes-demand',original:ordered,unsafe:eager});
  // Returning to the public matcher after projection repeats foreign effects.
  const fallback=repeat=>observe(events=>{
    const value={get a(){events.push('a');return [3]}};
    if(!repeat)return normalize(original(value,events));
    const p=project('ReviewPair',value);if(p.length!==2)return normalize(original(value,events));
    return p[0]+p[1];
  });
  const once=fallback(false),twice=fallback(true);assert.notDeepEqual(twice,once);assert.deepEqual(once.events,['a']);assert.deepEqual(twice.events,['a','a']);
  report.counterexamples.push({name:'reprojection-fallback-repeats-getter',original:once,unsafe:twice});
  // A zero-arity global reference is a computation, not a stable argument atom.
  {
    let calls=0;G.reviewInit=fn(0,()=>++calls);const getInit=()=>call(G.reviewInit,[]);
    assert.equal(getInit(),1);assert.equal(getInit(),2);report.observations.push({name:'global-initializer-not-an-atom',calls});
  }
  // A direct copy made after evaluating the next argument sees the wrong value.
  const snapshot=late=>observe(events=>{
    const fields=[3,5],value={a:fields},next=()=>{events.push('next');fields[0]=100;return 7};
    const matched=matcher1('ReviewPair',()=>fn(3,a=>[a[0],a[1],a[2]]));
    return late?((v,y)=>call(matched,[v,y]))(value,next()):call(call(matched,[value]),[next()]);
  });
  const early=snapshot(false),late=snapshot(true);assert.deepEqual(early.result,[3,5,7]);assert.deepEqual(late.result,[100,5,7]);
  report.counterexamples.push({name:'field-snapshot-before-later-argument',original:early,unsafe:late});
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  report.complete=true;report.pass=true;
} catch(error) {report.error=error.stack??String(error);process.exitCode=1;}
save('report.json',report);
console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,counterexamples:report.counterexamples.length,error:report.error}));
