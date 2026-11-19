# A match on a box tests a later enumeration first (a Cmp, a Bool, or a field
# of a record argument) when, for some value of it, the box is re-formed on
# every arm; and a match whose arms all re-form their node does not open it.
# Each def below meets that rule's edges at run time, on leaves and nodes,
# owned, lent and shared trees: a child read on one value and kept on the
# others, a default row, the node's own enumeration field matched first, an
# erased field, two enumerations of one record, arms that re-form the node but
# differ around it, a node re-formed twice or dropped.
import Base

type Color is Data:
  Red{}
  Black{}
  Blue{}

type T is Data:
  L{}
  N{c: Color, l: T, k: U32, r: T}

type E is Data:
  EL{}
  EN{-n: Nat, l: E, b: Bool, k: U32, r: E}

type P is Data:
  P{a: Bool, b: Bool, x: U32}

def col(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Black{}:
      2
    case Blue{}:
      3

def dig(t: T, acc: U32) -> U32:
  match t:
    case L{}:
      U32.add(U32.mul(acc, 31), 7)
    case N{c, l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 31), col(c))), 131), k))

def edig(t: E, acc: U32) -> U32:
  match t:
    case EL{}:
      U32.add(U32.mul(acc, 29), 5)
    case EN{n, l, b, k, r}:
      edig(r, U32.add(U32.mul(edig(l, U32.add(U32.mul(acc, 29), Bool.to_u32(b))), 137), k))

def pick.go(m: U32) -> Color:
  match m:
    case 0:
      Red{}
    case 1:
      Black{}
    case _:
      Blue{}

def pick(i: U32) -> Color:
  pick.go(U32.mod(i, 3))

def gen(+d: Nat, +i: U32) -> T:
  match d:
    case 0n:
      L{}
    case 1n+e:
      N{pick(i), gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

# l's fields read on LT, l kept on GT and EQ; r the other way round
def ins(t: T, o: Cmp, +k: U32) -> T:
  match t o:
    case L{} _:
      N{Red{}, L{}, k, L{}}
    case N{c, L{}, kx, r} LT{}:
      N{c, N{Red{}, L{}, k, L{}}, kx, r}
    case N{c, N{c2, a, +ky, b}, kx, r} LT{}:
      N{c, ins(N{c2, a, ky, b}, U32.cmp(k, ky), k), kx, r}
    case N{c, l, kx, L{}} GT{}:
      N{c, l, kx, N{Blue{}, L{}, k, L{}}}
    case N{c, l, kx, N{c2, a, +ky, b}} GT{}:
      N{c, l, kx, ins(N{c2, a, ky, b}, U32.cmp(k, ky), k)}
    case N{c, l, kx, r} EQ{}:
      N{Black{}, l, kx, r}

# the child's colour matched first
def ins2(t: T, o: Cmp, +k: U32) -> T:
  match t o:
    case L{} _:
      N{Black{}, L{}, k, L{}}
    case N{c, N{Red{}, a, +ky, b}, kx, r} LT{}:
      N{Blue{}, ins2(N{Red{}, a, ky, b}, U32.cmp(k, ky), k), kx, r}
    case N{c, N{c2, a, +ky, b}, kx, r} LT{}:
      N{c, ins2(N{c2, a, ky, b}, U32.cmp(k, ky), k), kx, r}
    case N{c, L{}, kx, r} LT{}:
      N{c, N{Red{}, L{}, k, L{}}, kx, r}
    case N{c, l, kx, N{Black{}, a, +ky, b}} GT{}:
      N{Red{}, l, kx, ins2(N{Black{}, a, ky, b}, U32.cmp(k, ky), k)}
    case N{c, l, kx, N{c2, a, +ky, b}} GT{}:
      N{c, l, kx, ins2(N{c2, a, ky, b}, U32.cmp(k, ky), k)}
    case N{c, l, kx, L{}} GT{}:
      N{c, l, kx, N{Red{}, L{}, k, L{}}}
    case N{c, l, kx, r} EQ{}:
      N{c, r, kx, l}

# a lent tree
def has(t: T, o: Cmp, +k: U32) -> U32:
  match t o:
    case L{} _:
      0
    case N{_, L{}, _, _} LT{}:
      1
    case N{_, N{c2, a, +ky, b}, _, _} LT{}:
      U32.add(has(N{c2, a, ky, b}, U32.cmp(k, ky), k), 2)
    case N{_, _, _, L{}} GT{}:
      3
    case N{_, _, _, N{c2, a, +ky, b}} GT{}:
      U32.add(has(N{c2, a, ky, b}, U32.cmp(k, ky), k), 5)
    case N{c, _, _, _} EQ{}:
      U32.add(col(c), 100)

# an erased field before the children
def eins(t: E, o: Cmp, +k: U32) -> E:
  match t o:
    case EL{} _:
      EN{0n, EL{}, True{}, k, EL{}}
    case EN{n, EN{m, a, b2, +ky, c}, b, kx, r} LT{}:
      EN{n, eins(EN{m, a, b2, ky, c}, U32.cmp(k, ky), k), b, kx, r}
    case EN{n, EL{}, b, kx, r} LT{}:
      EN{n, EN{0n, EL{}, False{}, k, EL{}}, b, kx, r}
    case EN{n, l, b, kx, EN{m, a, b2, +ky, c}} GT{}:
      EN{n, l, b, kx, eins(EN{m, a, b2, ky, c}, U32.cmp(k, ky), k)}
    case EN{n, l, b, kx, EL{}} GT{}:
      EN{n, l, b, kx, EN{0n, EL{}, True{}, k, EL{}}}
    case EN{n, l, b, kx, r} EQ{}:
      EN{n, l, Bool.not(b), kx, r}

def root(t: T) -> T & U32:
  match t:
    case L{}:
      (L{}, 0)
    case N{c, l, +k, r}:
      (N{c, l, k, r}, k)

# the selector computed from the tree
def ins_at(p: T & U32, +k: U32) -> T:
  match p:
    case (t, kr):
      ins(t, U32.cmp(k, kr), k)

def ins2_at(p: T & U32, +k: U32) -> T:
  match p:
    case (t, kr):
      ins2(t, U32.cmp(k, kr), k)

def build(+n: Nat, t: T) -> T:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins_at(root(t), x))

def build2(+n: Nat, t: T) -> T:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 40503), 977)
      build2(m, ins2_at(root(t), x))

def probe(+t: T, +n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 7919), 1000)
      probe(t, m, U32.add(U32.mul(acc, 3), has(t, U32.cmp(x, 500), x)))

def ebuild(+n: Nat, t: E) -> E:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      ebuild(m, eins(t, U32.cmp(x, 500), x))

# both arms hand back their node, the answers differ
def tag(t: T) -> U32 & T:
  match t:
    case L{}:
      (1, L{})
    case N{c, l, k, r}:
      (2, N{c, l, k, r})

# a default row
def dflt(t: T) -> U32 & T:
  match t:
    case N{c, l, k, r}:
      (5, N{c, l, k, r})
    case t0:
      (6, t0)

# the node re-formed, what is around it differs
def wrap(t: T, b: Bool) -> T:
  match t b:
    case N{c, l, k, r} True{}:
      N{Blue{}, N{c, l, k, r}, 1, L{}}
    case N{c, l, k, r} False{}:
      N{Red{}, L{}, 2, N{c, l, k, r}}
    case L{} _:
      N{Black{}, L{}, 3, L{}}

# split on the colour: each value re-forms (no match), or all turn red
def same3(t: T) -> T:
  match t:
    case N{Red{}, l, k, r}:
      N{Red{}, l, k, r}
    case N{Black{}, l, k, r}:
      N{Black{}, l, k, r}
    case t0:
      t0

def allred(t: T) -> T:
  match t:
    case N{Red{}, l, k, r}:
      N{Red{}, l, k, r}
    case N{Black{}, l, k, r}:
      N{Red{}, l, k, r}
    case N{Blue{}, l, k, r}:
      N{Red{}, l, k, r}
    case L{}:
      L{}

# re-formed twice; re-formed or dropped
def twice(t: T) -> T & T:
  match t:
    case L{}:
      (L{}, L{})
    case N{+c, +l, +k, +r}:
      (N{c, l, k, r}, N{c, l, k, r})

def keep(t: T, b: Bool) -> T:
  match t b:
    case N{c, l, k, r} True{}:
      N{c, l, k, r}
    case N{c, l, k, r} False{}:
      L{}
    case L{} _:
      L{}

# two enumerations of one flat record
def two(t: T, p: P) -> T:
  match t p:
    case N{c, N{c2, a, k2, b2}, k, r} P{True{}, False{}, x}:
      N{c2, a, U32.add(k2, x), N{c, b2, k, r}}
    case N{c, l, k, N{c2, a, k2, b2}} P{False{}, True{}, x}:
      N{c2, N{c, l, k, a}, U32.mul(k2, x), b2}
    case N{c, l, k, r} P{True{}, True{}, x}:
      N{c, r, U32.sub(k, x), l}
    case t0 _:
      t0

# the node kept on one value of b, read on the other; a is never tested
def one(t: T, p: P) -> T:
  match t p:
    case N{c, l, k, r} P{_, False{}, x}:
      N{c, l, U32.add(k, x), r}
    case t0 _:
      t0

# the enumeration rides in a tuple, as in Base's Map
def bit(+k: U32, p: U32) -> U32 & Bool:
  (k, U32.is_eq(U32.and(U32.shrn(k, U32.to_nat(p)), 1), 1))

def put(t: T, kb: U32 & Bool) -> T:
  match t kb:
    case N{c, L{}, p, r} Tuple{k, False{}}:
      N{c, N{Red{}, L{}, k, L{}}, p, r}
    case N{c, N{c2, a, +q, b}, p, r} Tuple{k, False{}}:
      N{c, put(N{c2, a, q, b}, bit(k, U32.mod(q, 31))), p, r}
    case N{c, l, p, L{}} Tuple{k, True{}}:
      N{c, l, p, N{Blue{}, L{}, k, L{}}}
    case N{c, l, p, N{c2, a, +q, b}} Tuple{k, True{}}:
      N{c, l, p, put(N{c2, a, q, b}, bit(k, U32.mod(q, 31)))}
    case t0 _:
      t0

def tsum(p: U32 & T) -> U32:
  match p:
    case (a, t):
      U32.add(U32.mul(a, 1000003), dig(t, 9))

def psum(p: T & T) -> U32:
  match p:
    case (a, b):
      U32.add(dig(a, 1), U32.mul(dig(b, 2), 3))

# every shape on every subtree, leaves included
def each(t: T, +i: U32) -> U32:
  match t:
    case L{}:
      U32.add(i, 11)
    case N{c, +l, +k, +r}:
      +j = U32.add(U32.mul(i, 7), k)
      U32.add(U32.add(U32.add(tsum(tag(l)), tsum(dflt(r))), U32.add(dig(wrap(l, U32.is_eq(U32.mod(j, 2), 0)), 3), dig(allred(r), 4))),
        U32.add(U32.add(U32.add(dig(two(l, P{U32.is_eq(U32.mod(j, 3), 0), U32.is_eq(U32.mod(j, 5), 0), j}), 5), dig(same3(keep(r, U32.is_eq(U32.mod(j, 4), 1))), 6)),
          U32.add(U32.add(psum(twice(l)), dig(put(r, bit(j, U32.mod(k, 31))), 8)),
            dig(one(r, P{U32.is_eq(U32.mod(j, 2), 1), U32.is_eq(U32.mod(j, 7), 3), k}), 10))), U32.add(U32.mul(each(l, j), 3), each(r, U32.add(j, 1)))))

def main() -> U32:
  +t = build(120n, L{})
  +a = ins(t, LT{}, 3)
  +b = ins(t, GT{}, 997)
  +c = build2(80n, t)
  U32.add(U32.add(U32.add(dig(t, 1), dig(a, 2)), U32.add(dig(b, 3), dig(c, 4))),
    U32.add(U32.add(probe(c, 150n, 9), edig(ebuild(60n, EL{}), 2)), each(gen(5n, 1), 1)))

#|94322643
