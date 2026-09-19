import Base

# A checked, executable model of a six-constructor fragment of Bend's core.
# It reduces weak heads and compares terms up to beta, let, definition
# unfolding and eta. Fuel makes cycles inconclusive. It does not parse or
# type-check Bend source; bend.lean models the full calculus.
#
#   bun bend2/main.ts demos/bend_core/main.bend
#   bun bend2/main.ts demos/bend_core/PROOF.bend
#   bun demos/bend_core/parity.ts

# Binder numbers are de Bruijn indices. Substitution follows bend.lean;
# unlike bend.ts, it does not memoize variables.
type Term is Data:
  TVar{+i: Nat}
  TLam{body: Term}
  TApp{fn: Term, arg: Term}
  TLet{value: Term, body: Term}
  TRef{+name: Nat}
  TAnn{term: Term, ty: Term}

type Def is Data:
  Def{+name: Nat, +arity: Nat, body: Term}

type WHResult is Data:
  Exhausted{}
  Value{term: Term}

# Fuel exhaustion is inconclusive, never inequality.
type EqResult is Data:
  Equal{}
  Different{}
  EqExhausted{}

type EqPair is Data:
  EqPair{a: Term, b: Term}

# Computed normal forms move through fields so every match stays checked.
type EqState is Data:
  EqCheck{a: Term, b: Term, rest: List<&2, EqPair>}
  EqResults{a: WHResult, b: WHResult, rest: List<&2, EqPair>}
  EqValues{a: Term, b: Term, rest: List<&2, EqPair>}
  EqAgree{same: Bool, rest: List<&2, EqPair>}

# ponytail: linear book lookup keeps this slice small; use indexed storage if definition count makes it slow.
type State is Data:
  Go{term: Term, args: List<&2, Term>}
  Seek{+name: Nat, args: List<&2, Term>, rest: List<&2, Def>}
  Found{+name: Nat, +arity: Nat, body: Term, args: List<&2, Term>}
  Stop{term: Term}

def shift_var(+i: Nat, +d: Nat, c: Cmp) -> Term:
  match c:
    case LT{}:
      TVar{i}
    case _:
      TVar{1n+i}

def shift(t: Term, +d: Nat) -> Term:
  match t:
    case TVar{i}:
      shift_var(i, d, Nat.cmp(i, d))
    case TLam{body}:
      TLam{shift(body, 1n+d)}
    case TApp{fn, arg}:
      TApp{shift(fn, d), shift(arg, d)}
    case TLet{value, body}:
      TLet{shift(value, d), shift(body, 1n+d)}
    case TRef{name}:
      TRef{name}
    case TAnn{term, ty}:
      TAnn{shift(term, d), shift(ty, d)}

def subst_var(+i: Nat, +d: Nat, w: Term, c: Cmp) -> Term:
  match c:
    case LT{}:
      TVar{i}
    case EQ{}:
      w
    case GT{}:
      TVar{Nat.sub(i, 1n)}

def subst(t: Term, +d: Nat, +w: Term) -> Term:
  match t:
    case TVar{i}:
      subst_var(i, d, w, Nat.cmp(i, d))
    case TLam{body}:
      TLam{subst(body, 1n+d, shift(w, 0n))}
    case TApp{fn, arg}:
      TApp{subst(fn, d, w), subst(arg, d, w)}
    case TLet{value, body}:
      TLet{subst(value, d, w), subst(body, 1n+d, shift(w, 0n))}
    case TRef{name}:
      TRef{name}
    case TAnn{term, ty}:
      TAnn{subst(term, d, w), subst(ty, d, w)}

def apply_args(args: List<&2, Term>, head: Term) -> Term:
  match args:
    case Nil{}:
      head
    case Con{arg, rest}:
      apply_args(rest, TApp{head, arg})

def seek_next(+name: Nat, args: List<&2, Term>,
              +arity: Nat, body: Term,
              rest: List<&2, Def>, same: Bool) -> State:
  match same:
    case True{}:
      Found{name, arity, body, args}
    case False{}:
      Seek{name, args, rest}

def found_next(+name: Nat, +arity: Nat, body: Term, args: List<&2, Term>, enough: Bool) -> State:
  match enough:
    case True{}:
      Go{body, args}
    case False{}:
      Stop{apply_args(args, TRef{name})}

# Every transition consumes one unit of fuel, including reference lookup.
# The book is kept intact while Seek walks a separate copy.
def go(fuel: Nat, +book: List<&2, Def>, state: State) -> WHResult:
  match fuel:
    case 0n:
      Exhausted{}
    case 1n+left:
      match state:
        case Go{term, args}:
          match term:
            case TApp{fn, arg}:
              go(left, book, Go{fn, Con{arg, args}})
            case TLet{value, body}:
              go(left, book, Go{subst(body, 0n, value), args})
            case TAnn{term, ty}:
              go(left, book, Go{term, args})
            case TLam{body}:
              match args:
                case Con{arg, rest}:
                  go(left, book, Go{subst(body, 0n, arg), rest})
                case Nil{}:
                  Value{TLam{body}}
            case TRef{name}:
              go(left, book, Seek{name, args, book})
            case TVar{i}:
              Value{apply_args(args, TVar{i})}
        case Seek{name, args, rest}:
          match rest:
            case Nil{}:
              Value{apply_args(args, TRef{name})}
            case Con{Def{entry_name, arity, body}, tail}:
              go(left, book, seek_next(name, args, arity,
                body, tail, Nat.is_eq(name, entry_name)))
        case Found{name, arity, body, +args}:
          go(left, book, found_next(name, arity, body, args,
            Nat.is_le(arity, List.length(&2, Term, args))))
        case Stop{term}:
          Value{term}

def run(fuel: Nat, book: List<&2, Def>, term: Term) -> WHResult:
  go(fuel, book, Go{term, Nil{}})

def compare_go(fuel: Nat, +book: List<&2, Def>, state: EqState) -> EqResult:
  match fuel:
    case 0n:
      EqExhausted{}
    case 1n++left:
      match state:
        case EqCheck{a, b, rest}:
          compare_go(left, book, EqResults{run(left, book, a), run(left, book, b), rest})
        case EqResults{a, b, rest}:
          match a:
            case Exhausted{}:
              EqExhausted{}
            case Value{a_nf}:
              match b:
                case Exhausted{}:
                  EqExhausted{}
                case Value{b_nf}:
                  compare_go(left, book, EqValues{a_nf, b_nf, rest})
        case EqValues{a, b, rest}:
          match a:
            case TLam{a_body}:
              match b:
                case TLam{b_body}:
                  compare_go(left, book, EqCheck{a_body, b_body, rest})
                case other:
                  compare_go(left, book, EqCheck{a_body, TApp{shift(other, 0n), TVar{0n}}, rest})
            case TVar{i}:
              match b:
                case TLam{body}:
                  compare_go(left, book, EqCheck{TApp{shift(TVar{i}, 0n), TVar{0n}}, body, rest})
                case TVar{j}:
                  compare_go(left, book, EqAgree{Nat.is_eq(i, j), rest})
                case _:
                  Different{}
            case TRef{name}:
              match b:
                case TLam{body}:
                  compare_go(left, book, EqCheck{TApp{TRef{name}, TVar{0n}}, body, rest})
                case TRef{other_name}:
                  compare_go(left, book, EqAgree{Nat.is_eq(name, other_name), rest})
                case _:
                  Different{}
            case TApp{a_fn, a_arg}:
              match b:
                case TLam{body}:
                  compare_go(left, book, EqCheck{TApp{shift(TApp{a_fn, a_arg}, 0n), TVar{0n}}, body, rest})
                case TApp{b_fn, b_arg}:
                  compare_go(left, book, EqCheck{a_fn, b_fn, Con{EqPair{a_arg, b_arg}, rest}})
                case _:
                  Different{}
            case _:
              Different{}
        case EqAgree{same, rest}:
          match same:
            case False{}:
              Different{}
            case True{}:
              match rest:
                case Nil{}:
                  Equal{}
                case Con{EqPair{a, b}, tail}:
                  compare_go(left, book, EqCheck{a, b, tail})

def compare(fuel: Nat, book: List<&2, Def>, a: Term, b: Term) -> EqResult:
  compare_go(fuel, book, EqCheck{a, b, Nil{}})

def json(t: Term) -> String:
  match t:
    case TVar{i}:
      "[\"Var\"," ++ Nat.show(i) ++ "]"
    case TLam{body}:
      "[\"Lam\"," ++ json(body) ++ "]"
    case TApp{fn, arg}:
      "[\"App\"," ++ json(fn) ++ "," ++ json(arg) ++ "]"
    case TLet{value, body}:
      "[\"Let\"," ++ json(value) ++ "," ++ json(body) ++ "]"
    case TRef{name}:
      "[\"Ref\"," ++ Nat.show(name) ++ "]"
    case TAnn{term, ty}:
      "[\"Ann\"," ++ json(term) ++ "," ++ json(ty) ++ "]"

def json_result(r: WHResult) -> String:
  match r:
    case Exhausted{}:
      "[\"Exhausted\"]"
    case Value{term}:
      json(term)

def json_eq_result(r: EqResult) -> String:
  match r:
    case Equal{}:
      "\"Equal\""
    case Different{}:
      "\"Different\""
    case EqExhausted{}:
      "\"Exhausted\""

def main() -> IO(Unit):
  +book = {[Def{0n, 2n, TLam{TLam{TVar{1n}}}}, Def{2n, 0n, TRef{2n}}] : List<&2, Def>}
  IO.print("[" ++
    json_eq_result(compare(256n, book, TApp{TApp{TRef{0n}, TRef{9n}}, TRef{8n}}, TRef{9n})) ++ "," ++
    json_eq_result(compare(256n, book, TRef{9n}, TRef{8n})) ++ "," ++
    json_eq_result(compare(64n, book, TRef{2n}, TRef{2n})) ++ "]")

#|["Equal","Different","Exhausted"]
