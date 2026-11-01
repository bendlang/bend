# regression witness: blk_fill keeps a run of equal cells with one bump of
# its length. Clones of String and {String, U32} arrays, made by Array.new
# (one run) and broken up by Array.set (runs of one and of many), are each
# written then summed in full, depths 0 to 11, both copies. A run kept too
# few times frees a string another copy still reads (a run kept too many
# times only leaks, which this does not see).
import Base

type Sx is Data:
  Sx{s: String, n: U32}

def ks(s: String) -> U32:
  U32.from_nat(String.length(s))

def kx(p: Sx) -> U32:
  match p:
    case Sx{s, n}:
      U32.add(U32.mul(U32.from_nat(String.length(s)), 7), n)

def sum_s(a: Array<String>) -> U32:
  match a:
    case ALeaf{x}:
      ks(x)
    case ANode{xs, ys}:
      U32.add(U32.mul(sum_s(xs), 31), sum_s(ys))

def sum_x(a: Array<Sx>) -> U32:
  match a:
    case ALeaf{x}:
      kx(x)
    case ANode{xs, ys}:
      U32.add(U32.mul(sum_x(xs), 31), sum_x(ys))

def mix(+k: Nat, +i: U32, a: Array<String>) -> Array<String>:
  match k:
    case 0n:
      a
    case 1n+p:
      mix(p, U32.add(i, 3), Array.set(String, a, i, U32.show(U32.mul(i, 977))))

def mixx(+k: Nat, +i: U32, a: Array<Sx>) -> Array<Sx>:
  match k:
    case 0n:
      a
    case 1n+p:
      mixx(p, U32.add(i, 5), Array.set(Sx, a, i, Sx{U32.show(i), i}))

def both_s(p: Array<String> & Array<String>, +i: U32) -> U32:
  (a, b) = p
  +x = sum_s(Array.set(String, a, i, "changed"))
  +y = sum_s(b)
  U32.xor(U32.mul(x, 3), y)

def both_x(p: Array<Sx> & Array<Sx>, +i: U32) -> U32:
  (a, b) = p
  +x = sum_x(b)
  +y = sum_x(Array.set(Sx, a, i, Sx{"z", 1}))
  U32.xor(U32.mul(x, 5), y)

def twice(p: Array<String> & Array<String>) -> U32:
  (a, b) = p
  +x = both_s(Array.clone(String, a), 1)
  +y = both_s(Array.clone(String, b), 2)
  U32.add(x, y)

def row(+d: Nat, +i: U32) -> U32:
  +a = both_s(Array.clone(String, Array.new(String, d, U32.show(i))), i)
  +b = both_s(Array.clone(String, mix(d, 0, Array.new(String, d, U32.show(i)))), U32.add(i, 1))
  +c = both_x(Array.clone(Sx, Array.new(Sx, d, Sx{U32.show(i), 9})), i)
  +x = both_x(Array.clone(Sx, mixx(d, 1, Array.new(Sx, d, Sx{"q", i}))), 2)
  +t = twice(Array.clone(String, mix(d, 1, Array.new(String, d, "shared"))))
  U32.add(U32.mul(a, 3), U32.add(U32.mul(b, 5), U32.add(U32.mul(c, 7), U32.add(x, t))))

def go(+d: Nat, +acc: U32) -> U32:
  match d:
    case 0n:
      acc
    case 1n+p:
      go(p, U32.add(U32.mul(acc, 33), row(p, U32.add(acc, 1))))

def main() -> IO(Unit):
  IO.print(U32.show(go(12n, 1)))

#|4065460981
