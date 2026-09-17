# An access-control service keeps an audit log of Grant and Revoke
# actions. The log is a rope: a leaf holds one action, a node holds two
# halves and caches the number of actions under them, so the count is
# O(1) and the halves replay in parallel. undo(log, k) drops the last k
# actions: the right half first, what is left of k off the left half.
# LAW: two undos are one undo of the summed count, and undo keeps the
# cached counts true.

import Base

type Act is Data:
  Grant{p: Nat}
  Revoke{p: Nat}

type Log is Data:
  Emp{}
  One{e: Act}
  Cat{n: Nat, l: Log, r: Log}

# the cached count of actions
def size(t: Log) -> Nat:
  match t:
    case Emp{}:
      0n
    case One{e}:
      1n
    case Cat{n, l, r}:
      n

# joins two logs; an empty half is dropped
def cat.go(+l: Log, +r: Log) -> Log:
  match r:
    case Emp{}:
      l
    case r:
      Cat{Nat.add(size(l), size(r)), l, r}

def cat(+l: Log, +r: Log) -> Log:
  match l:
    case Emp{}:
      r
    case l:
      cat.go(l, r)

# drops the last k actions
def undo(t: Log, +k: Nat) -> Log:
  match t:
    case Emp{}:
      Emp{}
    case One{e}:
      match k:
        case 0n:
          One{e}
        case 1n+p:
          Emp{}
    case Cat{n, l, +r}:
      cat(undo(l, Nat.sub(k, size(r))), undo(r, k))

# every node caches the count of its halves
def WF(t: Log) -> Type:
  match t:
    case Emp{}:
      Unit
    case One{e}:
      Unit
    case Cat{n, l, r}:
      {Nat.add(size(l), size(r)) == n : Nat} & WF(l) & WF(r)

# LAW: undoing b actions, then a more, is undoing a+b actions
law undo_undo:
  for +t: Log
  for +a: Nat
  for +b: Nat
  for w: WF(t)
  {undo(undo(t, b), a) == undo(t, Nat.add(a, b)) : Log}

# LAW: undo keeps the cached counts true
law undo_wf:
  for +t: Log
  for +k: Nat
  for w: WF(t)
  WF(undo(t, k))

# solution

def add_zero(a: Nat) -> {a == Nat.add(a, 0n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def add_succ(a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def zero_sub(b: Nat) -> {0n == Nat.sub(0n, b) : Nat}:
  match b:
    case 0n:
      {==}
    case 1n+p:
      {==}

# a plus zero, minus s, is a minus s plus zero
def sub_add_zero(a: Nat, s: Nat) -> {Nat.add(Nat.sub(a, s), 0n) == Nat.sub(Nat.add(a, 0n), s) : Nat}:
  match a s:
    case 0n 0n:
      {==}
    case 0n 1n+s0:
      {==}
    case 1n+a0 0n:
      {==}
    case 1n+a0 1n+s0:
      sub_add_zero(a0, s0)

# what a drops after b took its share of s, plus what b had left,
# is what a+b drop
def sub_split(+b: Nat, +s: Nat, +a: Nat) -> {Nat.add(Nat.sub(a, Nat.sub(s, b)), Nat.sub(b, s)) == Nat.sub(Nat.add(a, b), s) : Nat}:
  match b s:
    case 0n 0n:
      match a:
        case 0n:
          {==}
        case 1n+a0:
          {==}
    case 0n 1n+s0:
      match a:
        case 0n:
          {==}
        case 1n+a0:
          sub_add_zero(a0, s0)
    case 1n+b0 0n:
      match a:
        case 0n:
          {==}
        case 1n+a0:
          {==}
    case 1n+b0 1n+s0:
      %add_succ(a, b0) : {Nat.add(Nat.sub(a, Nat.sub(s0, b0)), Nat.sub(b0, s0)) == Nat.sub(_, 1n+s0) : Nat}
      sub_split(b0, s0, a)

def cat_emp(t: Log) -> {t == cat(t, Emp{}) : Log}:
  match t:
    case Emp{}:
      {==}
    case One{e}:
      {==}
    case Cat{n, l, r}:
      {==}

# a join with a kept left half: undo walks into it as into a node, its
# count is the sum, and it is well formed
def cat_go(+l: Log, r: Log, wl: WF(l), wr: WF(r), +a: Nat) -> {undo(cat.go(l, r), a) == cat(undo(l, Nat.sub(a, size(r))), undo(r, a)) : Log} & {size(cat.go(l, r)) == Nat.add(size(l), size(r)) : Nat} & WF(cat.go(l, r)):
  match r a:
    case Emp{} 0n:
      (cat_emp(undo(l, 0n)), add_zero(size(l)), wl)
    case Emp{} 1n+p:
      (cat_emp(undo(l, 1n+p)), add_zero(size(l)), wl)
    case One{e} a:
      ({==}, {==}, ({==}, wl, wr))
    case Cat{n, x, y} a:
      ({==}, {==}, ({==}, wl, wr))

# a join: undo walks into it as into a node, its count is the sum, and
# it is well formed
def cat_cat(+a: Nat, l: Log, r: Log, wl: WF(l), wr: WF(r)) -> {undo(cat(l, r), a) == cat(undo(l, Nat.sub(a, size(r))), undo(r, a)) : Log} & {size(cat(l, r)) == Nat.add(size(l), size(r)) : Nat} & WF(cat(l, r)):
  match l:
    case Emp{}:
      ({==}, {==}, wr)
    case One{e}:
      cat_go(One{e}, r, wl, wr, a)
    case Cat{n, x, y}:
      cat_go(Cat{n, x, y}, r, wl, wr, a)

# the node case of undo_both, undo half: the halves' undo claims, at what
# the undo of b leaves of them, give the node's
def cat_both.undo(+a: Nat, +b: Nat, +l: Log, +r: Log, +l2: Log, +r2: Log,
  el: {undo(l2, Nat.sub(a, Nat.sub(size(r), b))) == undo(l, Nat.add(Nat.sub(a, Nat.sub(size(r), b)), Nat.sub(b, size(r)))) : Log},
  er: {undo(r2, a) == undo(r, Nat.add(a, b)) : Log},
  u: {undo(cat(l2, r2), a) == cat(undo(l2, Nat.sub(a, Nat.sub(size(r), b))), undo(r2, a)) : Log})
  -> {undo(cat(l2, r2), a) == cat(undo(l, Nat.sub(Nat.add(a, b), size(r))), undo(r, Nat.add(a, b))) : Log}:
  %er : {undo(cat(l2, r2), a) == cat(undo(l, Nat.sub(Nat.add(a, b), size(r))), _) : Log}
  %sub_split(b, size(r), a) : {undo(cat(l2, r2), a) == cat(undo(l, _), undo(r2, a)) : Log}
  %el : {undo(cat(l2, r2), a) == cat(_, undo(r2, a)) : Log}
  u

# the node case of undo_both, size half: the halves' size claims give the node's
def cat_both.size(-n: Nat, +b: Nat, +l: Log, +r: Log, +l2: Log, +r2: Log,
  e: {Nat.add(size(l), size(r)) == n : Nat},
  sl: {size(l2) == Nat.sub(size(l), Nat.sub(b, size(r))) : Nat},
  s: {size(cat(l2, r2)) == Nat.add(size(l2), Nat.sub(size(r), b)) : Nat})
  -> {size(cat(l2, r2)) == Nat.sub(n, b) : Nat}:
  %e : {size(cat(l2, r2)) == Nat.sub(_, b) : Nat}
  %sub_split(size(r), b, size(l)) : {size(cat(l2, r2)) == _ : Nat}
  %sl : {size(cat(l2, r2)) == Nat.add(_, Nat.sub(size(r), b)) : Nat}
  s

# the join's claims, with the right half's size spelled as what undo left of r
def cat_both.sr(+a: Nat, +b: Nat, +r: Log, +l2: Log, +r2: Log,
  sr: {size(r2) == Nat.sub(size(r), b) : Nat},
  cc: {undo(cat(l2, r2), a) == cat(undo(l2, Nat.sub(a, size(r2))), undo(r2, a)) : Log} & {size(cat(l2, r2)) == Nat.add(size(l2), size(r2)) : Nat} & WF(cat(l2, r2)))
  -> {undo(cat(l2, r2), a) == cat(undo(l2, Nat.sub(a, Nat.sub(size(r), b))), undo(r2, a)) : Log} & {size(cat(l2, r2)) == Nat.add(size(l2), Nat.sub(size(r), b)) : Nat} & WF(cat(l2, r2)):
  %sr : {undo(cat(l2, r2), a) == cat(undo(l2, Nat.sub(a, _)), undo(r2, a)) : Log} & {size(cat(l2, r2)) == Nat.add(size(l2), _) : Nat} & WF(cat(l2, r2))
  cc

# the node case of undo_both, assembled from the join's claims cc
def cat_both.fin(-n: Nat, +a: Nat, +b: Nat, +l: Log, +r: Log, +l2: Log, +r2: Log,
  e: {Nat.add(size(l), size(r)) == n : Nat},
  el: {undo(l2, Nat.sub(a, Nat.sub(size(r), b))) == undo(l, Nat.add(Nat.sub(a, Nat.sub(size(r), b)), Nat.sub(b, size(r)))) : Log},
  er: {undo(r2, a) == undo(r, Nat.add(a, b)) : Log},
  sl: {size(l2) == Nat.sub(size(l), Nat.sub(b, size(r))) : Nat},
  cc: {undo(cat(l2, r2), a) == cat(undo(l2, Nat.sub(a, Nat.sub(size(r), b))), undo(r2, a)) : Log} & {size(cat(l2, r2)) == Nat.add(size(l2), Nat.sub(size(r), b)) : Nat} & WF(cat(l2, r2)))
  -> {undo(cat(l2, r2), a) == undo(Cat{n, l, r}, Nat.add(a, b)) : Log} & {size(cat(l2, r2)) == Nat.sub(n, b) : Nat} & WF(cat(l2, r2)):
  (u, s, w) = cc
  (cat_both.undo(a, b, l, r, l2, r2, el, er, u), cat_both.size(n, b, l, r, l2, r2, e, sl, s), w)

# the node case of undo_both: the halves' claims, at what the undo of b
# leaves of them, give the node's
def cat_both(-n: Nat, +l: Log, +r: Log, +a: Nat, +b: Nat, +l2: Log, +r2: Log, e: {Nat.add(size(l), size(r)) == n : Nat},
  pl: {undo(l2, Nat.sub(a, Nat.sub(size(r), b))) == undo(l, Nat.add(Nat.sub(a, Nat.sub(size(r), b)), Nat.sub(b, size(r)))) : Log} & {size(l2) == Nat.sub(size(l), Nat.sub(b, size(r))) : Nat} & WF(l2),
  pr: {undo(r2, a) == undo(r, Nat.add(a, b)) : Log} & {size(r2) == Nat.sub(size(r), b) : Nat} & WF(r2))
  -> {undo(cat(l2, r2), a) == undo(Cat{n, l, r}, Nat.add(a, b)) : Log} & {size(cat(l2, r2)) == Nat.sub(n, b) : Nat} & WF(cat(l2, r2)):
  (el, sl, wl) = pl
  (er, sr, wr) = pr
  cat_both.fin(n, a, b, l, r, l2, r2, e, el, er, sl, cat_both.sr(a, b, r, l2, r2, sr, cat_cat(a, l2, r2, wl, wr)))

# the strengthened claim: on a true count, two undos are one undo,
# undoing b actions drops b from the count, and the count stays true
def undo_both(+t: Log, +a: Nat, +b: Nat, w: WF(t)) -> {undo(undo(t, b), a) == undo(t, Nat.add(a, b)) : Log} & {size(undo(t, b)) == Nat.sub(size(t), b) : Nat} & WF(undo(t, b)):
  match t a b:
    case Emp{} a b:
      ({==}, zero_sub(b), Unit{})
    case One{e} 0n 0n:
      ({==}, {==}, Unit{})
    case One{e} 0n 1n+q:
      ({==}, zero_sub(q), Unit{})
    case One{e} 1n+p 0n:
      ({==}, {==}, Unit{})
    case One{e} 1n+p 1n+q:
      ({==}, zero_sub(q), Unit{})
    case Cat{n, l, r} a b:
      (e, wl, wr) = w
      cat_both(n, l, r, a, b, undo(l, Nat.sub(b, size(r))), undo(r, b), e, undo_both(l, Nat.sub(a, Nat.sub(size(r), b)), Nat.sub(b, size(r)), wl), undo_both(r, a, b, wr))

def undo_undo.fst(-t: Log, -a: Nat, -b: Nat, p: {undo(undo(t, b), a) == undo(t, Nat.add(a, b)) : Log} & {size(undo(t, b)) == Nat.sub(size(t), b) : Nat} & WF(undo(t, b))) -> {undo(undo(t, b), a) == undo(t, Nat.add(a, b)) : Log}:
  (x, y) = p
  x

def undo_undo(t, a, b, w):
  undo_undo.fst(t, a, b, undo_both(t, a, b, w))

def undo_wf.trd(-t: Log, -k: Nat, p: {undo(undo(t, k), 0n) == undo(t, k) : Log} & {size(undo(t, k)) == Nat.sub(size(t), k) : Nat} & WF(undo(t, k))) -> WF(undo(t, k)):
  (x, y, z) = p
  z

def undo_wf(t, k, w):
  undo_wf.trd(t, k, undo_both(t, 0n, k, w))
