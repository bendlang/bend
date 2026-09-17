import Base
# Radix: radix sort as merge of singleton bit-tries, with a
# verification scan, ported 1-to-1 from Bend3's par_tree_radix_sort.
# gen hashes the 2^d
# indices into 24-bit keys (key = masked xorshift) laid out as a concat
# tree, to_map inserts every element into a 24-bit trie (radix spells
# the path bit by bit, LSB deepest), merge unions the tries (duplicates
# collapse into one Busy), to_arr reads the sorted sequence back off,
# and chk folds the sorted output into a Chk record -- min, max, a
# strict-sortedness flag, the distinct count and the key sum -- which
# chk_out mixes into the checksum. The Arr Empty ctor is named Emp
# (Base owns the name Empty); the trie step count is a Nat (no U32
# match in Bend4).
#
# Sizes: small depth = 8 (expect 366571299, verified against a Bend3 C
# run on the cluster), big depth = 22 (expect 1998173798, from the
# Bend3 header).

type Arr is Data:
  Emp{}
  Single{v: U32}
  Concat{l: Arr, r: Arr}

type Trie is Data:
  Free{}
  Busy{}
  Mnode{l: Trie, r: Trie}

type Chk is Data:
  Cnil{}
  Cval{lo: U32, hi: U32, ok: U32, cnt: U32, sum: U32}

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

# xorshift: x ^= x<<13; x ^= x>>17; x ^= x<<5
def prng(+x: U32) -> U32:
  +b = U32.xor(x, U32.shln(x, 13n))
  +d = U32.xor(b, U32.shrn(b, 17n))
  U32.xor(d, U32.shln(d, 5n))

# 24-bit key: masked hash of the global index
def key(i: U32) -> U32:
  U32.and(prng(U32.mul(U32.inc(i), 2654435761)), 16777215)

def merge(a: Trie, b: Trie) -> Trie:
  match a b:
    case Free{} Free{}:
      Free{}
    case Free{} Busy{}:
      Busy{}
    case Free{} Mnode{b0, b1}:
      Mnode{b0, b1}
    case Busy{} Free{}:
      Busy{}
    case Busy{} Busy{}:
      Busy{}
    case Busy{} Mnode{b0, b1}:
      Busy{}
    case Mnode{a0, a1} Free{}:
      Mnode{a0, a1}
    case Mnode{a0, a1} Busy{}:
      Busy{}
    case Mnode{a0, a1} Mnode{b0, b1}:
      l r = merge(a0, b0) merge(a1, b1)
      Mnode{l, r}

def gen(+n: Nat, +x: U32) -> Arr:
  match n:
    case 0n:
      Single{key(x)}
    case 1n+p:
      l r = gen(p, U32.shl(x)) gen(p, U32.inc(U32.shl(x)))
      Concat{l, r}

def swap_bits.go(x0: Trie, x1: Trie, z: Bool) -> Trie:
  match z:
    case True{}:
      Mnode{x0, x1}
    case False{}:
      Mnode{x1, x0}

def swap_bits(n: U32, x0: Trie, x1: Trie) -> Trie:
  swap_bits.go(x0, x1, U32.is_zero(n))

def radix(i: Nat, +n: U32, +k: U32, r: Trie) -> Trie:
  match i:
    case 0n:
      r
    case 1n+p:
      radix(p, n, U32.shl(k), swap_bits(U32.and(n, k), r, Free{}))

def to_map(a: Arr) -> Trie:
  match a:
    case Emp{}:
      Free{}
    case Single{x}:
      radix(24n, x, 1, Busy{})
    case Concat{a, b}:
      l r = to_map(a) to_map(b)
      merge(l, r)

def to_arr(m: Trie, +k: U32) -> Arr:
  match m:
    case Free{}:
      Emp{}
    case Busy{}:
      Single{k}
    case Mnode{l, r}:
      la ra = to_arr(l, U32.shl(k)) to_arr(r, U32.inc(U32.shl(k)))
      Concat{la, ra}

# verification join: bounds ride outward, ok demands strict order
# (duplicates collapsed, so a sorted trie read-off is strictly increasing)
def chk_join(a: Chk, b: Chk) -> Chk:
  match a b:
    case Cnil{} Cnil{}:
      Cnil{}
    case Cnil{} Cval{lo, hi, ok, cnt, sum}:
      Cval{lo, hi, ok, cnt, sum}
    case Cval{lo, hi, ok, cnt, sum} Cnil{}:
      Cval{lo, hi, ok, cnt, sum}
    case Cval{alo, ahi, aok, acnt, asum} Cval{blo, bhi, bok, bcnt, bsum}:
      Cval{alo, bhi, U32.and(U32.and(aok, bok), b2u(U32.is_lt(ahi, blo))), U32.add(acnt, bcnt), U32.add(asum, bsum)}

# rank-summary scan over the sorted output
def chk(a: Arr) -> Chk:
  match a:
    case Emp{}:
      Cnil{}
    case Single{+x}:
      Cval{x, x, 1, 1, x}
    case Concat{a, b}:
      l r = chk(a) chk(b)
      chk_join(l, r)

def chk_out(c: Chk) -> U32:
  match c:
    case Cnil{}:
      0
    case Cval{lo, hi, ok, cnt, sum}:
      U32.add(U32.xor(U32.add(sum, U32.mul(cnt, 2654435761)), U32.add(hi, U32.mul(lo, 340573321))), U32.mul(ok, 2246822519))

def sort(a: Arr) -> Arr:
  to_arr(to_map(a), 0)

def size.small() -> Nat:
  8n

def expect.small() -> U32:
  366571299

def size.big() -> Nat:
  22n

def expect.big() -> U32:
  1998173798

def main() -> IO(Unit):
  IO.print(U32.show(chk_out(chk!(sort!(gen!(22n, 0))))))
