// Experimental checked-B1 derivative: literal choice thunks, same tail boundary.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const sha=s=>createHash('sha256').update(s).digest('hex');
const marker='// Program\n// =======\n';
const runtime='241696c207b257ba28e159699e08e749c1625542a92d901a663ac3f04dfd20fd';
const names=new Set(['$kc$','$f_choose$','$nt_choose$']);
export function tokens(source,start){
 const out=[];for(let i=start;i<source.length;){if(/\s/.test(source[i])){i++;continue;}const at=i,c=source[i];if(c==='"'||c==="'"){let closed=false;for(i++;i<source.length;i++){if(source[i]==='\\'){i++;continue;}assert.ok(source[i]!=='\n'&&source[i]!=='\r','Multiline string');if(source[i]===c){i++;closed=true;break;}}assert.ok(closed,'Unclosed string');}else if(/[A-Za-z_$]/.test(c)){while(i<source.length&&/[\w$]/.test(source[i]))i++;}else{assert.ok(c!=='`'&&!source.startsWith('//',i)&&!source.startsWith('/*',i),'Unsupported generated syntax');i++;}out.push({text:source.slice(at,i),start:at,end:i});}
 const stack=[];for(let i=0;i<out.length;i++){const t=out[i].text;if('([{'.includes(t)&&t.length===1)stack.push(i);else if(')]}'.includes(t)&&t.length===1){const k=stack.pop();assert.ok(k!==undefined&&'([{'.indexOf(out[k].text)===')]}'.indexOf(t),'Unbalanced module');out[k].close=i;}}
 assert.equal(stack.length,0);return out;
}
function choiceBody(name){return `function ${name}(_b_0, _yes_0, _no_0) {\n  if (_b_0) {\n    return run_tail(_yes_0, {$: "Unit"});\n  } else {\n    return run_tail(_no_0, {$: "Unit"});\n  }\n}`;}
export function transformChoices(source){
 const markerAt=source.indexOf(marker);assert.ok(markerAt>=0,'Missing runtime boundary');const start=markerAt+marker.length;assert.equal(sha(source.slice(0,start)),runtime,'Unknown runtime');const ts=tokens(source,start),functions=new Map();let at=0;
 while(ts[at]?.text==='function'){const first=at,name=ts[at+1]?.text;assert.match(name,/^\$[\w$]+\$$/);assert.equal(ts[at+2]?.text,'(');const body=ts[at+2].close+1;assert.equal(ts[body]?.text,'{');const end=ts[body].close;assert.ok(!functions.has(name),'Duplicate function');functions.set(name,{start:first,end,source:source.slice(ts[first].start,ts[end].end)});at=end+1;}
 assert.equal(ts[at]?.text,'export');assert.equal(ts[at+1]?.text,'default');assert.equal(ts[at+2]?.text,'{');assert.equal(ts[at+2].close,ts.length-2);assert.equal(ts.at(-1).text,';');
 for(const name of names)assert.equal(functions.get(name)?.source,choiceBody(name),'Unsupported choice body: '+name);
 const protectedNames=new Set([...names,'run_clo','run_tail','run_loop']);
 for(let j=0;j<ts.length;j++){
  let params;if(ts[j].text==='function')params=j+2;else if(ts[j].text==='('&&ts[ts[j].close+1]?.text==='='&&ts[ts[j].close+2]?.text==='>')params=j;
  if(params!==undefined){assert.equal(ts[params]?.text,'(');assert.ok(!ts.slice(params+1,ts[params].close).some(t=>protectedNames.has(t.text)),'Shadowed protected parameter');}
  if(!protectedNames.has(ts[j].text))continue;const prev=ts[j-1]?.text,next=ts[j+1]?.text;
  assert.ok(!['let','const','var'].includes(prev)&&next!=='='&&!(['+','-','*','/','&','|','^','?'].includes(next)&&['=',next].includes(ts[j+2]?.text)),'Rebound dependency');
  if(prev==='function')assert.equal(functions.get(ts[j].text)?.start,j-1,'Nested protected declaration');else assert.ok(next==='('&&!['.','new'].includes(prev),'Unsupported protected reference or member callee');
 }
 const sites=new Map(),skipped=[];
 const split=(open)=>{const args=[];let begin=open+1;for(let i=begin;i<ts[open].close;i++){if(ts[i].close!==undefined){i=ts[i].close;continue;}if(ts[i].text===','){args.push([begin,i]);begin=i+1;}}if(begin<ts[open].close)args.push([begin,ts[open].close]);return args;};
 const arrow=([lo,hi])=>{if(ts[lo]?.text!=='run_clo'||ts[lo+1]?.text!=='('||ts[lo+1].close!==hi-1)return null;const p=lo+2;if(ts[p]?.text!=='('||ts[p].close!==p+2||!/^[A-Za-z_$][\w$]*$/.test(ts[p+1]?.text??'')||ts[p+3]?.text!=='='||ts[p+4]?.text!=='>'||ts[p+5]?.text!=='{'||ts[p+5].close!==hi-2)return null;return [p,hi-1];};
 for(let i=0;i<at;i++)if(names.has(ts[i].text)&&ts[i-1]?.text!=='function'&&ts[i+1]?.text==='('){const end=ts[i+1].close,args=split(i+1),yes=args.length===3?arrow(args[1]):null,no=args.length===3?arrow(args[2]):null;if(yes&&no)sites.set(i,{first:i,end,args,yes,no});else skipped.push({at:ts[i].start,name:ts[i].text,argumentCount:args.length});}
 const render=(lo,hi)=>{if(lo===hi)return '';let output='',cursor=ts[lo].start;for(let i=lo;i<hi;i++){const s=sites.get(i);if(!s||s.end>=hi)continue;output+=source.slice(cursor,ts[i].start)+'run_tail(('+render(...s.args[0])+') ? ('+render(...s.yes)+') : ('+render(...s.no)+'), {$: "Unit"})';cursor=ts[s.end].end;i=s.end;}return output+source.slice(cursor,ts[hi-1].end);};
 const program=source.slice(0,start)+source.slice(start,ts[0].start)+render(0,ts.length)+source.slice(ts.at(-1).end);
 return {source:program,report:{kind:'literal-choice-tail-derivative',version:1,runtimeSha256:runtime,inputSha256:sha(source),outputSha256:sha(program),sites:sites.size,skipped,protectedBodies:[...names].map(name=>({name,sha256:sha(functions.get(name).source)})),scope:'Only saturated structurally verified choices with two literal run_clo arrows; keep original runtime, exports and trampoline boundary.'}};
}
