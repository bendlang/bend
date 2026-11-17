import Base

type Chain is Data:
  CNil{}
  CCons{k: U32, t: Chain}

def sum(c: Chain, acc: U32) -> U32:
  match c:
    case CNil{}:
      acc
    case CCons{h, t}:
      sum(t, (acc + h : U32))

def has(c: Chain, +k: U32, f: Bool) -> Bool:
  match c f:
    case _ True{}:
      True{}
    case CNil{} False{}:
      False{}
    case CCons{h, t} False{}:
      has(t, k, U32.is_eq(h, k))

# the hashmap insert
def put(a: Array<Chain>, b: U32, k: U32, c: Chain, found: Bool) -> Array<Chain>:
  match found:
    case True{}:
      a
    case False{}:
      Array.set(Chain, a, b, CCons{k, c})

def ins(+b: U32, +k: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, +c0) = r
  put(a, b, k, c0, has(c0, k, False{}))

# the value written back twice into the cons
def dup(+b: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, +c) = r
  Array.set(Chain, a, b, CCons{sum(c, 0), CCons{7, c}})

# written to another slot: the old slot keeps it
def other(+b: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, c) = r
  Array.set(Chain, a, (b + 1 : U32), CCons{5, c})

# the slot is cleared, the value dropped
def clear(+b: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, c) = r
  Array.set(Chain, a, b, CNil{})

# two reads of one slot, one written back
def two.go(+b: U32, c1: Chain, r: Array<Chain> & Chain) -> U32 & Array<Chain>:
  (a, c2) = r
  (sum(c2, 0), Array.set(Chain, a, b, CCons{3, c1}))

def two(+b: U32, r: Array<Chain> & Chain) -> U32 & Array<Chain>:
  (a, c1) = r
  two.go(b, c1, Array.get(Chain, a, b))

# used after the write
def after(+b: U32, r: Array<Chain> & Chain) -> U32 & Array<Chain>:
  (a, +c) = r
  a2 = Array.set(Chain, a, b, CCons{4, c})
  (sum(c, 0), a2)

# #2135 x #2149: the same helpers called each turn of a loop whose index is a
# counter bounded by its countdown: the loop has a mask-free copy (the count fits
# the Array) and a masked one (it does not).
def lp_ins(n: Nat, +j: U32, a: Array<Chain>) -> Array<Chain>:
  match n:
    case 0n:
      a
    case 1n+p:
      lp_ins(p, U32.inc(j), ins(j, (j * 5 % 13 : U32), Array.get(Chain, a, j)))

def lp_dup(n: Nat, +j: U32, a: Array<Chain>) -> Array<Chain>:
  match n:
    case 0n:
      a
    case 1n+p:
      lp_dup(p, U32.inc(j), dup(j, Array.get(Chain, a, j)))

def lp_other(n: Nat, +j: U32, a: Array<Chain>) -> Array<Chain>:
  match n:
    case 0n:
      a
    case 1n+p:
      lp_other(p, U32.inc(j), other(j, Array.get(Chain, a, j)))

def lp_clear(n: Nat, +j: U32, a: Array<Chain>) -> Array<Chain>:
  match n:
    case 0n:
      a
    case 1n+p:
      lp_clear(p, U32.add(j, 2), clear(j, Array.get(Chain, a, j)))

@unsafe
def lp_two(n: Nat, +j: U32, r: U32 & Array<Chain>) -> U32 & Array<Chain>:
  match n:
    case 0n:
      r
    case 1n+p:
      (s, a) = r
      lp_two.go(p, j, s, two(j, Array.get(Chain, a, j)))

@unsafe
def lp_two.go(n: Nat, +j: U32, s: U32, r: U32 & Array<Chain>) -> U32 & Array<Chain>:
  (t, a) = r
  lp_two(n, U32.inc(j), ((s * 31 + t : U32), a))

@unsafe
def lp_after(n: Nat, +j: U32, r: U32 & Array<Chain>) -> U32 & Array<Chain>:
  match n:
    case 0n:
      r
    case 1n+p:
      (s, a) = r
      lp_after.go(p, j, s, after(j, Array.get(Chain, a, j)))

@unsafe
def lp_after.go(n: Nat, +j: U32, s: U32, r: U32 & Array<Chain>) -> U32 & Array<Chain>:
  (t, a) = r
  lp_after(n, U32.inc(j), ((s * 31 + t : U32), a))

def tot.go(acc: U32, r: Array<Chain> & Chain) -> Array<Chain> & U32:
  (a, c) = r
  (a, (acc * 31 + sum(c, 0) : U32))

# a read lent across a write to another slot and a drop of the Array
def lp_len(n: Nat, +j: U32, r: Array<Chain> & U32) -> U32:
  match n:
    case 0n:
      (a, acc) = r
      acc
    case 1n+p:
      (a, acc) = r
      lp_len(p, U32.inc(j), tot.go(acc, Array.get(Chain, a, j)))

def tot(n: Nat, a: Array<Chain>) -> U32:
  lp_len(n, 0, (a, 0))

def fst(n: Nat, r: U32 & Array<Chain>) -> U32:
  (s, a) = r
  (s + tot(n, a) : U32)

def base(+n: Nat) -> Array<Chain>:
  lp_ins(Nat.mul(n, 3n), 0, Array.new(Chain, 3n, CNil{}))

def show(+one: Nat) -> String:
  +lo = Nat.mul(6n, one)
  +hi = Nat.mul(21n, one)
  +all = Nat.mul(8n, one)
  String.join([
    U32.show(tot(all, base(lo))),
    U32.show(tot(hi, base(hi))),
    U32.show(tot(all, lp_dup(lo, 1, base(lo)))),
    U32.show(tot(all, lp_dup(hi, 1, base(lo)))),
    U32.show(tot(all, lp_other(lo, 0, base(lo)))),
    U32.show(tot(all, lp_other(hi, 3, base(lo)))),
    U32.show(tot(all, lp_clear(Nat.mul(3n, one), 0, base(lo)))),
    U32.show(tot(all, lp_clear(hi, 1, base(lo)))),
    U32.show(fst(all, lp_two(lo, 0, (1, base(lo))))),
    U32.show(fst(all, lp_two(hi, 2, (1, base(lo))))),
    U32.show(fst(all, lp_after(lo, 0, (1, base(lo))))),
    U32.show(fst(all, lp_after(hi, 5, (1, base(lo)))))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|334949254
#|714896847
#|1861077436
#|3172612528
#|4128041345
#|2945482220
#|3094793805
#|1535123024
#|715352387
#|1376393208
#|3375249827
#|3030483298
