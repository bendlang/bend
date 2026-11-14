# the free chains by generation: a lane's chain that reaches KEEP_WORDS
# words is handed off whole (the first stays on the lane as its cold
# chain, the next banks the one before), and a miss takes the cold
# chain, then the bank. Each round frees several generations of 2-word,
# 4-word and 8-word nodes on one lane (a walk frees node by node, a drop
# frees through term_drop), builds again from what was handed off, and
# frees blocks of 2^16 words, which go straight to the bank. fan forks:
# its leaves build lists on their own lanes and its joins walk them, so
# under threads a lane frees nodes another one allocated, and takes from
# the bank what the other handed off. A count kept wrong would hand a
# chain off early or late; a chain handed off twice would give one node
# to two lists, and the sums below would differ between rounds.
import Base

type K2 is Data:
  K2Nil{}
  K2Con{k: U32, t: K2}

type K4 is Data:
  K4Nil{}
  K4Con{a: U32, b: U32, c: U32, t: K4}

type K8 is Data:
  K8Nil{}
  K8Con{a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32, t: K8}

def k2(n: Nat, +x: U32, acc: K2) -> K2:
  match n:
    case 0n:
      acc
    case 1n+p:
      k2(p, U32.inc(x), K2Con{x, acc})

def k4(n: Nat, +x: U32, acc: K4) -> K4:
  match n:
    case 0n:
      acc
    case 1n+p:
      k4(p, U32.inc(x), K4Con{x, 1, 2, acc})

def k8(n: Nat, +x: U32, acc: K8) -> K8:
  match n:
    case 0n:
      acc
    case 1n+p:
      k8(p, U32.inc(x), K8Con{x, 1, 2, 3, 4, 5, 6, acc})

def k2_sum(c: K2, acc: U32) -> U32:
  match c:
    case K2Nil{}:
      acc
    case K2Con{k, t}:
      k2_sum(t, U32.add(acc, k))

def k4_sum(c: K4, acc: U32) -> U32:
  match c:
    case K4Nil{}:
      acc
    case K4Con{a, b, c, t}:
      k4_sum(t, U32.add(acc, U32.add(a, U32.add(b, c))))

def k8_sum(c: K8, acc: U32) -> U32:
  match c:
    case K8Nil{}:
      acc
    case K8Con{a, b, c, d, e, f, g, t}:
      k8_sum(t, U32.add(acc, U32.add(a, g)))

def lose(a: K2, b: K4, c: K8, x: U32) -> U32:
  x

# a block of 2^16 words, written at both ends and freed
def big.read(r: Array<U32> & U32, x: U32) -> U32:
  (a, v) = r
  U32.add(v, x)

def big(+x: U32) -> U32:
  big.read(Array.get(U32, Array.set(U32, Array.new(U32, 17n, x), 131071,
    U32.add(x, 7)), 131071), x)

# one lane: three generations of each class freed by a walk, then by a
# drop, then built again from what was handed off
def lane(+n: Nat, +x: U32) -> U32:
  a = k2_sum(k2(n, x, K2Nil{}), 0)
  b = k4_sum(k4(n, x, K4Nil{}), a)
  c = k8_sum(k8(n, x, K8Nil{}), b)
  d = lose(k2(n, x, K2Nil{}), k4(n, x, K4Nil{}), k8(n, x, K8Nil{}), c)
  e = k2_sum(k2(n, x, K2Nil{}), U32.add(d, big(x)))
  k8_sum(k8(n, x, K8Nil{}), U32.add(e, big(U32.inc(x))))

# the fork tree: a leaf builds, a join walks the left list (freeing what
# another lane may have allocated) and hands the right one up
def fan(+d: Nat, +n: Nat, +x: U32) -> K2:
  match d:
    case 0n:
      k2(n, x, K2Nil{})
    case 1n+p:
      l r = fan(p, n, x) fan(p, n, U32.add(x, 1000003))
      K2Con{k2_sum(l, 0), r}

def round(+n: Nat, +x: U32) -> U32:
  U32.add(lane(n, x), k2_sum(fan(5n, n, x), 0))

def main() -> IO(Unit):
  IO.print(U32.show(round(50000n, 1)) ++ " " ++ U32.show(round(50000n, 1))
    ++ " " ++ U32.show(round(50000n, 1)) ++ " "
    ++ U32.show(round!(50000n, 1)))

#|404482188 404482188 404482188 404482188
