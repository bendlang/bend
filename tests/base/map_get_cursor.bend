# Map.get carries a cursor into the key: each level drops only the
# characters between the parent's position and the child's, instead of
# re-walking a shared prefix from the start. Hits, misses past the end,
# short and empty keys, keys that prefix each other, characters past
# U+10FFFF and a reused result all answer, and the returned map still
# holds its keys.
import Base

def pre(n: Nat, t: String) -> String:
  match n:
    case 0n:
      t
    case 1n+p:
      SCon{Chr{120}, pre(p, t)}

def hex(+i: U32, +s: Nat) -> Char:
  Chr{(97 + U32.and(U32.shrn(i, s), 15) : U32)}

def key(+p: Nat, +i: U32) -> String:
  pre(p, SCon{hex(i, 12n), SCon{hex(i, 8n), SCon{hex(i, 4n), SCon{hex(i, 0n), SNil{}}}}})

def build(n: Nat, +i: U32, +p: Nat, m: Map<&2, U32>) -> Map<&2, U32>:
  match n:
    case 0n:
      m
    case 1n+k:
      build(k, U32.inc(i), p, Map.set(&2, U32, m, key(p, i), U32.inc(i)))

def val(r: Map<&2, U32> & U32) -> String:
  (m, v) = r
  U32.show(v)

def get(m: Map<&2, U32>, k: String, d: U32) -> String:
  val(Map.get(U32, d, m, k))

# The map handed back by one lookup still answers the next one.
def twice.get(x: U32, r: Map<&2, U32> & U32) -> String:
  (m, y) = r
  String.append(U32.show(x), String.append("/", U32.show(y)))

def twice.go(r: Map<&2, U32> & U32, b: String) -> String:
  (m, x) = r
  twice.get(x, Map.get(U32, 0, m, b))

def twice(m: Map<&2, U32>, a: String, b: String) -> String:
  twice.go(Map.get(U32, 0, m, a), b)

def main() -> IO(Unit):
  +m = build(64n, 0, 64n, Map.new(&2, U32))
  +t = Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32,
    Map.set(&2, U32, m, key(0n, 7), 8), "a", 100), "ab", 101), "", 102)
  do IO<Unit>:
    Unit <- IO.print(get(t, key(64n, 0), 999))
    Unit <- IO.print(get(t, key(64n, 63), 999))
    Unit <- IO.print(get(t, key(64n, 64), 999))
    Unit <- IO.print(get(t, "zzz", 999))
    Unit <- IO.print(get(t, "", 999))
    Unit <- IO.print(get(t, "a", 999))
    Unit <- IO.print(get(t, "abc", 999))
    Unit <- IO.print(get(t, key(0n, 7), 999))
    Unit <- IO.print(get(t, String.repeat("y", 1024n), 999))
    Unit <- IO.print(twice(t, key(64n, 5), key(64n, 6)))
    Unit <- IO.print(get(Map.set(&2, U32, Map.new(&2, U32), "\u{ffffffff}", 7), "\u{ffffffff}", 999))
    IO.print(get(Map.set(&2, U32, Map.new(&2, U32), "\u{7fffffff}", 8), "\u{ffffffff}", 999))

#|1
#|64
#|999
#|999
#|102
#|100
#|999
#|8
#|999
#|6/7
#|7
#|999
