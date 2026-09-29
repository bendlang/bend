# Driver queries stay in Bend. The host supplies files and runs emitted programs.
@unsafe
def driver_has_main(
  +book: List<&2, KDef>,
) -> Bool:
  Bool.not(String.eq(tg(dv(lookup(book, "main"))), "Absent"))

@unsafe
def driver_is_io(
  +book: List<&2, KDef>,
) -> Bool:
  j_io_type(book, dt(lookup(book, "main")))

@unsafe
def driver_final(
  +book: List<&2,KDef>,
  +done: List<&2,KDef>,
) -> List<&2,KDef>:
  book_final_fast(book, done)

@unsafe
def driver_interpret(
  +book: List<&2, KDef>,
) -> String:
  +final = driver_final(book, Nil{})
  kp_show(strong(final, dv(lookup(final, "main"))))

@unsafe
def driver_todos(
  +book: List<&2,KDef>,
) -> U32:
  driver_count_todos(driver_final(book, Nil{}))

law driver_count_todos:
  for +book: List<&2,KDef>
  U32

@unsafe
def driver_count_todos(book):
  match book:
    case Nil{}: 0
    case Con{d, rest}:
      U32.add(kc(U32, String.eq(dk(d), "Def") && String.eq(tg(dv(d)), "Absent") && Bool.not(db(d)), u => 1, u => U32.add(driver_holes(dt(d)), driver_holes(dv(d)))), U32.add(driver_count_todos(dc(d)), driver_count_todos(rest)))

law driver_holes:
  for +t: KTerm
  U32

@unsafe
def driver_holes(t):
  U32.add(kc(U32, String.eq(tg(t), "Hol"), u => 1, u => 0), driver_holes_terms(ks(t)))

law driver_holes_terms:
  for +ts: List<&2,KTerm>
  U32

@unsafe
def driver_holes_terms(ts):
  match ts:
    case Nil{}: 0
    case Con{t, rest}: U32.add(driver_holes(t), driver_holes_terms(rest))

# Exact pinned compiler OWNED datatype set. User definitions remain valid for
# pure checking/normalization but cannot use the runtime's intrinsic layouts.
law driver_owned_names:
  for +book: List<&2,KDef>
  for +names: List<&2,String>
  String

law driver_owned_name:
  for +book: List<&2,KDef>
  for +name: String
  Bool

@unsafe
def driver_emit_owned(
  +book: List<&2,KDef>,
) -> String:
  driver_owned_names(book, ["IO", "Sigma", "String", "Word.Con", "IO.OP", "Result", "Maybe", "Bool", "Unit", "Nat", "U32", "F32", "Char", "Array"])

@unsafe
def driver_owned_names(book, names):
  match names:
    case Nil{}: ""
    case Con{name, rest}:
      kc(String, driver_owned_name(book, name),
        u => name ++ " is a name the compiler encodes itself: name yours apart",
        u => driver_owned_names(book, rest))

@unsafe
def driver_owned_name(book, name):
  match book:
    case Nil{}: False{}
    case Con{d, rest}:
      (String.eq(dn(d), name) && Bool.not(db(d))) || driver_owned_name(rest, name)

# Program completion follows ordinary and live-instance validation. Legacy
# diagnostic APIs retain their own open-law completion contract.
@unsafe
def check_program_diagnostic(+book: List<&2,KDef>, +validated: List<&2,KDef>, +origins: List<&2,DOrigin>) -> DResult:
  driver_program_checked(book, origins, dg_check_world(book))

@unsafe
def driver_program_checked(+original: List<&2,KDef>, +origins: List<&2,DOrigin>, +checked: DChecking) -> DResult:
  match checked:
    case DChecking{result, diagnostic}:
      kc(DResult, good(result),
        u => driver_program_complete(sp_assembled(rw(result)), origins, check_open_message(driver_todos(original))),
        u => dg_finish(ce(result), kw_book(rw(result)), diagnostic, origins))

@unsafe
def driver_program_complete(+book: List<&2,KDef>, +origins: List<&2,DOrigin>, +error: String) -> DResult:
  dg_finish(error, book, dg_no_report("", error), origins)
