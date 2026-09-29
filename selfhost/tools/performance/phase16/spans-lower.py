#!/usr/bin/env python3
from pathlib import Path
P=Path(__file__).resolve().parents[4]/'selfhost/build/phase16/spans-origin-source-01/project'
def edit(rel, changes):
 p=P/rel;s=p.read_text()
 for old,new in changes:
  assert old in s,(rel,old)
  s=s.replace(old,new)
 p.write_text(s)
def span(old,t):
 assert old.startswith('kt(') and old.endswith(')')
 return (old,'kt_span('+old[3:-1]+', kb('+t+'), ke('+t+'))')
edit('src/core/term.bend',[
 ('u => core_apply(kid(t, 0), kid(t, 1)), u => t)', 'u => core_apply_span(kid(t, 0), kid(t, 1), kb(t), ke(t)), u => t)'),
 ('u => core_apply(core_beta(kid(t, 0)), kid(t, 1)), u => t)', 'u => core_apply_span(core_beta(kid(t, 0)), kid(t, 1), kb(t), ke(t)), u => t)'),
 ('def core_apply(f, x):\n  kc(KTerm, String.eq(tg(f), "Lam"), u => subst(kid(f, 0), ix(f), x), u => app(f, x))', 'def core_apply(f, x):\n  core_apply_span(f, x, 0, 0)\n\n@unsafe\ndef core_apply_span(+f: KTerm, +x: KTerm, +begin: U32, +end: U32) -> KTerm:\n  kc(KTerm, String.eq(tg(f), "Lam"), u => subst(kid(f, 0), ix(f), x), u => kt_span("App", "", 0, 0, [f, x], begin, end))'),
 ('u => kt("Ctr", "Zero", 0, 1, Nil{}), u => kt("Ctr", "Succ", 0, 1, [core_nat_make(U32.sub(qt(t), 1))]))','u => kt_span("Ctr", "Zero", 0, 1, Nil{}, kb(t), ke(t)), u => kt_span("Ctr", "Succ", 0, 1, [kt_span("LitNat", "", 0, U32.sub(qt(t), 1), Nil{}, kb(t), ke(t))], kb(t), ke(t)))')])
edit('src/front/elaborate.bend',[
 span('kt("Var", nm(x), ix(x), 1, Nil{})','x'),
 ('u => f_literal(nm(t)),','u => k_with_span(f_literal(nm(t)), kb(t), ke(t)),'),
 span('kt("Var", nm(t), ix(t), qt(t), Nil{})','t'),
 ('u => kt("All", nm(t), ix(t), qt(t), [f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), Con{kt_span("Var", nm(t), ix(t), qt(t), Nil{}, kb(t), ke(t)), env}, book)]),','u => kt_span("All", nm(t), ix(t), qt(t), [f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), Con{kt_span("Var", nm(t), ix(t), qt(t), Nil{}, kb(t), ke(t)), env}, book)], kb(t), ke(t)),'),
 span('kt("Var", nm(x), ix(x), qt(x), Nil{})','x'),
 ('u => f_pattern_literal(nm(x)), u => kt(tg(x), nm(x), ix(x), qt(x), f_patterns(ks(x)))','u => k_with_span(f_pattern_literal(nm(x)), kb(x), ke(x)), u => k_with_children(x, f_patterns(ks(x)))'),
 span('kt("Match", "", 0, 1, Con{kt("Heads", "", 0, 1, f_scope_terms(ks(kid(t, 0)), env, book)), f_scope_rows(f_tail_terms(ks(t)), env, book)})','t'),
 span('kt("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)])','kid(t, 0)'),
 span('kt("Let", "", 0, 1, [kt_span("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)], kb(kid(t, 0)), ke(kid(t, 0))), kid(body, 0)])','t'),
 span('kt("Lam", nm(v), ix(v), qt(v), [f_flat_match(Con{h, hs}, rows, vs)])','v'),
 span('kt("Mat", nm(c), 0, 1, [f_flat_match(norm_join(fields, hs), f_hit_rows(rows, c, fields, v), norm_join(fields, vs)), f_flat_match(Con{h, hs}, f_miss_rows(rows, nm(c)), Con{v, vs})])','c'),
 span('kt("Ctr", nm(c), 0, 1, fields)','c'),
 ('f_scope_app(f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), env, book))','f_scope_app_span(f_scope(kid(t, 0), env, book), f_scope(kid(t, 1), env, book), kb(t), ke(t))')])
edit('src/front/families.bend',[
 ('def f_scope_app(f, x):\n  f_choose(KTerm, f_eq(tg(f), "Lam"), u => f_sub(kid(f, 0), ix(f), x), u => app(f, x))','def f_scope_app(f, x):\n  f_scope_app_span(f, x, 0, 0)\n\n@unsafe\ndef f_scope_app_span(+f: KTerm, +x: KTerm, +begin: U32, +end: U32) -> KTerm:\n  f_choose(KTerm, f_eq(tg(f), "Lam"), u => f_sub(kid(f, 0), ix(f), x), u => kt_span("App", "", 0, 0, [f, x], begin, end))'),
 span('kt("Var", nm(v), ix(v), q, Nil{})','v'),
 span('kt("Var", nm(v), ix(v), f_choose(U32, U32.is_eq(q, 2), u => 2, u => qt(v)), Nil{})','v'),
 ('f_scope_apply_many(head, f_scope_call_args(f_tail_terms(ks(t)), env, book))','f_scope_apply_span(head, f_scope_call_args(f_tail_terms(ks(t)), env, book), kb(t), ke(t))'),
 span('kt("Var", nm(bound), ix(bound), qt(bound), Nil{})','t'),
 span('kt("FUnboundVar", nm(t), ix(t), 0, Nil{})','t'),
 span('kt(f_choose(String, U32.is_eq(qt(t), 4), u => "RewriteVar", u => "Var"), nm(t), ix(t), f_choose(U32, U32.is_eq(qt(t), 4), u => 1, u => qt(t)), Nil{})','t'),
 span('kt("Var", nm(v), ix(v), qt(v), Nil{})','v'),
 span('kt("Ref", nm(t) ++ ".pure", ix(t), 1, Nil{})','t'),
 span('kt("Ref", nm(t) ++ ".bind", ix(t), 1, Nil{})','t')])
p=P/'src/front/families.bend';s=p.read_text();s+='''
@unsafe
def f_scope_apply_span(+head: KTerm, +args: List<&2,KTerm>, +begin: U32, +end: U32) -> KTerm:
  match args:
    case Nil{}: head
    case Con{a, rest}: f_scope_apply_span(f_scope_app_span(head, a, begin, end), rest, begin, end)
''';p.write_text(s)
edit('src/front/freshen.bend',[span('kt("Var", nm(t), ix(kid(m, 0)), qt(t), Nil{})','t')])
edit('src/front/fresh_work.bend',[
 span('kt("Var", nm(term), next, 1, Nil{})','term'),
 span('kt("All", nm(term), id, qt(term), [typ, value])','term'),
 span('kt("Lam", nm(term), id, qt(term), [value])','term'),
 span('kt("Bind", nm(binding), id, qt(binding), [value])','binding'),
 # One continuation around the entire Let keeps parent metadata without
 # threading another origin argument through all existing let continuations.
 ('  FFLetBody{+built: List<&2,KTerm>}','  FFLetBody{+built: List<&2,KTerm>}\n  FFOrigin{begin: U32, end: U32}'),
 ('u => ffw_let(env, env, ks(term), Nil{}, next, stack)','u => ffw_let(env, env, ks(term), Nil{}, next, Con{FFOrigin{kb(term), ke(term)}, stack})'),
 ('    case FFLetBody{built}:','    case FFOrigin{begin, end}:\n      ffw_done(k_with_span(value, begin, end), next, stack)\n    case FFLetBody{built}:')])
edit('src/front/flatten.bend',[
 span('kt("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)])','kid(t, 0)'),
 span('kt("Let", "", 0, 1, [kt_span("Bind", nm(kid(t, 0)), ix(kid(t, 0)), qt(kid(t, 0)), [kid(t, 1)], kb(kid(t, 0)), ke(kid(t, 0))), kid(body, 0)])','t'),
 span('kt("Let", "", 0, 1, norm_join(f_parallel_binds(ks(kid(t, 0)), ks(kid(t, 1))), [f_unlamb(body, terms_len(ks(kid(t, 0))))]))','t'),
 span('kt("Lam", nm(v), ix(v), qt(v), [body])','v'),
 span('kt("Var", nm(p), ix(p), f_choose(U32, U32.is_eq(q, 2), u => 2, u => qt(p)), Nil{})','p'),
 span('kt("Mat", nm(c), 0, 1, [hit, miss])','c')])
p=P/'tools/typed-driver.mjs';s=p.read_text().replace('api.diagnostic_result_locate&&detailed.diagnostic.definition','api.diagnostic_result_locate');p.write_text(s)
print(P)
