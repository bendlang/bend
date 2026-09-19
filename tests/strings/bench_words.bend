# Pure oracle; bench.sh imports these same functions into both runtime drivers.
# Each token contributes a rolling U32 checksum of its actual code points.
import Base

def token(s: String, h: U32) -> U32:
  match s:
    case SNil{}:
      h
    case SCon{Chr{x}, t}:
      token(t, U32.add(U32.mul(h, 33), x))

def tokens(xs: List<&2, String>, n: U32, h: U32) -> U32 & U32:
  match xs:
    case Nil{}:
      (n, h)
    case s <> tail:
      tokens(tail, U32.add(n, 1), U32.add(h, token(s, 0)))

def lines(xs: List<&2, String>, acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case Nil{}:
      acc
    case s <> tail:
      lines(tail, List.append(&2, String, String.words(String.trim(s)), acc))

def materialize(s: String) -> List<&2, String>:
  lines(String.lines(s), [])

def more(acc: U32 & U32, xs: List<&2, String>) -> U32 & U32:
  (n, h) = acc
  tokens(xs, n, h)

# fuel covers the input; chunk ends at a corpus-unit boundary (see bench.sh).
def scan(fuel: Nat, +s: String, +chunk: Nat, acc: U32 & U32) -> U32 & U32:
  match fuel:
    case 0n:
      acc
    case 1n+p:
      scan(p, String.drop(s, chunk), chunk,
        more(acc, materialize(String.take(s, chunk))))

def main() -> (U32 & U32) & (U32 & U32):
  (tokens(materialize("  alpha beta\n gamma\t\n  café λ😀\n 漢字\t\n"), 0, 0),
   scan(3n, String.repeat("  alpha beta\n gamma\t\n", 3n), 21n, (0, 0)))


#|((6, 253224172), 9, 745304751)
