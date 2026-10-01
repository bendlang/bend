#!/usr/bin/env node
// Parse generated JavaScript without importing it. Static sites are not costs.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath, pathToFileURL} from 'node:url';

const TOOL = fileURLToPath(import.meta.url);
const sha = data => createHash('sha256').update(data).digest('hex');
const identity = file => { const data = fs.readFileSync(file); return {path:path.resolve(file),sha256:sha(data),bytes:data.length}; };
const FUNCTIONS = new Set(['FunctionDeclaration','FunctionExpression','ArrowFunctionExpression']);
const METRICS = ['astNodes','functionDeclarations','functionExpressions','arrowFunctions','nestedFunctionSites',
  'blockScopes','calls','directCalls','memberCalls','iifes','newExpressions','arrayLiteralSites','arrayLiteralSlots',
  'objectLiteralSites','spreadSites','bigIntLiterals','bigIntConversionCalls','numericConversionCalls','branches',
  'loops','switchCases','throwSites','returnSites','trampolineHelperCalls','closureHelperCalls','scopeHelperCalls',
  'globalLookupCalls','constructorHelperCalls','projectionHelperCalls','arrayHelperCalls','argumentArraySites'];
const TRAMPOLINE = new Set(['call','callOwned','apply','force','jump','run_tail','run_loop','run_clo']);
const CONSTRUCTORS = new Set(['ctor','build','array_new','arrayfill','array_node']);
const PROJECTIONS = new Set(['project','fields','matcher','matcher1']);
const ARRAY_HELPERS = new Set(['arraydata','arrayset','arrayfill','array_new','array_node','array_rmw','arrayget']);
const SCOPES = new Set(['scope','lookup','bind','scopeGet','scopeSet']);
const META = new Set(['constructors','constructorOwn','constructorNative','showSchemas']);
const emptyMetrics = () => Object.fromEntries(METRICS.map(key => [key,0]));
const add = (map,key,n=1) => { map[key] = (map[key] || 0) + n; };
const name = node => node?.type === 'Identifier' ? node.name : null;
const value = node => node?.type === 'Literal' ? node.value : undefined;
const isNode = node => node && typeof node.type === 'string';
const escape = text => String(text).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

function parser() {
  const key = 'internal/deps/acorn/acorn/dist/acorn';
  const source = process.binding('natives')[key];
  assert.equal(typeof source,'string','This Node does not expose embedded Acorn; refusing a text-scanner fallback');
  const module = {exports:{}};
  // The only evaluated source is the parser embedded in this Node executable.
  new Function('exports','module',source)(module.exports,module);
  assert.equal(module.exports.version,'8.16.0','Unsupported embedded Acorn version; use the recorded Node 24.18.0');
  return {...module.exports,identity:{provider:'Node embedded Acorn',version:module.exports.version,
    sourceName:key,sha256:sha(source),node:process.version,executable:identity(process.execPath)}};
}
const ACORN = parser();

function children(node) {
  const result = [];
  for (const [key,v] of Object.entries(node)) {
    if (key === 'loc') continue;
    if (isNode(v)) result.push({node:v,key});
    else if (Array.isArray(v)) for (const item of v) if (isNode(item)) result.push({node:item,key});
  }
  return result;
}
function visit(root,fn,exclusive=false) {
  const stack = [{node:root,parent:null,key:null}];
  while (stack.length) {
    const item = stack.pop(); fn(item.node,item.parent,item.key);
    if (exclusive && item.node !== root && FUNCTIONS.has(item.node.type)) continue;
    const next = children(item.node);
    for (let i=next.length-1;i>=0;i--) stack.push({...next[i],parent:item.node});
  }
}
function member(node) {
  if (node?.type !== 'MemberExpression') return null;
  const p = node.computed ? value(node.property) : name(node.property);
  return typeof p === 'string' ? {object:name(node.object),property:p} : null;
}
function target(node) {
  if (name(node)) return node.name;
  const m = member(node);
  return m ? `${m.object || '<expression>'}.${m.property}` : '<dynamic>';
}
function assignment(node) {
  if (node?.type !== 'AssignmentExpression' || node.operator !== '=') return null;
  return member(node.left);
}
function globalName(node) {
  const m = assignment(node); return m?.object === 'G' ? m.property : null;
}
function keyName(node) {
  if (node?.type !== 'Property') return null;
  return node.computed ? value(node.key) : name(node.key) ?? value(node.key);
}
function count(metrics,node,parent,nesting=0) {
  metrics.astNodes++;
  const types = {FunctionDeclaration:'functionDeclarations',FunctionExpression:'functionExpressions',
    ArrowFunctionExpression:'arrowFunctions',BlockStatement:'blockScopes',NewExpression:'newExpressions',
    ObjectExpression:'objectLiteralSites',SpreadElement:'spreadSites',IfStatement:'branches',
    ConditionalExpression:'branches',SwitchStatement:'branches',SwitchCase:'switchCases',
    ForStatement:'loops',ForInStatement:'loops',ForOfStatement:'loops',WhileStatement:'loops',
    DoWhileStatement:'loops',ThrowStatement:'throwSites',ReturnStatement:'returnSites'};
  if (types[node.type]) metrics[types[node.type]]++;
  if (FUNCTIONS.has(node.type) && nesting > 0) metrics.nestedFunctionSites++;
  if (node.type === 'Literal' && node.bigint !== undefined) metrics.bigIntLiterals++;
  if (node.type === 'ArrayExpression') {
    metrics.arrayLiteralSites++; metrics.arrayLiteralSlots += node.elements.length;
    if (parent?.type === 'CallExpression' && TRAMPOLINE.has(name(parent.callee))) metrics.argumentArraySites++;
  }
  if (node.type !== 'CallExpression') return;
  metrics.calls++;
  if (name(node.callee)) metrics.directCalls++;
  if (node.callee.type === 'MemberExpression') metrics.memberCalls++;
  if (FUNCTIONS.has(node.callee.type)) metrics.iifes++;
  const call = name(node.callee);
  if (call === 'BigInt') metrics.bigIntConversionCalls++;
  if (call === 'Number') metrics.numericConversionCalls++;
  if (TRAMPOLINE.has(call)) metrics.trampolineHelperCalls++;
  if (['fn','exactCode','scalarCapture','run_clo'].includes(call)) metrics.closureHelperCalls++;
  if (SCOPES.has(call)) metrics.scopeHelperCalls++;
  if (call === 'get' && name(node.arguments[0]) === 'G') metrics.globalLookupCalls++;
  if (CONSTRUCTORS.has(call)) metrics.constructorHelperCalls++;
  if (PROJECTIONS.has(call)) metrics.projectionHelperCalls++;
  if (ARRAY_HELPERS.has(call)) metrics.arrayHelperCalls++;
}
function metrics(root,exclusive=false) {
  const out = emptyMetrics(), depth = new Map();
  visit(root,(n,p)=>{const nesting=p?depth.get(p):0;count(out,n,p,nesting);depth.set(n,nesting+Number(FUNCTIONS.has(n.type)));},exclusive);
  return out;
}
function sum(rows) {
  const out = emptyMetrics(); for (const row of rows) for (const key of METRICS) out[key] += row[key]; return out;
}
const delta = (left,right) => Object.fromEntries(METRICS.map(key=>[key,right[key]-left[key]]));
function range(node) {
  return {startUtf16:node.start,endUtf16:node.end,line:node.loc.start.line,column:node.loc.start.column,
    endLine:node.loc.end.line,endColumn:node.loc.end.column};
}
function declaredNames(source) {
  // Name inventory, not a Bend parser. JS registration/export evidence maps it.
  const result = new Map();
  for (const [i,line] of source.split('\n').entries()) {
    const m = /^(?:def|law|type)\s+([^\s(:<{=]+)/u.exec(line);
    if (m) result.set(m[1],i+1);
  }
  return result;
}
function decodedRegion(identifier) {
  const match = /^\$R((?:_\d+)+)(?:\$[A-Za-z0-9_]+)?$/.exec(identifier || '');
  if (!match) return null;
  const points = match[1].slice(1).split('_').map(Number);
  if (points.some(p=>p>0x10ffff)) return null;
  return String.fromCodePoint(...points);
}
function normalized(source) {
  const tokens = [...ACORN.tokenizer(source,{ecmaVersion:2025,sourceType:'module'})];
  const rows = tokens.filter(t=>t.type.label!=='eof').map(t=>{
    let spelling;
    if (t.value === undefined) spelling=t.type.label;
    else if (typeof t.value === 'bigint') spelling=`${t.value}n`;
    else spelling=JSON.stringify(t.value);
    return `${t.type.label}\t${spelling}`;
  });
  return {tokenCount:rows.length,normalizedSha256:sha(rows.join('\n')),text:rows.join('\n')+'\n'};
}
function boundary(source,ast,comments,config,inputs) {
  if (config.runtimePath) {
    const p=path.resolve(config.runtimePath),raw=fs.readFileSync(p),runtime=raw.toString('utf8');
    assert.ok(Buffer.from(runtime).equals(raw),'Runtime is not canonical UTF-8'); inputs.push(identity(p));
    assert.ok(source.startsWith(runtime),'Supplied runtime does not exactly prefix this generated module');
    return {offsetUtf16:runtime.length,method:'Exact supplied runtime prefix',confidence:'exact',section:'runtimePrefix',sha256:sha(raw)};
  }
  if (config.family === 'upstream') {
    const markers=comments.filter(c=>c.value.trim()==='Program' && source.slice(c.start).startsWith('// Program\n// =======\n'));
    assert.ok(markers.length<=1,'Ambiguous upstream Program boundary');
    if (markers.length) return {offsetUtf16:markers[0].start+'// Program\n// =======\n'.length,
      method:'Parsed upstream Program comment; prefix can contain runtime and foreign support',confidence:'marker',section:'runtimeSupportPrefix'};
  }
  if (config.family === 'selfhost') {
    const first = ast.body.find(top=>{
      if (top.type!=='ExpressionStatement' && top.type!=='IfStatement') return false;
      let found=false; visit(top,n=>{const a=assignment(n);if(a && (a.object==='G'||META.has(a.object)||a.object==='foreignModules')) found=true;},true);
      return found;
    });
    if (first) return {offsetUtf16:first.start,method:'First top-level generated registration/metadata statement; preceding support is inferred',confidence:'inferred',section:'runtimeSupportPrefix'};
  }
  return {offsetUtf16:0,method:'No verified emitter boundary; all non-export code unclassified',confidence:'unknown',section:'unclassified'};
}
function classify(top,bound) {
  if (top.end<=bound.offsetUtf16) return bound.section;
  assert.ok(top.start>=bound.offsetUtf16,'Runtime boundary splits a JavaScript statement');
  if (top.type.startsWith('Export')) return 'exportWrapper';
  const a=assignment(top.type==='ExpressionStatement'?top.expression:null);
  if (META.has(a?.object)) return 'programMetadata';
  if (a?.object==='foreignModules') return 'foreignSupport';
  return bound.confidence==='unknown'?'unclassified':'program';
}
function functionName(node,parent) {
  if (node.id) return node.id.name;
  if (parent?.type==='VariableDeclarator') return name(parent.id)||'<destructuring>';
  if (parent?.type==='Property') return String(keyName(parent));
  if (parent?.type==='CallExpression') return `${target(parent.callee)}:argument${parent.arguments.indexOf(node)}`;
  return `<${node.type}@${node.loc.start.line}:${node.loc.start.column}>`;
}

export function analyzeEntry(config) {
  assert.ok(config && ['upstream','selfhost'].includes(config.family),'Specify the emitter family');
  assert.ok(typeof config.id==='string' && typeof config.role==='string','Missing id or role');
  const file=path.resolve(config.path),raw=fs.readFileSync(file),source=raw.toString('utf8');
  assert.ok(Buffer.from(source).equals(raw),'Module is not canonical UTF-8');
  if (config.sha256) assert.equal(sha(raw),config.sha256,'Module hash differs');
  const sourceFile=path.resolve(config.sourcePath),sourceRaw=fs.readFileSync(sourceFile),bendSource=sourceRaw.toString('utf8');
  assert.ok(Buffer.from(bendSource).equals(sourceRaw),'Bend source is not canonical UTF-8');
  if (config.sourceSha256) assert.equal(sha(sourceRaw),config.sourceSha256,'Bend source hash differs');
  const inputs=[identity(file),identity(sourceFile)],sourceNames=declaredNames(bendSource),comments=[];
  const ast=ACORN.parse(source,{ecmaVersion:2025,sourceType:'module',locations:true,onComment:comments});
  const bound=boundary(source,ast,comments,config,inputs),parents=new Map(),topOf=new Map(),sections={},topSections=new Map();
  let cursor=0;
  for (const top of ast.body) {
    const section=classify(top,bound); topSections.set(top,section);
    if(top.start>=bound.offsetUtf16&&cursor<bound.offsetUtf16) {
      const prefix=sections[bound.section] ||= {bytes:0,topLevelStatements:0,metrics:emptyMetrics()};
      prefix.bytes+=Buffer.byteLength(source.slice(cursor,bound.offsetUtf16));cursor=bound.offsetUtf16;
    }
    const row=sections[section] ||= {bytes:0,topLevelStatements:0,metrics:emptyMetrics()};
    row.bytes+=Buffer.byteLength(source.slice(cursor,top.end)); row.topLevelStatements++; cursor=top.end;
    row.metrics=sum([row.metrics,metrics(top)]);
    visit(top,(n,p)=>{parents.set(n,p);topOf.set(n,top);});
  }
  if (ast.body.length) sections[topSections.get(ast.body.at(-1))].bytes+=Buffer.byteLength(source.slice(cursor));
  else sections.unclassified={bytes:raw.length,topLevelStatements:0,metrics:emptyMetrics()};
  assert.equal(Object.values(sections).reduce((a,s)=>a+s.bytes,0),raw.length);
  const topFunctions=new Map(ast.body.filter(n=>n.type==='FunctionDeclaration'&&topSections.get(n)==='program').map(n=>[n.id.name,n]));
  const exported=new Map();
  for (const top of ast.body) if (top.type==='ExportDefaultDeclaration' && top.declaration.type==='ObjectExpression') {
    for (const property of top.declaration.properties) {
      const bendName=keyName(property); if (typeof bendName!=='string') continue;
      const calls=new Set(); visit(property.value,n=>{if(n.type==='CallExpression'&&topFunctions.has(name(n.callee))) calls.add(n.callee.name);});
      if (calls.size===1) {const key=[...calls][0];const rows=exported.get(key)||[];rows.push(bendName);exported.set(key,rows);}
    }
  }
  function ownership(node) {
    if (node.type==='FunctionDeclaration') {
      const decoded=decodedRegion(node.id.name);
      if (decoded) return {bendNames:[decoded],method:'Encoded private-region function name',confidence:'convention'};
      if (exported.has(node.id.name)) return {bendNames:exported.get(node.id.name),method:'Sole top-level function called by named export wrapper',confidence:'syntax'};
      if (config.family==='upstream') {
        const matched=[...sourceNames.keys()].filter(n=>`$${n.replaceAll('.','$')}$`===node.id.name);
        if (matched.length===1) return {bendNames:matched,method:'Upstream generated identifier convention',confidence:'convention'};
      }
    }
    for (let at=node;at;at=parents.get(at)) {
      const global=globalName(at); if(global!==null) return {bendNames:[global],method:'Enclosing literal G registration',confidence:'syntax'};
      if (at!==node && at.type==='FunctionDeclaration') {
        const outer=ownership(at); if(outer.bendNames.length) return outer;
      }
    }
    return {bendNames:[],method:'No source-name association established',confidence:'unknown'};
  }
  const functions=[],calls={},units=new Map([...sourceNames].map(([n,line])=>[n,{name:n,sourceLine:line,units:[]}]));
  const sharedArrayTables=[];
  for(const top of ast.body) if(topSections.get(top)==='program'&&top.type==='VariableDeclaration') {
    for(const d of top.declarations) if(name(d.id)&&d.init?.type==='ArrayExpression') {
      const users=[]; visit(ast,n=>{if(n.type==='MemberExpression'&&name(n.object)===d.id.name)users.push({...range(n),...ownership(n)});});
      sharedArrayTables.push({name:d.id.name,...range(d),elements:d.init.elements.length,
        bytes:Buffer.byteLength(source.slice(d.start,d.end)),metricsInclusive:metrics(d),users});
    }
  }
  const unitText=[];
  function addUnit(node,bendName,mapping,kind) {
    if (!units.has(bendName)) return;
    const text=source.slice(node.start,node.end),norm=normalized(text);
    const row={kind,...range(node),bytes:Buffer.byteLength(text),sha256:sha(text),
      tokenCount:norm.tokenCount,normalizedSha256:norm.normalizedSha256,metricsInclusive:metrics(node),mapping};
    if(units.get(bendName).units.some(u=>u.startUtf16===row.startUtf16&&u.endUtf16===row.endUtf16)) return;
    units.get(bendName).units.push(row); unitText.push({name:bendName,unit:row,source:text,normalized:norm.text});
  }
  visit(ast,(n,p)=>{
    const section=topSections.get(topOf.get(n))||'unclassified';
    if (n.type==='CallExpression') add(calls,`${section}\0${target(n.callee)}`);
    if (FUNCTIONS.has(n.type)) {
      const own=ownership(n);
      functions.push({name:functionName(n,p),kind:n.type,...range(n),section,bendNames:own.bendNames,
        mapping:{method:own.method,confidence:own.confidence},formalParameters:n.params.length,
        bytes:Buffer.byteLength(source.slice(n.start,n.end)),metricsExclusive:metrics(n,true)});
      if(n.type==='FunctionDeclaration') for (const bendName of own.bendNames) addUnit(n,bendName,own,'function');
    }
    const global=globalName(n);
    if (global!==null) addUnit(n,global,{method:'Literal G registration',confidence:'syntax'},'registration');
  });
  for(const row of units.values()) row.totals={unitCount:row.units.length,bytesInclusive:row.units.reduce((a,u)=>a+u.bytes,0),
    tokensInclusive:row.units.reduce((a,u)=>a+u.tokenCount,0),metricsInclusive:sum(row.units.map(u=>u.metricsInclusive))};
  const programInventory={sourceOwnedTopLevel:{statements:0,bytes:0,metrics:emptyMetrics()},
    otherTopLevel:{statements:0,bytes:0,metrics:emptyMetrics()}};
  for(const top of ast.body) if(topSections.get(top)==='program') {
    let owned=top.type==='FunctionDeclaration'&&ownership(top).bendNames.some(n=>sourceNames.has(n));
    if(!owned)visit(top,n=>{if(sourceNames.has(globalName(n)))owned=true;},true);
    const bucket=programInventory[owned?'sourceOwnedTopLevel':'otherTopLevel'];
    bucket.statements++;bucket.bytes+=Buffer.byteLength(source.slice(top.start,top.end));bucket.metrics=sum([bucket.metrics,metrics(top)]);
  }
  programInventory.triviaBytes=(sections.program?.bytes||0)-programInventory.sourceOwnedTopLevel.bytes-programInventory.otherTopLevel.bytes;
  for(const input of inputs) assert.equal(identity(input.path).sha256,input.sha256,'Input changed during syntax analysis');
  return {report:{id:config.id,role:config.role,family:config.family,path:file,sha256:sha(raw),bytes:raw.length,
    physicalLines:source.split('\n').length-Number(source.endsWith('\n')),sourcePath:sourceFile,sourceSha256:sha(sourceRaw),
    boundary:bound,metrics:metrics(ast),sections,programInventory,functions,sharedArrayTables,definitions:[...units.values()],
    callTargets:Object.entries(calls).map(([key,sites])=>{const [section,name]=key.split('\0');return {section,name,sites};}).sort((a,b)=>b.sites-a.sites)},unitText,inputs};
}

function compare(left,right) {
  assert.equal(left.sourceSha256,right.sourceSha256,'Comparison sources differ');
  const rightDefs=new Map(right.definitions.map(d=>[d.name,d]));
  return {id:left.id,leftRole:left.role,rightRole:right.role,metricsDelta:delta(left.metrics,right.metrics),
    programMetricsDelta:delta(left.sections.program?.metrics||emptyMetrics(),right.sections.program?.metrics||emptyMetrics()),
    definitions:left.definitions.map(a=>{
      const b=rightDefs.get(a.name); assert.ok(b,'Missing source definition in comparison');
      const present=a.units.length>0&&b.units.length>0;
      return {name:a.name,leftUnits:a.units.length,rightUnits:b.units.length,
        normalizedEqual:present?a.units.map(u=>u.normalizedSha256).join(',')===b.units.map(u=>u.normalizedSha256).join(','):null,
        tokenDelta:b.totals.tokensInclusive-a.totals.tokensInclusive,
        metricsDelta:delta(a.totals.metricsInclusive,b.totals.metricsInclusive)};
    })};
}
function markdown(report) {
  const lines=['# Generated JavaScript syntax comparison','',report.semantics.counts,'',
    '| Case / role | Module bytes | Post-runtime bytes (includes Base) | Post-runtime calls | Function-expression / arrow sites | Array / object literal sites | BigInt literal / conversion sites |',
    '|---|---:|---:|---:|---:|---:|---:|'];
  for(const row of report.entries) {const p=row.sections.program;const m=p?.metrics||emptyMetrics();
    lines.push(`| ${row.id} / ${row.role} | ${row.bytes} | ${p?.bytes??'unclassified'} | ${m.calls} | ${m.functionExpressions+m.arrowFunctions} | ${m.arrayLiteralSites} / ${m.objectLiteralSites} | ${m.bigIntLiterals} / ${m.bigIntConversionCalls} |`);}
  lines.push('','Top-level statements mapped to declarations in the selected Bend source, excluding copied runtime, Base-only registrations and shared support declarations:',
    '', '| Case / role | Source-owned bytes | Source-owned calls | Function-expression / arrow sites | Array / object literal sites | Trampoline helper sites | BigInt literal / conversion sites |',
    '|---|---:|---:|---:|---:|---:|---:|');
  for(const row of report.entries) {const p=row.programInventory.sourceOwnedTopLevel,m=p.metrics;
    lines.push(`| ${row.id} / ${row.role} | ${p.bytes} | ${m.calls} | ${m.functionExpressions+m.arrowFunctions} | ${m.arrayLiteralSites} / ${m.objectLiteralSites} | ${m.trampolineHelperCalls} | ${m.bigIntLiterals} / ${m.bigIntConversionCalls} |`);}
  lines.push('','These source-owned statement ranges are disjoint. They include any private specializations nested inside an owned registration, but omit shared helper/table declarations that those functions can use. Missing mappings can make this inventory incomplete; the per-definition comparison keeps unmatched names visible.',
    '`programInventory` retains the other support counts and trivia separately. `sharedArrayTables` records top-level array constants and their indexing sites.',
    'Open [comparison.html](comparison.html) for aligned Bend-definition source and token comparisons.',
    'Per-role normalized files retain token kind and value, removing formatting and comments. They are not a semantic normal form.',
    'Function metrics exclude nested bodies. Definition metrics include nested units and must not be summed as disjoint execution or allocation counts.','');
  return lines.join('\n');
}
function html(report,texts) {
  const parts=['<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Generated JavaScript comparison</title>',
    '<style>body{font:15px system-ui;margin:2em}table{width:100%;table-layout:fixed;border-collapse:collapse}td,th{border:1px solid #bbb;vertical-align:top;padding:.5em}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:12px monospace}summary{cursor:pointer;padding:.5em;background:#eef}details{margin:1em 0}.missing{color:#777}</style>',
    '<h1>Generated JavaScript comparison</h1><p>Static syntax sites, not execution frequency or allocation measurements. Source names align definitions, not equivalent optimization regions. Private specializations may also be nested in another definition; these displays can overlap.</p>'];
  for(const cmp of report.comparisons) {
    const key=role=>`${cmp.id}\0${role}`,left=texts.get(key(cmp.leftRole)),right=texts.get(key(cmp.rightRole));
    parts.push(`<h2>${escape(cmp.id)}: ${escape(cmp.leftRole)} → ${escape(cmp.rightRole)}</h2>`);
    for(const def of cmp.definitions) {
      if (!def.leftUnits&&!def.rightUnits) continue;
      parts.push(`<details><summary>${escape(def.name)} — ${def.leftUnits} / ${def.rightUnits} units; token delta ${def.tokenDelta}; ${def.normalizedEqual===true?'same normalized tokens':def.normalizedEqual===null?'one side absent':'different normalized tokens'}</summary><table><tr><th>${escape(cmp.leftRole)}</th><th>${escape(cmp.rightRole)}</th></tr><tr>`);
      for(const rows of [left,right]) {
        const matching=rows.filter(x=>x.name===def.name);
        parts.push('<td>');
        if(!matching.length) parts.push('<p class="missing">No mapping established; absence is not proof of dead-code elimination.</p>');
        for(const row of matching) parts.push(`<p>${escape(row.unit.kind)} at ${row.unit.line}:${row.unit.column}; ${row.unit.tokenCount} tokens; ${escape(row.unit.mapping.method)}</p><pre>${escape(row.source)}</pre><details><summary>Normalized tokens</summary><pre>${escape(row.normalized)}</pre></details>`);
        parts.push('</td>');
      }
      parts.push('</tr></table></details>');
    }
  }
  return parts.join('\n')+'\n';
}

export function analyze(config,output) {
  assert.ok(Array.isArray(config.entries)&&config.entries.length>0,'Expected nonempty entries');
  const out=path.resolve(output); fs.mkdirSync(out);
  const save=(file,data)=>fs.writeFileSync(path.join(out,file),data,{flag:'wx'});
  const report={kind:'bend-generated-program-analysis',schemaVersion:1,complete:false,parser:ACORN.identity,
    tool:identity(TOOL),inputs:config.configIdentity?[config.configIdentity]:[],entries:[],comparisons:[],semantics:{
      counts:'Static syntax sites, not execution frequency, executed allocations, retained memory, or semantic correctness.',
      closures:'Function expressions, arrows, nesting and runtime helper names are syntax sites; capture analysis and actual closure allocation are not measured.',
      helperNames:'Helper categories match emitted callee spellings; shadowing and dynamic dispatch are not resolved.',
      sections:'Section bytes partition each complete module, with leading trivia assigned to the following statement. Inferred runtime/support boundaries are labelled.',
      functions:'Metrics exclude nested function bodies, but include their function creation/declaration sites; source ranges and sizes remain inclusive.',
      definitions:'Source names come from a declaration-name inventory, then JS export/global-registration or emitter-name evidence. Mapping is not a Bend parser or a semantic equivalence proof. Nested specialized function ranges may overlap outer registration ranges.',
      tables:'Top-level program array-literal declarations and syntactic indexing sites are reported separately. A table-indexing function does not include the table declaration in its own metrics.',
      inventory:'Source-owned top-level statements are recognized by named registrations or mapped function declarations; all other program statements are support (including Base and shared tables), not proven unused or unrelated. Statement bytes are disjoint, with trivia counted separately.',
      tokens:'Normalized tokens discard whitespace/comments but preserve token kinds and values. No alpha-renaming, equivalence proof, semantic rewrite or runtime import occurs.',
      comparisons:'Deltas are right minus left. Missing mappings stay visible. Equal source identities are required; timing and behavior are checked separately.'}};
  const seen=new Set(),texts=new Map();
  try {
    for(const entry of config.entries) {
      assert.match(entry.id,/^[A-Za-z0-9_.-]+$/); assert.match(entry.role,/^[A-Za-z0-9_.-]+$/);
      const key=`${entry.id}\0${entry.role}`; assert.ok(!seen.has(key),'Duplicate case/role'); seen.add(key);
      const row=analyzeEntry(entry),file=`${entry.id}-${entry.role}.tokens.txt`;
      save(file,row.unitText.map(u=>`# ${u.name} ${u.unit.kind} ${u.unit.line}:${u.unit.column}\n${u.normalized}`).join('\n'));
      row.report.artifacts={normalized:file}; report.entries.push(row.report); report.inputs.push(...row.inputs); texts.set(key,row.unitText);
    }
    const byCase=new Map();for(const row of report.entries){const rows=byCase.get(row.id)||[];rows.push(row);byCase.set(row.id,rows);}
    for(const rows of byCase.values()) for(let i=0;i<rows.length;i++) for(let j=i+1;j<rows.length;j++) report.comparisons.push(compare(rows[i],rows[j]));
    for(const input of report.inputs) assert.equal(identity(input.path).sha256,input.sha256,'Input changed before report publication');
    assert.equal(identity(TOOL).sha256,report.tool.sha256,'Analyzer changed during analysis');
    save('comparison.html',html(report,texts)); save('report.md',markdown(report)); report.complete=true;
    save('report.json',JSON.stringify(report,null,2)+'\n'); return report;
  } catch(error) {
    report.error=String(error.stack||error); save('report.json',JSON.stringify(report,null,2)+'\n'); throw error;
  }
}
function main() {
  assert.equal(process.argv.length,4,'Use: node analyze.mjs CONFIG.json NEW_OUTPUT_DIRECTORY');
  const file=path.resolve(process.argv[2]),input=identity(file),config=JSON.parse(fs.readFileSync(file));
  config.configIdentity=input;
  const base=path.dirname(file);
  config.entries=config.entries.map(e=>({...e,path:path.resolve(base,e.path),sourcePath:path.resolve(base,e.sourcePath),
    ...(e.runtimePath?{runtimePath:path.resolve(base,e.runtimePath)}:{})}));
  const report=analyze(config,process.argv[3]);
  assert.equal(identity(file).sha256,input.sha256,'Configuration changed during analysis');
  console.log(JSON.stringify({complete:report.complete,entries:report.entries.length,comparisons:report.comparisons.length,config:input}));
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href) {
  try {main();} catch(error) {console.error(error.stack||String(error));process.exitCode=1;}
}
