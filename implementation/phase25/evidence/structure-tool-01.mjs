#!/usr/bin/env node
// Static AST census only. Never executes an analyzed module or rewrites compiler code.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath, pathToFileURL} from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_RUNTIME = path.resolve(HERE, '../../../src/runtime.mjs');
const sha = data => createHash('sha256').update(data).digest('hex');
const PROGRAM = '// Program\n// =======\n';
const CLI_MARKER = '// Cli\n// ===\n';
const FUNCTIONS = new Set(['FunctionDeclaration', 'FunctionExpression', 'ArrowFunctionExpression']);
const HELPERS = new Set(['fn','call','apply','force','jump','build','get','ctor','fields','project','matcher1','scope',
  'run_loop','run_tail','run_clo','run_lib','array_new','array_node','array_rmw','list','op','bad']);
const SECTIONS = ['runtimePrefix','runtimeAndForeignPrefix','foreignSupport','programMetadata','program',
  'exportWrapper','entrypointRuntime','entrypointWrapper'];
const COUNTERS = ['astNodes','functionDeclarations','functionExpressions','arrowFunctions','calls','identifierCalls',
  'memberCalls','otherCalls','optionalCalls','iifes','newExpressions','arrayLiteralSites','arrayLiteralElements',
  'arrayLiteralHoles','objectLiteralSites','spreadSites','restParameters','ifStatements','conditionalExpressions',
  'switchStatements','switchCases','forStatements','whileStatements','returnStatements','throws','tryStatements',
  'globalLookupSites','matcherHelperSites','projectionHelperSites','trampolineHelperSites','closureFactorySites',
  'constructorHelperSites','taggedConstructorObjectSites','bounceObjectSites','argumentArraySites',
  'sliceOrConcatMethodSites','explicitBoundClosureSites'];

function parser() {
  const name = 'internal/deps/acorn/acorn/dist/acorn';
  const source = process.binding('natives')[name];
  assert.equal(typeof source, 'string', 'Node does not expose its embedded Acorn source; refusing a fallback scanner');
  const module = {exports: {}};
  // Execute only Node's own embedded parser module, never any analyzed input.
  new Function('exports', 'module', source)(module.exports, module);
  assert.equal(module.exports.version, '8.16.0', 'Unreviewed embedded Acorn version');
  return {parse: module.exports.parse, identity: {provider: 'Node embedded Acorn', name,
    version: module.exports.version, sha256: sha(source), node: process.version, executable: process.execPath}};
}
const ACORN = parser();
const isNode = value => value && typeof value.type === 'string';
function children(node) {
  const result = [];
  for (const [key, value] of Object.entries(node)) {
    if (key === 'loc') continue;
    if (isNode(value)) result.push({node: value, key});
    else if (Array.isArray(value)) for (const child of value) if (isNode(child)) result.push({node: child, key});
  }
  return result;
}
function visit(root, action, {skipNested = false} = {}) {
  const stack = [{node: root, parent: null, key: null}];
  while (stack.length) {
    const item = stack.pop(); action(item.node, item.parent, item.key);
    if (skipNested && item.node !== root && FUNCTIONS.has(item.node.type)) continue;
    const next = children(item.node);
    for (let i = next.length - 1; i >= 0; i--) stack.push({...next[i], parent: item.node});
  }
}
const nameOf = node => node?.type === 'Identifier' ? node.name : null;
const literal = node => node?.type === 'Literal' ? node.value : undefined;
function propertyName(node) {
  if (!node) return null;
  if (!node.computed && node.property?.type === 'Identifier') return node.property.name;
  return typeof literal(node.property) === 'string' ? literal(node.property) : null;
}
function memberName(node) {
  if (node?.type !== 'MemberExpression') return null;
  const base = nameOf(node.object), key = propertyName(node);
  return base && key !== null ? `${base}[${JSON.stringify(key)}]` : null;
}
function keyName(property) {
  if (property.type !== 'Property') return null;
  return !property.computed && property.key.type === 'Identifier' ? property.key.name : literal(property.key);
}
const hasObjectKey = (node, key) => node.type === 'ObjectExpression' && node.properties.some(p => keyName(p) === key);
function globalTarget(node) {
  if (node?.type !== 'CallExpression' || nameOf(node.callee) !== 'get' || node.arguments.length !== 2) return null;
  return nameOf(node.arguments[0]) === 'G' && typeof literal(node.arguments[1]) === 'string' ? literal(node.arguments[1]) : null;
}
function globalAssignment(node) {
  const left = node?.left;
  return node?.type === 'AssignmentExpression' && node.operator === '=' && left.type === 'MemberExpression'
    && nameOf(left.object) === 'G' && typeof literal(left.property) === 'string' ? literal(left.property) : null;
}
function runtimeArity(node) {
  if (node?.type !== 'CallExpression') return null;
  if (nameOf(node.callee) === 'fn' && Number.isInteger(literal(node.arguments[0])) && literal(node.arguments[0]) >= 0) return literal(node.arguments[0]);
  if (nameOf(node.callee) === 'matcher1') return 1;
  return null;
}
const emptyMetrics = () => ({...Object.fromEntries(COUNTERS.map(k => [k, 0])), helperCalls: {}, callArgumentHistogram: {}, constructorTags: {}});
const add = (object, key) => {object[key] = (object[key] || 0) + 1;};
function countNode(out, node, parent) {
  out.astNodes++;
  const types = {FunctionDeclaration:'functionDeclarations',FunctionExpression:'functionExpressions',ArrowFunctionExpression:'arrowFunctions',
    NewExpression:'newExpressions',SpreadElement:'spreadSites',IfStatement:'ifStatements',ConditionalExpression:'conditionalExpressions',
    SwitchStatement:'switchStatements',SwitchCase:'switchCases',ForStatement:'forStatements',ForOfStatement:'forStatements',ForInStatement:'forStatements',
    WhileStatement:'whileStatements',DoWhileStatement:'whileStatements',ReturnStatement:'returnStatements',ThrowStatement:'throws',TryStatement:'tryStatements'};
  if (types[node.type]) out[types[node.type]]++;
  if (node.type === 'RestElement' && parent && FUNCTIONS.has(parent.type)) out.restParameters++;
  if (node.type === 'ArrayExpression') {
    out.arrayLiteralSites++; out.arrayLiteralElements += node.elements.length;
    out.arrayLiteralHoles += node.elements.filter(x => x === null).length;
    if (parent?.type === 'CallExpression' && ['call','jump','apply'].includes(nameOf(parent.callee)) && parent.arguments[1] === node) out.argumentArraySites++;
  }
  if (node.type === 'ObjectExpression') {
    out.objectLiteralSites++;
    const tag = node.properties.find(p => keyName(p) === '$');
    if (tag) {
      const value = literal(tag.value);
      if (value === '$JMP') out.bounceObjectSites++;
      else {out.taggedConstructorObjectSites++; add(out.constructorTags, typeof value === 'string' ? value : '<dynamic>');}
    }
    if (hasObjectKey(node, 'bounce')) out.bounceObjectSites++;
  }
  if (node.type !== 'CallExpression') return;
  out.calls++;
  if (node.optional) out.optionalCalls++;
  const name = nameOf(node.callee);
  if (name) out.identifierCalls++;
  else if (node.callee.type === 'MemberExpression') out.memberCalls++;
  else out.otherCalls++;
  if (FUNCTIONS.has(node.callee.type)) out.iifes++;
  add(out.callArgumentHistogram, node.arguments.some(a => a.type === 'SpreadElement') ? `${node.arguments.length}+spread` : String(node.arguments.length));
  if (HELPERS.has(name)) add(out.helperCalls, name);
  if (globalTarget(node) !== null) out.globalLookupSites++;
  if (['matcher1','fields'].includes(name)) out.matcherHelperSites++;
  if (name === 'project') out.projectionHelperSites++;
  if (['jump','run_tail','run_loop','force'].includes(name)) out.trampolineHelperSites++;
  if (['fn','run_clo'].includes(name)) out.closureFactorySites++;
  if (['ctor','build'].includes(name)) {out.constructorHelperSites++;add(out.constructorTags, typeof literal(node.arguments[0]) === 'string' ? literal(node.arguments[0]) : '<dynamic>');}
  if (node.callee.type === 'MemberExpression' && ['slice','concat'].includes(propertyName(node.callee))) out.sliceOrConcatMethodSites++;
  if (name === 'fn' && node.arguments[3]?.type === 'ArrayExpression' && node.arguments[3].elements.length > 0) out.explicitBoundClosureSites++;
}
function metrics(root, skipNested = false) {
  const out = emptyMetrics();
  if (skipNested && FUNCTIONS.has(root.type)) countNode(out,root,null);
  else visit(root, (n,p) => countNode(out,n,p), {skipNested});
  return out;
}
function mergeMetrics(target, source) {
  for (const key of COUNTERS) target[key] += source[key];
  for (const group of ['helperCalls','callArgumentHistogram','constructorTags']) for (const [key,value] of Object.entries(source[group])) target[group][key] = (target[group][key] || 0) + value;
}
function sourceRange(source, file, node) {
  return {startUtf16:node.start,endUtf16:node.end,line:node.loc.start.line,column:node.loc.start.column,
    endLine:node.loc.end.line,endColumn:node.loc.end.column,bytes:Buffer.byteLength(source.slice(node.start,node.end)),
    sourceLink:`${file}:${node.loc.start.line}`};
}
function normalizedShape(root) {
  // Deliberately syntactic, NOT alpha-equivalence or a semantics-preserving rewrite.
  const hash = createHash('sha256');
  function write(value, parent = null, role = null) {
    if (value === null || typeof value !== 'object') {hash.update(JSON.stringify(typeof value === 'bigint' ? '<bigint>' : value));return;}
    if (Array.isArray(value)) {hash.update('[');for (const v of value) {write(v,parent,role);hash.update(',');}hash.update(']');return;}
    if (value.type === 'Identifier') {
      const property = parent?.type === 'MemberExpression' && role === 'property' && !parent.computed
        || parent?.type === 'Property' && role === 'key' && !parent.computed;
      hash.update(JSON.stringify({type:'Identifier',name:property || HELPERS.has(value.name) ? value.name : '<identifier>'}));return;
    }
    if (value.type === 'Literal') {
      hash.update(JSON.stringify({type:'Literal',kind:value.regex ? 'regexp' : value.bigint !== undefined ? 'bigint' : value.value === null ? 'null' : typeof value.value}));return;
    }
    hash.update('{');
    for (const key of Object.keys(value).sort()) {
      if (['start','end','loc','range','raw'].includes(key)) continue;
      hash.update(JSON.stringify(key)+':');write(value[key],value,key);hash.update(',');
    }
    hash.update('}');
  }
  write(root);return hash.digest('hex');
}
function boundary(source, ast, comments, family, runtime) {
  if (family === 'selfhost') {
    assert.ok(runtime, 'Selfhost analysis requires an exact runtime file');
    assert.ok(source.startsWith(runtime.source), 'Selfhost copied runtime does not exactly match supplied runtime');
    return {end:runtime.source.length,section:'runtimePrefix',method:'Exact supplied runtime bytes are a module prefix',
      sha256:runtime.sha256,exactRuntimeMatch:true,runtimeFile:runtime.path};
  }
  const start = source.indexOf(PROGRAM);
  assert.ok(start >= 0 && source.indexOf(PROGRAM,start+1) < 0, 'Upstream module must contain exactly one reviewed Program boundary');
  assert.ok(comments.some(c => c.start === start && c.value.trim() === 'Program'), 'Program marker is not a JavaScript comment');
  const end = start + PROGRAM.length;
  if (runtime) {
    assert.ok(source.startsWith(runtime.source) && runtime.source.length <= start, 'Upstream supplied runtime is not an exact prefix before Program');
    return {end:runtime.source.length,programStart:end,section:'runtimePrefix',method:'Exact supplied runtime prefix; intervening prefix is foreign support',
      sha256:runtime.sha256,exactRuntimeMatch:true,runtimeFile:runtime.path};
  }
  return {end,section:'runtimeAndForeignPrefix',method:'Actual upstream Program comment; prefix may include copied foreign effects',
    sha256:sha(source.slice(0,end)),exactRuntimeMatch:false};
}
function classify(node, family, entryRuntimeStart) {
  if (node.type.startsWith('Export')) return 'exportWrapper';
  if (family === 'upstream' && entryRuntimeStart !== null && node.start >= entryRuntimeStart) {
    const expression = node.type === 'ExpressionStatement' ? node.expression : null;
    return expression?.type === 'CallExpression' && ['cli','io_exit'].includes(nameOf(expression.callee)) ? 'entrypointWrapper' : 'entrypointRuntime';
  }
  if (node.type === 'ExpressionStatement') {
    const expr = node.expression;
    if (expr.type === 'AwaitExpression' && expr.argument.type === 'CallExpression' && nameOf(expr.argument.callee) === 'runmain') return 'entrypointWrapper';
    if (expr.type === 'AssignmentExpression' && expr.left.type === 'MemberExpression') {
      if (nameOf(expr.left.object) === 'foreignModules') return 'foreignSupport';
      if (['constructors','constructorOwn','constructorNative','showSchemas'].includes(nameOf(expr.left.object))) return 'programMetadata';
    }
  }
  return 'program';
}
function segmentsFor(source, ast, bound, family, comments) {
  let entryRuntimeStart = null;
  if (family === 'upstream') {
    const pos = source.indexOf(CLI_MARKER,bound.end);
    if (pos >= 0) {
      assert.ok(comments.some(c => c.start === pos && c.value.trim() === 'Cli'), 'CLI marker is not a comment');
      assert.ok(source.indexOf(CLI_MARKER,pos+1) < 0, 'Ambiguous CLI runtime boundary');
      entryRuntimeStart = pos;
    }
  }
  const pieces = [{start:0,end:bound.end,section:bound.section}];
  let at = bound.end;
  const topSections = new Map();
  for (const node of ast.body) {
    assert.ok(node.end <= bound.end || node.start >= bound.end, 'Runtime boundary splits a statement');
    if (node.end <= bound.end) {topSections.set(node,bound.section);continue;}
    let section = bound.programStart !== undefined && node.end <= bound.programStart ? 'foreignSupport' : classify(node,family,entryRuntimeStart);
    assert.ok(bound.programStart === undefined || node.start >= bound.programStart || node.end <= bound.programStart, 'Program boundary splits a statement');
    if (pieces.at(-1).section === section) pieces.at(-1).end = node.end;
    else pieces.push({start:at,end:node.end,section});
    topSections.set(node,section);at = node.end;
  }
  if (at < source.length) pieces.at(-1).end = source.length;
  assert.equal(pieces[0].start,0);assert.equal(pieces.at(-1).end,source.length);
  for (let i=1;i<pieces.length;i++) assert.equal(pieces[i-1].end,pieces[i].start);
  return {pieces,topSections,entryRuntimeStart};
}
function functionName(node,parent,key) {
  if (node.id?.name) return node.id.name;
  if (parent?.type === 'VariableDeclarator') return nameOf(parent.id) || '<destructured variable>';
  if (parent?.type === 'Property') return String(keyName(parent) ?? '<computed property>');
  if (parent?.type === 'AssignmentExpression') return nameOf(parent.left) || memberName(parent.left) || '<assignment>';
  if (parent?.type === 'CallExpression') return `${nameOf(parent.callee) || memberName(parent.callee) || '<call>'}:argument${parent.arguments.indexOf(node)}`;
  return `<${node.type}@${node.loc.start.line}:${node.loc.start.column}>`;
}

export function analyzeFile(config) {
  assert.ok(config && typeof config.path === 'string', 'Missing module path');
  const file = path.resolve(config.path), raw = fs.readFileSync(file), source = raw.toString('utf8');
  assert.ok(Buffer.from(source).equals(raw), 'Input is not canonical UTF-8');
  if (config.sha256) assert.equal(sha(raw),config.sha256,'Module differs from manifest hash');
  const comments = [];
  const ast = ACORN.parse(source,{ecmaVersion:2025,sourceType:'module',locations:true,onComment:comments});
  let family = config.family || (source.includes(PROGRAM) ? 'upstream' : 'selfhost');
  assert.ok(['selfhost','upstream'].includes(family), 'Unknown emitter family');
  const runtimePath = config.runtimePath || (family === 'selfhost' ? DEFAULT_RUNTIME : null);
  let runtime = null;
  if (runtimePath) {const p=path.resolve(runtimePath),r=fs.readFileSync(p);runtime={path:p,source:r.toString('utf8'),sha256:sha(r)};assert.ok(Buffer.from(runtime.source).equals(r));}
  const bound = boundary(source,ast,comments,family,runtime);
  const {pieces,topSections,entryRuntimeStart} = segmentsFor(source,ast,bound,family,comments);
  const sectionNodes = new Map();
  for (const top of ast.body) visit(top,n=>sectionNodes.set(n,topSections.get(top)));
  const summaries = Object.fromEntries(SECTIONS.map(k=>[k,{bytes:0,topLevelStatements:0,metrics:emptyMetrics()}]));
  for (const piece of pieces) summaries[piece.section].bytes += Buffer.byteLength(source.slice(piece.start,piece.end));
  for (const top of ast.body) {const out=summaries[topSections.get(top)];out.topLevelStatements++;mergeMetrics(out.metrics,metrics(top));}
  assert.equal(Object.values(summaries).reduce((sum,x)=>sum+x.bytes,0),raw.length, 'Segment bytes do not sum to input');
  const parents = new Map();visit(ast,(n,p,k)=>parents.set(n,{parent:p,key:k}));
  const functions = [], definitions = [], programUnits = [], arityCandidates = new Map();
  for(const top of ast.body.filter(n=>topSections.get(n)==='program')) {
    const owners=[];
    if(family==='upstream'&&top.type==='FunctionDeclaration')owners.push(top.id.name);
    if(family==='selfhost')visit(top,n=>{const owner=globalAssignment(n);if(owner!==null)owners.push(owner);});
    programUnits.push({owners:[...new Set(owners)],kind:top.type,...sourceRange(source,file,top),
      sourceSha256:sha(source.slice(top.start,top.end)),metricsInclusive:metrics(top)});
  }
  function owningGlobal(node) {
    for(let at=node;at;at=parents.get(at)?.parent) {const global=globalAssignment(at);if(global!==null)return global;}
    return null;
  }
  visit(ast,(n,p,k)=>{
    const section=sectionNodes.get(n);
    if (FUNCTIONS.has(n.type)) {
      const arity = p?.type === 'CallExpression' && nameOf(p.callee) === 'fn' && p.arguments[1] === n ? runtimeArity(p) : null;
      let enclosing=parents.get(n)?.parent;while(enclosing && !FUNCTIONS.has(enclosing.type)) enclosing=parents.get(enclosing)?.parent;
      functions.push({name:functionName(n,p,k),owningGlobal:owningGlobal(n),kind:n.type,section,formalParameterSlots:n.params.length,
        restParameter:n.params.some(x=>x.type==='RestElement'),runtimeFnArity:arity,nested:!!enclosing,
        ...sourceRange(source,file,n),bodyBytesInclusive:Buffer.byteLength(source.slice(n.body.start,n.body.end)),
        metricsExclusive:metrics(n.body,true),syntaxShapeSha256:normalizedShape(n),sourceSha256:sha(source.slice(n.start,n.end))});
    }
    if (section !== 'program') return;
    const global=globalAssignment(n);
    if (global !== null) {
      const arity=runtimeArity(n.right);
      definitions.push({name:global,kind:'global-initializer',runtimeFnArity:arity,...sourceRange(source,file,n),metricsInclusive:metrics(n.right)});
      const candidates=arityCandidates.get(global)||new Set();candidates.add(arity);arityCandidates.set(global,candidates);
    }
    if (family==='upstream' && n.type==='FunctionDeclaration' && p.type==='Program')
      definitions.push({name:n.id.name,kind:'top-level-function',formalParameterSlots:n.params.length,...sourceRange(source,file,n),metricsInclusive:metrics(n.body)});
  });
  // An initializer arity is evidence of a source shape, not a proof of the dynamic callee value.
  const apparentCalls = [], functionRows = new Map(functions.map(f=>[f.startUtf16,f]));
  for(const f of functions) f.apparentGlobalCallsExclusive={under:0,over:0,equal:0,unresolved:0};
  visit(ast,n=>{
    if (sectionNodes.get(n)!=='program' || n.type!=='CallExpression' || !['call','jump','apply'].includes(nameOf(n.callee))) return;
    const target=globalTarget(n.arguments[0]),args=n.arguments[1];
    const values=arityCandidates.get(target);const arity=values?.size===1?[...values][0]:null;
    const supplied=args?.type==='ArrayExpression'&&!args.elements.some(x=>x?.type==='SpreadElement')?args.elements.length:null;
    const relation=arity===null||arity===0||supplied===null?'unresolved':supplied<arity?'under':supplied>arity?'over':'equal';
    let owner=parents.get(n)?.parent;while(owner&&!FUNCTIONS.has(owner.type))owner=parents.get(owner)?.parent;
    const ownerRow=owner&&functionRows.get(owner.start);if(ownerRow)ownerRow.apparentGlobalCallsExclusive[relation]++;
    apparentCalls.push({target,helper:nameOf(n.callee),initializerArity:arity,suppliedSlots:supplied,relation,owningGlobal:owningGlobal(n),
      ownerFunction:ownerRow?{name:ownerRow.name,startUtf16:ownerRow.startUtf16,line:ownerRow.line,column:ownerRow.column}:null,
      ...sourceRange(source,file,n)});
  });
  const groups = new Map();
  for (const f of functions.filter(f=>f.section==='program')) {const group=groups.get(f.syntaxShapeSha256)||[];group.push(f);groups.set(f.syntaxShapeSha256,group);}
  const recurringShapes=[...groups].filter(([,fs])=>fs.length>1).map(([digest,rows])=>({syntaxShapeSha256:digest,count:rows.length,
    summedFunctionBytesInclusive:rows.reduce((n,r)=>n+r.bytes,0),examples:rows.map(r=>({name:r.name,owningGlobal:r.owningGlobal,line:r.line,column:r.column,bytes:r.bytes,sourceLink:r.sourceLink}))})).sort((a,b)=>b.summedFunctionBytesInclusive-a.summedFunctionBytesInclusive);
  assert.equal(sha(fs.readFileSync(file)),sha(raw),'Analyzed module changed during census');
  if(runtime) assert.equal(sha(fs.readFileSync(runtime.path)),runtime.sha256,'Runtime changed during census');
  return {id:config.id||path.basename(file),variant:config.variant||family,family,mode:config.mode||'unspecified',path:file,
    sha256:sha(raw),bytes:raw.length,physicalLines:source.split('\n').length-Number(source.endsWith('\n')),
    inputSourceSha256:config.sourceSha256||null,boundary:bound,entryRuntimeStartUtf16:entryRuntimeStart,
    sections:summaries,segments:pieces.map(p=>({...p,bytes:Buffer.byteLength(source.slice(p.start,p.end)),sha256:sha(source.slice(p.start,p.end))})),
    functions,definitions,programUnits,apparentGlobalCalls:{counts:apparentCalls.reduce((o,x)=>(add(o,x.relation),o),{}),sites:apparentCalls},recurringShapes};
}
function pairSummary(entries) {
  const ids=new Map();for(const e of entries){const a=ids.get(e.id)||[];a.push(e);ids.set(e.id,a);}
  return [...ids].map(([id,rows])=>{
    const supplied=rows.map(r=>r.inputSourceSha256).filter(Boolean);assert.ok(new Set(supplied).size<=1,`Source identity mismatch for paired id ${id}`);
    return {id,variants:rows.map(r=>({variant:r.variant,family:r.family,sha256:r.sha256,bytes:r.bytes,
      runtimeBytes:r.sections.runtimePrefix.bytes+r.sections.runtimeAndForeignPrefix.bytes,
      programBytes:r.sections.program.bytes,metadataBytes:r.sections.programMetadata.bytes,
      foreignBytes:r.sections.foreignSupport.bytes,exportWrapperBytes:r.sections.exportWrapper.bytes,
      entrypointBytes:r.sections.entrypointRuntime.bytes+r.sections.entrypointWrapper.bytes,
      programFunctionSites:r.functions.filter(f=>f.section==='program').length,
      programMetrics:r.sections.program.metrics,programInventory:r.programInventory})),sourceIdentity:supplied.length===rows.length?'All supplied source hashes agree':'Source hashes not supplied for every variant; pairing is caller-labelled'};
  });
}
export function analyzeCorpus(config) {
  assert.ok(Array.isArray(config.entries)&&config.entries.length>0,'Expected nonempty entries');
  const seen=new Set();for(const row of config.entries){const key=`${row.id}\0${row.variant}`;assert.ok(!seen.has(key),'Duplicate id/variant');seen.add(key);}
  const entries=config.entries.map(analyzeFile);
  // Whole top-level units retain guards around Base fallback registrations. Exact
  // text repeated in every module of a variant is common output, not kernel code.
  const byVariant=new Map();for(const e of entries){const rows=byVariant.get(e.variant)||[];rows.push(e);byVariant.set(e.variant,rows);}
  const commonGeneratedDefinitions=[];
  for(const [variant,rows] of byVariant){
    const occurrences=new Map();
    for(const entry of rows)for(const unit of entry.programUnits.filter(u=>u.owners.length)){
      const key=JSON.stringify([unit.owners,unit.sourceSha256]);const record=occurrences.get(key)||{owners:unit.owners,sha256:unit.sourceSha256,statementBytes:unit.bytes,entries:new Set(),examples:[]};
      record.entries.add(entry.id);record.examples.push({id:entry.id,line:unit.line,column:unit.column,sourceLink:unit.sourceLink});occurrences.set(key,record);
    }
    const common=new Set([...occurrences].filter(([,r])=>rows.length>1&&r.entries.size===rows.length).map(([key])=>key));
    commonGeneratedDefinitions.push({variant,moduleCount:rows.length,commonUnitCount:common.size,definitions:[...common].map(key=>{const r=occurrences.get(key);return {owners:r.owners,sha256:r.sha256,statementBytes:r.statementBytes,examples:r.examples};})});
    for(const entry of rows){
      const inventory={commonAcrossVariant:{units:0,statementBytes:0,metrics:emptyMetrics()},remaining:{units:0,statementBytes:0,metrics:emptyMetrics()}};
      for(const unit of entry.programUnits){
        unit.commonAcrossVariant=common.has(JSON.stringify([unit.owners,unit.sourceSha256]));
        const bucket=inventory[unit.commonAcrossVariant?'commonAcrossVariant':'remaining'];bucket.units++;bucket.statementBytes+=unit.bytes;mergeMetrics(bucket.metrics,unit.metricsInclusive);
      }
      inventory.programTriviaBytes=entry.sections.program.bytes-inventory.commonAcrossVariant.statementBytes-inventory.remaining.statementBytes;
      assert.ok(inventory.programTriviaBytes>=0);
      entry.programInventory=inventory;
      for(const f of entry.functions.filter(f=>f.section==='program')){const unit=entry.programUnits.find(u=>u.startUtf16<=f.startUtf16&&u.endUtf16>=f.endUtf16);assert.ok(unit);f.commonAcrossVariant=unit.commonAcrossVariant;}
    }
  }
  const prefixes=new Map();
  for(const entry of entries){
    const key=`${entry.boundary.section}:${entry.boundary.sha256}`;
    const row=prefixes.get(key)||{section:entry.boundary.section,sha256:entry.boundary.sha256,bytes:Buffer.byteLength(fs.readFileSync(entry.path,'utf8').slice(0,entry.boundary.end)),exactRuntimeMatch:entry.boundary.exactRuntimeMatch,entries:[]};
    row.entries.push({id:entry.id,variant:entry.variant});prefixes.set(key,row);
  }
  const recurring=new Map();
  for(const entry of entries) for(const f of entry.functions.filter(f=>f.section==='program')) {
    const group=recurring.get(f.syntaxShapeSha256)||[];group.push({id:entry.id,variant:entry.variant,path:entry.path,name:f.name,owningGlobal:f.owningGlobal,line:f.line,column:f.column,bytes:f.bytes,sourceLink:f.sourceLink});recurring.set(f.syntaxShapeSha256,group);
  }
  return {kind:'phase25-generated-javascript-structure',complete:true,parser:ACORN.identity,
    tool:{path:fileURLToPath(import.meta.url),sha256:sha(fs.readFileSync(fileURLToPath(import.meta.url)))},
    semantics:{counts:'Static syntax sites, not execution frequency, allocations, retained memory, or semantic correctness.',
      bytes:'Disjoint section byte ranges sum to the complete input. Interstatement whitespace belongs to the following statement; final whitespace to the preceding section.',
      functionMetrics:'Metrics exclude bodies of nested functions; creation sites themselves count. Function source/body sizes include nested functions and therefore cannot be summed as disjoint bytes.',
      arity:'Formal JavaScript parameter slots and fn(n,code) runtime arities are different quantities. Apparent global calls use unambiguous initializer syntax only; zero-arity thunk globals remain unresolved, and runtime overrides/mutations are not proven absent.',
      matchers:'Helper sites and switch/conditional syntax are counted separately; counts are not the number of semantic pattern matches.',
      shapes:'Syntax-shape groups erase ordinary identifier and literal spelling, retain helper/property names and operators. They are not alpha-equivalence, capture analysis, or proof that fusion is valid.',
      copiedRuntime:'Selfhost requires exact supplied runtime-prefix equality. Upstream without runtimePath reports the complete runtime-and-foreign prefix before its actual Program comment.',
      commonDefinitions:'A whole top-level named definition/registration with byte-identical text in every module of one variant is counted separately. This identifies corpus-common output, not a proof of Base ownership; remaining units may still include library support. No common-unit claim is made for a single-module variant.',
      corpus:'Id and variant pairing is caller-labelled; equal emitted behavior requires separate execution validation.'},
    pairs:pairSummary(entries),entries,commonGeneratedDefinitions,
    runtimePrefixInventory:{groups:[...prefixes.values()],distinctPrefixBytes:[...prefixes.values()].reduce((n,r)=>n+r.bytes,0),
      repeatedPrefixBytes:[...prefixes.values()].reduce((n,r)=>n+r.bytes*r.entries.length,0),
      scope:'Byte-identical recorded prefixes counted once; upstream prefixes without runtimePath may include foreign effects and Program boundary comments.'},
    corpusRecurringShapes:[...recurring].filter(([,rows])=>rows.length>1).map(([digest,rows])=>({syntaxShapeSha256:digest,count:rows.length,
      variants:[...new Set(rows.map(r=>r.variant))],examples:rows})).sort((a,b)=>b.count-a.count)};
}
function main() {
  const args=process.argv.slice(2),options={};
  for(let i=0;i<args.length;i+=2){assert.ok(['--manifest','--out','--file','--variant','--runtime','--family','--mode'].includes(args[i]),`Unknown option ${args[i]}`);assert.ok(args[i+1]&&!args[i+1].startsWith('--'),'Missing option value');options[args[i]]=args[i+1];}
  assert.ok(options['--out'],'Use --manifest CORPUS.json --out REPORT.json, or --file MODULE --variant NAME --family upstream|selfhost --out REPORT.json [--runtime FILE]');
  assert.ok(Boolean(options['--manifest'])!==Boolean(options['--file']),'Supply exactly one of --manifest and --file');
  let config, manifestIdentity;
  if(options['--manifest']){
    const manifest=path.resolve(options['--manifest']),root=path.dirname(manifest);const bytes=fs.readFileSync(manifest);manifestIdentity={path:manifest,sha256:sha(bytes)};config=JSON.parse(bytes);
    assert.ok(Array.isArray(config.entries),'Manifest has no entries');
    config.entries=config.entries.map(e=>({...e,path:path.resolve(root,e.path),...(e.runtimePath?{runtimePath:path.resolve(root,e.runtimePath)}:{})}));
  }else config={entries:[{path:path.resolve(options['--file']),variant:options['--variant'],family:options['--family'],mode:options['--mode'],runtimePath:options['--runtime']&&path.resolve(options['--runtime'])}]};
  const report=analyzeCorpus(config),out=path.resolve(options['--out']);
  if(manifestIdentity){assert.equal(sha(fs.readFileSync(manifestIdentity.path)),manifestIdentity.sha256,'Manifest changed during census');report.manifest=manifestIdentity;}
  fs.mkdirSync(path.dirname(out),{recursive:true});fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
  process.stdout.write(JSON.stringify({output:out,entries:report.entries.length,pairs:report.pairs.length,complete:true})+'\n');
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href) {
  try{main();}catch(error){console.error(error.stack||String(error));process.exitCode=1;}
}
