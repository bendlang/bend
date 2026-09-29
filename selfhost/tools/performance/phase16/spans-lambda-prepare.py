#!/usr/bin/env python3
"""Explicit Lambda-only syntax presence on the frozen literal/context union."""
import hashlib,json,re,shutil,difflib
from pathlib import Path
r=Path(__file__).resolve().parents[4];parent=r/'selfhost/build/phase16/literal-context-source-04/project';out=r/'selfhost/build/phase16/spans-lambda-source-01';assert not out.exists();p=out/'project';shutil.copytree(parent,p)

def edit(file,old,new):
 f=p/file;s=f.read_text();assert s.count(old)==1,(file,old,s.count(old));f.write_text(s.replace(old,new))

def function(text,name):
 a=text.index('def '+name+'(');n=re.search(r'\n(?:@unsafe|law |def |type )',text[a+4:]);b=a+4+n.start() if n else len(text);return a,b

f=p/'src/core/term.bend';s=f.read_text()
s=s.replace('  KLiteral{+kind:', '  KLambda{+name: String, +id: U32, +quant: U32, +kids: List<&2,KTerm>, +removed: List<&2,String>, +originBegin: U32, +originEnd: U32, +quantityPresent: Bool}\n  KLiteral{+kind:',1)
projection={'tg':'"Lam"','nm':'name','ix':'id','qt':'quant','ks':'kids','rm':'removed','kb':'begin','ke':'end','core_literal':'False{}','kl_number':'0','kl_text':'""'}
case='    case KLambda{name, id, quant, kids, removed, begin, end, present}:\n'
for name,body in projection.items():
 a,b=function(s,name);piece=s[a:b];at=piece.index('    case KLiteral{');piece=piece[:at]+case+'      '+body+'\n'+piece[at:];s=s[:a]+piece+s[b:]
branches={
 'subst_node':'core_rebuild(KLambda{name, id, quant, subst_terms(kids, id0, v), removed, begin, end, present})',
 'core_subst_stable':'core_subst_stable_terms(kids)',
 'k_with_children':'KLambda{name, id, quant, newKids, removed, begin, end, present}',
 'k_with_span':'KLambda{name, id, quant, kids, removed, newBegin, newEnd, present}',
}
for name,body in branches.items():
 a,b=function(s,name);piece=s[a:b]
 if name=='subst_node':piece=piece.replace('def subst_node(t, id, v):','def subst_node(t, id0, v):').replace('subst_terms(kids, id, v)','subst_terms(kids, id0, v)')
 if name=='k_with_children':piece=piece.replace('+kids: List<&2,KTerm>', '+newKids: List<&2,KTerm>').replace('quant, kids, removed, originBegin','quant, newKids, removed, originBegin')
 if name=='k_with_span':piece=piece.replace('+begin: U32, +end: U32','+newBegin: U32, +newEnd: U32').replace('removed, begin, end}', 'removed, newBegin, newEnd}').replace('text, begin, end}', 'text, newBegin, newEnd}')
 at=piece.index('    case KLiteral{');piece=piece[:at]+case+'      '+body+'\n'+piece[at:];s=s[:a]+piece+s[b:]
s=s.replace('def compiler_literal_abi()', 'def compiler_term_abi()')
s+='''
# Quantity presence is explicit syntax metadata on Lambda only. Ordinary term
# allocation remains unchanged; legacy KTerm/Lam inputs supplied a quantity.
@unsafe
def k_lam(+name: String, +id: U32, +quant: U32, +kids: List<&2,KTerm>, +begin: U32, +end: U32, +present: Bool) -> KTerm:
  KLambda{name, id, quant, kids, Nil{}, begin, end, present}

@unsafe
def k_quantity_present(+t: KTerm) -> Bool:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: String.eq(tag, "Lam")
    case KLambda{name, id, quant, kids, removed, begin, end, present}: present
    case KLiteral{kind, number, text, begin, end}: False{}

# Field-changing structural rebuilds retain the input variant and syntax fact.
@unsafe
def k_rebuild(+t: KTerm, +name: String, +id: U32, +quant: U32, +kids: List<&2,KTerm>, +removed: List<&2,String>, +begin: U32, +end: U32) -> KTerm:
  match t:
    case KTerm{tag, oldName, oldId, oldQuant, oldKids, oldRemoved, oldBegin, oldEnd}:
      KTerm{tag, name, id, quant, kids, removed, begin, end}
    case KLambda{oldName, oldId, oldQuant, oldKids, oldRemoved, oldBegin, oldEnd, present}:
      KLambda{name, id, quant, kids, removed, begin, end, present}
    case KLiteral{kind, number, text, oldBegin, oldEnd}: t

# Strong normalization, unlike alpha-renaming, omits the optional syntax q.
@unsafe
def k_snf_children(+t: KTerm, +kids: List<&2,KTerm>) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, oldKids, removed, begin, end}:
      kc(KTerm, String.eq(tag, "Lam"), u => KLambda{name, id, quant, kids, removed, begin, end, False{}}, u => KTerm{tag, name, id, quant, kids, removed, begin, end})
    case KLambda{name, id, quant, oldKids, removed, begin, end, present}:
      KLambda{name, id, quant, kids, removed, begin, end, False{}}
    case KLiteral{kind, number, text, begin, end}: t
''';f.write_text(s)

# The two source-range recursive rebuilds pattern-match the public variants.
f=p/'src/front/parser.bend';s=f.read_text();a,b=function(s,'f_span_created');piece=s[a:b];at=piece.index('    case KLiteral{');piece=piece[:at]+'''    case KLambda{name, id, quant, kids, removed, oldBegin, oldEnd, present}:
      f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(oldBegin, 0), u => t,
        u => KLambda{name, id, quant, f_spans_created(kids, begin, end), removed, begin, end, present})
'''+piece[at:];s=s[:a]+piece+s[b:];f.write_text(s)
f=p/'src/front/elaborate.bend';s=f.read_text();a,b=function(s,'f_pattern_value');piece=s[a:b];at=piece.index('    case KLiteral{');piece=piece[:at]+'''    case KLambda{name, id, quant, kids, removed, oldBegin, oldEnd, present}:
      KLambda{name, id, quant, f_pattern_values(kids, begin, end), removed,
        f_choose(U32, U32.is_gt(begin, 0), u => begin, u => oldBegin),
        f_choose(U32, U32.is_gt(begin, 0), u => end, u => oldEnd), present}
'''+piece[at:];s=s[:a]+piece+s[b:];f.write_text(s)

def mask(text):
 chars=list(text);i=0
 while i<len(text):
  if text[i]=='#':
   j=text.find('\n',i);j=len(text) if j<0 else j;chars[i:j]=' '*(j-i);i=j
  elif text[i] in '\"\'':
   quote=text[i];j=i+1
   while j<len(text):
    if text[j]=='\\':j+=2;continue
    if text[j]==quote:j+=1;break
    j+=1
   chars[i:j]=''.join('\n' if c=='\n' else ' ' for c in text[i:j]);i=j
  else:i+=1
 return ''.join(chars)

producers=[]
for f in (p/'src').rglob('*.bend'):
 s=f.read_text();code=mask(s);defs=list(re.finditer(r'^def\s+(\w+)\(',code,re.M));edits=[]
 for m in re.finditer(r'\b(kt|kt_span)\("Lam",\s*',s):
  if code[m.start():m.start()+len(m.group(1))]!=m.group(1):continue
  name=next(x.group(1) for x in reversed(defs) if x.start()<m.start());at=code.index('(',m.start())+1;depth=1;end=at
  while depth:depth+=(code[end]=='(')-(code[end]==')');end+=1
  end-=1
  absent=(str(f.relative_to(p)).startswith('src/back/') or str(f.relative_to(p))=='src/check/annotate.bend' or name in ['lhs_ext','f_rewrite_proof','f_law_where','f_law_bind'] or str(f.relative_to(p))=='src/front/parser.bend')
  present='k_quantity_present(term)' if name=='ffw_frame' else 'False{}' if absent else 'True{}'
  edits += [(m.start(),m.end(),'k_lam('),(end,end,(', 0, 0, ' if m.group(1)=='kt' else ', ')+present)]
  producers.append({'path':str(f.relative_to(p)),'function':name,'presence':present})
 for a,b,replacement in sorted(edits,reverse=True):s=s[:a]+replacement+s[b:]
 if edits:f.write_text(s)

# All remaining direct generic rebuilds capable of receiving Lambda retain it.
generic=['src/check/specialize.bend','src/core/normalize.bend','src/load/graph.bend','src/load/paths.bend','src/load/modules.bend','src/back/js/emit.bend']
for file in generic:
 f=p/file;s=f.read_text();code=mask(s);edits=[]
 for m in re.finditer(r'KTerm\{tg\((\w+)\),\s*',s):
  # These three match-goal updates are statically ADT-only.
  if m.group(1)=='a':continue
  at=m.start()+len('KTerm{');depth=1;end=at
  while depth:depth+=(code[end]=='{')-(code[end]=='}');end+=1
  edits.extend([(m.start(),m.end(),'k_rebuild('+m.group(1)+', '),(end-1,end,')')])
 for a,b,v in sorted(edits,reverse=True):s=s[:a]+v+s[b:]
 f.write_text(s)

# Native erasure deliberately clears old ranges/marks; retain that policy and
# Lambda syntax presence while rebuilding its remaining children.
for file in ['src/back/native/erase.bend','src/back/native/bridge.bend']:
 f=p/file;s=f.read_text();code=mask(s);edits=[]
 for m in re.finditer(r'kt\(tg\((\w+)\),\s*',s):
  at=code.index('(',m.start())+1;depth=1;end=at
  while depth:depth+=(code[end]=='(')-(code[end]==')');end+=1
  edits.extend([(m.start(),m.end(),'k_rebuild('+m.group(1)+', '),(end-1,end-1,', Nil{}, 0, 0')])
 for a,b,v in sorted(edits,reverse=True):s=s[:a]+v+s[b:]
 f.write_text(s)
edit('src/core/graph.bend','k_with_children(parent, List.reverse(&2, KTerm, done))','k_snf_children(parent, List.reverse(&2, KTerm, done))')

# Consolidated term capability replaces only this uninstalled prototype's
# literal-specific capability. Frozen literal05 keeps its original host.
f=p/'tools/typed-driver.mjs';s=f.read_text().replace('compiler_literal_abi','compiler_term_abi').replace('literalAbi','termAbi').replace('LITERAL_CACHE=5','TERM_CACHE=6').replace('LITERAL_CACHE','TERM_CACHE').replace('Unknown compiler literal ABI','Unknown compiler term ABI').replace('Literal ABI requires source-range ABI3','Term ABI requires source-range ABI3')
s=s.replace("{KLiteral:['kind','number','text','originBegin','originEnd']}","{KLiteral:['kind','number','text','originBegin','originEnd'],KLambda:['name','id','quant','kids','removed','originBegin','originEnd','quantityPresent']}")
old="    if(value.$==='KTerm'||value.$==='KLiteral') {"
assert s.count(old)==1;s=s.replace(old,"    if(value.$==='KLambda'&&(termAbi!==1||typeof value.quantityPresent!=='boolean'))throw Error('Invalid compiler Lambda payload');\n    if(value.$==='KTerm'||value.$==='KLiteral'||value.$==='KLambda') {")
f.write_text(s)
f=p/'tools/development/workflow.mjs';s=f.read_text();old='c.version===5&&c.literalAbi===1';assert s.count(old)==1;s=s.replace(old,'c.version===6&&c.termAbi===1');f.write_text(s)

changes=[]
for f in p.rglob('*'):
 if f.is_file() and f.relative_to(p).parts[0] in ['src','tools']:
  old=parent/f.relative_to(p)
  if f.read_bytes()!=old.read_bytes():
   rel=f.relative_to(p);patch=out/(str(rel).replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(old.read_text().splitlines(True),f.read_text().splitlines(True),fromfile='a/'+str(rel),tofile='b/'+str(rel))));changes.append({'path':str(rel),'parentSha256':hashlib.sha256(old.read_bytes()).hexdigest(),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'patch':str(patch),'lineDelta':len(f.read_text().splitlines())-len(old.read_text().splitlines())})
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(p),'changes':changes,'producers':producers,'netLines':sum(x['lineDelta'] for x in changes)},indent=2)+'\n');(out/'workflow.json').write_text(json.dumps({'project':str(p),'upstream':str(r/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':2,'jobs':1},indent=2)+'\n');print(out)
