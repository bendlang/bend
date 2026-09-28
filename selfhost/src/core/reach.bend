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
# Foreign sources use CID(name)/FID(name) in their importing namespace, then
# globally, just as the pinned upstream emitter does. Keep spelling resolution
# shared by both backends; each backend renders the resolved names itself.
type KF_Source is Data:
  KF_Source{+parts: List<&2, KTerm>, +error: String}

law kf_scan:
  for +book: List<&2, KDef>
  for +ns: String
  for +source: String
  for +word: Bool
  for +text: String
  for +parts: List<&2, KTerm>
  KF_Source

@unsafe
def kf_unann(+t: KTerm) -> KTerm:
  kc(KTerm, String.eq(tg(t), "Ann"), u => kf_unann(kid(t, 0)), u => t)

@unsafe
def kf_has_path(paths: List<&2, KTerm>, +path: String) -> Bool:
  match paths:
    case Nil{}: False{}
    case Con{h, rest}: String.eq(nm(h), path) || kf_has_path(rest, path)

law kf_namespace_step:
  for rest: List<&2, KDef>
  for +path: String
  for +ns: String
  for +seen: Bool
  for +prefix: String
  KTerm

@unsafe
def kf_namespaces(ds: List<&2, KDef>, +path: String, +ns: String, +seen: Bool) -> KTerm:
  match ds:
    case Nil{}: kt("Namespace", ns, 0, 0, Nil{})
    case Con{+d, +rest}:
      +value = kf_unann(dv(d))
      kc(KTerm, String.eq(tg(value), "Foreign") && kf_has_path(ks(value), path),
        u => kf_namespace_step(rest, path, ns, seen, kc(String, db(d) || String.eq(nm(value), ""), u => "", u => String.take(dn(d), Nat.sub(String.length(dn(d)), String.length(nm(value)))))),
        u => kf_namespaces(rest, path, ns, seen))

@unsafe
def kf_namespace_step(rest, path, ns, seen, prefix):
  kc(KTerm, seen && Bool.not(String.eq(ns, prefix)), u => kt("Error", path ++ " is imported from two namespaces", 0, 0, Nil{}), u => kf_namespaces(rest, path, prefix, True{}))

@unsafe
def kf_namespace(book: List<&2, KDef>, path: String) -> KTerm:
  kf_namespaces(book, path, "", False{})

@unsafe
def kf_word(+c: Char) -> Bool:
  +n = Char.to_u32(c)
  (U32.is_ge(n, 48) && U32.is_le(n, 57)) || (U32.is_ge(n, 65) && U32.is_le(n, 90)) || (U32.is_ge(n, 97) && U32.is_le(n, 122)) || Char.is_eq(c, '_')

@unsafe
def kf_name(source: String, +acc: String) -> String:
  match source:
    case SNil{}: String.reverse(acc)
    case SCon{+h, rest}:
      kc(String, kf_word(h) || Char.is_eq(h, '.') || Char.is_eq(h, '/') || Char.is_eq(h, '~') || Char.is_eq(h, '-'), u => kf_name(rest, SCon{h, acc}), u => String.reverse(acc))

@unsafe
def kf_known(+book: List<&2, KDef>, +prefix: String, +name: String) -> Bool:
  Bool.not(String.eq(dk(kr_resolve(book, name)), "Absent")) || (String.eq(prefix, "FID") && (String.eq(name, "EXIT") || String.eq(name, "ENTER")))

@unsafe
def kf_resolve(+book: List<&2, KDef>, +ns: String, +prefix: String, +name: String) -> String:
  kc(String, kf_known(book, prefix, ns ++ name), u => ns ++ name, u => kc(String, kf_known(book, prefix, name), u => name, u => ""))

@unsafe
def kf_char(+book: List<&2, KDef>, +ns: String, source: String, +text: String, +parts: List<&2, KTerm>) -> KF_Source:
  match source:
    case SNil{}: KF_Source{List.reverse(&2, KTerm, Con{kt("Text", String.reverse(text), 0, 0, Nil{}), parts}), ""}
    case SCon{+h, rest}: kf_scan(book, ns, rest, kf_word(h), SCon{h, text}, parts)

@unsafe
def kf_token(+book: List<&2, KDef>, +ns: String, +source: String, +text: String, +parts: List<&2, KTerm>) -> KF_Source:
  +prefix = String.take(source, 3n)
  +name = kf_name(String.drop(source, 4n), "")
  +rest = String.drop(source, Nat.add(4n, String.length(name)))
  +resolved = kf_resolve(book, ns, prefix, name)
  kc(KF_Source, Bool.not(String.eq(name, "")) && String.starts_with(rest, ")"),
    u => kc(KF_Source, String.eq(resolved, ""),
      u => KF_Source{Nil{}, prefix ++ "(" ++ name ++ ") names no constructor or def"},
      u => kf_scan(book, ns, String.drop(rest, 1n), False{}, "", Con{kt(prefix, resolved, 0, 0, Nil{}), Con{kt("Text", String.reverse(text), 0, 0, Nil{}), parts}})),
    u => kf_char(book, ns, source, text, parts))

@unsafe
def kf_scan(book, ns, source, word, text, parts):
  kc(KF_Source, Bool.not(word) && (String.starts_with(source, "CID(") || String.starts_with(source, "FID(")), u => kf_token(book, ns, source, text, parts), u => kf_char(book, ns, source, text, parts))

@unsafe
def kf_source(+book: List<&2, KDef>, path: String, source: String) -> KF_Source:
  +ns = kf_namespace(book, path)
  kc(KF_Source, String.eq(tg(ns), "Error"), u => KF_Source{Nil{}, nm(ns)}, u => kf_scan(book, nm(ns), source, False{}, "", Nil{}))
