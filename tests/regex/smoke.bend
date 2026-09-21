# Independent subjects cross one ! transfer: each is its own Regex.exec
# and Regex.match_at, the pairs fork in parallel, and the results keep the
# list's order
import Base

def one(+re: Regex, +s: String) -> List<&2, Maybe<&2, Regex.Match>>:
  [Regex.exec(re, s, 0n), Regex.match_at(re, s, 1n)]

def each(+re: Regex, xs: List<&2, String>) -> List<&2, List<&2, Maybe<&2, Regex.Match>>>:
  match xs:
    case Nil{}:
      []
    case s <> tail:
      h t = one(re, s) each(re, tail)
      h <> t

def all(r: Result<&2, &2, String, Regex>, xs: List<&2, String>) -> List<&2, List<&2, Maybe<&2, Regex.Match>>>:
  match r:
    case Fail{e}:
      []
    case Done{re}:
      each(re, xs)

def main() -> List<&2, List<&2, Maybe<&2, Regex.Match>>>:
  all!(Regex.compile("(\\w+)@(\\w+)\\.(?:com|org)|^$"),
    ["ann@bend.org", "no match here", "", "é😀 <bob@hvm.com>, c@d.com", "xa@b.org\n", "a@b.net",
     String.append(String.repeat("pad ", 40n), "z@y.com")])

#|[[Some{Match{0n, 12n, [Some{(0n, 3n)}, Some{(4n, 8n)}]}}, Some{Match{1n, 12n, [Some{(1n, 3n)}, Some{(4n, 8n)}]}}], [None{}, None{}], [Some{Match{0n, 0n, [None{}, None{}]}}, Some{Match{0n, 0n, [None{}, None{}]}}], [Some{Match{4n, 15n, [Some{(4n, 7n)}, Some{(8n, 11n)}]}}, None{}], [Some{Match{0n, 8n, [Some{(0n, 2n)}, Some{(3n, 4n)}]}}, Some{Match{1n, 8n, [Some{(1n, 2n)}, Some{(3n, 4n)}]}}], [None{}, None{}], [Some{Match{160n, 167n, [Some{(160n, 161n)}, Some{(162n, 163n)}]}}, None{}]]
