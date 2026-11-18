# Ownership and layouts round a tail-call cycle that runs as one loop: a list
# one def matches and its helper rebuilds, reusable lists both defs read, a
# value one def builds and the other answers, a string lent to the whole
# cycle, parameters that swap at the back edge, a helper lent a string from
# outside and handed one to own by the cycle, a record of words, an erased
# type parameter, defs whose parameters differ in count and kind, a Nat
# rebuilt as matched, an Array written and read in place, and Base's own
# cycles on text made at run time.
import Base

# the list is matched by one def and handed on to a helper that owns it
@unsafe
def keep.if(big: Bool, h: U32, t: List<U32>, acc: List<U32>, n: Nat) -> List<U32>:
  match big:
    case True{}:
      keep(n, t, h <> acc)
    case False{}:
      keep(n, t, acc)

@unsafe
def keep(n: Nat, xs: List<U32>, acc: List<U32>) -> List<U32>:
  match n:
    case 0n:
      acc
    case 1n+m:
      match xs:
        case Nil{}:
          acc
        case h <> t:
          +g = h
          keep.if(U32.is_gt(g, 4), g, t, acc, m)

# a reusable list goes round: one def reads it, the other reads it again
@unsafe
def look.if(hit: Bool, +xs: List<&2, U32>, +ys: List<&2, U32>, i: Nat, acc: U32) -> U32:
  match hit:
    case True{}:
      look(ys, xs, i, U32.add(acc, List.sum.u(xs)))
    case False{}:
      look(xs, ys, i, U32.add(acc, 1))

@unsafe
def look(+xs: List<&2, U32>, +ys: List<&2, U32>, i: Nat, acc: U32) -> U32:
  match i:
    case 0n:
      U32.add(acc, List.sum.u(ys))
    case 1n+j:
      look.if(U32.is_gt(List.sum.u(xs), 10), xs, ys, j, acc)

def List.sum.go(xs: List<&2, U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      List.sum.go(t, U32.add(h, acc))

def List.sum.u(xs: List<&2, U32>) -> U32:
  List.sum.go(xs, 0)

# one def builds the answer, the other returns it, or drops it for another
@unsafe
def mk.if(done: Bool, s: String, n: Nat) -> String:
  match done:
    case True{}:
      s
    case False{}:
      mk(n, s)

@unsafe
def mk(+n: Nat, s: String) -> String:
  match n:
    case 0n:
      "none"
    case 1n+p:
      mk.if(Nat.is_eq(p, 2n), SCon{'a', s}, p)

# a borrowed string is walked by one def, and the other decides to go on
@unsafe
def cnt.if(same: Bool, t: String, +c: Char, acc: Nat) -> Nat:
  match same:
    case True{}:
      cnt(t, c, 1n+acc)
    case False{}:
      cnt(t, c, acc)

@unsafe
def cnt(s: String, +c: Char, acc: Nat) -> Nat:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      cnt.if(Char.is_eq(h, c), t, c, acc)

def cnt.twice(+s: String) -> Nat:
  Nat.add(cnt(s, 'a', 0n), cnt(s, 'b', 0n))

# parameters swap at the back edge
@unsafe
def swp.if(go: Bool, a: String, b: String, n: Nat) -> String:
  match go:
    case True{}:
      swp(b, SCon{'x', a}, n)
    case False{}:
      SCon{'<', a}

@unsafe
def swp(a: String, b: String, n: Nat) -> String:
  match n:
    case 0n:
      swp.if(False{}, a, b, 0n)
    case 1n+p:
      swp.if(True{}, a, b, p)

# the caller keeps the string: it is lent to the whole cycle
def ends(+s: String, n: Nat) -> String:
  String.append(swp(s, "-", n), s)

# the helper rebuilds the node its caller matched
@unsafe
def inc.if(odd: Bool, h: U32, t: List<U32>, acc: List<U32>) -> List<U32>:
  match odd:
    case True{}:
      inc(t, U32.add(h, 1) <> acc)
    case False{}:
      inc(t, h <> acc)

@unsafe
def inc(xs: List<U32>, acc: List<U32>) -> List<U32>:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      +g = h
      inc.if(U32.is_eq(U32.and(g, 1), 1), g, t, acc)

def upto(+n: Nat, acc: List<U32>) -> List<U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      upto(p, U32.from_nat(n) <> acc)

def upto2(+n: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      upto2(p, U32.from_nat(n) <> acc)

def total(xs: List<U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      total(t, U32.add(acc, h))

type P is Data:
  P{a: U32, b: U32}

# a record of words rides the cycle; the helper takes it apart
@unsafe
def fibp.if(more: Bool, p: P, n: Nat) -> P:
  match more:
    case True{}:
      fibp(n, p)
    case False{}:
      p

@unsafe
def fibp(+n: Nat, p: P) -> P:
  match n:
    case 0n:
      p
    case 1n+m:
      P{+a, +b} = p
      fibp.if(Nat.is_gt(n, 1n), P{b, U32.add(a, b)}, m)

def P.sum(p: P) -> U32:
  P{a, b} = p
  U32.add(a, b)

# an erased type parameter: the same cycle over words and over boxes
@unsafe
def rev.if(-A: Type, stop: Bool, xs: List<A>, acc: List<A>, n: Nat) -> List<A>:
  match stop:
    case True{}:
      acc
    case False{}:
      rev(A, n, xs, acc)

@unsafe
def rev(-A: Type, +n: Nat, xs: List<A>, acc: List<A>) -> List<A>:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      rev.if(A, Nat.is_eq(n, 1n), t, h <> acc, Nat.sub(n, 1n))

def len(-A: Type, xs: List<A>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      len(A, t, U32.add(acc, 1))

def heads(xs: List<P>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      heads(t, U32.add(U32.mul(acc, 10), P.sum(h)))

def nums(xs: List<U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      nums(t, U32.add(U32.mul(acc, 10), h))

# defs whose parameters differ in count and kind: a word where the other
# has a box, and the reverse
@unsafe
def mix.a(n: Nat, s: String, k: U32) -> String:
  match n:
    case 0n:
      SCon{Chr{U32.add(48, k)}, s}
    case 1n+p:
      mix.b(U32.add(k, 1), p, SCon{'.', s}, True{}, 7)

@unsafe
def mix.b(k: U32, n: Nat, s: String, flag: Bool, pad: U32) -> String:
  match flag:
    case True{}:
      mix.c(s, n, U32.add(k, pad))
    case False{}:
      s

@unsafe
def mix.c(s: String, n: Nat, k: U32) -> String:
  mix.a(n, SCon{'c', s}, U32.mod(k, 10))

# a Nat matched and rebuilt as matched in the other def
@unsafe
def dn.if(+n: Nat, big: Bool, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      match big:
        case True{}:
          dn(Nat.div(1n+p, 2n), 1n+acc)
        case False{}:
          dn(p, Nat.add(acc, 1n+p))

@unsafe
def dn(+n: Nat, acc: Nat) -> Nat:
  dn.if(n, Nat.is_gt(n, 100n), acc)

# an Array written in place round the cycle
@unsafe
def fill.if(odd: Bool, a: Array<U32>, +i: U32, n: Nat) -> Array<U32>:
  match odd:
    case True{}:
      fill(n, Array.set(U32, a, i, U32.mul(i, 3)), U32.add(i, 1))
    case False{}:
      fill(n, a, U32.add(i, 1))

@unsafe
def fill(n: Nat, a: Array<U32>, +i: U32) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      fill.if(U32.is_eq(U32.and(i, 1), 1), a, i, p)

# the Array read is a helper's argument, and the helper hands the Array back
@unsafe
def asum.at(av: Array<U32> & U32, n: Nat, acc: U32) -> U32:
  (a, v) = av
  asum(n, a, U32.add(acc, v))

@unsafe
def asum(+n: Nat, a: Array<U32>, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      asum.at(Array.get(U32, a, U32.from_nat(p)), p, acc)

def wk.len(s: String, n: Nat) -> Nat:
  match s:
    case SNil{}:
      n
    case SCon{h, t}:
      wk.len(t, 1n+n)

@unsafe
def wk.if(more: Bool, s: String, n: Nat, acc: Nat) -> Nat:
  match more:
    case True{}:
      wk(n, s, acc)
    case False{}:
      Nat.add(acc, Nat.mul(10n, wk.len(s, 0n)))

@unsafe
def wk(+n: Nat, s: String, acc: Nat) -> Nat:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      wk.if(Nat.is_gt(n, 0n), t, Nat.sub(n, 1n), 1n+acc)

# wk is handed a node built for it, so it owns its string
def wk.new(+n: Nat, s: String) -> Nat:
  wk(n, SCon{'q', s}, 0n)

# the caller reads s again after the helper returns
def wk.out(+s: String, more: Bool) -> Nat:
  Nat.add(wk.if(more, s, 3n, 0n), Nat.mul(1000n, wk.len(s, 0n)))

# the helper only reads its string: a caller outside lends it one, and the
# cycle hands it one it made, which the helper must then free; gt calls itself
# too, so the helper is held in gt's loop and has no loop of its own
def rd.len(s: String, n: Nat) -> Nat:
  match s:
    case SNil{}:
      n
    case SCon{h, t}:
      rd.len(t, 1n+n)

@unsafe
def gt.if(done: Bool, +s: String, n: Nat, acc: Nat) -> Nat:
  match done:
    case True{}:
      Nat.add(rd.len(s, acc), rd.len(s, 0n))
    case False{}:
      gt(n, acc)

@unsafe
def gt(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n:
      gt(0n, Nat.add(acc, 50n))
    case 2n+p:
      s = Nat.show(Nat.mul(n, 1000n))
      gt.if(Nat.is_eq(p, 2n), s, 1n+p, 1n+acc)

def gt.out(+s: String, done: Bool) -> Nat:
  Nat.add(gt.if(done, s, 3n, 0n), Nat.mul(100n, rd.len(s, 0n)))

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    +z : Nat = Nat.mod(t, 1n)
    +u : U32 = U32.from_nat(z)
    IO.print(U32.show(total(keep(100n, upto(Nat.add(9n, z), []), []), 0)))
    IO.print(U32.show(total(keep(6n, upto(Nat.add(9n, z), []), []), 0)))
    IO.print(U32.show(look(upto2(Nat.add(5n, z), []), upto2(Nat.add(3n, z), []), Nat.add(7n, z), 0)))
    IO.print(mk(Nat.add(5n, z), "z"))
    IO.print(mk(Nat.add(2n, z), "z"))
    IO.print(Nat.show(cnt.twice(String.append("abracadabra", Nat.show(z)))))
    IO.print(ends(String.append("ab", Nat.show(z)), Nat.add(3n, z)))
    IO.print(swp("p", "q", Nat.add(4n, z)))
    IO.print(U32.show(total(inc(upto(Nat.add(300000n, z), []), []), 0)))
    IO.print(U32.show(total(inc(inc(upto(Nat.add(10n, z), []), []), []), 0)))
    IO.print(U32.show(P.sum(fibp(Nat.add(30n, z), P{u, 1}))))
    IO.print(U32.show(P.sum(fibp.if(True{}, P{u, 1}, Nat.add(10n, z)))))
    IO.print(U32.show(nums(rev(U32, Nat.add(3n, z), [1, 2, 3, 4, 5], []), 0)))
    IO.print(U32.show(nums(rev(U32, Nat.add(9n, z), [1, 2, 3, 4, 5], []), 0)))
    IO.print(U32.show(heads(rev(P, Nat.add(2n, z), [P{1, 0}, P{1, 1}, P{u, 3}], []), 0)))
    IO.print(U32.show(len(String, rev(String, Nat.add(2n, z), ["a", "b", "c"], []), 0)))
    IO.print(mix.a(Nat.add(4n, z), "!", 0))
    IO.print(mix.b(3, Nat.add(2n, z), "!", True{}, 4))
    IO.print(mix.c("!", Nat.add(1n, z), 4))
    IO.print(Nat.show(dn(Nat.add(1000n, z), 0n)))
    IO.print(U32.show(asum(Nat.add(64n, z), fill(Nat.add(64n, z), [0 : U32*64n], 0), 0)))
    IO.print(Nat.show(wk(Nat.add(2n, z), String.append("abcdefg", Nat.show(z)), 0n)))
    IO.print(Nat.show(wk.out(String.append("abcdefg", Nat.show(z)), True{})))
    IO.print(Nat.show(wk.out(String.append("abcdefg", Nat.show(z)), False{})))
    IO.print(Nat.show(wk.new(Nat.add(2n, z), String.append("abcdefg", Nat.show(z)))))
    IO.print(Nat.show(gt(Nat.add(7n, z), 0n)))
    IO.print(Nat.show(gt.out(String.append("abc", Nat.show(z)), Nat.is_eq(z, 0n))))
    IO.print(Nat.show(gt.out(String.append("abc", Nat.show(z)), Nat.is_eq(z, 1n))))
    +w : String = String.append("hello wor", String.append(Nat.show(z), "ld"))
    IO.print(Bool.show(String.contains(w, "or0l")))
    IO.print(Bool.show(String.contains(w, "orl")))
    IO.print(Bool.show(String.starts_with(w, "hello w")))
    IO.print(Bool.show(String.eq(w, "hello wor0ld")))
    IO.print(String.trim_start(String.append("  \t ", w)))
    IO.print(U32.show(U32.add(4000000000, U32.from_nat(z))))
    IO.print(U32.hex(U32.add(48879, U32.from_nat(z))))
    IO.print(Nat.show(Nat.add(Nat.mul(1000000n, 1000000n), z)))

#|35
#|11
#|36
#|aaaz
#|none
#|7
#|<x-ab0
#|<xxp
#|2050627040
#|60
#|2178309
#|144
#|321
#|54321
#|21
#|2
#|2c.c.c.c.!
#|3c.c.c!
#|2c.c!
#|1957
#|3072
#|53
#|8044
#|8080
#|63
#|12
#|408
#|452
#|True
#|False
#|True
#|True
#|hello wor0ld
#|4000000000
#|beef
#|1000000000000
