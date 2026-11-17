# a statement's call unfolds through the matches its constant arguments
# decide, in a def that is not flat too. Each line below is one shape:
# (1) a fold over a constant list whose step is a call that is not flat;
# (2) a constant argument the taken arm drops, beside a value it frees;
# (3) a value the caller keeps, shared by two arguments of a def that
#     walks it, and walked again by the caller after; the same value
#     handed to an arm that drops it, while the caller keeps it and at
#     its last use;
# (4) a def with no match of its own that unfolds through its callee, the
#     class of its constant character decided by ops on constants;
# (5) a def that forks, over a constant tree: it stays a call, as its
#     caller would fork with it;
# (6) a count too long for the fuel (the call stays a call), and a call
#     tree that is (fib);
# (7) Base's String.append and List.append on literals, and a literal
#     list walked by a def that borrows it;
# (8) a pair returned unboxed, and a constant matched two levels deep;
# (9) a template expanded as the lexer bench's is, with a slot that calls
#     a recursive builder.
# n comes from a list built and walked at run time, so no result is a
# constant C could fold. Every round prints the same line, and frees
# poisoned (CCC_OVERRIDE_OPTIONS=+-DBEND_POISON) read back wrong.
import Base

type KL is Data:
  KNil{}
  KCon{k: U32, t: KL}

type Tree is Data:
  Lf{v: U32}
  Nd{a: Tree, b: Tree}

type Op is Data:
  Add{}
  Mul{}
  Skip{}

def kl(n: Nat, +x: U32, acc: KL) -> KL:
  match n:
    case 0n:
      acc
    case 1n+p:
      kl(p, U32.inc(x), KCon{x, acc})

def kl_sum(c: KL, acc: U32) -> U32:
  match c:
    case KNil{}:
      acc
    case KCon{k, t}:
      kl_sum(t, U32.add(acc, k))

# not flat: the recursion is not a tail call
def deep(c: KL) -> U32:
  match c:
    case KNil{}:
      0
    case KCon{k, t}:
      U32.add(k, deep(t))

# a list of n words built at run time, n too large to unroll
def far(+n: U32) -> KL:
  kl(U32.to_nat(U32.add(U32.and(n, 7), 3)), n, KNil{})

def step(o: Op, a: U32, w: KL) -> U32:
  match o:
    case Add{}:
      U32.add(a, deep(w))
    case Mul{}:
      U32.mul(a, kl_sum(w, 3))
    case Skip{}:
      a

# (1) a fold over a constant list: its step is not flat either
def fold(ops: List<Op>, +x: U32) -> U32:
  match ops:
    case Nil{}:
      x
    case Con{o, t}:
      step(o, fold(t, U32.inc(x)), far(x))

# (2) the arm for False drops both lists, the one for True walks one
def pick(b: Bool, x: KL, y: KL, +n: U32) -> KL:
  match b:
    case False{}:
      far(n)
    case True{}:
      KCon{U32.add(deep(y), n), x}

# (3) w is read by both arguments and walked after, here and by the caller
def both(o: Op, +w: KL, n: U32) -> U32:
  step(o, U32.add(deep(w), n), w)

# (4) wrap has no match; cls decides by comparisons on the constant
def cls.go(l: Bool, d: Bool) -> Op:
  match l d:
    case True{} _:
      Add{}
    case _ True{}:
      Mul{}
    case _ _:
      Skip{}

def cls(+c: U32) -> Op:
  cls.go(U32.is_le(97, c) && U32.is_le(c, 122), U32.is_eq(c, 48))

def wrap(+c: U32, a: U32, +n: U32) -> U32:
  step(cls(c), a, far(U32.add(n, c)))

# (5) a fork per node of a constant tree: not unfolded
def tsum(t: Tree, +n: U32) -> U32:
  match t:
    case Lf{v}:
      +w = v
      kl_sum(far(U32.add(n, w)), w)
    case Nd{a, b}:
      l r = tsum(a, n) tsum(b, U32.inc(n))
      U32.add(l, U32.mul(r, 3))

# (6) the fuel: neither unfolds whole (fib's tree has 2^14 leaves)
def count(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      U32.add(kl_sum(far(x), 1), count(p, U32.xor(x, 5)))

def fib(+n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      U32.add(fib(p, x), fib(p, U32.inc(x)))

# (7) a literal walked by a def that only reads it
def reads(xs: List<U32>, +n: U32) -> U32:
  match xs:
    case Nil{}:
      n
    case Con{h, t}:
      U32.add(kl_sum(far(h), n), reads(t, U32.inc(n)))

def ksum(xs: List<U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      ksum(t, U32.add(acc, h))

def slen(s: String, acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{Chr{c}, t}:
      slen(t, U32.add(U32.mul(acc, 31), c))

# (8) an unboxed pair out of a def that is not flat, joined by a helper
def fst(r: U32 & U32) -> U32:
  (x, y) = r
  U32.add(U32.mul(x, 65537), y)

def two.join(l: U32 & U32, +r: U32, +n: U32) -> U32 & U32:
  (a, b) = l
  (U32.add(a, r), U32.xor(b, U32.mul(n, r)))

def two(t: Tree, +n: U32) -> U32 & U32:
  match t:
    case Lf{v}:
      +w = v
      (w, kl_sum(far(n), w))
    case Nd{a, b}:
      two.join(two(a, n), fst(two(b, U32.inc(n))), n)

# (9) the template: a slot calls a recursive builder in front of the rest
def digits(n: Nat, +t: U32, rest: String) -> String:
  match n:
    case 0n:
      rest
    case 1n+p:
      SCon{Chr{U32.add(48, U32.mod(t, 10))}, digits(p, U32.div(t, 10), rest)}

def gen.at(hole: Bool, c: U32, +t: U32, rest: String) -> String:
  match hole:
    case True{}:
      digits(U32.to_nat(U32.add(1, U32.and(t, 3))), t, rest)
    case False{}:
      SCon{Chr{c}, rest}

def gen.one(+c: U32, t: U32, rest: String) -> String:
  gen.at(U32.is_eq(c, 35), c, t, rest)

def gen(tpl: String, +s: U32, +k: U32) -> String:
  match tpl:
    case SNil{}:
      SNil{}
    case SCon{Chr{c}, u}:
      gen.one(c, U32.mul(U32.add(s, k), 2654435761), gen(u, s, U32.inc(k)))

def round(+n: U32) -> U32:
  +a = fold([Add{}, Mul{}, Skip{}, Add{}, Mul{}], n)
  +b = kl_sum(pick(False{}, far(n), far(a), n), kl_sum(pick(True{}, far(n),
    far(a), n), a))
  +w = far(b)
  +v = both(Skip{}, w, n)
  +c = U32.add(both(Mul{}, w, n), U32.add(both(Add{}, w, v), kl_sum(w, 0)))
  +u = far(c)
  +q = U32.add(both(Add{}, u, c), both(Skip{}, u, c))
  +d = wrap(107, wrap(48, wrap(32, q, n), n), n)
  +e = tsum(Nd{Nd{Lf{1}, Nd{Lf{2}, Lf{3}}}, Nd{Lf{4}, Lf{5}}}, d)
  +f = U32.add(count(3000n, e), fib(14n, e))
  +g = reads([3, 1, 4, 1, 5, 9, 2, 6], f)
  +h = ksum(List.append(&1, U32, [1, 2, 3], [4, 5, 6]), g)
  +i = slen("ab" ++ "cd" ++ U32.show(h) ++ "ef", h)
  +j = fst(two(Nd{Nd{Lf{7}, Lf{8}}, Nd{Lf{9}, Nd{Lf{10}, Lf{11}}}}, i))
  slen(gen("x = # + ( # * # ) ;", j, 0), j)

def base() -> U32:
  kl_sum(kl(1000n, 1, KNil{}), 0)

def main() -> IO(Unit):
  IO.print(U32.show(round(base())) ++ " " ++ U32.show(round(base()))
    ++ " " ++ U32.show(round!(base())))

#|1678529528 1678529528 1678529528
