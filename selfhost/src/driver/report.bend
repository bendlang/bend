# Transitive promise reporting follows type, constructor-field and body refs.
# Caller supplies the main module's own declaration names in source order.
law dr_bad_names:
  for +book: List<&2,KDef>
  for names: List<&2,String>
  List<&2,String>

law dr_relies:
  for +book: List<&2,KDef>
  for todo: List<&2,String>
  for +seen: List<&2,String>
  Bool

law dr_relies_def:
  for +book: List<&2,KDef>
  for +todo: List<&2,String>
  for +seen: List<&2,String>
  for +d: KDef
  Bool

law dr_verdict:
  for +names: List<&2,String>
  String

law dr_count:
  for names: List<&2,String>
  U32

law dr_lines:
  for names: List<&2,String>
  String

@unsafe
def driver_report(
  +book: List<&2,KDef>,
  +names: List<&2,String>,
) -> String:
  dr_verdict(dr_bad_names(book_cached(book, norm_max_book(book)), names))

@unsafe
def dr_bad_names(book, names):
  match names:
    case Nil{}: Nil{}
    case Con{+name, +rest}:
      kc(List<&2,String>, dr_relies(book, [name], Nil{}),
        u => Con{name, dr_bad_names(book, rest)}, u => dr_bad_names(book, rest))

@unsafe
def dr_relies(book, todo, seen):
  match todo:
    case Nil{}: False{}
    case Con{+name, +rest}:
      kc(Bool, has_name(seen, name),
        u => dr_relies(book, rest, seen),
        u => dr_relies_def(book, rest, Con{name, seen}, kr_resolve(book, name)))

@unsafe
def dr_relies_def(book, todo, seen, d):
  kc(Bool, du(d) || (String.eq(tg(dv(d)), "Foreign") && Bool.not(db(d))),
    u => True{},
    u => dr_relies(book, kr_dependencies(d, Nil{}, todo), seen))

@unsafe
def dr_verdict(names):
  match names:
    case Nil{}: "All terms check.\n"
    case Con{+name, +rest}:
      "All terms check, but " ++ U32.show(dr_count(names)) ++
      kc(String, U32.is_eq(dr_count(names), 1), u => " def relies", u => " defs rely") ++
      " on unsafe or foreign code:\n" ++ dr_lines(names)

@unsafe
def dr_count(names):
  match names:
    case Nil{}: 0
    case Con{+name, +rest}: U32.add(1, dr_count(rest))

@unsafe
def dr_lines(names):
  match names:
    case Nil{}: ""
    case Con{+name, +rest}: "- " ++ name ++ "\n" ++ dr_lines(rest)
