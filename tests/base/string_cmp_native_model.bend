# String.cmp runs as native C (comp.ts OPERATIONS string_cmp); the
# interpreter and JS run Base's def. model proves by {==} that the codes
# keep Base's order -- numeric over the full U32 of each Char, outside
# Unicode too -- and that both strings come back whole, so --verdict pins
# the model; main prints the same calls, so every lane must print what the
# model computes.
import Base

def ch(x: U32) -> Char:
  Char.from_u32(x)

def code.go(r: (String & String) & Cmp) -> Cmp:
  ((a, b), c) = r
  c

def code(a: String, b: String) -> Cmp:
  code.go(String.cmp(a, b))

def kept.go(a: String, b: String, r: (String & String) & Cmp) -> Bool:
  ((a2, b2), c) = r
  Bool.and(String.eq(a2, a), String.eq(b2, b))

def kept(+a: String, +b: String) -> Bool:
  kept.go(a, b, String.cmp(a, b))

def code_u32(c: Cmp) -> U32:
  match c:
    case LT{}:
      0
    case EQ{}:
      1
    case GT{}:
      2

def code_calls() -> List<Cmp>:
  [
    code("", ""),
    code("a", ""),
    code("", "a"),
    code("abc", "abd"),
    code("abc", "abc"),
    code("ab", "abc"),
    code("abc", "ab"),
    code(SCon{ch(4294967295), SNil{}}, SCon{ch(2147483647), SNil{}}),
    code(SCon{ch(2147483648), SNil{}}, SCon{ch(2147483647), SNil{}}),
    code(SCon{ch(0), SNil{}}, ""),
    code("", SCon{ch(0), SNil{}}),
    code(SCon{ch(0), SNil{}}, SCon{ch(0), SNil{}})
  ]

def kept_calls() -> List<Bool>:
  [
    kept("", ""),
    kept("abc", "abd"),
    kept(SCon{ch(4294967295), SNil{}}, SCon{ch(2147483647), SNil{}}),
    kept(String.repeat("a", 256n), String.repeat("a", 256n) ++ "b")
  ]

def code_model() -> {code_calls() == [
    EQ{},
    GT{},
    LT{},
    LT{},
    EQ{},
    LT{},
    GT{},
    GT{},
    GT{},
    GT{},
    LT{},
    EQ{}
  ] : List<Cmp>}:
  {==}

def kept_model() -> {kept_calls() == [
    True{},
    True{},
    True{},
    True{}
  ] : List<Bool>}:
  {==}

def codes(xs: List<Cmp>) -> String:
  match xs:
    case Nil{}:
      ""
    case h <> t:
      U32.show(code_u32(h)) ++ codes(t)

def keeps(xs: List<Bool>) -> String:
  match xs:
    case Nil{}:
      ""
    case h <> t:
      Bool.show(h) ++ keeps(t)

def main() -> IO(Unit):
  do IO<Unit>:
    c : Unit <- IO.print(codes(code_calls()))
    k : Unit <- IO.print(keeps(kept_calls()))
    return Unit{}

#|120010222201
#|TrueTrueTrueTrue
