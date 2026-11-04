# a def whose parameters span past WIDE words takes its wide records
# boxed. One whose type has no box words stays boxed until a use needs
# its words, and a match reads them in place: matched, passed back
# whole, dropped unread, threaded through a loop, and a sum matched on
# its tag. Read again, even after a constant fold, a use that needs its
# words reads them in place and the node stays: lent to lend's pick
# after sum1 reads it, it is passed as it is. One holding a heap field
# (W's list) opens on entry, so passing it to g, which borrows, keeps g
# borrowing for L; read again it stays boxed, so peek, lent a closure's
# W around a read that stores it in H, keeps borrowing. A closure that
# captures a boxed record still used after it shares the node. One that
# a later call of a fork reads first, or that a fork's call reads and
# its join reads again (forked's c), keeps the words its frame and join
# took at the fork; tree's 4096 leaves run those forks in sequence on
# any thread count.
import Base

type R0 is Data:
  R0{a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32, h: U32}

type R1 is Data:
  R1{a: R0, b: R0, c: R0, d: R0, e: R0, f: R0, g: R0, h: R0}

type M is Data:
  MNo{}
  MYes{p: R1, q: U32}

type Xs is Data:
  X0{}
  X1{v: U32, rest: Xs}

type W is Data:
  W{xs: Xs, p: R1}

type H is Data:
  H{w: W, n: U32}

type P is Data:
  P{a: U32, b: U32}

def r0(+x: U32) -> R0:
  R0{x, x, x, x, x, x, x, x}

def r1(+x: U32) -> R1:
  R1{r0(x), r0(x), r0(x), r0(x), r0(x), r0(x), r0(x), r0(x)}

def sum0(x: R0) -> U32:
  match x:
    case R0{a, b, c, d, e, f, g, h}:
      U32.add(U32.add(U32.add(a, b), U32.add(c, d)), U32.add(U32.add(e, f), U32.add(g, h)))

def sum1(x: R1) -> U32:
  match x:
    case R1{a, b, c, d, e, f, g, h}:
      U32.add(U32.add(U32.add(sum0(a), sum0(b)), U32.add(sum0(c), sum0(d))), U32.add(U32.add(sum0(e), sum0(f)), U32.add(sum0(g), sum0(h))))

def twice(a: R1, b: R1, +c: R1, d: R1) -> U32:
  x y = sum1(a) sum1(c)
  z w = sum1(c) sum1(d)
  U32.add(U32.add(x, y), U32.add(U32.add(z, w), sum1(b)))

def pick(a: R1, b: R1, c: R1, d: R1) -> U32:
  match c:
    case R1{p, q, r, s, t, u, v, w}:
      U32.add(sum0(r), sum1(d))

def lend(+a: R1, b: R1, c: R1, d: R1) -> U32:
  U32.add(sum1(a), pick(b, c, a, d))

def pass(a: R1, b: R1, c: R1, d: R1) -> R1:
  b

def loop(n: Nat, a: R1, b: R1, c: R1, d: R1) -> U32:
  match n:
    case 0n:
      U32.add(U32.add(sum1(a), sum1(b)), U32.add(sum1(c), sum1(d)))
    case 1n+p:
      loop(p, b, c, d, a)

def msum(m: M) -> U32:
  match m:
    case MNo{}:
      0
    case MYes{p, q}:
      U32.add(sum1(p), q)

def sums(a: M, b: M, c: M, d: M) -> U32:
  match a:
    case MNo{}:
      x y = msum(b) msum(c)
      U32.add(U32.add(x, y), msum(d))
    case MYes{p, q}:
      x y = msum(b) msum(c)
      U32.add(U32.add(U32.add(sum1(p), q), U32.add(x, y)), msum(d))

def h(+v: R1, t: Bool) -> U32:
  match t:
    case True{}:
      U32.add(sum1(v), sum1(v))
    case False{}:
      0

def folded(a: R1, b: R1, c: R1, d: R1) -> U32:
  U32.add(U32.add(h(a, True{}), sum1(b)), U32.add(sum1(c), sum1(d)))

def Xs.sum(xs: Xs, acc: U32) -> U32:
  match xs:
    case X0{}:
      acc
    case X1{v, rest}:
      Xs.sum(rest, (acc + v : U32))

def g(v: W) -> U32:
  match v:
    case W{xs, p}:
      U32.add(Xs.sum(xs, 0), sum1(p))

def L(+v: W) -> U32:
  a = g(v)
  b = g(v)
  (a + b : U32)

def heap(a: W, b: W, c: W, d: R1) -> U32:
  U32.add(U32.add(g(a), g(b)), U32.add(g(c), sum1(d)))

def peek(v: W, a: R1, b: R1, c: R1) -> U32:
  match v:
    case W{xs, p}:
      U32.add(U32.add(Xs.sum(xs, 0), sum1(p)), U32.add(sum1(a), U32.add(sum1(b), sum1(c))))

def hsum(h: H) -> U32:
  match h:
    case H{w, n}:
      U32.add(g(w), n)

def mkw(+x: U32) -> W:
  W{X1{x, X1{2, X0{}}}, r1(x)}

def stash(f: U32 -> W, +x: U32) -> U32:
  +v = f(x)
  a = peek(v, r1(1), r1(2), r1(3))
  +h = {H{v, 1} : H}
  b = peek(v, r1(4), r1(5), r1(6))
  U32.add(U32.add(a, b), hsum(h))

def sum(p: P) -> U32:
  match p:
    case P{a, b}:
      U32.add(a, b)

def dif(p: P) -> U32:
  match p:
    case P{a, b}:
      U32.sub(a, b)

def apply(f: U32 -> U32, x: U32) -> U32:
  f(x)

def captured(f: U32 -> P, x: U32) -> U32:
  +p = f(x)
  a = apply(y => U32.add(sum(p), y), 1)
  U32.add(a, dif(p))

def mk(+x: U32) -> P:
  P{U32.add(x, 3), x}

def late(f: U32 -> P, x: U32, +q: P) -> U32:
  +p = f(x)
  a b = sum(q) sum(p)
  U32.add(U32.add(a, b), U32.add(dif(p), dif(q)))

def own(r: R1) -> U32:
  sum1(r)

def forked(a: R1, b: R1, +c: R1, d: R1) -> U32:
  x y = sum1(a) own(c)
  U32.add(U32.add(x, y), U32.add(sum1(c), U32.add(sum1(b), sum1(d))))

def tree(+d: Nat, +x: U32) -> U32:
  match d:
    case 0n:
      U32.add(late(y => mk(y), x, mk(1)), forked(r1(x), r1(2), r1(3), r1(4)))
    case 1n+e:
      a b = tree(e, x) tree(e, U32.add(x, 1))
      U32.add(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    u0 : Unit <- IO.print(U32.show(U32.add(twice(r1(1), r1(2), r1(3), r1(4)), twice(r1(5), r1(6), r1(7), r1(8)))))
    u1 : Unit <- IO.print(U32.show(U32.add(pick(r1(1), r1(2), r1(3), r1(4)), sum1(pass(r1(5), r1(6), r1(7), r1(8))))))
    u2 : Unit <- IO.print(U32.show(loop(1000n, r1(1), r1(2), r1(3), r1(4))))
    u3 : Unit <- IO.print(U32.show(U32.add(sums(MYes{r1(1), 7}, MYes{r1(2), 8}, MNo{}, MYes{r1(4), 9}), sums(MNo{}, MNo{}, MYes{r1(3), 1}, MNo{}))))
    u4 : Unit <- IO.print(U32.show(folded(r1(1), r1(2), r1(3), r1(4))))
    u5 : Unit <- IO.print(U32.show(U32.add(L(W{X1{1, X1{2, X0{}}}, r1(1)}), heap(W{X1{3, X0{}}, r1(2)}, W{X0{}, r1(3)}, W{X1{4, X1{5, X0{}}}, r1(4)}, r1(5)))))
    u6 : Unit <- IO.print(U32.show(captured(y => mk(y), 4)))
    u7 : Unit <- IO.print(U32.show(stash(y => mkw(y), 1)))
    u8 : Unit <- IO.print(U32.show(lend(r1(1), r1(2), r1(3), r1(4))))
    IO.print(U32.show(tree(12n, 0)))

#|2944
#|664
#|640
#|665
#|704
#|1042
#|15
#|1546
#|328
#|4825088
