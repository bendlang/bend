# regression witness: a spin that frees (directly or transitively) must not
# cache an Array param's blk_loc across a drop + reallocation that recycles
# the same class-0 RFC redirect cell for a new Array at a different data loc.
# Covers direct drop (term_sink), self-tail-loop (WL_AGAIN), transitive
# freeing spin callee + non-freeing leaf callee, ANode match (blk_half), and
# ALeaf match (blk_free) — all in 100% safe Bend.
import Base

def head_u32(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      h

def dup_sum(p: List<&2, U32> & List<&2, U32>) -> U32:
  (a, b) = p
  U32.add(head_u32(a), head_u32(b))

def heat(+xs: List<&2, U32>) -> U32:
  dup_sum((xs, xs))

def unwrap(xs: List<&1, Array<U32>>) -> Array<U32>:
  match xs:
    case Nil{}:
      Array.new(U32, 2n, 0)
    case x <> t:
      x

def wrap_list(+k: Nat, a: Array<U32>) -> List<&1, Array<U32>>:
  match k:
    case 0n:
      Nil{}
    case 1n+p:
      a <> Nil{}

def wrap(+k: Nat, a: Array<U32>) -> Array<U32>:
  unwrap(wrap_list(k, a))

type Pair2 is Data:
  P2{a: Nat, b: Nat}

def unwrap_nn(xs: List<&1, Array<Pair2>>) -> Array<Pair2>:
  match xs:
    case Nil{}:
      ALeaf{P2{0n, 0n}}
    case x <> t:
      x

def wrap_nn_list(+k: Nat, a: Array<Pair2>) -> List<&1, Array<Pair2>>:
  match k:
    case 0n:
      Nil{}
    case 1n+p:
      a <> Nil{}

def wrap_nn(+k: Nat, a: Array<Pair2>) -> Array<Pair2>:
  unwrap_nn(wrap_nn_list(k, a))

def fst_u32(r: Array<U32> & U32) -> U32:
  (a, +v) = r
  v

def fst_nn(r: Array<Pair2> & Pair2) -> U32:
  (a, p) = r
  match p:
    case P2{+x, +y}:
      U32.from_nat(x)

def spin_read(a: Array<U32>) -> Array<U32> & U32:
  Array.get(U32, a, 0)

def pair_get(r: Array<U32> & U32, pad: Array<U32>) -> U32 & U32:
  (b2, +got_b) = r
  b3 = Array.set(U32, b2, 0, 333)
  (U32.add(U32.mul(got_b, 1000), fst_u32(Array.get(U32, b3, 0))), fst_u32(Array.get(U32, pad, 0)))

def pair_get_nn(r: Array<Pair2> & Pair2, pad: Array<Pair2>) -> U32 & U32:
  (b2, p) = r
  match p:
    case P2{+got_b, +u}:
      b3 = Array.set(Pair2, b2, 0, P2{803n, 0n})
      (U32.add(U32.mul(U32.from_nat(got_b), 1000), fst_nn(Array.get(Pair2, b3, 0))), fst_nn(Array.get(Pair2, pad, 0)))

# 1. Direct drop (term_sink) + reallocation reusing RFC cell:
def direct_reuse(+k: Nat, a: Array<U32>) -> U32 & U32:
  match k:
    case 0n:
      (fst_u32(Array.get(U32, a, 0)), 0)
    case 1n+p:
      pad = Array.new(U32, 2n, 111)
      b1  = wrap(k, Array.new(U32, 2n, 222))
      pair_get(Array.get(U32, b1, 0), pad)

# 2. Self-tail-loop (WL_AGAIN) dropping a and looping with recycled RFC handle:
def loop_reuse(+k: Nat, a: Array<U32>, pad: Array<U32>) -> U32 & U32:
  match k:
    case 0n:
      pair_get(Array.get(U32, a, 0), pad)
    case 1n+p:
      pad2 = Array.new(U32, 2n, 444)
      b1   = wrap(k, Array.new(U32, 2n, 555))
      loop_reuse(p, b1, pad2)

# 3. Transitive freeing spin callee + non-freeing leaf callee (spin_read):
def drop_and_make(+k: Nat, a: Array<U32>) -> Array<U32> & Array<U32>:
  pad = Array.new(U32, 2n, 666)
  b1  = wrap(k, Array.new(U32, 2n, 777))
  (pad, b1)

def trans_fin2(r: Array<U32> & U32, +got_b: U32, pad: Array<U32>) -> U32 & U32:
  (b3, +leaf_b) = r
  b4 = Array.set(U32, b3, 0, 888)
  (U32.add(U32.mul(got_b, 1000), leaf_b), fst_u32(Array.get(U32, pad, 0)))

def trans_fin(r: Array<U32> & U32, pad: Array<U32>) -> U32 & U32:
  (b2, +got_b) = r
  trans_fin2(spin_read(b2), got_b, pad)

def trans_step(p: Array<U32> & Array<U32>) -> U32 & U32:
  (pad, b1) = p
  trans_fin(Array.get(U32, b1, 0), pad)

def trans_reuse(+k: Nat, a: Array<U32>) -> U32 & U32:
  match k:
    case 0n:
      (fst_u32(Array.get(U32, a, 0)), 0)
    case 1n+p:
      trans_step(drop_and_make(k, a))

# 4. ANode match (blk_half -> blk_free) freeing a, then reusing RFC cell:
def split_fin(r: Array<U32> & U32, pad: Array<U32>, lo: Array<U32>, hi: Array<U32>) -> U32 & U32:
  (b2, +got_b) = r
  b3 = Array.set(U32, b2, 0, 903)
  +u = U32.add(fst_u32(Array.get(U32, lo, 0)), fst_u32(Array.get(U32, hi, 0)))
  (U32.add(U32.mul(got_b, 1000), fst_u32(Array.get(U32, b3, 0))), U32.add(fst_u32(Array.get(U32, pad, 0)), U32.sub(u, u)))

def split_reuse(+k: Nat, a: Array<U32>) -> U32 & U32:
  match a:
    case ALeaf{+x}:
      (x, 0)
    case ANode{lo, hi}:
      pad = Array.new(U32, 2n, 901)
      b1  = wrap(k, Array.new(U32, 2n, 902))
      split_fin(Array.get(U32, b1, 0), pad, lo, hi)

# 5. ALeaf match (blk_free) freeing a (class-1 leaf, class-0 RFC cell):
def leaf_reuse(+k: Nat, a: Array<Pair2>) -> U32 & U32:
  match a:
    case ALeaf{p}:
      pad = Array.new(Pair2, 0n, P2{801n, 0n})
      b1  = wrap_nn(k, Array.new(Pair2, 0n, P2{802n, 0n}))
      pair_get_nn(Array.get(Pair2, b1, 0), pad)
    case ANode{lo, hi}:
      (0, 0)

def show_pair(p: U32 & U32) -> IO(Unit):
  (+x, +y) = p
  IO.print(U32.show(x) ++ " " ++ U32.show(y))

def one_nat(r: Array<U32> & U32) -> Nat:
  (a, +n) = r
  U32.to_nat(n)

def main() -> IO(Unit):
  do IO<Unit>:
    +n : Nat <- IO.pure(Nat, one_nat(Array.size(U32, [0 : U32*1n])))
    Unit <- IO.print(U32.show(heat(U32.from_nat(n) <> Nil{})))
    Unit <- show_pair(direct_reuse(n, wrap(n, Array.new(U32, 2n, 10))))
    Unit <- show_pair(loop_reuse(n, wrap(n, Array.new(U32, 2n, 20)), Array.new(U32, 3n, 21)))
    Unit <- show_pair(trans_reuse(n, wrap(n, Array.new(U32, 2n, 30))))
    Unit <- show_pair(split_reuse(n, wrap(n, Array.new(U32, 2n, 40))))
    show_pair(leaf_reuse(n, wrap_nn(n, Array.new(Pair2, 0n, P2{50n, 0n}))))

#|2
#|222333 111
#|555333 444
#|777777 666
#|902903 901
#|802803 801
