# Regex.exec is Pattern.search(s, at), Regex.match_at is match(s, at),
# Regex.fullmatch is fullmatch(s): leftmost-first alternation, a
# catastrophic pattern terminates, lazy repeats, $ before a final newline
# only, ^ only at the real start and \b seeing the char before at, at past
# the end clamped to it
import Base

def go(r: Result<&2, &2, String, Regex>, s: String, at: Nat, k: Nat) -> Maybe<&2, Regex.Match>:
  match r k:
    case Fail{e}, _:
      None{}
    case Done{re}, 0n:
      Regex.exec(re, s, at)
    case Done{re}, 1n:
      Regex.match_at(re, s, at)
    case Done{re}, 2n+_:
      Regex.fullmatch(re, s)

def m(p: String, s: String, at: Nat, k: Nat) -> Maybe<&2, Regex.Match>:
  go(Regex.compile(p), s, at, k)

def main() -> List<&2, Maybe<&2, Regex.Match>>:
  [m("a|ab", "ab", 0n, 0n), m("^(a+)+$", "aaaaaaaaaaaaaaaaaaaab", 0n, 0n),
   m("(a|b)*?c", "abc", 0n, 0n), m("a+?", "aaa", 0n, 0n), m("a$", "a\n", 0n, 0n),
   m("a$", "a\n\n", 0n, 0n), m("a", "ba", 1n, 0n), m("^a", "aa", 1n, 0n),
   m("\\ba", "ba", 1n, 0n), m("\\Ba", "ba", 1n, 0n), m("", "", 0n, 0n),
   m("x", "abc", 5n, 0n), m("", "ab", 5n, 0n), m("a", "ba", 0n, 1n),
   m("a", "ba", 1n, 1n), m("b|$", "ab", 2n, 1n), m("a+", "aa\n", 0n, 2n),
   m("a*?", "aa", 0n, 2n), m("a|ab", "ab", 0n, 2n), m("a$", "a\n", 0n, 2n)]

#|[Some{Match{0n, 1n, []}}, None{}, Some{Match{0n, 3n, [Some{(1n, 2n)}]}}, Some{Match{0n, 1n, []}}, Some{Match{0n, 1n, []}}, None{}, Some{Match{1n, 2n, []}}, None{}, None{}, Some{Match{1n, 2n, []}}, Some{Match{0n, 0n, []}}, None{}, Some{Match{2n, 2n, []}}, None{}, Some{Match{1n, 2n, []}}, Some{Match{2n, 2n, []}}, None{}, Some{Match{0n, 2n, []}}, Some{Match{0n, 2n, []}}, None{}]
