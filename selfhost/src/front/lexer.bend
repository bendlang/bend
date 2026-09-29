# Tokenization is implemented in Bend, retaining source f_line and column.
type FToken is Data:
  FToken{+text: String, f_line: U32, f_col: U32, f_kind: U32, begin: U32, end: U32, previousEnd: U32}

type FScanned is Data:
  FScanned{+word: String, +rest: String, size: U32}

law f_three:
  for +s: String
  String

law f_triple_op:
  for +s: String
  Bool

law f_symbol_text:
  for +s: String
  for +c: U32
  for +acc: List<&2, FToken>
  String

law f_ascii_char_eq:
  for +a: Char
  for +b: Char
  Bool

law f_ascii_alpha:
  for +c: Char
  Bool

law f_ascii_digit:
  for +c: Char
  Bool

law f_ascii_space:
  for +c: Char
  Bool

law f_ascii_ident_code:
  for +code: U32
  Bool

law f_ascii_space_code:
  for +code: U32
  Bool

@unsafe
def f_choose(
  -A: Type,
  +b: Bool,
  yes: Unit -> A,
  no: Unit -> A,
) -> A:
  match b:
    case True{}:
      yes(Unit{})
    case False{}:
      no(Unit{})

@unsafe
def f_eq(
  +a: String,
  +b: String,
) -> Bool:
  String.eq(a, b)

@unsafe
def f_raw_tx(
  +ts: List<&2, FToken>,
) -> String:
  match ts:
    case Nil{}:
      "<eof>"
    case Con{FToken{t, l, c, k, begin, end, previousEnd}, rest}:
      t

@unsafe
def f_raw_tl(
  +ts: List<&2, FToken>,
) -> List<&2, FToken>:
  match ts:
    case Nil{}:
      Nil{}
    case Con{t, rest}:
      rest

@unsafe
def f_raw_line(
  +ts: List<&2, FToken>,
) -> U32:
  match ts:
    case Nil{}:
      0
    case Con{FToken{t, l, c, k, begin, end, previousEnd}, rest}:
      l

@unsafe
def f_raw_col(
  +ts: List<&2, FToken>,
) -> U32:
  match ts:
    case Nil{}:
      0
    case Con{FToken{t, l, c, k, begin, end, previousEnd}, rest}:
      c

@unsafe
def f_raw_kind(
  +ts: List<&2, FToken>,
) -> U32:
  match ts:
    case Nil{}:
      0
    case Con{FToken{t, l, c, k, begin, end, previousEnd}, rest}:
      k

@unsafe
def f_raw_skip(
  +ts: List<&2, FToken>,
) -> List<&2, FToken>:
  f_choose(List<&2, FToken>, Bool.or(f_eq(f_raw_tx(ts), "\n"), f_eq(f_raw_tx(ts), ";")),
    u => f_raw_skip(f_raw_tl(ts)), u => ts)

@unsafe
def f_head(
  +s: String,
) -> Char:
  match s:
    case SNil{}:
      '\0'
    case SCon{h, t}:
      h

@unsafe
def f_tail(
  +s: String,
) -> String:
  match s:
    case SNil{}:
      ""
    case SCon{h, t}:
      t

@unsafe
def f_ident(
  +c: Char,
) -> Bool:
  f_ascii_ident_code(Char.to_u32(c))

@unsafe
def f_scan_word(
  +s: String,
  +acc: String,
  +n: U32,
) -> FScanned:
  f_choose(FScanned, f_choose(Bool, f_ident(f_head(s)), u => True{}, u => (f_ascii_char_eq(f_head(s), '+') || f_ascii_char_eq(f_head(s), '-')) && (f_ascii_char_eq(f_head(acc), 'e') || f_ascii_char_eq(f_head(acc), 'E')) && f_ascii_digit(f_head(f_tail(s)))),
    u => f_scan_word(f_tail(s), SCon{f_head(s), acc}, U32.add(n, 1)),
    u => FScanned{String.reverse(acc), s, n})

@unsafe
def f_scan_quote(
  +s: String,
  +quote: Char,
  +acc: String,
  +n: U32,
) -> FScanned:
  f_choose(FScanned, String.is_empty(s),
    u => FScanned{"", "", 0},
    u => f_choose(FScanned, f_ascii_char_eq(f_head(s), quote),
      u => FScanned{String.reverse(SCon{quote, acc}), f_tail(s), U32.add(n, 1)},
      u => f_choose(FScanned, f_ascii_char_eq(f_head(s), '\\'),
        u => f_scan_quote(f_tail(f_tail(s)), quote, SCon{f_head(f_tail(s)), SCon{'\\', acc}}, U32.add(n, 2)),
        u => f_scan_quote(f_tail(s), quote, SCon{f_head(s), acc}, U32.add(n, 1)))))

@unsafe
def f_two(
  +s: String,
) -> String:
  SCon{f_head(s), SCon{f_head(f_tail(s)), ""}}

@unsafe
def f_pair_op(
  +s: String,
) -> Bool:
  f_eq(s, "->") || f_eq(s, "=>") || f_eq(s, "<-") || f_eq(s, "++") || f_eq(s, "<>") || f_eq(s, "==") || f_eq(s, "!=") || f_eq(s, "<=") || f_eq(s, ">=") || f_eq(s, "&&") || f_eq(s, "||") || f_eq(s, "<<") || f_eq(s, ">>")

# Zero disables cursor metadata and preserves the legacy token list.
@unsafe
def f_cursor_add(+offset: U32, +size: U32) -> U32:
  f_choose(U32, U32.is_eq(offset, 0), u => 0, u => U32.add(offset, size))

@unsafe
def f_raw_begin(+ts: List<&2,FToken>) -> U32:
  match ts:
    case Nil{}: 0
    case Con{FToken{text, line, column, kind, begin, end, previousEnd}, rest}: begin

@unsafe
def f_raw_end(+ts: List<&2,FToken>) -> U32:
  match ts:
    case Nil{}: 0
    case Con{FToken{text, line, column, kind, begin, end, previousEnd}, rest}: end

@unsafe
def f_raw_previous_end(+ts: List<&2,FToken>) -> U32:
  match ts:
    case Nil{}: 0
    case Con{FToken{text, line, column, kind, begin, end, previousEnd}, rest}: previousEnd

@unsafe
def f_lex_scanned(
  +sc: FScanned, +l: U32, +c: U32, +d: U32, +k: U32,
  +acc: List<&2,FToken>, +offset: U32, +previous: U32,
) -> List<&2,FToken>:
  match sc:
    case FScanned{word, rest, size}:
      +end = f_cursor_add(offset, f_choose(U32, U32.is_eq(offset, 0), u => 0, u => f_choose(U32, U32.is_eq(k, 1), u => size, u => dg_width(word))))
      f_choose(List<&2,FToken>, U32.is_eq(size, 0),
        u => List.reverse(&2, FToken, Con{FToken{"unterminated string", l, c, 3, offset, offset, previous}, acc}),
        u => f_choose(List<&2,FToken>, U32.is_eq(k, 2),
          u => f_lex_quote_end(word, rest, l, c, d, Con{FToken{word, l, c, k, offset, end, previous}, acc}, end),
          u => f_lex_cursor(rest, l, U32.add(c, size), d, Con{FToken{word, l, c, k, offset, end, previous}, acc}, end, end)))

# Preserve legacy physical columns while indexed cursors count UTF16 units.
@unsafe
def f_lex_quote_end(
  +word: String, +rest: String, +line: U32, +column: U32, +depth: U32,
  +tokens: List<&2,FToken>, +end: U32,
) -> List<&2,FToken>:
  match word:
    case SNil{}: f_lex_cursor(rest, line, column, depth, tokens, end, end)
    case SCon{head, tail}: f_choose(List<&2,FToken>, Char.is_eq(head, '\n'), u => f_lex_quote_end(tail, rest, U32.add(line, 1), 0, depth, tokens, end), u => f_lex_quote_end(tail, rest, line, U32.add(column, 1), depth, tokens, end))

@unsafe
def f_lex_symbol(
  +s: String, +l: U32, +c: U32, +d: U32,
  +acc: List<&2,FToken>, +offset: U32, +previous: U32,
) -> List<&2,FToken>:
  f_choose(List<&2,FToken>, f_pair_op(f_two(s)) && Bool.not(f_eq(f_two(s), "++") && String.ends_with(f_raw_tx(acc), "n") && U32.is_eq(c, U32.add(f_raw_col(acc), U32.from_nat(String.length(f_raw_tx(acc)))))),
    u => f_lex_cursor(f_tail(f_tail(s)), l, U32.add(c, 2), d, Con{FToken{f_choose(String, f_eq(f_two(s), ">>") && U32.is_gt(c, U32.add(f_raw_col(acc), U32.from_nat(String.length(f_raw_tx(acc))))), u => ">>op", u => f_two(s)), l, c, 0, offset, f_cursor_add(offset, 2), previous}, acc}, f_cursor_add(offset, 2), f_cursor_add(offset, 2)),
    u => f_lex_cursor(f_tail(s), l, U32.add(c, 1),
      f_choose(U32, f_ascii_char_eq(f_head(s), '(') || f_ascii_char_eq(f_head(s), '[') || f_ascii_char_eq(f_head(s), '{'),
        u => U32.add(d, 1),
        u => f_choose(U32, f_ascii_char_eq(f_head(s), ')') || f_ascii_char_eq(f_head(s), ']') || f_ascii_char_eq(f_head(s), '}'), u => U32.sub(d, 1), u => d)),
      Con{FToken{f_symbol_text(s, c, acc), l, c, 0, offset, f_cursor_add(offset, dg_units(f_head(s))), previous}, acc}, f_cursor_add(offset, dg_units(f_head(s))), f_cursor_add(offset, dg_units(f_head(s)))))

@unsafe
def f_lex_comment(+s: String, +l: U32, +c: U32, +d: U32, +acc: List<&2,FToken>, +offset: U32, +previous: U32) -> List<&2,FToken>:
  f_choose(List<&2,FToken>, String.is_empty(s) || f_ascii_char_eq(f_head(s), '\n'),
    u => f_lex_cursor(s, l, c, d, acc, offset, previous),
    u => f_lex_comment(f_tail(s), l, c, d, acc, f_cursor_add(offset, dg_units(f_head(s))), previous))

@unsafe
def f_lex_cursor(+s: String, +l: U32, +c: U32, +d: U32, +acc: List<&2,FToken>, +offset: U32, +previous: U32) -> List<&2,FToken>:
  f_choose(List<&2,FToken>, String.is_empty(s),
    u => List.reverse(&2, FToken, f_choose(List<&2,FToken>, U32.is_eq(offset, 0), u => acc, u => Con{FToken{"<eof>", 0, 0, 0, offset, offset, previous}, acc})),
    u => f_choose(List<&2,FToken>, f_ascii_char_eq(f_head(s), '\n'),
      u => f_lex_cursor(f_tail(s), U32.add(l, 1), 0, d, f_choose(List<&2,FToken>, U32.is_eq(d, 0), u => Con{FToken{"\n", l, c, 0, offset, f_cursor_add(offset, 1), previous}, acc}, u => acc), f_cursor_add(offset, 1), previous),
      u => f_choose(List<&2,FToken>, f_ascii_space(f_head(s)),
        u => f_lex_cursor(f_tail(s), l, U32.add(c, 1), d, acc, f_cursor_add(offset, dg_units(f_head(s))), previous),
        u => f_choose(List<&2,FToken>, f_ascii_char_eq(f_head(s), '#'),
          u => f_lex_comment(s, l, c, d, acc, offset, previous),
          u => f_choose(List<&2,FToken>, f_ascii_char_eq(f_head(s), '"') || f_ascii_char_eq(f_head(s), '\''),
            u => f_lex_scanned(f_scan_quote(f_tail(s), f_head(s), SCon{f_head(s), ""}, 1), l, c, d, 2, acc, offset, previous),
            u => f_choose(List<&2,FToken>, f_ident(f_head(s)) && Bool.not(f_ascii_char_eq(f_head(s), '.')),
              u => f_lex_scanned(f_scan_word(s, "", 0), l, c, d, 1, acc, offset, previous),
              u => f_choose(List<&2,FToken>, f_triple_op(s),
                u => f_lex_cursor(f_tail(f_tail(f_tail(s))), l, U32.add(c, 3), d, Con{FToken{f_three(s), l, c, 0, offset, f_cursor_add(offset, 3), previous}, acc}, f_cursor_add(offset, 3), f_cursor_add(offset, 3)),
                u => f_choose(List<&2,FToken>, f_ident(f_head(s)),
                  u => f_lex_scanned(f_scan_word(s, "", 0), l, c, d, 1, acc, offset, previous),
                  u => f_lex_symbol(s, l, c, d, acc, offset, previous)))))))))

@unsafe
def f_three(s):
  SCon{f_head(s), SCon{f_head(f_tail(s)), SCon{f_head(f_tail(f_tail(s))), ""}}}

@unsafe
def f_triple_op(s):
  f_eq(f_three(s), ".&.") || f_eq(f_three(s), ".|.") || f_eq(f_three(s), ".^.") || f_eq(f_three(s), "<&>")

@unsafe
def f_symbol_text(s, c, acc):
  f_choose(String, f_ascii_char_eq(f_head(s), '+') && f_ascii_alpha(f_head(f_tail(s))) && Bool.not(String.ends_with(f_raw_tx(acc), "n") && U32.is_eq(U32.add(f_raw_col(acc), U32.from_nat(String.length(f_raw_tx(acc)))), c)),
    u => "+bind", u => f_choose(String, f_ascii_char_eq(f_head(s), '>') && U32.is_gt(c, U32.add(f_raw_col(acc), U32.from_nat(String.length(f_raw_tx(acc))))), u => ">op", u => SCon{f_head(s), ""}))


# Compiler-local ASCII classification. Unsigned subtraction tests a bounded
# ASCII range; setting bit 5 folds uppercase ASCII into lowercase. Other Unicode
# codepoints cannot enter either ASCII range, including isolated surrogates.
# Base Char workers and exported runtime primitive semantics remain unchanged.
@unsafe
def f_ascii_char_eq(a, b):
  U32.is_eq(Char.to_u32(a), Char.to_u32(b))

@unsafe
def f_ascii_alpha(c):
  U32.is_le(U32.sub(U32.or(Char.to_u32(c), 32), 97), 25)

@unsafe
def f_ascii_digit(c):
  U32.is_le(U32.sub(Char.to_u32(c), 48), 9)

@unsafe
def f_ascii_space(c):
  f_ascii_space_code(Char.to_u32(c))

@unsafe
def f_ascii_ident_code(code):
  U32.is_le(U32.sub(U32.or(code, 32), 97), 25) || U32.is_le(U32.sub(code, 48), 9) || U32.is_eq(code, 95) || U32.is_eq(code, 46)

@unsafe
def f_ascii_space_code(code):
  U32.is_eq(code, 32) || U32.is_le(U32.sub(code, 9), 4)

# Header and argument whitespace preserves statement semicolons.
@unsafe
def f_raw_space(
  +ts: List<&2,FToken>,
) -> List<&2,FToken>:
  f_choose(List<&2,FToken>, f_eq(f_raw_tx(ts), "\n"), u => f_raw_space(f_raw_tl(ts)), u => ts)

# Stage18 representation ablation: the shared context is inert.
type FParseContext is Data:
  FParseContext{+scope: FParseScope, +env: List<&2,KTerm>, next: U32}
type FInput is Data:
  FInput{+tokens: List<&2,FToken>, +context: FParseContext}

@unsafe
def f_input(+tokens: List<&2,FToken>) -> FInput:
  FInput{tokens, FParseContext{f_parse_scope_empty(), Nil{}, 0}}

@unsafe
def f_empty(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}: FInput{Nil{}, context}

@unsafe
def f_prepend(+token: FToken, +input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}: FInput{Con{token, tokens}, context}

@unsafe
def f_tx(+input: FInput) -> String:
  match input:
    case FInput{tokens, context}: f_raw_tx(tokens)

@unsafe
def f_line(+input: FInput) -> U32:
  match input:
    case FInput{tokens, context}: f_raw_line(tokens)

@unsafe
def f_col(+input: FInput) -> U32:
  match input:
    case FInput{tokens, context}: f_raw_col(tokens)

@unsafe
def f_kind(+input: FInput) -> U32:
  match input:
    case FInput{tokens, context}: f_raw_kind(tokens)

@unsafe
def f_begin(+input: FInput) -> U32:
  match input:
    case FInput{tokens, context}: f_raw_begin(tokens)

@unsafe
def f_end(+input: FInput) -> U32:
  match input:
    case FInput{tokens, context}: f_raw_end(tokens)

@unsafe
def f_previous_end(+input: FInput) -> U32:
  match input:
    case FInput{tokens, context}: f_raw_previous_end(tokens)

@unsafe
def f_tl(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}:
      match tokens:
        case Nil{}: input
        case Con{token, rest}: FInput{rest, context}

@unsafe
def f_skip(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}:
      f_choose(FInput, f_eq(f_raw_tx(tokens), "\n") || f_eq(f_raw_tx(tokens), ";"),
        u => FInput{f_raw_skip(tokens), context}, u => input)

@unsafe
def f_space(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}:
      f_choose(FInput, f_eq(f_raw_tx(tokens), "\n"),
        u => FInput{f_raw_space(tokens), context}, u => input)
