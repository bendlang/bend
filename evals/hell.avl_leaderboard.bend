# A high-score board keeps its scores in an AVL tree: a binary search
# tree whose insert rotates a node when one side grows two levels
# taller than the other. Scores may repeat; build folds a list of
# scores into a tree and to_list reads them back in order. LAWS: insert
# keeps the search order and adds exactly one score, so build yields an
# ordered tree with the same scores, multiplicities and size as its
# list, and to_list of an ordered tree is sorted and keeps every count.

import Base

type Tree is Data:
  Leaf{}
  Node{l: Tree, k: Nat, r: Tree}

def max(a: Nat, b: Nat) -> Nat:
  match a b:
    case 0n b:
      b
    case 1n+a 0n:
      1n+a
    case 1n+a 1n+b:
      1n+max(a, b)

def height(t: Tree) -> Nat:
  match t:
    case Leaf{}:
      0n
    case Node{l, k, r}:
      1n+max(height(l), height(r))

# LE(a, b): a <= b, as a type: Unit when it holds, Empty when it fails
def LE(a: Nat, b: Nat) -> Data:
  match a b:
    case 0n b:
      Unit
    case 1n+a 0n:
      Empty
    case 1n+a 1n+b:
      LE(a, b)

# the verdict of a comparison, with its evidence
def le_case(x: Nat, k: Nat) -> Or(LE(x, k), LE(k, x)):
  match x k:
    case 0n b:
      Inl{Unit{}}
    case 1n+a 0n:
      Inr{Unit{}}
    case 1n+a 1n+b:
      le_case(a, b)

# the left child becomes the root
def rot_r(l: Tree, k: Nat, r: Tree) -> Tree:
  match l:
    case Leaf{}:
      Node{Leaf{}, k, r}
    case Node{ll, lk, lr}:
      Node{ll, lk, Node{lr, k, r}}

# the right child becomes the root
def rot_l(l: Tree, k: Nat, r: Tree) -> Tree:
  match r:
    case Leaf{}:
      Node{l, k, Leaf{}}
    case Node{rl, rk, rr}:
      Node{Node{l, k, rl}, rk, rr}

# the left child is two levels taller; c compares its own two sides,
# and a taller inner side is rotated out first
def fix_l(ll: Tree, lk: Nat, lr: Tree, k: Nat, r: Tree, c: Cmp) -> Tree:
  match c:
    case LT{}:
      rot_r(rot_l(ll, lk, lr), k, r)
    case c:
      rot_r(Node{ll, lk, lr}, k, r)

def fix_r(l: Tree, k: Nat, rl: Tree, rk: Nat, rr: Tree, c: Cmp) -> Tree:
  match c:
    case GT{}:
      rot_l(l, k, rot_r(rl, rk, rr))
    case c:
      rot_l(l, k, Node{rl, rk, rr})

# c compares height(l) with 1n+height(r): GT means l is two levels taller
def bal_l(l: Tree, k: Nat, r: Tree, c: Cmp) -> Tree:
  match l c:
    case Node{+ll, lk, +lr} GT{}:
      fix_l(ll, lk, lr, k, r, Nat.cmp(height(ll), height(lr)))
    case l c:
      Node{l, k, r}

def bal_r(l: Tree, k: Nat, r: Tree, c: Cmp) -> Tree:
  match r c:
    case Node{+rl, rk, +rr} GT{}:
      fix_r(l, k, rl, rk, rr, Nat.cmp(height(rl), height(rr)))
    case r c:
      Node{l, k, r}

# x goes left when x <= k, else right; il and ir insert it there
def ins.go(-x: Nat, +l: Tree, k: Nat, +r: Tree, c: Or(LE(x, k), LE(k, x)), il: Unit -> Tree, ir: Unit -> Tree) -> Tree:
  match c:
    case Inl{e}:
      +l2 = il(Unit{})
      bal_l(l2, k, r, Nat.cmp(height(l2), 1n+height(r)))
    case Inr{e}:
      +r2 = ir(Unit{})
      bal_r(l, k, r2, Nat.cmp(height(r2), 1n+height(l)))

def insert(+x: Nat, +t: Tree) -> Tree:
  match t:
    case Leaf{}:
      Node{Leaf{}, x, Leaf{}}
    case Node{+l, +k, +r}:
      ins.go(x, l, k, r, le_case(x, k), u => insert(x, l), u => insert(x, r))

def build(xs: List<&2, Nat>) -> Tree:
  match xs:
    case Nil{}:
      Leaf{}
    case h <> t:
      insert(h, build(t))

# Bst(lo, hi, t): every score of t lies in lo..hi and the tree is ordered
def Bst(lo: Nat, hi: Nat, t: Tree) -> Type:
  match t:
    case Leaf{}:
      Unit
    case Node{l, k, r}:
      (LE(lo, k) & LE(k, hi) & Bst(lo, k, l) & Bst(k, hi, r))

# every score of the list is at most top
def InRange(top: Nat, xs: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case h <> t:
      (LE(h, top) & InRange(top, t))

def bump(b: Bool, n: Nat) -> Nat:
  match b:
    case True{}:
      1n+n
    case False{}:
      n

# how many times y occurs in the tree
def count(+y: Nat, t: Tree) -> Nat:
  match t:
    case Leaf{}:
      0n
    case Node{l, k, r}:
      Nat.add(count(y, l), bump(Cmp.is_eq(Nat.cmp(y, k)), count(y, r)))

# how many times y occurs in the list
def tally(+y: Nat, xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      bump(Cmp.is_eq(Nat.cmp(y, h)), tally(y, t))

# the scores in order, in front of acc
def to_list(t: Tree, acc: List<&2, Nat>) -> List<&2, Nat>:
  match t:
    case Leaf{}:
      acc
    case Node{l, k, r}:
      to_list(l, k <> to_list(r, acc))

# Sorted.from(lo, xs): every element is at least lo and the list ascends
def Sorted.from(lo: Nat, xs: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case h <> t:
      (LE(lo, h) & Sorted.from(h, t))

def size(t: Tree) -> Nat:
  match t:
    case Leaf{}:
      0n
    case Node{l, k, r}:
      Nat.add(size(l), 1n+size(r))

def len(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      1n+len(t)

# LAW: insert keeps the tree ordered within its bounds
law insert_ord:
  for +x: Nat
  for +t: Tree
  for +lo: Nat
  for +hi: Nat
  Bst(lo, hi, t) -> LE(lo, x) -> LE(x, hi) -> Bst(lo, hi, insert(x, t))

# LAW: insert adds one occurrence of x and keeps every other count
law insert_count:
  for +y: Nat
  for +x: Nat
  for +t: Tree
  {bump(Cmp.is_eq(Nat.cmp(y, x)), count(y, t)) == count(y, insert(x, t)) : Nat}

# LAW: a board built from scores at most top is ordered within 0..top
law build_ord:
  for +top: Nat
  for +xs: List<&2, Nat>
  for ok: InRange(top, xs)
  Bst(0n, top, build(xs))

# LAW: the board holds each score as many times as the list does
law build_count:
  for +y: Nat
  for +xs: List<&2, Nat>
  {count(y, build(xs)) == tally(y, xs) : Nat}

# LAW: the board lists its scores in ascending order
law to_list_sorted:
  for +top: Nat
  for +t: Tree
  for b: Bst(0n, top, t)
  Sorted.from(0n, to_list(t, Nil{}))

# LAW: the listing holds each score as many times as the tree does
law to_list_count:
  for +y: Nat
  for +t: Tree
  for +acc: List<&2, Nat>
  {Nat.add(count(y, t), tally(y, acc)) == tally(y, to_list(t, acc)) : Nat}

# LAW: the board holds as many scores as its list
law build_size:
  for +xs: List<&2, Nat>
  {size(build(xs)) == len(xs) : Nat}

# solution

# Order
# -----

def le_trans(a: Nat, b: Nat, c: Nat, ab: LE(a, b), bc: LE(b, c)) -> LE(a, c):
  match a b c:
    case 0n b c:
      Unit{}
    case 1n+a 0n c:
      match ab:
    case 1n+a 1n+b 0n:
      match bc:
    case 1n+a 1n+b 1n+c:
      le_trans(a, b, c, ab, bc)

def rot_r_bst(+lo: Nat, +hi: Nat, l: Tree, +k: Nat, -r: Tree, b: Bst(lo, hi, Node{l, k, r})) -> Bst(lo, hi, rot_r(l, k, r)):
  match l:
    case Leaf{}:
      b
    case Node{ll, lk, lr}:
      (lok, +khi, bl, br) = b
      (lolk, +lkk, bll, blr) = bl
      (lolk, le_trans(lk, k, hi, lkk, khi), bll, (lkk, khi, blr, br))

def rot_l_bst(+lo: Nat, +hi: Nat, -l: Tree, +k: Nat, r: Tree, b: Bst(lo, hi, Node{l, k, r})) -> Bst(lo, hi, rot_l(l, k, r)):
  match r:
    case Leaf{}:
      b
    case Node{rl, rk, rr}:
      (+lok, khi, bl, br) = b
      (+krk, rkhi, brl, brr) = br
      (le_trans(lo, k, rk, lok, krk), rkhi, (lok, krk, bl, brl), brr)

def fix_l_bst(+lo: Nat, +hi: Nat, +ll: Tree, +lk: Nat, +lr: Tree, +k: Nat, +r: Tree, c: Cmp, b: Bst(lo, hi, Node{Node{ll, lk, lr}, k, r})) -> Bst(lo, hi, fix_l(ll, lk, lr, k, r, c)):
  match c:
    case LT{}:
      (lok, khi, bl, br) = b
      rot_r_bst(lo, hi, rot_l(ll, lk, lr), k, r, (lok, khi, rot_l_bst(lo, k, ll, lk, lr, bl), br))
    case EQ{}:
      rot_r_bst(lo, hi, Node{ll, lk, lr}, k, r, b)
    case GT{}:
      rot_r_bst(lo, hi, Node{ll, lk, lr}, k, r, b)

def fix_r_bst(+lo: Nat, +hi: Nat, +l: Tree, +k: Nat, +rl: Tree, +rk: Nat, +rr: Tree, c: Cmp, b: Bst(lo, hi, Node{l, k, Node{rl, rk, rr}})) -> Bst(lo, hi, fix_r(l, k, rl, rk, rr, c)):
  match c:
    case GT{}:
      (lok, khi, bl, br) = b
      rot_l_bst(lo, hi, l, k, rot_r(rl, rk, rr), (lok, khi, bl, rot_r_bst(k, hi, rl, rk, rr, br)))
    case LT{}:
      rot_l_bst(lo, hi, l, k, Node{rl, rk, rr}, b)
    case EQ{}:
      rot_l_bst(lo, hi, l, k, Node{rl, rk, rr}, b)

def bal_l_bst(+lo: Nat, +hi: Nat, +l: Tree, +k: Nat, +r: Tree, c: Cmp, b: Bst(lo, hi, Node{l, k, r})) -> Bst(lo, hi, bal_l(l, k, r, c)):
  match l c:
    case Node{+ll, +lk, +lr} GT{}:
      fix_l_bst(lo, hi, ll, lk, lr, k, r, Nat.cmp(height(ll), height(lr)), b)
    case Leaf{} c:
      b
    case Node{ll, lk, lr} LT{}:
      b
    case Node{ll, lk, lr} EQ{}:
      b

def bal_r_bst(+lo: Nat, +hi: Nat, +l: Tree, +k: Nat, +r: Tree, c: Cmp, b: Bst(lo, hi, Node{l, k, r})) -> Bst(lo, hi, bal_r(l, k, r, c)):
  match r c:
    case Node{+rl, +rk, +rr} GT{}:
      fix_r_bst(lo, hi, l, k, rl, rk, rr, Nat.cmp(height(rl), height(rr)), b)
    case Leaf{} c:
      b
    case Node{rl, rk, rr} LT{}:
      b
    case Node{rl, rk, rr} EQ{}:
      b

# the step of insert at a node: the verdict picks the side, and the
# side's own insert is ordered by the hypothesis for that side
def go_bst(+lo: Nat, +hi: Nat, -x: Nat, +l: Tree, +k: Nat, +r: Tree, il: Unit -> Tree, ir: Unit -> Tree, c: Or(LE(x, k), LE(k, x)), b: Bst(lo, hi, Node{l, k, r}), lx: LE(lo, x), xh: LE(x, hi),
  hl: Bst(lo, k, l) -> LE(lo, x) -> LE(x, k) -> Bst(lo, k, il(Unit{})), hr: Bst(k, hi, r) -> LE(k, x) -> LE(x, hi) -> Bst(k, hi, ir(Unit{}))) -> Bst(lo, hi, ins.go(x, l, k, r, c, il, ir)):
  match c:
    case Inl{e}:
      (lok, khi, bl, br) = b
      +l2 = il(Unit{})
      bal_l_bst(lo, hi, l2, k, r, Nat.cmp(height(l2), 1n+height(r)), (lok, khi, hl(bl, lx, e), br))
    case Inr{e}:
      (lok, khi, bl, br) = b
      +r2 = ir(Unit{})
      bal_r_bst(lo, hi, l, k, r2, Nat.cmp(height(r2), 1n+height(l)), (lok, khi, bl, hr(br, e, xh)))

def insert_ord(x, t, lo, hi):
  match t:
    case Leaf{}:
      b => lx => xh => (lx, xh, Unit{}, Unit{})
    case Node{l, k, r}:
      b => lx => xh => go_bst(lo, hi, x, l, k, r, u => insert(x, l), u => insert(x, r), le_case(x, k), b, lx, xh, insert_ord(x, l, lo, k), insert_ord(x, r, k, hi))

def build_ord(top, xs, ok):
  match xs:
    case Nil{}:
      Unit{}
    case h <> t:
      (ht, rest) = ok
      insert_ord(h, build(t), 0n, top)(build_ord(top, t, rest), Unit{}, ht)
# Counts
# ------

def bump_add(b: Bool, -m: Nat, -n: Nat) -> {bump(b, Nat.add(m, n)) == Nat.add(bump(b, m), n) : Nat}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

# a bump moves out of a left sum, and the sum re-associates
def assoc_l(a: Nat, b: Bool, -m: Nat, -n: Nat) -> {Nat.add(Nat.add(a, bump(b, m)), n) == Nat.add(a, bump(b, Nat.add(m, n))) : Nat}:
  match a b:
    case 0n True{}:
      {==}
    case 0n False{}:
      {==}
    case 1n+p b:
      %assoc_l(p, b, m, n) : {1n+Nat.add(Nat.add(p, bump(b, m)), n) == 1n+_ : Nat}
      {==}

def assoc_r(a: Nat, b: Bool, -m: Nat, -n: Nat) -> {Nat.add(a, bump(b, Nat.add(m, n))) == Nat.add(Nat.add(a, bump(b, m)), n) : Nat}:
  match a:
    case 0n:
      bump_add(b, m, n)
    case 1n+p:
      %assoc_r(p, b, m, n) : {1n+Nat.add(p, bump(b, Nat.add(m, n))) == 1n+_ : Nat}
      {==}

# a successor moves into the right of a sum, past a bump
def succ_in(m: Nat, c: Bool, -n: Nat) -> {1n+Nat.add(m, bump(c, n)) == Nat.add(m, bump(c, 1n+n)) : Nat}:
  match m c:
    case 0n True{}:
      {==}
    case 0n False{}:
      {==}
    case 1n+p c:
      %succ_in(p, c, n) : {1n+1n+Nat.add(p, bump(c, n)) == 1n+_ : Nat}
      {==}

def bump_in(b: Bool, c: Bool, m: Nat, -n: Nat) -> {bump(b, Nat.add(m, bump(c, n))) == Nat.add(m, bump(c, bump(b, n))) : Nat}:
  match b:
    case True{}:
      succ_in(m, c, n)
    case False{}:
      {==}

# a rotation keeps every count: it only re-associates the sum
def rot_r_count(+y: Nat, l: Tree, +k: Nat, +r: Tree) -> {count(y, Node{l, k, r}) == count(y, rot_r(l, k, r)) : Nat}:
  match l:
    case Leaf{}:
      {==}
    case Node{+ll, +lk, +lr}:
      assoc_l(count(y, ll), Cmp.is_eq(Nat.cmp(y, lk)), count(y, lr), bump(Cmp.is_eq(Nat.cmp(y, k)), count(y, r)))

def rot_l_count(+y: Nat, +l: Tree, +k: Nat, r: Tree) -> {count(y, Node{l, k, r}) == count(y, rot_l(l, k, r)) : Nat}:
  match r:
    case Leaf{}:
      {==}
    case Node{+rl, +rk, +rr}:
      assoc_r(count(y, l), Cmp.is_eq(Nat.cmp(y, k)), count(y, rl), bump(Cmp.is_eq(Nat.cmp(y, rk)), count(y, rr)))

def fix_l_count(+y: Nat, +ll: Tree, +lk: Nat, +lr: Tree, +k: Nat, +r: Tree, c: Cmp) -> {count(y, Node{Node{ll, lk, lr}, k, r}) == count(y, fix_l(ll, lk, lr, k, r, c)) : Nat}:
  match c:
    case LT{}:
      -g = count(y, Node{Node{ll, lk, lr}, k, r})
      %rot_r_count(y, rot_l(ll, lk, lr), k, r) : {g == _ : Nat}
      %rot_l_count(y, ll, lk, lr) : {g == Nat.add(_, bump(Cmp.is_eq(Nat.cmp(y, k)), count(y, r))) : Nat}
      {==}
    case EQ{}:
      rot_r_count(y, Node{ll, lk, lr}, k, r)
    case GT{}:
      rot_r_count(y, Node{ll, lk, lr}, k, r)

def fix_r_count(+y: Nat, +l: Tree, +k: Nat, +rl: Tree, +rk: Nat, +rr: Tree, c: Cmp) -> {count(y, Node{l, k, Node{rl, rk, rr}}) == count(y, fix_r(l, k, rl, rk, rr, c)) : Nat}:
  match c:
    case GT{}:
      -g = count(y, Node{l, k, Node{rl, rk, rr}})
      %rot_l_count(y, l, k, rot_r(rl, rk, rr)) : {g == _ : Nat}
      %rot_r_count(y, rl, rk, rr) : {g == Nat.add(count(y, l), bump(Cmp.is_eq(Nat.cmp(y, k)), _)) : Nat}
      {==}
    case LT{}:
      rot_l_count(y, l, k, Node{rl, rk, rr})
    case EQ{}:
      rot_l_count(y, l, k, Node{rl, rk, rr})

def bal_l_count(+y: Nat, +l: Tree, +k: Nat, +r: Tree, c: Cmp) -> {count(y, Node{l, k, r}) == count(y, bal_l(l, k, r, c)) : Nat}:
  match l c:
    case Node{+ll, +lk, +lr} GT{}:
      fix_l_count(y, ll, lk, lr, k, r, Nat.cmp(height(ll), height(lr)))
    case Leaf{} c:
      {==}
    case Node{ll, lk, lr} LT{}:
      {==}
    case Node{ll, lk, lr} EQ{}:
      {==}

def bal_r_count(+y: Nat, +l: Tree, +k: Nat, +r: Tree, c: Cmp) -> {count(y, Node{l, k, r}) == count(y, bal_r(l, k, r, c)) : Nat}:
  match r c:
    case Node{+rl, +rk, +rr} GT{}:
      fix_r_count(y, l, k, rl, rk, rr, Nat.cmp(height(rl), height(rr)))
    case Leaf{} c:
      {==}
    case Node{rl, rk, rr} LT{}:
      {==}
    case Node{rl, rk, rr} EQ{}:
      {==}

# the step of insert at a node: the chosen side gains y's bump, and
# the bump moves out through the sum
def go_count(+y: Nat, +x: Nat, +ex: Bool, +l: Tree, +k: Nat, +r: Tree, il: Unit -> Tree, ir: Unit -> Tree, c: Or(LE(x, k), LE(k, x)),
  hl: {bump(ex, count(y, l)) == count(y, il(Unit{})) : Nat}, hr: {bump(ex, count(y, r)) == count(y, ir(Unit{})) : Nat})
  -> {bump(ex, count(y, Node{l, k, r})) == count(y, ins.go(x, l, k, r, c, il, ir)) : Nat}:
  match c:
    case Inl{e}:
      +ek = Cmp.is_eq(Nat.cmp(y, k))
      -g = bump(ex, count(y, Node{l, k, r}))
      +bk = bump(ek, count(y, r))
      +l2 = il(Unit{})
      %bal_l_count(y, l2, k, r, Nat.cmp(height(l2), 1n+height(r))) : {g == _ : Nat}
      %hl : {g == Nat.add(_, bk) : Nat}
      bump_add(ex, count(y, l), bk)
    case Inr{e}:
      +ek = Cmp.is_eq(Nat.cmp(y, k))
      -g = bump(ex, count(y, Node{l, k, r}))
      +r2 = ir(Unit{})
      %bal_r_count(y, l, k, r2, Nat.cmp(height(r2), 1n+height(l))) : {g == _ : Nat}
      %hr : {g == Nat.add(count(y, l), bump(ek, _)) : Nat}
      bump_in(ex, ek, count(y, l), count(y, r))

def insert_count(y, x, t):
  match t:
    case Leaf{}:
      {==}
    case Node{l, k, r}:
      go_count(y, x, Cmp.is_eq(Nat.cmp(y, x)), l, k, r, u => insert(x, l), u => insert(x, r), le_case(x, k), insert_count(y, x, l), insert_count(y, x, r))

def build_count(y, xs):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %insert_count(y, h, build(t)) : {_ == tally(y, h <> t) : Nat}
      %build_count(y, t) : {bump(Cmp.is_eq(Nat.cmp(y, h)), count(y, build(t))) == bump(Cmp.is_eq(Nat.cmp(y, h)), _) : Nat}
      {==}

# Listing
# -------

def le_refl(a: Nat) -> LE(a, a):
  match a:
    case 0n:
      Unit{}
    case 1n+p:
      le_refl(p)

# a list above hi is above any lo <= hi
def sorted_weaken(xs: List<&2, Nat>, +lo: Nat, +hi: Nat, lh: LE(lo, hi), s: Sorted.from(hi, xs)) -> Sorted.from(lo, xs):
  match xs:
    case Nil{}:
      Unit{}
    case h <> t:
      (hh, st) = s
      (le_trans(lo, hi, h, lh, hh), st)

# an ordered tree in lo..hi lists in order before a list above hi
def to_list_bst(t: Tree, +lo: Nat, +hi: Nat, +acc: List<&2, Nat>, lh: LE(lo, hi), b: Bst(lo, hi, t), s: Sorted.from(hi, acc)) -> Sorted.from(lo, to_list(t, acc)):
  match t:
    case Leaf{}:
      sorted_weaken(acc, lo, hi, lh, s)
    case Node{l, +k, +r}:
      (lok, khi, bl, br) = b
      to_list_bst(l, lo, k, k <> to_list(r, acc), lok, bl, (le_refl(k), to_list_bst(r, k, hi, acc, khi, br, s)))

def to_list_sorted(top, t, b):
  to_list_bst(t, 0n, top, Nil{}, Unit{}, b, Unit{})

def to_list_count(y, t, acc):
  match t:
    case Leaf{}:
      {==}
    case Node{l, k, r}:
      +ek = Cmp.is_eq(Nat.cmp(y, k))
      -g = Nat.add(count(y, Node{l, k, r}), tally(y, acc))
      %to_list_count(y, l, k <> to_list(r, acc)) : {g == _ : Nat}
      %to_list_count(y, r, acc) : {g == Nat.add(count(y, l), bump(ek, _)) : Nat}
      assoc_l(count(y, l), ek, count(y, r), tally(y, acc))

# Size
# ----

def rot_r_size(l: Tree, -k: Nat, +r: Tree) -> {size(Node{l, k, r}) == size(rot_r(l, k, r)) : Nat}:
  match l:
    case Leaf{}:
      {==}
    case Node{+ll, lk, +lr}:
      assoc_l(size(ll), True{}, size(lr), 1n+size(r))

def rot_l_size(+l: Tree, -k: Nat, r: Tree) -> {size(Node{l, k, r}) == size(rot_l(l, k, r)) : Nat}:
  match r:
    case Leaf{}:
      {==}
    case Node{+rl, rk, +rr}:
      assoc_r(size(l), True{}, size(rl), 1n+size(rr))

def fix_l_size(+ll: Tree, +lk: Nat, +lr: Tree, +k: Nat, +r: Tree, c: Cmp) -> {size(Node{Node{ll, lk, lr}, k, r}) == size(fix_l(ll, lk, lr, k, r, c)) : Nat}:
  match c:
    case LT{}:
      -g = size(Node{Node{ll, lk, lr}, k, r})
      %rot_r_size(rot_l(ll, lk, lr), k, r) : {g == _ : Nat}
      %rot_l_size(ll, lk, lr) : {g == Nat.add(_, 1n+size(r)) : Nat}
      {==}
    case EQ{}:
      rot_r_size(Node{ll, lk, lr}, k, r)
    case GT{}:
      rot_r_size(Node{ll, lk, lr}, k, r)

def fix_r_size(+l: Tree, +k: Nat, +rl: Tree, +rk: Nat, +rr: Tree, c: Cmp) -> {size(Node{l, k, Node{rl, rk, rr}}) == size(fix_r(l, k, rl, rk, rr, c)) : Nat}:
  match c:
    case GT{}:
      -g = size(Node{l, k, Node{rl, rk, rr}})
      %rot_l_size(l, k, rot_r(rl, rk, rr)) : {g == _ : Nat}
      %rot_r_size(rl, rk, rr) : {g == Nat.add(size(l), 1n+_) : Nat}
      {==}
    case LT{}:
      rot_l_size(l, k, Node{rl, rk, rr})
    case EQ{}:
      rot_l_size(l, k, Node{rl, rk, rr})

def bal_l_size(+l: Tree, +k: Nat, +r: Tree, c: Cmp) -> {size(Node{l, k, r}) == size(bal_l(l, k, r, c)) : Nat}:
  match l c:
    case Node{+ll, +lk, +lr} GT{}:
      fix_l_size(ll, lk, lr, k, r, Nat.cmp(height(ll), height(lr)))
    case Leaf{} c:
      {==}
    case Node{ll, lk, lr} LT{}:
      {==}
    case Node{ll, lk, lr} EQ{}:
      {==}

def bal_r_size(+l: Tree, +k: Nat, +r: Tree, c: Cmp) -> {size(Node{l, k, r}) == size(bal_r(l, k, r, c)) : Nat}:
  match r c:
    case Node{+rl, +rk, +rr} GT{}:
      fix_r_size(l, k, rl, rk, rr, Nat.cmp(height(rl), height(rr)))
    case Leaf{} c:
      {==}
    case Node{rl, rk, rr} LT{}:
      {==}
    case Node{rl, rk, rr} EQ{}:
      {==}

def go_size(-x: Nat, +l: Tree, +k: Nat, +r: Tree, il: Unit -> Tree, ir: Unit -> Tree, c: Or(LE(x, k), LE(k, x)),
  hl: {1n+size(l) == size(il(Unit{})) : Nat}, hr: {1n+size(r) == size(ir(Unit{})) : Nat})
  -> {1n+size(Node{l, k, r}) == size(ins.go(x, l, k, r, c, il, ir)) : Nat}:
  match c:
    case Inl{e}:
      -g = {1n+size(Node{l, k, r}) : Nat}
      +l2 = il(Unit{})
      %bal_l_size(l2, k, r, Nat.cmp(height(l2), 1n+height(r))) : {g == _ : Nat}
      %hl : {g == Nat.add(_, 1n+size(r)) : Nat}
      {==}
    case Inr{e}:
      -g = {1n+size(Node{l, k, r}) : Nat}
      +r2 = ir(Unit{})
      %bal_r_size(l, k, r2, Nat.cmp(height(r2), 1n+height(l))) : {g == _ : Nat}
      %hr : {g == Nat.add(size(l), 1n+_) : Nat}
      succ_in(size(l), True{}, size(r))

def insert_size(+x: Nat, +t: Tree) -> {1n+size(t) == size(insert(x, t)) : Nat}:
  match t:
    case Leaf{}:
      {==}
    case Node{l, k, r}:
      go_size(x, l, k, r, u => insert(x, l), u => insert(x, r), le_case(x, k), insert_size(x, l), insert_size(x, r))

def build_size(xs):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %insert_size(h, build(t)) : {_ == len(h <> t) : Nat}
      %build_size(t) : {1n+size(build(t)) == 1n+_ : Nat}
      {==}
