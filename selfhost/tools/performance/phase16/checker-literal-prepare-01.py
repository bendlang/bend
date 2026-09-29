from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/wave6-source-01/project';out=base/'build/phase16/checker-literal-source-01';out.mkdir();shutil.copytree(old,out/'project');project=out/'project'
def edit(name,fn):
 p=project/name;p.write_text(fn(p.read_text()))
def add_case(s,name,body):
 a=s.index('def '+name+'(');b=s.find('\n@unsafe',a)
 if b<0:b=len(s)
 return s[:b].rstrip()+ '\n    case KLiteral{kind, number, text, literalBegin, literalEnd}:\n      '+body+'\n'+s[b:]
def term(s):
 needle='  KTerm{+tag:';a=s.index(needle);b=s.index('\n',a)
 s=s[:b]+'\n  KLiteral{+kind: String, +number: U32, +text: String, +originBegin: U32, +originEnd: U32}'+s[b:]
 for name,body in [('tg','"Lit"'),('nm','kind'),('ix','0'),('qt','0'),('ks','Nil{}'),('rm','Nil{}'),('subst_node','t'),('core_subst_stable','True{}'),('kb','literalBegin'),('ke','literalEnd'),('k_with_children','t'),('k_with_span','KLiteral{kind, number, text, begin, end}')]:s=add_case(s,name,body)
 s+='''
# Interpreted literal leaves are closed; payload is never a binder or quantity.
@unsafe
def core_literal(+t: KTerm) -> Bool:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: False{}
    case KLiteral{kind, number, text, begin, end}: True{}

@unsafe
def kl_number(+t: KTerm) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: 0
    case KLiteral{kind, number, text, begin, end}: number

@unsafe
def kl_text(+t: KTerm) -> String:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: ""
    case KLiteral{kind, number, text, begin, end}: text

@unsafe
def kl_make(+kind: String, +number: U32, +text: String) -> KTerm:
  KLiteral{kind, number, text, 0, 0}
'''
 return s
edit('src/core/term.bend',term)
edit('src/front/parser.bend',lambda s:add_case(s,'f_span_created','f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(literalBegin, 0), u => t, u => k_with_span(t, begin, end))'))
edit('src/front/elaborate.bend',lambda s:add_case(s,'f_pattern_value','f_choose(KTerm, U32.is_gt(begin, 0), u => k_with_span(t, begin, end), u => t)'))
# Closed literals have no binders, namespace references or relative paths.
for name,fn in [('src/check/specialize.bend','sp_shift'),('src/load/paths.bend','f_path_term'),('src/load/modules.bend','f_qual_term'),('src/load/graph.bend','f_alias_named')]:
 def wrap(s):
  a=s.index('def '+fn+'(');a=s.index('\n  ',s.index(') -> KTerm:',a))+3;b=s.find('\n@unsafe',a)
  if b<0:b=len(s)
  expr=s[a:b].rstrip();return s[:a]+'kc(KTerm, core_literal(t), u => t, u =>\n    '+expr+')\n'+s[b:]
 edit(name,wrap)
# Public direct controls only; production capability/cache changes come with generation.
exports=['tg','nm','ix','qt','ks','rm','kb','ke','kl_make','kl_number','kl_text','core_literal','k_with_children','k_with_span','subst','core_subst_stable','sp_shift','f_path_term','f_pattern_value','f_span_created','f_qual_term','f_alias_term','f_fresh_defs']
edit('tools/typed-driver.mjs',lambda s:s.replace('const exports=[...roots];','const exports=[...roots];\n  exports.push('+','.join(repr(x) for x in exports)+');'))
changes=[]
for p in sorted(project.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(project);before=(old/rel).read_bytes();after=p.read_bytes()
 if before!=after:
  changes.append({'file':str(rel),'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)})
  (out/(str(rel).replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=str(rel),tofile=str(rel))))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-compact-literal-transport','parent':str(old),'changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'plan':str(root/'design/phase16/checker-compact-literals.md'),'generationEnabled':False,'installationEligible':False},indent=2)+'\n')
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n')
print(out)
