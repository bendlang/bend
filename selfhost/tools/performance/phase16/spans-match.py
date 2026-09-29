#!/usr/bin/env python3
from pathlib import Path
import shutil,re
R=Path(__file__).resolve().parents[4];base=R/'selfhost/build/phase16/spans-integration-source-02/project';out=R/'selfhost/build/phase16/spans-origin-source-03';out.mkdir();P=out/'project';shutil.copytree(base,P)
def calls(s,name,arg):
 # Add a final explicit argument at every complete occurrence of a call/def.
 edits=[]
 for m in re.finditer(r'\b'+name+r'\(',s):
  i=m.end();depth=1;quote=False;escape=False
  while depth:
   c=s[i]
   if quote:
    if escape:escape=False
    elif c=='\\':escape=True
    elif c=='"':quote=False
   elif c=='"':quote=True
   elif c in '([{':depth+=1
   elif c in ')]}':depth-=1
   i+=1
  edits.append(i-1)
 for i in reversed(edits):s=s[:i]+', '+arg+s[i:]
 return s
names=['ff_match','ff_column','ff_split','ff_fields_done','ff_hit_done','ff_miss_done']
p=P/'src/front/flatten.bend';s=p.read_text()
for name in names:
 a=s.index('law '+name+':');b=s.index('\n\n',a);s=s[:b]+s[b:] if False else s
 block=s[a:b];assert block.endswith('  FFlatten');s=s[:a]+block[:-len('  FFlatten')]+'  for +origin: KTerm\n  FFlatten'+s[b:];s=calls(s,name,'origin')
s=s.replace('ff_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars, next, origin)','ff_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars, next, t)')
s=s.replace('ff_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars, next, origin)','ff_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars, next, kid(t, 1))')
s=s.replace('FFlatten{atom("Efq"), next}','FFlatten{kt_span("Efq", "", 0, 0, Nil{}, kb(origin), ke(origin)), next}')
# A fresh pattern-field name still denotes the source pattern occurrence.
s=s.replace('kt("Var", "_" ++ U32.show(next), U32.add(2147483648, next), q, Nil{})','kt_span("Var", "_" ++ U32.show(next), U32.add(2147483648, next), q, Nil{}, kb(p), ke(p))')
p.write_text(s)
p=P/'src/front/elaborate.bend';s=p.read_text()
names=['f_flat_match','f_flat_column','f_flat_split','f_flat_fields']
for name in names:
 a=s.index('law '+name+':');b=s.index('\n\n',a);block=s[a:b];assert block.endswith('  KTerm');s=s[:a]+block[:-len('  KTerm')]+'  for +origin: KTerm\n  KTerm'+s[b:];s=calls(s,name,'origin')
s=s.replace('f_flat_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars, origin)','f_flat_match(ks(kid(t, 0)), f_tail_terms(ks(t)), vars, t)')
s=s.replace('f_flat_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars, origin)','f_flat_match([kid(t, 1)], [kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, [kid(t, 0)]), kid(t, 2)])], vars, kid(t, 1))')
s=s.replace('u => atom("Efq"), u => f_flat(', 'u => kt_span("Efq", "", 0, 0, Nil{}, kb(origin), ke(origin)), u => f_flat(')
s=s.replace('f_eq(tg(c), "Absent"), u => atom("Efq"),','f_eq(tg(c), "Absent"), u => kt_span("Efq", "", 0, 0, Nil{}, kb(origin), ke(origin)),')
# Pattern substitution preserves each use occurrence; beta substitution above
# keeps the inserted argument's range and remains a separate semantic operation.
for name in ['f_var_rows','f_hit_row']:
 a=s.index('def '+name+'(');b=s.index('\n@unsafe',a);block=s[a:b].replace('f_sub(', 'f_pattern_sub(');s=s[:a]+block+s[b:]
s+='''
# Pattern substitution is renaming/destructuring, not beta substitution: each
# occurrence supplies the range for the substituted pattern and all its fields.
@unsafe
def f_pattern_sub(+t: KTerm, +id: U32, +value: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Var") && U32.is_eq(ix(t), id),
    u => f_pattern_value(value, kb(t), ke(t)),
    u => k_with_children(t, f_pattern_subs(ks(t), id, value)))

@unsafe
def f_pattern_subs(+terms: List<&2,KTerm>, +id: U32, +value: KTerm) -> List<&2,KTerm>:
  match terms:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{f_pattern_sub(head, id, value), f_pattern_subs(rest, id, value)}

@unsafe
def f_pattern_value(+t: KTerm, +begin: U32, +end: U32) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, oldBegin, oldEnd}:
      KTerm{tag, name, id, quant, f_pattern_values(kids, begin, end), removed,
        f_choose(U32, U32.is_gt(begin, 0), u => begin, u => oldBegin),
        f_choose(U32, U32.is_gt(begin, 0), u => end, u => oldEnd)}

@unsafe
def f_pattern_values(+terms: List<&2,KTerm>, +begin: U32, +end: U32) -> List<&2,KTerm>:
  match terms:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{f_pattern_value(head, begin, end), f_pattern_values(rest, begin, end)}
'''
p.write_text(s)
p=P/'src/diagnostic/frontend.bend';s=p.read_text().replace('String.eq(f_source_text(source), f_source_text(old))','f_seed_text_equal(f_source_text(source), f_source_text(old))');p.write_text(s)
shutil.copy2(__file__,out/Path(__file__).name)
print(P)
