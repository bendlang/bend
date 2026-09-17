# A game's quiver draws its arrows as stacks of at most 1n+m arrows each:
# the UI pours the count into stacks, and draws the open stack even when
# it is empty. Saving sums the stacks back into the count. LAWS: the
# count survives the round trip, so no arrow is lost or made, and no
# drawn stack holds more than 1n+m arrows.

import Base

def sum(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case x <> rest:
      Nat.add(x, sum(rest))

# pours n more arrows into stacks of at most 1n+m arrows; the open
# stack holds c arrows and has room for r more
def pour(+m: Nat, n: Nat, r: Nat, c: Nat) -> List<Nat>:
  match n:
    case 0n:
      [c]
    case 1n+p:
      match r:
        case 0n:
          c <> pour(m, p, m, 1n)
        case 1n+q:
          pour(m, p, q, 1n+c)

# the stacks that draw n arrows
def split(+m: Nat, n: Nat) -> List<Nat>:
  pour(m, n, 1n+m, 0n)

# LE(a, b): a proof that a <= b
def LE(a: Nat, b: Nat) -> Type:
  match a b:
    case 0n b0:
      Unit
    case 1n+a1 0n:
      Empty
    case 1n+a1 1n+b1:
      LE(a1, b1)

# every stack holds at most 1n+m arrows
def Bounded(m: Nat, xs: List<Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case x <> rest:
      (LE(x, 1n+m) & Bounded(m, rest))

# LAW: the arrows survive the round trip
law split_sum:
  for +m: Nat
  for n: Nat
  {sum(split(m, n)) == n : Nat}

# LAW: no drawn stack overflows
law split_bounded:
  for +m: Nat
  for n: Nat
  Bounded(m, split(m, n))

# solution

def add_succ(a: Nat, -b: Nat) -> {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

# the poured stacks hold the c open arrows and the n poured ones
def sum_pour(+m: Nat, n: Nat, r: Nat, +c: Nat) -> {Nat.add(c, n) == sum(pour(m, n, r, c)) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      match r:
        case 0n:
          %sum_pour(m, p, m, 1n) : {Nat.add(c, 1n+p) == Nat.add(c, _) : Nat}
          {==}
        case 1n+q:
          %sum_pour(m, p, q, 1n+c) : {Nat.add(c, 1n+p) == _ : Nat}
          add_succ(c, p)

def split_sum(m, n):
  %sum_pour(m, n, 1n+m, 0n) : {_ == n : Nat}
  {==}

# c <= c + r
def le_add(c: Nat, -r: Nat) -> LE(c, Nat.add(c, r)):
  match c:
    case 0n:
      Unit{}
    case 1n+p:
      le_add(p, r)

# an open stack whose arrows and room add up to 1n+m holds at most 1n+m
def le_fit(+c: Nat, -r: Nat, -m: Nat, e: {Nat.add(c, r) == 1n+m : Nat}) -> LE(c, 1n+m):
  %e : LE(c, _)
  le_add(c, r)

# while the open stack's arrows and room add up to 1n+m, no stack overflows
def pour_bounded(+m: Nat, n: Nat, +r: Nat, +c: Nat, e: {Nat.add(c, r) == 1n+m : Nat}) -> Bounded(m, pour(m, n, r, c)):
  match n:
    case 0n:
      (le_fit(c, r, m, e), Unit{})
    case 1n+p:
      match r:
        case 0n:
          (le_fit(c, 0n, m, e), pour_bounded(m, p, m, 1n, {==}))
        case 1n+q:
          pour_bounded(m, p, q, 1n+c,
            %add_succ(c, q) : {_ == 1n+m : Nat}
            e)

def split_bounded(m, n):
  pour_bounded(m, n, 1n+m, 0n, {==})
