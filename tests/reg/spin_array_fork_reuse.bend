# regression witness: Array.fork + Array.join RFC cell reuse inside a freeing
# spin must not use a stale cached blk_loc from the dropped Array param.
import Base

def fst_u32(r: Array<U32> & U32) -> U32:
  (a, +v) = r
  v

def drop_one(fa: Array<U32> & Array<U32>) -> Array<U32>:
  (a1, a2) = fa
  Array.join(U32, a2, a1)

def fork_wrap(a: Array<U32>) -> Array<U32>:
  drop_one(Array.fork(U32, a))

def pair_get(r: Array<U32> & U32, pad: Array<U32>) -> U32 & U32:
  (b2, +got_b) = r
  b3 = Array.set(U32, b2, 0, 333)
  (U32.add(U32.mul(got_b, 1000), fst_u32(Array.get(U32, b3, 0))), fst_u32(Array.get(U32, pad, 0)))

def fork_reuse(+k: Nat, a: Array<U32>) -> U32 & U32:
  match k:
    case 0n:
      (fst_u32(Array.get(U32, a, 0)), 0)
    case 1n+p:
      pad = Array.new(U32, 2n, 111)
      b1  = fork_wrap(Array.new(U32, 2n, 222))
      b2  = Array.set(U32, b1, 1, 999)
      pair_get(Array.get(U32, b2, 0), pad)

def show_pair(p: U32 & U32) -> IO(Unit):
  (+x, +y) = p
  IO.print(U32.show(x) ++ " " ++ U32.show(y))

def one_nat(r: Array<U32> & U32) -> Nat:
  (a, +n) = r
  U32.to_nat(n)

def main() -> IO(Unit):
  do IO<Unit>:
    +n : Nat <- IO.pure(Nat, one_nat(Array.size(U32, [0 : U32*1n])))
    show_pair(fork_reuse(n, fork_wrap(Array.new(U32, 2n, 10))))

#|222333 111
