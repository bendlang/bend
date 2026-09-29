# Surface expressions preserve proof terms, quantities, and annotations.
# Internal Literal nodes are expanded before checking; Error is never accepted.
type FParsed is Data:
  FParsed{+term: KTerm, +rest: FInput}

law f_args:
  for +ts: FInput
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

law f_arg_next:
  for +p: FParsed
  for +end: String
  for +acc: List<&2, KTerm>
  FParsed

law f_expr:
  for +ts: FInput
  for +min: U32
  FParsed

law f_atom:
  for +ts: FInput
  FParsed

law f_kind_token:
  for +ts: FInput
  U32

law f_kind_wrap:
  for +p: FParsed
  FParsed

law f_mark:
  for +p: FParsed
  for +q: U32
  FParsed

law f_grade:
  for +ts: FInput
  FParsed

law f_all:
  for +ts: FInput
  for +exi: Bool
  FParsed

law f_all_domain:
  for +name: String
  for +id: U32
  for +q: U32
  for +exi: Bool
  for +p: FParsed
  FParsed

law f_all_body:
  for +name: String
  for +id: U32
  for +q: U32
  for +exi: Bool
  for +a: KTerm
  for +p: FParsed
  FParsed

law f_group:
  for +p: FParsed
  FParsed

law f_tuple:
  for +n: KTerm
  for +p: FParsed
  FParsed

law f_list_nodes:
  for +xs: List<&2, KTerm>
  KTerm

law f_brace:
  for +ts: FInput
  FParsed

law f_brace_left:
  for +p: FParsed
  FParsed

law f_equation:
  for +a: KTerm
  for +neg: Bool
  for +opBegin: U32
  for +opEnd: U32
  for +p: FParsed
  FParsed

law f_equation_type:
  for +a: KTerm
  for +b: KTerm
  for +neg: Bool
  for +opBegin: U32
  for +opEnd: U32
  for +p: FParsed
  FParsed

law f_grow:
  for +p: FParsed
  for +min: U32
  FParsed

law f_grow_args:
  for +n: KTerm
  for +op: String
  for +min: U32
  for +p: FParsed
  FParsed

law f_operator:
  for +s: String
  String

law f_matcher:
  for +ts: FInput
  FParsed

law f_matcher_head:
  for +p: FParsed
  FParsed

law f_matcher_arm:
  for +name: String
  for +p: FParsed
  FParsed

law f_matcher_tail:
  for +name: String
  for +n: KTerm
  for +p: FParsed
  FParsed

@unsafe
def f_pn(
  +p: FParsed,
) -> KTerm:
  match p:
    case FParsed{n, ts}:
      n

@unsafe
def f_pr(
  +p: FParsed,
) -> FInput:
  match p:
    case FParsed{n, ts}:
      ts

@unsafe
def f_atid(
  +ts: FInput,
) -> U32:
  U32.add(U32.mul(f_line(ts), 65536), f_col(ts))

@unsafe
def f_err(
  +ts: FInput,
  +msg: String,
) -> FParsed:
  FParsed{kt("Error", "line " ++ U32.show(f_line(ts)) ++ ":" ++ U32.show(f_col(ts)) ++ ": " ++ msg ++ "; got " ++ f_tx(ts), 0, 0, Nil{}), f_empty(ts)}

@unsafe
def f_expect(
  +p: FParsed,
  +s: String,
) -> FParsed:
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_context_stop(n), u => FParsed{n, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), s), u => FParsed{n, f_tl(ts)}, u => fpe_error(ts, "expected " ++ s, "'" ++ s ++ "'")))

@unsafe
def f_app(
  +f: KTerm,
  +xs: List<&2, KTerm>,
) -> KTerm:
  match xs:
    case Nil{}:
      f
    case Con{x, xt}:
      f_app(kt("App", "", 0, 1, [f, x]), xt)

@unsafe
def f_args_base(
  +ts: FInput,
  +end: String,
  +acc: List<&2, KTerm>,
) -> FParsed:
  +spaced = f_space(ts)
  f_choose(FParsed, f_eq(f_tx(spaced), ";"), u => fpe_error(spaced, f_choose(String, f_eq(end, "]"), u => "expected term; a list does not use semicolon separators", u => "expected term; arguments do not use semicolon separators"), "a term"), u => f_choose(FParsed, f_eq(f_tx(spaced), end), u => FParsed{kt("Args", "", 0, 1, List.reverse(&2, KTerm, acc)), f_tl(spaced)}, u => f_arg_next(f_expr(spaced, 0), end, acc)))

@unsafe
def f_arg_next(p, end, acc):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_context_stop(n), u => FParsed{n, ts}, u => f_args(f_choose(FInput, f_eq(f_tx(ts), ","), u => f_tl(ts), u => ts), end, Con{n, acc}))

@unsafe
def f_expr(ts, min):
  f_grow(f_atom(f_skip(ts)), min)

@unsafe
def f_atom_base(
  +ts: FInput,
) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "++"), u => f_atom_base(f_prepend(FToken{"+", f_line(ts), f_col(ts), 0, f_begin(ts), f_cursor_add(f_begin(ts), 1), f_previous_end(ts)}, f_prepend(FToken{"+", f_line(ts), U32.add(f_col(ts), 1), 0, f_cursor_add(f_begin(ts), 1), f_end(ts), f_cursor_add(f_begin(ts), 1)}, f_tl(ts)))),
    u => f_choose(FParsed, f_eq(f_tx(ts), "("), u => f_group(f_body(f_tl(ts))),
    u => f_choose(FParsed, f_eq(f_tx(ts), "{"), u => f_brace(f_tl(ts)),
    u => f_choose(FParsed, f_eq(f_tx(ts), "["), u => f_array(f_tl(ts)),
    u => f_choose(FParsed, f_eq(f_tx(ts), "@"), u => f_all(f_tl(ts), False{}),
    u => f_choose(FParsed, f_eq(f_tx(ts), "&"), u => f_grade(f_tl(ts)),
    u => f_choose(FParsed, f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind"), u => f_mark(f_expr(f_tl(ts), 12), 2),
    u => f_choose(FParsed, f_eq(f_tx(ts), "?"), u => FParsed{kt("Hol", f_tx(f_tl(ts)), 0, 0, Nil{}), f_tl(f_tl(ts))},
    u => f_choose(FParsed, f_eq(f_tx(ts), "\\"), u => f_choose(FParsed, f_eq(f_tx(f_tl(ts)), "{"), u => f_matcher(f_tl(f_tl(ts))), u => fpe_error(f_tl(ts), "expected {", "'{'")),
    u => f_choose(FParsed, f_eq(f_tx(ts), "Type") || f_eq(f_tx(ts), "Data"), u => FParsed{kt("Typ", "", 0, 0, [kt("Qua", "", 0, f_choose(U32, f_eq(f_tx(ts), "Data"), u => 2, u => 1), Nil{})]), f_tl(ts)},
    u => f_choose(FParsed, f_eq(f_tx(ts), "Quant"), u => FParsed{kt("Qnt", "", 0, 0, Nil{}), f_tl(ts)},
    u => f_choose(FParsed, f_eq(f_tx(ts), "Kind"), u => f_kind_wrap(f_expect(f_expr(f_tl(f_tl(ts)), 0), ")")),
    u => f_choose(FParsed, U32.is_eq(f_kind_token(ts), 2), u => FParsed{kt("Literal", f_tx(ts), 0, 1, Nil{}), f_tl(ts)},
    u => f_choose(FParsed, U32.is_eq(f_kind_token(ts), 1) && Bool.not(f_reserved(f_tx(ts))), u => f_choose(FParsed, f_ascii_alpha(f_head(f_tx(ts))) || f_ascii_digit(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_'), u => f_atom_name(ts), u => fpe_error(ts, "expected term", "a term")),
    u => f_choose(FParsed, f_reserved(f_tx(ts)), u => f_choose(FParsed, f_eq(f_tx(ts), "return"), u => fpe_word(ts, "return outside do", "a do-block heading this return"), u => fpe_error(ts, "expected term", "a term")), u => fpe_error(ts, "expected term", "a term"))))))))))))))))

# A constructor brace belongs to the raw name only when lexically adjacent.
# General term growth must not absorb the next independent braced value.
law f_atom_name:
  for +ts: FInput
  FParsed

@unsafe
def f_atom_name(ts):
  f_choose(FParsed, Char.is_digit(f_head(f_tx(ts))),
    u => f_choose(FParsed, String.ends_with(f_tx(ts), "n") && f_eq(f_tx(f_tl(ts)), "+") && U32.is_eq(f_line(ts), f_line(f_tl(ts))) && U32.is_eq(f_col(f_tl(ts)), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts))))),
      u => f_atom_nat_start(ts, f_literal(f_tx(ts))),
      u => FParsed{kt("Literal", f_tx(ts), f_atid(ts), 1, Nil{}), f_tl(ts)}),
    u => f_choose(FParsed, Bool.not(f_valid_name(f_tx(ts))),
      u => fpe_error(ts, "invalid name", "a name (words joined by dots, got '" ++ f_tx(ts) ++ "')"),
    u => f_choose(FParsed, f_eq(f_tx(f_tl(ts)), "{") && U32.is_eq(f_line(ts), f_line(f_tl(ts))) && U32.is_eq(f_col(f_tl(ts)), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts))))),
      u => f_atom_constructor(f_tx(ts), f_atid(ts), f_args(f_tl(f_tl(ts)), "}", Nil{})),
      u => f_context_atom_name(ts))))

# Immediate n+ is part of the numeric atom, at every surrounding precedence.
law f_atom_nat_start:
  for +ts: FInput
  for +lit: KTerm
  FParsed
law f_atom_nat_plus:
  for +lit: KTerm
  for +p: FParsed
  FParsed

@unsafe
def f_atom_nat_start(ts, lit):
  f_choose(FParsed, f_eq(tg(lit), "Error"), u => FParsed{lit, f_empty(ts)}, u => f_atom_nat_plus(lit, f_expr(f_tl(f_tl(ts)), 0)))

@unsafe
def f_atom_nat_plus(lit, p):
  match p:
    case FParsed{+rhs, rest}:
      f_choose(FParsed, f_eq(tg(rhs), "Error"), u => FParsed{rhs, rest}, u => FParsed{f_nat_extend(lit, rhs), rest})

law f_atom_constructor:
  for +name: String
  for +id: U32
  for +p: FParsed
  FParsed

@unsafe
def f_atom_constructor(name, id, p):
  match p:
    case FParsed{+args, ts}:
      f_choose(FParsed, f_context_stop(args), u => FParsed{args, ts}, u => f_context_constructor(kt("Ctr", name, id, 1, ks(args)), ts))

@unsafe
def f_kind_token(ts):
  f_kind(ts)

@unsafe
def f_kind_wrap(p):
  match p:
    case FParsed{n, ts}:
      FParsed{kt("Typ", "", 0, 0, [n]), ts}

@unsafe
def f_mark(p, q):
  f_context_mark(p)

@unsafe
def f_grade(ts):
  f_choose(FParsed, f_eq(f_tx(ts), "0") || f_eq(f_tx(ts), "1") || f_eq(f_tx(ts), "2"), u => FParsed{kt("Qua", "", 0, f_choose(U32, f_eq(f_tx(ts), "0"), u => 0, u => f_choose(U32, f_eq(f_tx(ts), "1"), u => 1, u => 2)), Nil{}), f_tl(ts)}, u => f_all(ts, True{}))

@unsafe
def f_quant(
  +ts: FInput,
) -> U32:
  f_choose(U32, f_eq(f_tx(ts), "-") || f_eq(f_tx(ts), "~"), u => 0, u => f_choose(U32, f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind"), u => 2, u => 1))

@unsafe
def f_unmark(
  +ts: FInput,
) -> FInput:
  f_choose(FInput, U32.is_eq(f_quant(ts), 1), u => ts, u => f_tl(ts))

@unsafe
def f_all(ts, exi):
  f_choose(FParsed, Bool.not(f_valid_name(f_tx(f_unmark(ts)))) || f_eq(f_tx(ts), "~"), u => fpe_name_error(f_choose(FInput, f_eq(f_tx(ts), "~"), u => ts, u => f_unmark(ts))), u => f_all_domain(f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts), exi, f_expect(f_expr_after(f_expect(FParsed{atom("Absent"), f_tl(f_unmark(ts))}, ":"), 1), "->")))

@unsafe
def f_all_domain(name, id, q, exi, p):
  match p:
    case FParsed{a, ts}:
      f_choose(FParsed, f_eq(tg(a), "Error"), u => FParsed{a, ts}, u => f_context_all(name, q, exi, a, ts))

@unsafe
def f_all_body(name, id, q, exi, a, p):
  match p:
    case FParsed{b, ts}:
      FParsed{f_choose(KTerm, f_context_stop(b), u => b, u => f_choose(KTerm, exi, u => f_app(kt("Ref", "Exists", 0, 1, Nil{}), [a, k_lam(name, id, q, [b], 0, 0, False{})]), u => kt("All", name, id, q, [a, b]))), ts}

@unsafe
def f_group(p):
  match p:
    case FParsed{term, rest}:
      f_choose(FParsed, f_context_stop(term), u => p, u => f_choose(FParsed, String.eq(f_tx(rest), ",") && Bool.not(String.eq(tg(term), "Local") || String.eq(tg(term), "Parallel") || String.eq(tg(term), "Match")), u => f_group_existing(p), u => f_context_group_done(f_context_flat(p, Nil{}))))

@unsafe
def f_group_existing(+p: FParsed) -> FParsed:
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), ","), u => f_tuple(n, f_group(f_body(f_tl(ts)))), u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_group_namespace(n, f_expect(f_expr(f_tl(ts), 0), ")")), u => f_expect(FParsed{n, ts}, ")")))

@unsafe
def f_group_ann(
  +n: KTerm,
  +p: FParsed,
) -> FParsed:
  match p:
    case FParsed{ty, ts}:
      FParsed{f_choose(KTerm, f_eq(tg(n), "Error"), u => n, u => f_choose(KTerm, f_eq(tg(ty), "Error"), u => ty, u => kt("Ann", "", 0, 1, [n, ty]))), ts}

@unsafe
def f_tuple(n, p):
  match p:
    case FParsed{m, ts}:
      FParsed{f_choose(KTerm, f_context_stop(m), u => m, u => kt("Ctr", "Tuple", 0, 1, [n, m])), ts}

@unsafe
def f_list(
  +p: FParsed,
) -> FParsed:
  match p:
    case FParsed{+n, ts}:
      FParsed{f_choose(KTerm, f_eq(tg(n), "Error"), u => n, u => f_list_nodes(ks(n))), ts}

@unsafe
def f_list_nodes(xs):
  match xs:
    case Nil{}:
      kt("Ctr", "Nil", 0, 1, Nil{})
    case Con{x, xt}:
      kt("Ctr", "Con", 0, 1, [x, f_list_nodes(xt)])

@unsafe
def f_brace(ts):
  f_choose(FParsed, f_eq(f_tx(ts), "=="), u => f_expect(FParsed{kt("Rfl", "", 0, 1, Nil{}), f_tl(ts)}, "}"), u => f_brace_left(f_expr(ts, 0)))

@unsafe
def f_brace_left(p):
  match p:
    case FParsed{+a, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), "==") || f_eq(f_tx(ts), "!="), u => f_equation(a, f_eq(f_tx(ts), "!="), f_begin(ts), f_end(ts), f_expect(f_expr(f_tl(ts), 0), ":")), u => f_group_ann(a, f_expect(f_expr_after(f_expect(FParsed{a, ts}, ":"), 0), "}")))

@unsafe
def f_equation(a, neg, opBegin, opEnd, p):
  match p:
    case FParsed{b, ts}:
      f_choose(FParsed, f_eq(tg(b), "Error"), u => FParsed{b, ts}, u => f_equation_type(a, b, neg, opBegin, opEnd, f_expect(f_expr(ts, 0), "}")))

@unsafe
def f_equation_type(a, b, neg, opBegin, opEnd, p):
  match p:
    case FParsed{ty, ts}:
      FParsed{f_choose(KTerm, neg, u => kt("All", "_", 0, 1, [kt("Eql", "", 0, 1, [a, b, ty]), kt_span("FGlobal", "Empty", 0, 1, Nil{}, opBegin, opEnd)]), u => kt("Eql", "", 0, 1, [a, b, ty])), ts}

@unsafe
def f_prec(
  +s: String,
) -> U32:
  f_choose(U32, f_eq(s, "=>") || f_eq(s, "->"), u => 1,
    u => f_choose(U32, f_eq(s, "&") || f_eq(s, "|"), u => 2,
    u => f_choose(U32, f_eq(s, "||"), u => 3,
    u => f_choose(U32, f_eq(s, "&&"), u => 4,
    u => f_choose(U32, f_eq(s, "<") || f_eq(s, ">op") || f_eq(s, "<=") || f_eq(s, ">="), u => 5,
    u => f_choose(U32, f_eq(s, "<>") || f_eq(s, "++") || f_eq(s, "<&>"), u => 6,
    u => f_choose(U32, f_eq(s, ".|."), u => 7,
    u => f_choose(U32, f_eq(s, ".^."), u => 8,
    u => f_choose(U32, f_eq(s, ".&."), u => 9,
    u => f_choose(U32, f_eq(s, "<<") || f_eq(s, ">>op"), u => 10,
    u => f_choose(U32, f_eq(s, "+") || f_eq(s, "-"), u => 11,
    u => f_choose(U32, f_eq(s, "*") || f_eq(s, "/") || f_eq(s, "%"), u => 12, u => 0))))))))))))

@unsafe
def f_grow_base(
  +p: FParsed,
  +min: U32,
) -> FParsed:
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts},
        u => f_choose(FParsed, f_eq(f_tx(ts), "("),
          u => f_context_call(n, ts, min),
        u => f_choose(FParsed, (U32.is_gt(f_prec(f_tx(ts)), min) || (f_eq(f_tx(ts), "<") && U32.is_eq(ke(n), f_begin(ts)))) && Bool.not((f_eq(f_tx(ts), "%") || f_eq(f_tx(ts), "-")) && U32.is_eq(f_col(f_tl(ts)), U32.add(f_col(ts), 1)) && Char.is_alpha(f_head(f_tx(f_tl(ts))))) && Bool.not(f_eq(f_tx(ts), ">")) && Bool.not(f_eq(f_tx(ts), ">>") && (f_eq(f_tx(f_tl(ts)), ")") || f_eq(f_tx(f_tl(ts)), "}") || f_eq(f_tx(f_tl(ts)), ",") || f_eq(f_tx(f_tl(ts)), ":") || f_eq(f_tx(f_tl(ts)), ">") || f_eq(f_tx(f_tl(ts)), "\n") || f_eq(f_tx(f_tl(ts)), "->") || f_eq(f_tx(f_tl(ts)), "<eof>") || f_eq(f_tx(f_tl(ts)), "]"))),
          u => f_binary_start(n, ts, min),
          u => FParsed{n, ts})))

# The first angle argument is parsed at comparison precedence. Compound type
# operators need explicit parentheses; later comma arguments retain full terms.
@unsafe
def f_family_first(+ts: FInput) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ">") || f_eq(f_tx(ts), ">>"), u => f_args(ts, ">", Nil{}), u => f_family_first_done(f_expr(ts, 5)))

@unsafe
def f_family_first_done(+p: FParsed) -> FParsed:
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts},
        u => f_choose(FParsed, f_eq(f_tx(f_space(ts)), "&") || f_eq(f_tx(f_space(ts)), "|") || f_eq(f_tx(f_space(ts)), "->"),
          u => fpe_error(f_space(ts), "a compound type argument takes parentheses", "'>' or ',' (a compound type argument takes parens: F<(A & B)>)"),
          u => f_family_range(f_arg_next(FParsed{n, ts}, ">", Nil{}), f_begin(f_space(ts)))))

@unsafe
def f_grow_args(n, op, min, p):
  match p:
    case FParsed{+args, ts}:
      f_choose(FParsed, f_context_stop(args), u => FParsed{args, ts}, u => f_grow(FParsed{f_choose(KTerm, f_eq(op, "("), u => f_app_span(n, ks(args), kb(n), f_previous_end(ts)), u => kt_span("ADT", nm(n), ix(n), qt(n), ks(args), kb(n), f_choose(U32, U32.is_gt(ke(args), 0), u => ke(args), u => f_previous_end(ts)))), ts}, min))

@unsafe
def f_binary_plain(a, op, b, opBegin, opEnd, begin, end):
  f_choose(KTerm, f_eq(op, "=>"), u => f_lambda_valid(a, b, opEnd),
    u => f_choose(KTerm, f_eq(op, "->"), u => kt_span("All", "_", ix(a), 1, [a, b], begin, end),
    u => f_choose(KTerm, f_eq(op, "<>"), u => kt_span("Ctr", "Con", 0, 1, [a, b], begin, end),
    u => f_choose(KTerm, f_eq(op, "<&>"), u => kt_span("Min", "", 0, 1, [a, b], begin, end),
    u => f_app_span(kt_span("Ref", f_operator(op), 0, 1, Nil{}, f_choose(U32, f_eq(op, "&") || f_eq(op, "|"), u => begin, u => opBegin), f_choose(U32, f_eq(op, "&") || f_eq(op, "|"), u => end, u => opEnd)), [a, b], begin, end)))))

@unsafe
def f_operator(s):
  f_choose(String, f_eq(s, "&"), u => "Pair", u => f_choose(String, f_eq(s, "|"), u => "Or", u => f_choose(String, f_eq(s, "++"), u => "String.append", u => f_choose(String, f_eq(s, "||"), u => "Bool.or", u => f_choose(String, f_eq(s, "&&"), u => "Bool.and", u => f_choose(String, f_eq(s, "+"), u => ".add", u => f_choose(String, f_eq(s, "-"), u => ".sub", u => f_choose(String, f_eq(s, "*"), u => ".mul", u => f_choose(String, f_eq(s, "/"), u => ".div", u => f_choose(String, f_eq(s, "%"), u => ".mod", u => f_choose(String, f_eq(s, "<"), u => ".is_lt", u => f_choose(String, f_eq(s, ">op"), u => ".is_gt", u => f_choose(String, f_eq(s, "<="), u => ".is_le", u => f_choose(String, f_eq(s, ">="), u => ".is_ge", u => f_choose(String, f_eq(s, "<<"), u => ".shln", u => f_choose(String, f_eq(s, ">>op"), u => ".shrn", u => f_choose(String, f_eq(s, ".&."), u => ".and", u => f_choose(String, f_eq(s, ".|."), u => ".or", u => f_choose(String, f_eq(s, ".^."), u => ".xor", u => s)))))))))))))))))))

@unsafe
def f_matcher(ts):
  f_choose(FParsed, f_eq(f_tx(ts), "}"), u => FParsed{kt("Efq", "", 0, 1, Nil{}), f_tl(ts)}, u => f_matcher_head(f_expr(ts, 0)))

@unsafe
def f_matcher_head(p):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, (f_eq(tg(n), "Ref") || f_eq(tg(n), "FName") || f_eq(tg(n), "Var")) && f_eq(f_tx(ts), ":"), u => f_matcher_arm(f_context_type_name(nm(n), ts), f_expr(f_tl(ts), 0)), u => f_expect(FParsed{n, ts}, "}"))

@unsafe
def f_matcher_arm(name, p):
  match p:
    case FParsed{n, ts}:
      f_matcher_tail(name, n, f_matcher(f_skip(ts)))

@unsafe
def f_matcher_tail(name, n, p):
  match p:
    case FParsed{m, ts}:
      FParsed{f_choose(KTerm, f_context_stop(n), u => n, u => f_choose(KTerm, f_context_stop(m), u => m, u => kt("Mat", name, 0, 1, [n, m]))), ts}


@unsafe
def f_atom_raw(+ts: FInput) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "do"), u => f_do_start(f_tl(ts), f_begin(ts)), u => f_choose(FParsed, f_eq(f_tx(ts), "%"), u => f_rewrite(f_tl(ts), f_begin(ts)), u => f_atom_base(ts)))

@unsafe
def f_args(ts, end, acc):
  f_args_existing(ts, end, acc)

@unsafe
def f_args_existing(+ts: FInput, +end: String, +acc: List<&2,KTerm>) -> FParsed:
  f_choose(FParsed, f_eq(end, ">") && f_eq(f_tx(ts), ">>"), u => FParsed{kt("Args", "", 0, 1, List.reverse(&2, KTerm, acc)), f_prepend(FToken{">", f_line(ts), U32.add(f_col(ts), 1), 0, f_cursor_add(f_begin(ts), 1), f_end(ts), f_cursor_add(f_begin(ts), 1)}, f_tl(ts))}, u => f_args_base(ts, end, acc))

@unsafe
def f_grow(p, min):
  f_context_grow(p, min)

@unsafe
def f_grow_existing(+p: FParsed, +min: U32) -> FParsed:
  match p:
    case FParsed{n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), "\n") && U32.is_gt(f_prec(f_tx(f_skip(ts))), 0) && Bool.not((f_eq(f_tx(f_skip(ts)), "%") || f_eq(f_tx(f_skip(ts)), "-")) && U32.is_eq(f_col(f_tl(f_skip(ts))), U32.add(f_col(f_skip(ts)), 1))), u => f_grow_base(FParsed{n, f_skip(ts)}, min), u => f_choose(FParsed, f_eq(f_tx(ts), "!") && f_eq(f_tx(f_tl(ts)), "(") && U32.is_eq(f_line(ts), f_line(f_tl(ts))) && U32.is_eq(f_col(f_tl(ts)), U32.add(f_col(ts), 1)), u => f_bang(f_context_call_head(n), ts, min), u => f_choose(FParsed, f_eq(f_tx(ts), "["), u => f_index(n, f_expect(f_expr(f_tl(ts), 0), "]"), min), u => f_grow_base(FParsed{n, ts}, min))))

law f_binary_plain:
  for +a: KTerm
  for +op: String
  for +b: KTerm
  for +opBegin: U32
  for +opEnd: U32
  for +begin: U32
  for +end: U32
  KTerm

law f_rhs:
  for +ts: FInput
  for +op: String
  for +min: U32
  FParsed

@unsafe
def f_rhs(ts, op, min):
  f_choose(FParsed, f_eq(op, "=>"), u => f_body(ts), u => f_expr(ts, min))


# P5-011 rejection-only rendering; raw errors retain their legacy text for fallback.
law fpe_error:
  for +ts: FInput
  for +legacy: String
  for +expected: String
  FParsed
law fpe_render:
  for +source: String
  for +error: KTerm
  String
law fpe_seek:
  for +source: String
  for +rest: String
  for +line: U32
  for +column: U32
  for +offset: U32
  for +error: KTerm
  String
law fpe_here:
  for +source: String
  for +rest: String
  for +offset: U32
  for +error: KTerm
  String
law fpe_message:
  for +source: String
  for +offset: U32
  for +end: U32
  for +error: KTerm
  for +observed: String
  String
@unsafe
def fpe_error(ts, legacy, expected):
  fpe_legacy(ts, nm(f_pn(f_err(ts, legacy))), expected)

# Keep an already formatted fallback unchanged; expectation is explicit input.
law fpe_legacy:
  for +ts: FInput
  for +legacy: String
  for +expected: String
  FParsed

@unsafe
def fpe_legacy(ts, legacy, expected):
  FParsed{kt("Error", legacy, f_line(ts), f_col(ts), [kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseToken", f_tx(ts), 0, 0, Nil{})]), f_context_failure_rest(ts, ts)}

@unsafe
def fpe_render(source, error):
  f_choose(String, String.eq(tg(error), "Absent"), u => "", u => f_choose(String, String.eq(tg(error), "Error") && String.eq(tg(kid(error, 0)), "ParseExpected") && String.eq(tg(kid(error, 1)), "ParseToken"), u => f_choose(String, U32.is_gt(ix(error), 0), u => fpe_seek(source, source, 1, 0, 0, error), u => f_choose(String, f_eq(nm(kid(error, 1)), "<eof>"), u => fpe_eof(source, source, 0, error), u => nm(error))), u => nm(error)))

@unsafe
def fpe_seek(source, rest, line, column, offset, error):
  f_choose(String, U32.is_eq(line, ix(error)) && U32.is_eq(column, qt(error)), u => fpe_here(source, rest, offset, error), u => f_choose(String, String.is_empty(rest), u => nm(error), u => f_choose(String, U32.is_eq(Char.to_u32(f_head(rest)), 10), u => fpe_seek(source, f_tail(rest), U32.add(line, 1), 0, U32.add(offset, 1), error), u => fpe_seek(source, f_tail(rest), line, U32.add(column, 1), U32.add(offset, dg_units(f_head(rest))), error))))

@unsafe
def fpe_here(source, rest, offset, error):
  f_choose(String, String.is_empty(rest), u => f_choose(String, String.eq(nm(kid(error, 1)), "<eof>"), u => fpe_observe(source, rest, offset, error, "end of input"), u => nm(error)), u => f_choose(String, Bool.not(U32.is_eq(Char.to_u32(f_head(rest)), Char.to_u32(f_head(nm(kid(error, 1)))))) || U32.is_gt(Char.to_u32(f_head(rest)), 65535) || (U32.is_ge(Char.to_u32(f_head(rest)), 55296) && U32.is_le(Char.to_u32(f_head(rest)), 57343)), u => nm(error), u => fpe_observe(source, rest, offset, error, "'" ++ SCon{f_head(rest), ""} ++ "'")))

@unsafe
def fpe_message(source, offset, end, error, observed):
  "Error:\n- expected : " ++ nm(kid(error, 0)) ++ "\n- observed : " ++ observed ++ "\nLocation:" ++ fpe_snippet(source, offset, end, error)

# A range is explicit producer data; point diagnostics retain their old path.
@unsafe
def fpe_span(+start: FInput, +end: FInput, +legacy: String, +expected: String, +observed: String) -> FParsed:
  FParsed{kt("Error", nm(f_pn(f_err(start, legacy))), f_line(start), f_col(start), [kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseToken", f_tx(start), 0, 0, Nil{}), kt("ParseRange", observed, f_line(end), f_col(end), Nil{})]), f_context_failure_rest(start, end)}

@unsafe
def fpe_word(+ts: FInput, +legacy: String, +expected: String) -> FParsed:
  fpe_span(ts, f_prepend(FToken{"", f_line(ts), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts)))), 0, f_end(ts), f_end(ts), f_end(ts)}, f_empty(ts)), legacy, expected, "")

@unsafe
def fpe_observe(+source: String, +rest: String, +offset: U32, +error: KTerm, +observed: String) -> String:
  f_choose(String, f_eq(tg(kid(error, 2)), "ParseLine"), u => fpe_message(source, offset, offset, error, "'" ++ fpe_line_text(String.lines(source), ix(error)) ++ "'"), u => f_choose(String, f_eq(tg(kid(error, 2)), "ParseRange"), u => fpe_range(source, rest, ix(error), qt(error), offset, offset, error, ""), u => fpe_message(source, offset, offset, error, observed)))

@unsafe
def fpe_range(+source: String, +rest: String, +line: U32, +column: U32, +offset: U32, +start: U32, +error: KTerm, +acc: String) -> String:
  f_choose(String, U32.is_eq(line, ix(kid(error, 2))) && U32.is_eq(column, qt(kid(error, 2))),
    u => fpe_message(source, start, offset, error, f_choose(String, String.is_empty(nm(kid(error, 2))), u => "'" ++ String.reverse(acc) ++ "'", u => nm(kid(error, 2)))),
    u => f_choose(String, String.is_empty(rest), u => nm(error), u => fpe_range(source, f_tail(rest), f_choose(U32, Char.is_eq(f_head(rest), '\n'), u => U32.add(line, 1), u => line), f_choose(U32, Char.is_eq(f_head(rest), '\n'), u => 0, u => U32.add(column, 1)), U32.add(offset, dg_units(f_head(rest))), start, error, SCon{f_head(rest), acc})))

@unsafe
def f_expr_after(+p: FParsed, +min: U32) -> FParsed:
  match p:
    case FParsed{n, ts}: f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_expr(ts, min))

@unsafe
def fpe_eof(+source: String, +rest: String, +offset: U32, +error: KTerm) -> String:
  f_choose(String, String.is_empty(rest), u => fpe_message(source, offset, offset, error, "end of input"), u => fpe_eof(source, f_tail(rest), U32.add(offset, dg_units(f_head(rest))), error))


@unsafe
def fpe_name_error(+ts: FInput) -> FParsed:
  f_choose(FParsed, f_ascii_alpha(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_'),
    u => fpe_word(ts, "invalid name", f_choose(String, f_reserved(f_tx(ts)), u => "a name (got the keyword '" ++ f_tx(ts) ++ "')", u => "a name (words joined by dots, got '" ++ f_tx(ts) ++ "')")),
    u => fpe_error(ts, "expected a name", "a name"))

@unsafe
def f_atom(ts):
  f_context_atom_done(f_atom_existing(ts))

@unsafe
def f_atom_existing(+ts: FInput) -> FParsed:
  f_locate(f_atom_raw(ts), f_begin(ts), f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind") || f_eq(f_tx(ts), "++"), f_eq(f_tx(ts), "@") || (f_eq(f_tx(ts), "&") && Bool.not(f_eq(f_tx(f_tl(ts)), "0") || f_eq(f_tx(f_tl(ts)), "1") || f_eq(f_tx(f_tl(ts)), "2"))) || f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind") || (String.ends_with(f_tx(ts), "n") && f_eq(f_tx(f_tl(ts)), "+")), f_eq(f_tx(ts), "[") || f_eq(f_tx(ts), "(") || f_eq(f_tx(ts), "&") || f_eq(f_tx(ts), "\\"))

@unsafe
def f_locate(+p: FParsed, +begin: U32, +force: Bool, +spaced: Bool, +created: Bool) -> FParsed:
  match p:
    case FParsed{n, ts}:
      +end = f_choose(U32, spaced, u => f_begin(f_space(ts)), u => f_previous_end(ts))
      FParsed{f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_lt(end, begin) || f_context_stop(n) || (U32.is_gt(kb(n), 0) && Bool.not(force)), u => n, u => f_located_term(n, begin, end, created)), ts}

@unsafe
def f_family_range(+p: FParsed, +end: U32) -> FParsed:
  match p:
    case FParsed{n, ts}: FParsed{f_choose(KTerm, f_eq(tg(n), "Error"), u => n, u => k_with_span(n, end, end)), ts}

# Only explicitly desugared list/tuple/existential/matcher trees use this walk.
# Existing child origins are boundaries, so parsed subtrees are never revisited.
@unsafe
def f_located_term(+t: KTerm, +begin: U32, +end: U32, +created: Bool) -> KTerm:
  f_choose(KTerm, created, u => f_span_created(t, begin, end), u => k_with_span(t, begin, end))

@unsafe
def f_span_created(+t: KTerm, +begin: U32, +end: U32) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, oldBegin, oldEnd}:
      f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(oldBegin, 0), u => t,
        u => KTerm{tag, name, id, quant, f_spans_created(kids, begin, end), removed, begin, end})
    case KLambda{name, id, quant, kids, removed, oldBegin, oldEnd, present}:
      f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(oldBegin, 0), u => t,
        u => KLambda{name, id, quant, f_spans_created(kids, begin, end), removed, begin, end, present})
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(literalBegin, 0), u => t, u => k_with_span(t, begin, end))

@unsafe
def f_spans_created(+terms: List<&2,KTerm>, +begin: U32, +end: U32) -> List<&2,KTerm>:
  match terms:
    case Nil{}: Nil{}
    case Con{term, rest}: Con{f_span_created(term, begin, end), f_spans_created(rest, begin, end)}

@unsafe
def f_app_span(+f: KTerm, +xs: List<&2,KTerm>, +begin: U32, +end: U32) -> KTerm:
  match xs:
    case Nil{}: f
    case Con{x, rest}: f_app_span(kt_span("App", "", 0, 1, [f, x], begin, end), rest, begin, end)

# Semantic parser errors carry explicit producer data and an actual term range.
# Their historical fallback remains available to deliberately unlocated callers.
@unsafe
def fpe_message_at(+term: KTerm, +legacy: String, +message: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseMessage", message, 0, 0, Nil{})], kb(term), ke(term))

@unsafe
def fpe_expected_at(+term: KTerm, +legacy: String, +expected: String, +observed: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseObserved", observed, 0, 0, Nil{})], kb(term), ke(term))

@unsafe
def fpe_origin_render(+source: String, +start: U32, +error: KTerm) -> String:
  f_choose(String, U32.is_eq(kb(error), 0), u => fpe_render(source, error),
    u => f_choose(String, U32.is_gt(start, 0) && U32.is_ge(kb(error), start) && U32.is_ge(ke(error), kb(error)) && U32.is_le(U32.sub(ke(error), start), dg_width(source)),
    u => f_choose(String, f_eq(tg(kid(error, 0)), "ParseMessage"),
      u => "Error:\n- message  : " ++ nm(kid(error, 0)) ++ "\nLocation:" ++ fpe_snippet(source, U32.sub(kb(error), start), U32.sub(ke(error), start), error) ++ f_choose(String, f_eq(tg(kid(error, 1)), "ParseNote"), u => "\nNote: " ++ nm(kid(error, 1)), u => ""),
      u => f_choose(String, f_eq(tg(kid(error, 0)), "ParseExpected") && (f_eq(tg(kid(error, 1)), "ParseObserved") || f_eq(tg(kid(error, 1)), "ParseObservedPoint")),
        u => fpe_point_message(source, U32.sub(kb(error), start), U32.sub(ke(error), start), error, f_choose(String, f_eq(tg(kid(error, 1)), "ParseObservedPoint"), u => fpe_point_observed(source, U32.sub(kb(error), start)), u => nm(kid(error, 1)))), u => fpe_render(source, error))),
    u => fpe_render(source, error)))

@unsafe
def fpe_finish_indexed(+start: U32, +source: String, +raw: FRawResult) -> FResult:
  match raw:
    case FRawResult{book, error, imports}: FResult{book, fpe_origin_render(source, start, error), imports}

@unsafe
def fpe_message_note_at(+term: KTerm, +legacy: String, +message: String, +note: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseMessage", message, 0, 0, Nil{}), kt("ParseNote", note, 0, 0, Nil{})], kb(term), ke(term))


# Failure payloads request an original line or exact UTF16 cursor observation.
@unsafe
def fpe_line(+ts: FInput, +legacy: String, +expected: String) -> KTerm:
  kt("Error", legacy, f_line(ts), f_col(ts), [kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseToken", f_tx(ts), 0, 0, Nil{}), atom("ParseLine")])

@unsafe
def fpe_line_text(+lines: List<&2,String>, +line: U32) -> String:
  match lines:
    case Nil{}: ""
    case Con{text, rest}: f_choose(String, U32.is_le(line, 1), u => String.trim(text), u => fpe_line_text(rest, U32.sub(line, 1)))

@unsafe
def fpe_point_at(+term: KTerm, +legacy: String, +expected: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseExpected", expected, 0, 0, Nil{}), atom("ParseObservedPoint")], kb(term), ke(term))

@unsafe
def fpe_point_observed(+source: String, +offset: U32) -> String:
  match source:
    case SNil{}: "end of input"
    case SCon{c, rest}:
      f_choose(String, U32.is_lt(offset, dg_units(c)),
        u => f_choose(String, U32.is_le(Char.to_u32(c), 65535), u => "'" ++ SCon{c, ""} ++ "'", u => ""),
        u => fpe_point_observed(rest, U32.sub(offset, dg_units(c))))

@unsafe
def fpe_snippet(+source: String, +begin: U32, +end: U32, +error: KTerm) -> String:
  f_choose(String, f_eq(tg(kid(error, 2)), "ParseLine") || f_eq(tg(kid(error, 3)), "ParseRaw"),
    u => dg_snippet(DSpan{source, begin, end}),
    u => dg_module_snippet(DSpan{source, begin, end}))

# UTF16 surrogate halves cannot be manufactured as Bend Unicode scalar chars.
# Keep the producer's legacy diagnostic on that boundary instead of crashing.
@unsafe
def fpe_point_message(+source: String, +begin: U32, +end: U32, +error: KTerm, +observed: String) -> String:
  f_choose(String, f_eq(tg(kid(error, 1)), "ParseObservedPoint") && String.is_empty(observed),
    u => nm(error), u => fpe_message(source, begin, end, error, observed))
