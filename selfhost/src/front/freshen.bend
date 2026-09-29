# Alpha-renaming assigns globally unique binder IDs after graph assembly.
type FFresh is Data:
  FFresh{+term: KTerm, next: U32}

type FFreshDefs is Data:
  FFreshDefs{+defs: List<&2, KDef>, next: U32}

law f_fresh_term:
  for +t: KTerm
  for +env: List<&2, KTerm>
  for +next: U32
  FFresh

law f_rename_var:
  for +t: KTerm
  for +env: List<&2, KTerm>
  KTerm

law f_fresh_result_end:
  for +r: FFreshDefs
  for +err: String
  for +imports: List<&2, KTerm>
  FResult

@unsafe
def f_fresh_term(t, env, next):
  f_fresh_stack(t, env, next)

@unsafe
def f_rename_var(t, env):
  match env:
    case Nil{}:
      t
    case Con{+m, ms}:
      f_choose(KTerm, U32.is_eq(ix(t), ix(m)), u => kt_span("Var", nm(t), ix(kid(m, 0)), qt(t), Nil{}, kb(t), ke(t)), u => f_rename_var(t, ms))

@unsafe
def f_fresh_defs(
  +ds: List<&2,KDef>,
  +next: U32,
) -> FFreshDefs:
  f_fresh_book_stack(ds, next)

@unsafe
def f_fresh_result(
  +r: FResult,
) -> FResult:
  match r:
    case FResult{book, err, imports}:
      f_fresh_result_end(f_fresh_defs(book, 1), err, imports)

@unsafe
def f_fresh_result_end(r, err, imports):
  match r:
    case FFreshDefs{book, next}:
      FResult{book, err, imports}

