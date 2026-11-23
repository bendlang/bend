# A lambda passed to a def runs in a copy of the def, its captures passed
# as parameters: a capture shared with the caller (a list read after the
# call, a tree read twice), several captures of different layouts, a lambda
# handed through two defs, one def copied for two lambdas, a lambda the def
# returns, a lambda the def stores in a node, a recursion that passes its
# lambda on unchanged, a recursion through the lambda's own body, and a
# recursion that wraps its lambda in a new one each step (left a closure
# past one copy). Inputs come from a list built at run time.
import Base

type Tree is Data:
  Leaf{v: U32}
  Node{l: Tree, r: Tree}

type Box is Type:
  Hold{f: U32 -> U32, n: U32}

def ap(x: U32, f: U32 -> U32) -> U32:
  f(x)

def ap2(x: U32, f: U32 -> U32) -> U32:
  ap((x + 1 : U32), f)

def pair.go(-A: Type, -B: Type, -R: Type, p: A & B, k: A -> B -> R) -> R:
  (a, b) = p
  k(a, b)

def ret(z: Bool, +n: U32, f: U32 -> U32) -> U32 -> U32:
  match z:
    case True{}:
      f
    case False{}:
      x => f((x + n : U32))

def keep(n: U32, f: U32 -> U32) -> Box:
  Hold{f, (n * 2 : U32)}

def open(b: Box) -> U32:
  match b:
    case Hold{f, n}:
      f(n)

def sum(t: Tree) -> U32:
  match t:
    case Leaf{v}:
      v
    case Node{l, r}:
      (sum(l) + sum(r) : U32)

def build(+n: Nat, +v: U32) -> Tree:
  match n:
    case 0n:
      Leaf{v}
    case 1n+(+p):
      Node{build(p, v), build(p, (v + 1 : U32))}

def len(xs: +List<U32>) -> U32:
  match xs:
    case []:
      0
    case h <> t:
      (1 + len(t) : U32)

# calls k once at the bottom, passing it on unchanged
def down(n: Nat, +acc: U32, k: U32 -> U32) -> U32:
  match n:
    case 0n:
      k(acc)
    case 1n+p:
      down(p, (acc * 3 + 1 : U32), k)

# a new lambda around k each step
def wrap(n: Nat, k: U32 -> U32) -> U32:
  match n:
    case 0n:
      k(1)
    case 1n+p:
      wrap(p, x => k((x * 2 + 1 : U32)))

# the lambda's body calls back into the loop
def loop(n: Nat, +c: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      pair.go(U32, U32, U32, ((acc + c : U32), 3), x => +y => loop(p, c, (x + y * c : U32)))

def shared(+xs: +List<U32>, +t: Tree, +k: U32) -> U32:
  +a = ap(k, y => (y + len(xs) + sum(t) : U32))
  (a + len(xs) + sum(t) : U32)

def many(+a: U32, +b: F32, +s: String, +t: Tree, x: U32) -> U32:
  ap(x, y => (y + a + F32.to_u32(b) + U32.from_nat(String.length(s)) + sum(t) : U32))

def two(+k: U32) -> U32:
  +p = ap(k, y => (y * 7 : U32))
  +q = ap(k, y => (y + 100 : U32))
  +r = ap2(k, y => (y * k : U32))
  (p + q + r : U32)

def show(+x: U32) -> String:
  U32.show(x)

def run(+k: U32, +xs: +List<U32>) -> String:
  +t = build(3n, k)
  +r1 = shared(xs, t, k)
  +r2 = many(k, 2.5, "four", t, 1)
  +r3 = two(k)
  +r4 = ret(False{}, k, y => (y * 5 : U32))(3)
  +r5 = ret(True{}, k, y => (y * 5 : U32))(3)
  +r6 = open(keep(k, y => (y + k : U32)))
  +r7 = down(5n, k, y => (y + sum(t) : U32))
  +r8 = wrap(6n, y => (y + k : U32))
  +r9 = loop(1000n, k, 1)
  show(r1) ++ " " ++ show(r2) ++ " " ++ show(r3) ++ " " ++ show(r4) ++ " " ++ show(r5) ++ " " ++ show(r6) ++ " " ++ show(r7) ++ " " ++ show(r8) ++ " " ++ show(r9)

def main() -> String:
  +xs : +List<U32> = [3, 1, 4, 1, 5]
  run(len(xs), xs)

#|"119 64 170 40 15 15 1388 132 20001"
