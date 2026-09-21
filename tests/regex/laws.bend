# Laws tying the three entry points together, three per (pattern, subject,
# at): exec is the first match_at from at on, span and groups alike (search
# is anchored matching tried at each start in turn); match_at(i) is None or
# starts at i, for every i; fullmatch is None or spans the whole subject. A
# pattern that fails to compile is a False, never a skipped row
import Base

def eq.span(a: Maybe<&2, Sigma<&2, &2, Nat, _ => Nat>>, b: Maybe<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> Bool:
  match a b:
    case None{}, None{}:
      True{}
    case Some{(i, j)}, Some{(k, l)}:
      Bool.and(Nat.is_eq(i, k), Nat.is_eq(j, l))
    case _, _:
      False{}

def eq.spans(a: List<&2, Maybe<&2, Sigma<&2, &2, Nat, _ => Nat>>>, b: List<&2, Maybe<&2, Sigma<&2, &2, Nat, _ => Nat>>>) -> Bool:
  match a b:
    case Nil{}, Nil{}:
      True{}
    case x <> xs, y <> ys:
      Bool.and(eq.span(x, y), eq.spans(xs, ys))
    case _, _:
      False{}

def eq(a: Maybe<&2, Regex.Match>, b: Maybe<&2, Regex.Match>) -> Bool:
  match a b:
    case None{}, None{}:
      True{}
    case Some{Match{i, j, gs}}, Some{Match{k, l, hs}}:
      eq.spans(Some{(i, j)} <> gs, Some{(k, l)} <> hs)
    case _, _:
      False{}

def first(k: Nat, m: Maybe<&2, Regex.Match>, +re: Regex, +s: String, +i: Nat) -> Maybe<&2, Regex.Match>:
  match k m:
    case _, Some{x}:
      Some{x}
    case 0n, None{}:
      None{}
    case 1n+k, None{}:
      first(k, Regex.match_at(re, s, 1n+i), re, s, 1n+i)

def starts(m: Maybe<&2, Regex.Match>, i: Nat) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{Match{a, b, gs}}:
      Nat.is_eq(a, i)

def anchored(ks: List<&2, Nat>, +re: Regex, +s: String) -> Bool:
  match ks:
    case Nil{}:
      True{}
    case +i <> t:
      Bool.and(starts(Regex.match_at(re, s, i), i), anchored(t, re, s))

def whole(m: Maybe<&2, Regex.Match>, n: Nat) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{Match{a, b, gs}}:
      Bool.and(Nat.is_eq(a, 0n), Nat.is_eq(b, n))

def laws(r: Result<&2, &2, String, Regex>, +s: String, +at: Nat) -> List<&2, Bool>:
  match r:
    case Fail{e}:
      [False{}]
    case Done{+re}:
      +n = String.length(s)
      [eq(Regex.exec(re, s, at), first(Nat.sub(n, at), Regex.match_at(re, s, at), re, s, at)),
       anchored(List.range(1n+n), re, s), whole(Regex.fullmatch(re, s), n)]

def l(p: String, +s: String, +at: Nat) -> List<&2, Bool>:
  laws(Regex.compile(p), s, at)

def main() -> List<&2, List<&2, Bool>>:
  [l("|a", "aba", 0n), l("a*", "baac", 1n), l("a*?", "aa", 0n), l("(a)|b", "cab", 0n),
   l("\\b", "ab cd", 2n), l("\\Bb", "ab b", 0n), l("^a|b$", "ab\n", 1n), l("x", "abc", 0n),
   l("", "", 0n), l("(?:a|ab)(c|bcd)?", "xabcdab", 0n), l("(a(b)?)+", "abab", 1n),
   l("[^\\s]+", "é😀 x", 0n), l("😀*", "a😀😀b", 1n), l("a$", "a\n", 0n),
   l("abcd|a", "abab", 0n)]

#|[[True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}], [True{}, True{}, True{}]]
