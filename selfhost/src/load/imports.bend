# Module header paths are token sequences, including slash and dot tokens.

law f_import_path:
  for +ts: List<&2, FToken>
  for +start: List<&2, FToken>
  for +path: String
  for +book: List<&2,KDef>
  for +imports: List<&2, KTerm>
  FRawResult

@unsafe
def f_import_path(ts, start, path, book, imports):
  f_choose(FRawResult, f_eq(f_tx(ts), "as"), u => f_import_alias(ts, start, path, book, imports), u => f_choose(FRawResult, f_eq(f_tx(ts), "\n") || f_eq(f_tx(ts), "<eof>"), u => f_choose(FRawResult, f_eq(path, "Base"), u => f_tops(ts, book, Con{kt("Import", path, f_line(start), f_col(start), Nil{}), imports}, False{}), u => f_result(book, kt("Error", "a module import requires as followed by an alias", 0, 0, Nil{}), imports)), u => f_import_path(f_tl(ts), start, path ++ f_tx(ts), book, imports)))


# Local imports use the pinned plain-segment grammar before path resolution.
# Hub/package resolution is unchanged and remains outside this host's scope.
@unsafe
def f_import_valid(+path: String) -> Bool:
  f_choose(Bool, Bool.not(String.starts_with(path, "./") || String.starts_with(path, "../") || String.starts_with(path, "/")) && (String.starts_with(path, "0x") || String.contains(path, "@")), u => True{}, u => f_import_local(f_strip_bend(f_choose(String, String.starts_with(path, "./"), u => f_drop_chars(path, 2), u => path))))

@unsafe
def f_import_local(+path: String) -> Bool:
  f_choose(Bool, String.starts_with(path, "/"), u => f_import_segments(f_tail(path), True{}), u => f_import_parents(path))

@unsafe
def f_import_parents(+path: String) -> Bool:
  f_choose(Bool, String.starts_with(path, "../"), u => f_import_parents(f_drop_chars(path, 3)), u => f_import_segments(path, True{}))

@unsafe
def f_import_segments(+path: String, +head: Bool) -> Bool:
  match path:
    case SNil{}: Bool.not(head)
    case SCon{c, rest}:
      f_choose(Bool, Char.is_eq(c, '/'), u => Bool.not(head) && f_import_segments(rest, True{}), u => (f_ascii_alpha(c) || Char.is_eq(c, '_') || (Bool.not(head) && (Char.is_digit(c) || Char.is_eq(c, '-')))) && f_import_segments(rest, False{}))

# Import nodes carry the original path token's line and code-point column.
# Convert this location to UTF-16 only when presenting an IO failure.
@unsafe
def f_import_offset(+source: String, +line: U32, +column: U32, +offset: U32) -> U32:
  match source:
    case SNil{}: offset
    case SCon{c, rest}:
      f_choose(U32, U32.is_gt(line, 1), u => f_import_offset(rest, f_choose(U32, Char.is_eq(c, '\n'), u => U32.sub(line, 1), u => line), column, U32.add(offset, dg_units(c))), u => f_choose(U32, U32.is_eq(column, 0), u => offset, u => f_import_offset(rest, line, U32.sub(column, 1), U32.add(offset, dg_units(c)))))

@unsafe
def f_import_failure(+source: String, +im: KTerm, +path: String, +cycle: Bool) -> String:
  +offset = f_import_offset(source, ix(im), qt(im), 0)
  "Error:\n- message  : " ++ f_choose(String, cycle, u => "an import cycle through ", u => "no such file: ") ++ path ++ "\nLocation:" ++ dg_snippet(DSpan{source, offset, offset})
