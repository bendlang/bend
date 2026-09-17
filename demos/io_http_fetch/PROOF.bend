# The proofs of the HTTP client laws. body_after_blank opens the
# text after the blank line: the window has matched, so the walker
# answers it. body_suffix is an induction over the text at every
# state of the walker: a matched window answers the rest (the prefix
# is empty), else the prefix grows by the character consumed.
import Base
import ./main.bend as Fetch
import ./LAWS.bend as Laws

def Laws.body_after_blank(b):
  match b:
    case SNil{}:
      {==}
    case SCon{Chr{a}, t}:
      {==}

# the prefix grows by the character the walker consumed
def suffix_step(a: U32, -t: String, -e: Bool, -w: U32, ih: (&p: String -> {p ++ Fetch.http_body.go(t, e, w) == t : String}))
  -> (&p: String -> {p ++ Fetch.http_body.go(t, e, w) == SCon{Chr{a}, t} : String}):
  (p, pf) = ih
  (SCon{Chr{a}, p}, Equal.cong(String, String, x => SCon{Chr{a}, x}, p ++ Fetch.http_body.go(t, e, w), t, pf))

# the suffix law over the walker, at every state
def suffix_go(s: String, e: Bool, w: U32) -> (&p: String -> {p ++ Fetch.http_body.go(s, e, w) == s : String}):
  match s:
    case SNil{}:
      ("", {==})
    case SCon{Chr{+a}, +t}:
      match e:
        case True{}:
          ("", {==})
        case False{}:
          +w2 = (w * 256 + a : U32)
          suffix_step(a, t, U32.is_eq(w2, 218762506), w2, suffix_go(t, U32.is_eq(w2, 218762506), w2))

def Laws.body_suffix(s):
  suffix_go(s, False{}, 0)
