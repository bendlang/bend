# Conservative whole-program dependency closure. Run only after checking and
# specialization have produced a canonical book (one final entry per name).
# Types, constructor telescopes, and constructor parents are retained as well
# as value references. Stopped primitives retain their types and declarations;
# the backend supplies the exact intrinsic set whose bodies it replaces.

law kr_filter:
  for book: List<&2, KDef>
  for +live: List<&2, String>
  List<&2, KDef>

law kr_visit:
  for +book: List<&2, KDef>
  for todo: List<&2, String>
  for +seen: List<&2, String>
  for +stops: List<&2, String>
  List<&2, String>

law kr_visit_def:
  for +book: List<&2, KDef>
  for +todo: List<&2, String>
  for +seen: List<&2, String>
  for +stops: List<&2, String>
  for +d: KDef
  List<&2, String>

law kr_resolve:
  for +book: List<&2, KDef>
  for +name: String
  KDef

law kr_resolve_head:
  for +book: List<&2, KDef>
  for +name: String
  for +d: KDef
  KDef

law kr_parent:
  for book: List<&2, KDef>
  for +name: String
  KDef

law kr_dependencies:
  for +d: KDef
  for +stops: List<&2, String>
  for +todo: List<&2, String>
  List<&2, String>

law kr_ctor_refs:
  for ctors: List<&2, KDef>
  for +todo: List<&2, String>
  List<&2, String>

law kr_refs:
  for +t: KTerm
  for +todo: List<&2, String>
  List<&2, String>

law kr_refs_list:
  for terms: List<&2, KTerm>
  for +todo: List<&2, String>
  List<&2, String>

law kr_push:
  for +name: String
  for +names: List<&2, String>
  List<&2, String>

@unsafe
def reach_book(
  +book: List<&2, KDef>,
  +roots: List<&2, String>,
  +stops: List<&2, String>,
) -> List<&2, KDef>:
  kr_filter(book, kr_visit(book, roots, Nil{}, stops))

@unsafe
def kr_filter(book, live):
  match book:
    case Nil{}: Nil{}
    case Con{+d, +rest}: kc(List<&2, KDef>, has_name(live, dn(d)), u => Con{d, kr_filter(rest, live)}, u => kr_filter(rest, live))

@unsafe
def kr_visit(book, todo, seen, stops):
  match todo:
    case Nil{}: seen
    case Con{+name, +rest}: kc(List<&2, String>, has_name(seen, name), u => kr_visit(book, rest, seen, stops), u => kr_visit_def(book, rest, Con{name, seen}, stops, kr_resolve(book, name)))

@unsafe
def kr_visit_def(book, todo, seen, stops, d):
  kc(List<&2, String>, String.eq(dk(d), "Absent"), u => kr_visit(book, todo, seen, stops), u => kr_visit(book, kr_dependencies(d, stops, todo), Con{dn(d), seen}, stops))

@unsafe
def kr_resolve(book, name):
  kr_resolve_head(book, name, lookup(book, name))

@unsafe
def kr_resolve_head(book, name, d):
  kc(KDef, String.eq(dk(d), "Absent"), u => kr_parent(book, name), u => d)

@unsafe
def kr_parent(book, name):
  match book:
    case Nil{}: missing()
    case Con{+d, +rest}: kc(KDef, String.eq(dk(d), "ADT") && Bool.not(String.eq(dk(lookup(dc(d), name)), "Absent")), u => d, u => kr_parent(rest, name))

@unsafe
def kr_dependencies(d, stops, todo):
  List.append(&2, String, kr_refs(dt(d), kr_ctor_refs(dc(d), kc(List<&2, String>, has_name(stops, dn(d)), u => Nil{}, u => kr_refs(dv(d), Nil{})))), todo)

@unsafe
def kr_ctor_refs(ctors, todo):
  match ctors:
    case Nil{}: todo
    case Con{d, rest}: kr_refs(dt(d), kr_ctor_refs(rest, todo))

@unsafe
def kr_refs(t, todo):
  kr_refs_list(ks(t), kc(List<&2, String>, String.eq(tg(t), "Ref") || String.eq(tg(t), "ADT") || String.eq(tg(t), "Ctr") || String.eq(tg(t), "Mat"), u => kr_push(nm(t), todo), u => todo))

@unsafe
def kr_refs_list(terms, todo):
  match terms:
    case Nil{}: todo
    case Con{h, rest}: kr_refs(h, kr_refs_list(rest, todo))

@unsafe
def kr_push(name, names):
  kc(List<&2, String>, has_name(names, name), u => names, u => Con{name, names})
