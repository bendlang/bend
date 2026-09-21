# Captures: a group keeps the last value it took, even once a later
# iteration skips it; a group that took no part is None, one that matched
# empty is Some; offsets count code points, so a supplementary char counts
# once; Regex.group is a span's text: group 0 the match, None past the last
# group or for one that took no part
import Base

def go(r: Result<&2, &2, String, Regex>, s: String) -> Maybe<&2, Regex.Match>:
  match r:
    case Fail{e}:
      None{}
    case Done{re}:
      Regex.exec(re, s, 0n)

def m(p: String, s: String) -> Maybe<&2, Regex.Match>:
  go(Regex.compile(p), s)

def txt.go(m: Maybe<&2, Regex.Match>, s: String, k: Nat) -> Maybe<&2, String>:
  match m:
    case None{}:
      None{}
    case Some{x}:
      Regex.group(s, x, k)

def txt(r: Result<&2, &2, String, Regex>, +s: String, k: Nat) -> Maybe<&2, String>:
  match r:
    case Fail{e}:
      None{}
    case Done{re}:
      txt.go(Regex.exec(re, s, 0n), s, k)

def t(p: String, s: String, k: Nat) -> Maybe<&2, String>:
  txt(Regex.compile(p), s, k)

def main() -> Sigma<&2, &2, List<&2, Maybe<&2, Regex.Match>>, _ => List<&2, Maybe<&2, String>>>:
  ([m("(a(b)?)+", "aba"), m("((a)|b)+", "ab"), m("(a)|b", "b"), m("a(b)?c", "ac"),
    m("a(b*)c", "ac"), m("(a|(b))*", "ab"), m(".", "😀x"), m("x😀y", "ax😀yb"),
    m("[😀-🙏]", "🙂"), m("(😀)+", "é😀😀")],
   [t("(a(b)?)+", "xaba", 0n), t("(a(b)?)+", "xaba", 1n), t("(a(b)?)+", "xaba", 2n),
    t("(a(b)?)+", "xaba", 3n), t("a(b)?c", "ac", 1n), t("a(b*)c", "ac", 1n),
    t("x(😀+)y", "ax😀😀yb", 1n), t("(\\w+)@(\\w+)", "mail ann@bend now", 2n)])

#|([Some{Match{0n, 3n, [Some{(2n, 3n)}, Some{(1n, 2n)}]}}, Some{Match{0n, 2n, [Some{(1n, 2n)}, Some{(0n, 1n)}]}}, Some{Match{0n, 1n, [None{}]}}, Some{Match{0n, 2n, [None{}]}}, Some{Match{0n, 2n, [Some{(1n, 1n)}]}}, Some{Match{0n, 2n, [Some{(1n, 2n)}, Some{(1n, 2n)}]}}, Some{Match{0n, 1n, []}}, Some{Match{1n, 4n, []}}, Some{Match{0n, 1n, []}}, Some{Match{1n, 3n, [Some{(2n, 3n)}]}}], [Some{"aba"}, Some{"a"}, Some{"b"}, None{}, None{}, Some{""}, Some{"😀😀"}, Some{"bend"}])
