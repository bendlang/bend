import Base

# Upstream-compatible structured diagnostic formatting, without host rendering.
law dg_snippet_at:
  for +lines: List<&2, String>
  for +at: U32
  for +left: String
  for +length: U32
  String

law dg_snippet_lines:
  for +lines: List<&2, String>
  for +at: U32
  for +end: U32
  for +line: U32
  for +left: String
  for +length: U32
  String

law dg_location_text:
  for +name: String
  for +snippet: String
  String

law dg_render_parts:
  for +book: List<&2, KDef>
  for +expected: DExpr
  for +observed: DExpr
  for +has_observed: Bool
  for +ctx: List<&2, KTerm>
  for +name: String
  for +span: DSpan
  for +note: String
  String

law dg_render_checked:
  for +book: List<&2, KDef>
  for +diagnostic: DDiagnostic
  for +error: String
  String

@unsafe
def dg_units(
  +c: Char,
) -> U32:
  kc(U32, U32.is_gt(Char.to_u32(c), 65535), u => 2, u => 1)

@unsafe
def dg_width(
  +s: String,
) -> U32:
  match s:
    case SNil{}: 0
    case SCon{c, rest}: U32.add(dg_units(c), dg_width(rest))

@unsafe
def dg_line_at(
  +s: String,
  +offset: U32,
  +line: U32,
) -> U32:
  match s:
    case SNil{}: line
    case SCon{c, rest}:
      kc(U32, U32.is_lt(offset, dg_units(c)), u => line, u => dg_line_at(rest, U32.sub(offset, dg_units(c)), kc(U32, Char.is_eq(c, '\n'), u => U32.add(line, 1), u => line)))

@unsafe
def dg_padding(
  +n: U32,
) -> String:
  kc(String, U32.is_eq(n, 0), u => "", u => " " ++ dg_padding(U32.sub(n, 1)))

@unsafe
def dg_lpad(
  +s: String,
  +width: U32,
) -> String:
  dg_padding(kc(U32, U32.is_gt(width, dg_width(s)), u => U32.sub(width, dg_width(s)), u => 0)) ++ s

@unsafe
def dg_rpad(
  +s: String,
  +width: U32,
) -> String:
  s ++ dg_padding(kc(U32, U32.is_gt(width, dg_width(s)), u => U32.sub(width, dg_width(s)), u => 0))

@unsafe
def dg_lines_count(
  +lines: List<&2, String>,
) -> U32:
  match lines:
    case Nil{}: 0
    case Con{h, rest}: U32.add(1, dg_lines_count(rest))

@unsafe
def dg_snippet(
  +span: DSpan,
) -> String:
  match span:
    case DNoSpan{}: ""
    case DSpan{source, begin, end}: dg_snippet_at(String.lines(source), dg_line_at(source, begin, 1), dg_marker_left(source, begin, ""), kc(U32, U32.is_gt(end, begin), u => U32.sub(end, begin), u => 0))

@unsafe
def dg_marker_left(
  +source: String,
  +offset: U32,
  +left: String,
) -> String:
  match source:
    case SNil{}: left
    case SCon{c, rest}:
      kc(String, U32.is_eq(offset, 0), u => left, u => kc(String, U32.is_lt(offset, dg_units(c)), u => left ++ dg_padding(offset), u => dg_marker_left(rest, U32.sub(offset, dg_units(c)), kc(String, Char.is_eq(c, '\n'), u => "", u => left ++ kc(String, Char.is_eq(c, '\t'), u => "\t", u => dg_padding(dg_units(c)))))))

@unsafe
def dg_carets(
  +count: U32,
) -> String:
  kc(String, U32.is_eq(count, 0), u => "", u => "^" ++ dg_carets(U32.sub(count, 1)))

@unsafe
def dg_marker(
  +text: String,
  +width: U32,
  +left: String,
  +length: U32,
) -> String:
  dg_padding(width) ++ " | " ++ left ++ dg_carets(norm_max(1, U32.min(length, kc(U32, U32.is_gt(dg_width(text), dg_width(left)), u => U32.sub(dg_width(text), dg_width(left)), u => 0))))

@unsafe
def dg_snippet_at(lines, at, left, length):
  dg_snippet_lines(lines, at, kc(U32, U32.is_lt(dg_lines_count(lines), U32.add(at, 1)), u => dg_lines_count(lines), u => U32.add(at, 1)), 1, left, length)

@unsafe
def dg_snippet_lines(lines, at, end, line, left, length):
  match lines:
    case Nil{}: ""
    case Con{h, rest}:
      kc(String, U32.is_gt(line, end), u => "", u => kc(String, U32.is_lt(U32.add(line, 1), at), u => "", u => "\n" ++ dg_lpad(U32.show(line), dg_width(U32.show(end))) ++ kc(String, U32.is_eq(line, at), u => ">| " ++ h ++ "\n" ++ dg_marker(h, dg_width(U32.show(end)), left, length), u => " | " ++ h)) ++ dg_snippet_lines(rest, at, end, U32.add(line, 1), left, length))

@unsafe
def dg_scope(
  +ctx: List<&2, KTerm>,
  +env: List<&2, KPName>,
) -> List<&2, KPName>:
  match ctx:
    case Nil{}: env
    case Con{h, rest}: dg_scope(rest, kp_bind(env, h))

@unsafe
def dg_context_width(
  +ctx: List<&2, KTerm>,
) -> U32:
  match ctx:
    case Nil{}: 0
    case Con{h, rest}: norm_max(dg_width(nm(h)), dg_context_width(rest))

@unsafe
def dg_expr(
  +book: List<&2, KDef>,
  +expr: DExpr,
  +env: List<&2, KPName>,
) -> String:
  match expr:
    case DText{text}: text
    case DTerm{term}: kp_go(strong(book, term), 0, env)

@unsafe
def dg_context(
  +book: List<&2, KDef>,
  +ctx: List<&2, KTerm>,
  +env: List<&2, KPName>,
  +width: U32,
) -> String:
  match ctx:
    case Nil{}: ""
    case Con{h, rest}: "\n- " ++ dg_rpad(nm(h), width) ++ " : " ++ dg_expr(book, DTerm{kid(h, 0)}, env) ++ dg_context(book, rest, kp_bind(env, h), width)

@unsafe
def dg_location(
  +name: String,
  +span: DSpan,
) -> String:
  dg_location_text(name, dg_snippet(span))

@unsafe
def dg_location_text(name, snippet):
  kc(String, String.eq(name, "") && String.eq(snippet, ""), u => "", u => "\nLocation:" ++ kc(String, String.eq(name, ""), u => "", u => " " ++ name) ++ snippet)

@unsafe
def dg_render(
  +book: List<&2, KDef>,
  +diagnostic: DDiagnostic,
) -> String:
  match diagnostic:
    case DDiagnostic{expected, observed, has_observed, context, definition, span, note, trail}:
      dg_render_parts(book, expected, observed, has_observed, List.reverse(&2, KTerm, context), definition, span, note)

@unsafe
def dg_render_parts(book, expected, observed, has_observed, ctx, name, span, note):
  "Error:" ++ kc(String, has_observed, u => "\n- expected : " ++ dg_expr(book, expected, dg_scope(ctx, Nil{})) ++ "\n- observed : " ++ dg_expr(book, observed, dg_scope(ctx, Nil{})), u => "\n- message  : " ++ dg_expr(book, expected, dg_scope(ctx, Nil{}))) ++ kc(String, U32.is_eq(terms_len(ctx), 0), u => "", u => "\nContext:" ++ dg_context(book, ctx, Nil{}, dg_context_width(ctx))) ++ dg_location(name, span) ++ kc(String, String.eq(note, ""), u => "", u => "\n" ++ note)

@unsafe
def diagnostic_render(
  +result: DResult,
) -> String:
  match result:
    case DResult{error, book, diagnostic}: kc(String, String.eq(error, ""), u => "", u => dg_render_checked(book, diagnostic, error))

@unsafe
def dg_render_checked(book, diagnostic, error):
  match diagnostic:
    case DDiagnostic{expected, observed, has_observed, context, definition, span, note, trail}:
      kc(String, U32.is_eq(terms_len(trail), 0), u => "Error: " ++ error, u => dg_render(book, diagnostic))

