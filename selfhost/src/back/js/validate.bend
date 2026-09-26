import Base

# Build-time entry checks shared by native and JavaScript executable drivers.
# Pure functions and type values belong to the normalizer/term-printer lane.
@unsafe
def j_compile_error(
  +book: List<&2, KDef>,
) -> String:
  kc(String, String.eq(dk(lookup(book, "IO")), "Absent"), u => "a build needs import Base", u => j_main_error(book, lookup(book, "main")))

law j_main_error:
  for +book: List<&2, KDef>
  for +main: KDef
  String

@unsafe
def j_main_error(book, main):
  kc(String, Bool.not(String.eq(dk(main), "Def")) || String.eq(tg(j_strip(dv(main))), "Absent"), u => "no main to run", u => kc(String, j_io_type(book, dt(main)), u => kc(String, String.eq(tg(j_strip(dv(main))), "Foreign"), u => "main must be a filled def: a foreign main cannot anchor IO", u => ""), u => kc(String, j_printable(book, dt(main), Nil{}, 0), u => "", u => "main's type " ++ kp_show(dt(main)) ++ " cannot be printed (a function, a Type, an erased or dependent field)")))

law j_printable:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +seen: List<&2, String>
  for +fuel: U32
  Bool

@unsafe
def j_printable(book, ty, seen, fuel):
  j_printable_head(book, wnf(book, ty), seen, fuel)

law j_printable_head:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +seen: List<&2, String>
  for +fuel: U32
  Bool

@unsafe
def j_printable_head(book, ty, seen, fuel):
  kc(Bool, String.eq(tg(ty), "Eql"), u => True{}, u => kc(Bool, String.eq(tg(ty), "ADT") && Bool.not(String.eq(nm(ty), "IO.OP")) && String.eq(dk(lookup(book, nm(ty))), "ADT"), u => j_printable_adt(book, ty, seen, fuel), u => False{}))

law j_printable_adt:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +seen: List<&2, String>
  for +fuel: U32
  Bool

@unsafe
def j_printable_adt(book, ty, seen, fuel):
  kc(Bool, String.contains("|U32|F32|Nat|Char|String|", "|" ++ nm(ty) ++ "|") || has_name(seen, kp_show(ty)), u => True{}, u => kc(Bool, String.eq(nm(ty), "Array"), u => j_printable(book, kid(ty, 0), seen, fuel), u => j_printable_ctors(book, dc(lookup(book, nm(ty))), ks(ty), Con{kp_show(ty), seen}, fuel)))

law j_printable_ctors:
  for +book: List<&2, KDef>
  for +ctors: List<&2, KDef>
  for +params: List<&2, KTerm>
  for +seen: List<&2, String>
  for +fuel: U32
  Bool

@unsafe
def j_printable_ctors(book, ctors, params, seen, fuel):
  match ctors:
    case Nil{}:
      True{}
    case Con{d, rest}:
      j_printable_fields(book, j_specialize(book, dt(d), params), seen, fuel) && j_printable_ctors(book, rest, params, seen, fuel)

law j_printable_fields:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +seen: List<&2, String>
  for +fuel: U32
  Bool

@unsafe
def j_printable_fields(book, ty, seen, fuel):
  kc(Bool, String.eq(tg(ty), "All"), u => Bool.not(U32.is_eq(qt(ty), 0)) && j_printable(book, kid(ty, 0), seen, fuel) && j_printable_fields(book, kid(ty, 1), seen, fuel), u => True{})

# Layout validation follows executable references, not type dependencies or
# erased expressions. An Array representation is needed at elimination,
# construction, and element-sensitive native operations.
law j_layout_error:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  for +roots: List<&2, String>
  for +stops: List<&2, String>
  String

@unsafe
def j_layout_error(book, defs, roots, stops):
  kc(String, j_layout_visit(book_context(book), book_cached(defs, 0), roots, Nil{}, stops), u => "an open Array element type", u => "")

law j_layout_visit:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  for +todo: List<&2, String>
  for +seen: List<&2, String>
  for +stops: List<&2, String>
  Bool

@unsafe
def j_layout_visit(book, defs, todo, seen, stops):
  match todo:
    case Nil{}: False{}
    case Con{h, rest}:
      kc(Bool, String.eq(h, "$layout.open-array"), u => True{}, u => kc(Bool, has_name(seen, h) || has_name(stops, h), u => j_layout_visit(book, defs, rest, seen, stops), u => j_layout_def(book, defs, lookup(defs, h), rest, Con{h, seen}, stops)))

law j_layout_def:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  for +d: KDef
  for +todo: List<&2, String>
  for +seen: List<&2, String>
  for +stops: List<&2, String>
  Bool

@unsafe
def j_layout_def(book, defs, d, todo, seen, stops):
  j_layout_visit(book, defs, kc(List<&2, String>, String.eq(dk(d), "Def") && U32.is_eq(dx(d), 0), u => j_layout_term(book, Nil{}, dv(d), dt(d), todo), u => todo), seen, stops)

@unsafe
def j_layout_mark(
  +bad: Bool,
  +todo: List<&2, String>,
) -> List<&2, String>:
  kc(List<&2, String>, bad, u => Con{"$layout.open-array", todo}, u => todo)

@unsafe
def j_layout_open(
  +book: List<&2, KDef>,
  +ty: KTerm,
) -> Bool:
  j_layout_open_head(book, wnf(book, ty))

law j_layout_open_head:
  for +book: List<&2, KDef>
  for +ty: KTerm
  Bool

@unsafe
def j_layout_open_head(book, ty):
  kc(Bool, String.eq(tg(ty), "ADT") && String.eq(nm(ty), "Array"), u => Bool.not(String.eq(tg(wnf(book, kid(ty, 0))), "ADT")), u => False{})

law j_layout_term:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_term(book, env, t, ty, todo):
  j_layout_kind(book, env, t, ty, todo, tg(t))

law j_layout_kind:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +todo: List<&2, String>
  for +key: String
  List<&2, String>

@unsafe
def j_layout_kind(book, env, t, ty, todo, key):
  kc(List<&2, String>, String.eq(key, "Ann"), u => j_layout_term(book, env, kid(t, 0), kid(t, 1), todo), u =>
  kc(List<&2, String>, String.eq(key, "Ref"), u => j_layout_mark(j_layout_array_intrinsic(book, t), Con{nm(t), todo}), u =>
  kc(List<&2, String>, String.eq(key, "App"), u => j_layout_app(book, env, t, wnf(book, j_type(book, env, kid(t, 0))), todo), u =>
  kc(List<&2, String>, String.eq(key, "Lam"), u => j_layout_lam(book, env, t, wnf(book, ty), todo), u =>
  kc(List<&2, String>, String.eq(key, "Mat"), u => j_layout_match(book, env, t, wnf(book, ty), todo), u =>
  kc(List<&2, String>, String.eq(key, "Ctr"), u => kc(List<&2, String>, Bool.not(String.eq(j_literal_typed(book, t, ty), "")), u => todo, u => j_layout_mark(j_layout_open(book, ty), j_layout_fields(book, env, ks(t), j_specialize(book, dt(j_find_ctor(book, nm(t))), ks(wnf(book, ty))), todo))), u =>
  kc(List<&2, String>, String.eq(key, "Let"), u => j_layout_let(book, env, ks(t), ty, todo), u =>
  kc(List<&2, String>, String.eq(key, "Rwt"), u => j_layout_term(book, env, kid(t, 2), ty, todo), u => todo))))))))

law j_layout_lam:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_lam(book, env, t, ty, todo):
  j_layout_term(book, Con{kt("Env", "", ix(t), 0, Con{kid(ty, 0), Nil{}}), env}, kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), todo)

law j_layout_match:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_match(book, env, t, ty, todo):
  j_layout_mark(j_layout_open(book, kid(ty, 0)), j_layout_term(book, env, kid(t, 0), j_arm_type(book, ty, nm(t)), kc(List<&2, String>, U32.is_eq(j_constructor_count(book, wnf(book, kid(ty, 0))), 1), u => todo, u => j_layout_term(book, env, kid(t, 1), ty, todo))))

law j_layout_app:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +fty: KTerm
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_app(book, env, t, fty, todo):
  j_layout_mark(j_layout_intrinsic(book, j_strip(kid(t, 0)), kid(t, 1)), j_layout_function(book, env, kid(t, 0), fty, kc(List<&2, String>, String.eq(tg(fty), "All") && U32.is_eq(qt(fty), 0), u => todo, u => j_layout_term(book, env, kid(t, 1), kid(fty, 0), todo))))

law j_layout_function:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_function(book, env, t, ty, todo):
  kc(List<&2, String>, String.eq(tg(j_strip(t)), "Ref"), u => Con{nm(j_strip(t)), todo}, u => j_layout_term(book, env, t, ty, todo))

law j_layout_array_intrinsic:
  for +book: List<&2, KDef>
  for +f: KTerm
  Bool

@unsafe
def j_layout_array_intrinsic(book, f):
  String.eq(tg(f), "Ref") && db(lookup(book, nm(f))) && String.contains("|Array.new|Array.set|Array.get|Array.swap|Array.size|", "|" ++ nm(f) ++ "|")

law j_layout_intrinsic:
  for +book: List<&2, KDef>
  for +f: KTerm
  for +element: KTerm
  Bool

@unsafe
def j_layout_intrinsic(book, f, element):
  kc(Bool, j_layout_array_intrinsic(book, f), u => Bool.not(String.eq(tg(wnf(book, j_strip(element))), "ADT")), u => False{})

law j_layout_fields:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +tel: KTerm
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_fields(book, env, args, tel, todo):
  match args:
    case Nil{}: todo
    case Con{h, rest}:
      j_layout_fields(book, env, rest, j_app_type(tel, h), kc(List<&2, String>, String.eq(tg(tel), "All") && U32.is_eq(qt(tel), 0), u => todo, u => j_layout_term(book, env, h, kid(tel, 0), todo)))

law j_layout_let:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  for +ty: KTerm
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_let(book, env, xs, ty, todo):
  j_layout_bindings(book, env, xs, j_layout_term(book, j_context(book, env, xs), j_body(xs), ty, todo))

law j_layout_bindings:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  for +todo: List<&2, String>
  List<&2, String>

@unsafe
def j_layout_bindings(book, env, xs, todo):
  match xs:
    case Nil{}: todo
    case Con{h, Nil{}}: todo
    case Con{h, rest}:
      j_layout_bindings(book, env, rest, kc(List<&2, String>, U32.is_eq(qt(h), 0), u => todo, u => j_layout_term(book, env, kid(h, 0), j_type(book, env, kid(h, 0)), todo)))
