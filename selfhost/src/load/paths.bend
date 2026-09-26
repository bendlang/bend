# Source-relative foreign file paths and trusted Base declaration metadata.

law f_unquote:
  for +s: String
  String

law f_unquote_chars:
  for +s: String
  String

law f_path_scan:
  for +path: String
  for +acc: String
  for +dir: String
  String

law f_path_terms:
  for +ts: List<&2, KTerm>
  for +dir: String
  List<&2, KTerm>

@unsafe
def f_unquote(s):
  f_unquote_chars(f_tail(s))

@unsafe
def f_unquote_chars(s):
  f_choose(String, String.is_empty(s) || Char.is_eq(f_head(s), '"'), u => "", u => f_choose(String, Char.is_eq(f_head(s), '\\'), u => SCon{Chr{f_escape_code(f_head(f_tail(s)))}, f_unquote_chars(f_tail(f_tail(s)))}, u => SCon{f_head(s), f_unquote_chars(f_tail(s))}))

@unsafe
def f_path_dir(
  +path: String,
) -> String:
  f_path_scan(path, "", "")

@unsafe
def f_path_scan(path, acc, dir):
  f_choose(String, String.is_empty(path), u => dir, u => f_path_scan(f_tail(path), acc ++ SCon{f_head(path), ""}, f_choose(String, Char.is_eq(f_head(path), '/'), u => acc ++ "/", u => dir)))

@unsafe
def f_path_join(
  +dir: String,
  +path: String,
) -> String:
  f_choose(String, Char.is_eq(f_head(path), '/'), u => path, u => dir ++ path)

@unsafe
def f_path_term(
  +t: KTerm,
  +dir: String,
) -> KTerm:
  KTerm{tg(t), f_choose(String, f_eq(tg(t), "Path"), u => f_path_join(dir, nm(t)), u => nm(t)), ix(t), qt(t), f_path_terms(ks(t), dir), rm(t)}

@unsafe
def f_path_terms(ts, dir):
  match ts:
    case Nil{}:
      Nil{}
    case Con{t, rest}:
      Con{f_path_term(t, dir), f_path_terms(rest, dir)}

@unsafe
def f_path_defs(
  +ds: List<&2,KDef>,
  +dir: String,
  +native: Bool,
) -> List<&2,KDef>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{+d, rest}:
      Con{KDef{dn(d), dk(d), da(d), dx(d), dt(d), f_choose(KTerm, f_eq(tg(dv(d)), "Foreign"), u => f_path_term(dv(d), dir), u => dv(d)), f_path_defs(dc(d), dir, native), native || db(d), du(d)}, f_path_defs(rest, dir, native)}

@unsafe
def f_path_result(
  +r: FResult,
  +path: String,
  +native: Bool,
) -> FResult:
  match r:
    case FResult{book, err, imports}:
      FResult{f_path_defs(book, f_path_dir(path), native), err, imports}

