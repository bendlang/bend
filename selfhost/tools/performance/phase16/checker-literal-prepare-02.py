from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/checker-literal-source-01/project';out=base/'build/phase16/checker-literal-source-02';out.mkdir();shutil.copytree(old,out/'project');project=out/'project'
def edit(name,fn):
 p=project/name;p.write_text(fn(p.read_text()))
def replace(s,a,b):
 assert a in s,a;return s.replace(a,b)
def body(s,fn,new):
 a=s.index('def '+fn+'(');a=s.index('\n  ',a)+3;b=s.find('\n@unsafe',a)
 # Skip multiline signature to body (untyped law definitions are one line).
 sig=s[s.index('def '+fn+'('):a]
 if ') ->' not in sig and not sig.rstrip().endswith('):'):
  a=s.index('\n  ',s.index(') ->',a))+3
 if b<0:b=len(s)
 return s[:a]+new+'\n'+s[b:]
def wrap(s,fn,new):
 a=s.index('def '+fn+'(');b=s.index('\n  ',a)+3
 if ') ->' not in s[a:b] and not s[a:b].rstrip().endswith('):'): b=s.index('\n  ',s.index(') ->',b))+3
 end=s.find('\n@unsafe',b)
 if end<0:end=len(s)
 return s[:b]+new.replace('EXPR',s[b:end].rstrip())+'\n'+s[end:]
def term(s):
 a=s.index('# Compact source Nat literals');b=s.index('# Source ranges are',a)
 s=s[:a]+'''# Numeric and string values retain source literal identity until demanded.
@unsafe
def core_nat(+t: KTerm) -> Bool:
  core_literal(t) && String.eq(nm(t), "Nat")

@unsafe
def core_nat_make(+n: U32) -> KTerm:
  kl_make("Nat", n, "")

@unsafe
def core_literal_type(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm) -> Bool:
  String.eq(tg(ty), "ADT") && String.eq(nm(ty), nm(t)) && List.is_empty(&2, String, rm(ty)) && db(lookup(book, nm(t)))

@unsafe
def core_literal_word(+n: U32, +bits: U32, +begin: U32, +end: U32) -> KTerm:
  kc(KTerm, U32.is_eq(bits, 0), u => kt_span("Ctr", "WNil", 0, 1, Nil{}, begin, end),
    u => kt_span("Ctr", "WCon", 0, 1, [kt_span("Ctr", kc(String, U32.is_eq(U32.and(n, 1), 0), u => "False", u => "True"), 0, 1, Nil{}, begin, end), core_literal_word(U32.shrn(n, 1n), U32.sub(bits, 1), begin, end)], begin, end))

@unsafe
def core_literal_step(+t: KTerm) -> KTerm:
  kc(KTerm, String.eq(nm(t), "Nat"),
    u => kc(KTerm, U32.is_eq(kl_number(t), 0), u => kt_span("Ctr", "Zero", 0, 1, Nil{}, kb(t), ke(t)), u => kt_span("Ctr", "Succ", 0, 1, [KLiteral{"Nat", U32.sub(kl_number(t), 1), "", kb(t), ke(t)}], kb(t), ke(t))),
    u => kc(KTerm, String.eq(nm(t), "String"), u => core_literal_string(kl_text(t), kb(t), ke(t)),
      u => kt_span("Ctr", nm(t), 0, 1, [core_literal_word(kl_number(t), 32, kb(t), ke(t))], kb(t), ke(t))))

@unsafe
def core_literal_string(+s: String, +begin: U32, +end: U32) -> KTerm:
  match s:
    case SNil{}: kt_span("Ctr", "SNil", 0, 1, Nil{}, begin, end)
    case SCon{c, rest}: kt_span("Ctr", "SCon", 0, 1, [kt_span("Ctr", "Chr", 0, 1, [KLiteral{"U32", Char.to_u32(c), "", begin, end}], begin, end), KLiteral{"String", 0, rest, begin, end}], begin, end)

@unsafe
def core_literal_same(+a: KTerm, +b: KTerm) -> Bool:
  String.eq(nm(a), nm(b)) && U32.is_eq(kl_number(a), kl_number(b)) && String.eq(kl_text(a), kl_text(b))

@unsafe
def compiler_literal_abi() -> U32:
  1

'''+s[b:]
 return s
edit('src/core/term.bend',term)
# Existing demand points share one first-step helper.
for name in ['src/core/normalize.bend','src/core/graph.bend','src/check/quantity.bend','src/check/kernel.bend','src/check/annotate.bend','src/front/validate.bend','src/back/js/emit.bend']:
 def general(s):
  s=s.replace('core_nat(', 'core_literal(').replace('core_nat_step(', 'core_literal_step(')
  s=s.replace('core_nat_type(cb(e), wnf(cb(e), ty))','core_literal_type(cb(e), t, wnf(cb(e), ty))').replace('core_nat_type(cb(e), ty)','core_literal_type(cb(e), t, ty)')
  return s
 edit(name,general)
edit('src/core/normalize.bend',lambda s:replace(replace(s,'norm_cmp_test(book, U32.is_eq(qt(a), qt(b)), rest, alts), u =>\n  kc(Bool, String.eq(tg(a), "Ref")','norm_cmp_test(book, core_literal_same(a, b), rest, alts), u =>\n  kc(Bool, String.eq(tg(a), "Ref")'),'String.eq(tg(a), tg(b)) && String.eq(nm(a), nm(b))','String.eq(tg(a), tg(b)) && kc(Bool, core_literal(a), u => core_literal_same(a, b), u => True{}) && String.eq(nm(a), nm(b))'))
# Inference reports the original literal, while inspecting only its constructor head.
edit('src/check/kernel.bend',lambda s:replace(s,'u => infer(e, ctx, core_literal_step(t), dem, sp), u => bad(', 'u => bad("cannot infer: annotation required"), u => bad('))
edit('src/diagnostic/trace.bend',lambda s:replace(s,'String.eq(tg(t), "Ctr") && String.eq(dg_family(cb(e), nm(t)), "")','(String.eq(tg(t), "Ctr") || core_literal(t)) && String.eq(dg_family(cb(e), nm(kc(KTerm, core_literal(t), u => core_literal_step(t), u => t))), "")'))
# Raw source spelling is decoded before constructing a literal leaf.
edit('src/front/elaborate.bend',lambda s:replace(replace(s,'kt("Ctr", "U32", 0, 1, [f_word(n, 32)])','kl_make("U32", n, "")'),'u => kt("Ctr", "SNil", 0, 1, Nil{}), u => f_string_decoded_at','u => kl_make("String", 0, ""), u => f_string_decoded_at'))
edit('src/front/unicode.bend',lambda s:replace(replace(s,'u => kt("Ctr", "F32", 0, 1, [f_word(bits, 32)])','u => kl_make("F32", bits, "")'),'u => kt("Ctr", "SCon", 0, 1, [kt("Ctr", "Chr", 0, 1, [f_u32(code)]), f_string_at(rest, origin)])','u => f_string_cons(code, f_string_at(rest, origin))')+'''
# Invalid scalar escapes keep the reference constructor-chain representation.
@unsafe
def f_string_cons(+code: U32, +tail: KTerm) -> KTerm:
  f_choose(KTerm, U32.is_le(code, 1114111) && (U32.is_lt(code, 55296) || U32.is_gt(code, 57343)),
    u => f_choose(KTerm, core_literal(tail) && String.eq(nm(tail), "String"), u => kl_make("String", 0, SCon{Char.from_u32(code), kl_text(tail)}), u => kt("Ctr", "SCon", 0, 1, [kt("Ctr", "Chr", 0, 1, [f_u32(code)]), tail])),
    u => kt("Ctr", "SCon", 0, 1, [kt("Ctr", "Chr", 0, 1, [f_u32(code)]), f_string_expand(tail)]))

@unsafe
def f_string_expand(+t: KTerm) -> KTerm:
  f_choose(KTerm, core_literal(t) && String.eq(nm(t), "String"), u => f_string_expand(core_literal_step(t)),
    u => f_choose(KTerm, String.eq(tg(t), "Ctr") && String.eq(nm(t), "SCon"), u => k_with_children(t, [kid(t, 0), f_string_expand(kid(t, 1))]), u => t))
''')
# Literal patterns demand complete constructor patterns; terms remain compact.
edit('src/front/literals_arrays.bend',lambda s:replace(s,'u => f_literal(s))','u => f_literal_pattern(f_literal(s)))').replace('qt(value)','kl_number(value)').replace('qt(a)','kl_number(a)')+'''
@unsafe
def f_literal_pattern(+t: KTerm) -> KTerm:
  f_choose(KTerm, core_literal(t), u => f_literal_pattern(core_literal_step(t)), u => k_with_children(t, f_literal_patterns(ks(t))))

@unsafe
def f_literal_patterns(+ts: List<&2,KTerm>) -> List<&2,KTerm>:
  match ts:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{f_literal_pattern(head), f_literal_patterns(rest)}
''')
# Prettyprinting shares existing quoting and constructor sugar recognizers.
def pretty(s):
 s=s.replace('qt(t)', 'kl_number(t)') if False else s
 a=s.index('def kp_nat(');b=s.index('@unsafe\ndef kp_array',a);s=s[:a]+s[a:b].replace('qt(t)','kl_number(t)')+s[b:]
 s=replace(s,'kc(String, core_nat(t), u => U32.show(qt(t)) ++ "n", u =>','kc(String, core_literal(t), u => kc(String, core_nat(t), u => U32.show(kl_number(t)) ++ "n", u => kp_ctor(core_literal_step(t), p, env)), u =>')
 s=wrap(s,'kp_number','kc(Maybe<&2, U32>, core_literal(t) && (String.eq(nm(t), "U32") || String.eq(nm(t), "F32")), u => Some{kl_number(t)}, u => EXPR)')
 s=wrap(s,'kp_string','kc(Maybe<&2, String>, core_literal(t) && String.eq(nm(t), "String"), u => kp_string(core_literal_step(t)), u => EXPR)')
 return s
edit('src/core/pretty.bend',pretty)
# Existing JS native literal helpers consume values before allocating words.
def js(s):
 s=replace(s,'kc(String, core_nat(t), u => U32.show(qt(t)) ++ "n", u =>','kc(String, core_literal(t), u => kc(String, core_nat(t), u => U32.show(kl_number(t)) ++ "n", u => kc(String, String.eq(nm(t), "String"), u => j_quote(kl_text(t)), u => j_word_text(Some{kl_number(t)}, String.eq(nm(t), "F32")))), u =>')
 s=s.replace('U32.to_nat(qt(t))','U32.to_nat(kl_number(t))')
 s=wrap(s,'j_u32_node','kc(Maybe<&2,U32>, core_literal(t) && String.eq(nm(t), "U32"), u => Some{kl_number(t)}, u => EXPR)')
 s=wrap(s,'j_string','kc(Maybe<&2,String>, core_literal(t) && String.eq(nm(t), "String"), u => Some{String.reverse(acc) ++ kl_text(t)}, u => EXPR)')
 return s
edit('src/back/js/literals.bend',js)
edit('src/back/native/erase.bend',lambda s:wrap(s,'nc_erase','kc(KTerm, core_literal(t), u => t, u => EXPR)'))
def native(s):
 a=s.index('def nc_nat_literal(');b=s.index('@unsafe\ndef nc_literal',a);s=s[:a]+s[a:b].replace('qt(t)','kl_number(t)')+s[b:]
 s=wrap(s,'nc_literal','kc(NC_Literal, core_literal(t) && Bool.not(String.eq(nm(t), "String")), u => NC_Literal{True{}, kl_number(t)}, u => EXPR)')
 s=replace(s,'kc(KTerm, core_nat(t), u => kt("NWord", U32.show(qt(t)), 0, 0, Nil{}), u =>','kc(KTerm, core_literal(t), u => kc(KTerm, String.eq(nm(t), "String"), u => nc_compact(core_literal_step(t)), u => kt("NWord", U32.show(kl_number(t)), 0, 0, Nil{})), u =>')
 return s
edit('src/back/native/bridge.bend',native)
# Preserve literal-vs-constructor identity and every interpreted payload in memo.
edit('src/check/specialize.bend',lambda s:wrap(s,'term_key','kc(String, core_literal(t), u => sp_key_string("Lit") ++ sp_key_string(nm(t)) ++ U32.show(kl_number(t)) ++ ":" ++ sp_key_string(kl_text(t)), u => EXPR)'))
# Advertised literal representation is distinct from unchanged source-range ABI.
def host(s):
 s=replace(s,"const exports=[...roots];","const exports=[...roots];\n  if(fs.readFileSync(path.join(project,'src/core/term.bend'),'utf8').includes('def compiler_literal_abi('))exports.push('compiler_literal_abi');")
 s=replace(s,"const spanAbi=module.default.compiler_span_abi?.();","const literalAbi=module.default.compiler_literal_abi?.();\n  if(module.default.compiler_literal_abi!==undefined&&literalAbi!==1)throw Error('Unknown compiler literal ABI: '+literalAbi);\n  const spanAbi=module.default.compiler_span_abi?.();")
 s=replace(s,"KSpecialized:['book','error'],","...(literalAbi===1?{KLiteral:['kind','number','text','originBegin','originEnd']}:{}),\n    KSpecialized:['book','error'],")
 s=replace(s,'const SPAN_ABI=3,SPAN_CACHE=4,U32_MAX','const SPAN_ABI=3,SPAN_CACHE=4,LITERAL_CACHE=5,U32_MAX')
 s=replace(s,'validateSpanBook(book,ranges) {','validateSpanBook(book,ranges,literalAbi=0) {')
 s=replace(s,"if(value.$==='KTerm') {","if(value.$==='KLiteral') {\n      if(literalAbi!==1||!['Nat','U32','F32','String'].includes(value.kind)||!Number.isSafeInteger(value.number)||value.number<0||value.number>U32_MAX||typeof value.text!=='string'||(value.kind==='String'?value.number!==0:value.text!==''))throw Error('Invalid compiler literal payload');\n    }\n    if(value.$==='KTerm'||value.$==='KLiteral') {")
 s=replace(s,'validateSpanCache(c,{compilerSha256,baseSha256,sourcePath,sourceText})','validateSpanCache(c,{compilerSha256,baseSha256,sourcePath,sourceText,literalAbi=0})')
 s=replace(s,'c.version!==SPAN_CACHE||c.spanAbi',"c.version!==(literalAbi===1?LITERAL_CACHE:SPAN_CACHE)||(c.literalAbi??0)!==literalAbi||c.spanAbi")
 s=replace(s,'validateSpanBook(c.book,[range]);','validateSpanBook(c.book,[range],literalAbi);')
 s=replace(s,'validateSpanBook(parsed.book,[range]);','validateSpanBook(parsed.book,[range],api.compiler_literal_abi?.()??0);')
 s=replace(s,'const version=api.compiler_span_abi?.()===SPAN_ABI?SPAN_CACHE:api.f_load_graph_seed?2:1;','const literalAbi=api.compiler_literal_abi?.()??0;\n  const version=literalAbi===1?LITERAL_CACHE:api.compiler_span_abi?.()===SPAN_ABI?SPAN_CACHE:api.f_load_graph_seed?2:1;')
 s=replace(s,'return {version,compilerSha256,baseSha256,sourcePath,sourceText,directory,file};','return {version,literalAbi,compilerSha256,baseSha256,sourcePath,sourceText,directory,file};')
 s=s.replace('info.version===SPAN_CACHE','info.version>=SPAN_CACHE')
 s=replace(s,'const cached={version,compilerSha256,baseSha256,sourcePath,validatedBy:',"const cached={version,...(info.literalAbi?{literalAbi:info.literalAbi}:{}),compilerSha256,baseSha256,sourcePath,validatedBy:")
 return s
edit('tools/typed-driver.mjs',host)
edit('tools/development/workflow.mjs',lambda s:replace(s,'c.version===4&&c.spanAbi===3','(c.version===4||(c.version===5&&c.literalAbi===1))&&c.spanAbi===3'))
changes=[]
for p in sorted(project.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(project);before=(old/rel).read_bytes();after=p.read_bytes()
 if before!=after:
  changes.append({'file':str(rel),'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)})
  (out/(str(rel).replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=str(rel),tofile=str(rel))))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-compact-literal-consumers','parent':str(old),'changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'plan':str(root/'design/phase16/checker-compact-literals.md'),'generationEnabled':True,'literalAbi':1,'baseCacheVersion':5,'installationEligible':False,'remainingGate':'memo logical guard, historical protocol, focused semantics and full integration'},indent=2)+'\n')
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n')
print(out)
