# A one-constructor matcher whose entire arm selects a live field is a pure
# projection. Consume the complete constructor telescope: eta-short arms may
# apply a function-valued field to remaining constructor arguments instead.
law j_projection_match:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +ty: KTerm
  String

law j_projection_arm:
  for +t: KTerm
  for +tel: KTerm
  for +slots: List<&2, KTerm>
  for +at: U32
  String

law j_projection_slot:
  for +id: U32
  for +slots: List<&2, KTerm>
  String

law j_projection_code:
  for +name: String
  for +slot: String
  String

@unsafe
def j_projection_worker(
  +book: List<&2, KDef>,
  +t: KTerm,
  +ty: KTerm,
) -> String:
  kc(String, String.eq(tg(j_strip(t)), "Mat"), u => j_projection_match(book, j_strip(t), wnf(book, ty)), u => "")

@unsafe
def j_projection_match(book, t, ty):
  kc(String, String.eq(tg(ty), "All") && Bool.not(U32.is_eq(qt(ty), 0)) && U32.is_eq(j_constructor_count(book, wnf(book, kid(ty, 0))), 1),
    u => j_projection_code(nm(t), j_projection_arm(j_strip(kid(t, 0)), j_specialize(book, dt(j_find_ctor(book, nm(t))), ks(wnf(book, kid(ty, 0)))), Nil{}, 0)), u => "")

@unsafe
def j_projection_arm(t, tel, slots, at):
  kc(String, String.eq(tg(tel), "All"),
    u => kc(String, String.eq(tg(t), "Lam") && Bool.not(U32.is_eq(qt(tel), 0)),
      u => j_projection_arm(j_strip(kid(t, 0)), kid(tel, 1), Con{kt("Slot", "", ix(t), at, Nil{}), slots}, U32.inc(at)), u => ""),
    u => kc(String, String.eq(tg(t), "Var"), u => j_projection_slot(ix(t), slots), u => ""))

@unsafe
def j_projection_slot(id, slots):
  match slots:
    case Nil{}: ""
    case Con{s, rest}: kc(String, U32.is_eq(id, ix(s)), u => U32.show(qt(s)), u => j_projection_slot(id, rest))

@unsafe
def j_projection_code(name, slot):
  kc(String, String.eq(slot, ""), u => "", u => "fn(1,function(a){return project(" ++ j_quote(name) ++ ",a[0]).slice()[" ++ slot ++ "];})")

@unsafe
def j_l_global_worker(
  +book: List<&2, KDef>,
  +d: KDef,
  +t: KTerm,
  +worker: String,
) -> String:
  "G[" ++ j_quote(dn(d)) ++ "]=" ++ j_l_capture_scalar(book, d, kc(String, Bool.not(String.eq(worker, "")), u => worker,
    u => kc(String, (String.eq(tg(j_strip(t)), "Lam") || String.eq(tg(j_strip(t)), "Mat")), u => j_expr(book, Nil{}, t, dt(d), False{}), u => "fn(0,function(){return " ++ j_expr(book, Nil{}, t, dt(d), True{}) ++ ";})"))) ++ ";\n"

@unsafe
def j_l_capture_scalar(+book: List<&2,KDef>, +d: KDef, +code: String) -> String:
  kc(String, j_region_capture_eligible(book, d), u => "scalarCapture(" ++ j_quote(dn(d)) ++ "," ++ code ++ ")", u => code)
