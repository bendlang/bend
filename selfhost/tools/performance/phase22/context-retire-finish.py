from pathlib import Path
P=Path('selfhost/build/phase22/context-source-08/project/src/front')
def once(s,a,b):
 assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
p=P/'literals_arrays.bend';s=p.read_text()
s=once(s,'''      f_context_material_next(term, rest, built, lower,
        f_choose(KTerm, lower,
          u => f_context_lower(f_choose(KTerm, deferred, u => f_context_higher(head), u => head)),
          u => f_choose(KTerm, deferred, u => head, u => f_context_higher(head))))''','''      f_choose(KTerm, Bool.not(lower) && deferred,
        u => f_context_material_children(term, rest, Con{head, built}, lower),
        u => f_context_material_next(term, rest, built, lower,
          f_choose(KTerm, lower,
            u => f_context_lower(f_choose(KTerm, deferred, u => f_context_higher(head), u => head)),
            u => f_context_higher(head))))''')
p.write_text(s)
p=P/'elaborate.bend';s=p.read_text();s=once(s,'f_choose(KTerm, f_eq(tg(t), "Var") && U32.is_eq(ix(t), id), u => v, u => k_with_children(t, f_subs(ks(t), id, v)))','f_choose(KTerm, f_eq(tg(t), "Var") && U32.is_eq(ix(t), id),\n    u => f_choose(KTerm, U32.is_eq(kb(v), 0) && U32.is_eq(ke(v), 0) && Bool.not(f_eq(tg(v), "FUnboundVar")), u => k_with_span(v, kb(t), ke(t)), u => v),\n    u => k_with_children(t, f_subs(ks(t), id, v)))');p.write_text(s)
for p in P.glob('*.bend'):
 s=p.read_text().replace('FCursorContext','FParseContext').replace('FContextual','FParseContext');p.write_text(s)
