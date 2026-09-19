import Base

# Hashes / internal / Core
# ========================
#
# Shared fixed-width and byte helpers.
# Raw byte APIs use U32 values and deliberately mask each consumed byte to
# 0..255. This gives a total, deterministic API even if a caller supplies a
# wider U32 value.

# 64-bit word represented as two native U32 halves.
type W64 is Data:
  W64{hi: U32, lo: U32}

# U32 helpers
# -----------

def Bits.rotr32.norm(+x: U32, n: Nat) -> U32:
  match n:
    case 0n:
      x
    case 1n+ +p:
      U32.or(U32.shrn(x, 1n+p), U32.shln(x, Nat.sub(32n, 1n+p)))

# Rotation counts are normalized modulo the word width. This keeps the helper
# total and safe for reuse outside the current hash constants.
def Bits.rotr32(+x: U32, n: Nat) -> U32:
  Bits.rotr32.norm(x, Nat.mod(n, 32n))

def Bits.rotl32.norm(+x: U32, n: Nat) -> U32:
  match n:
    case 0n:
      x
    case 1n+ +p:
      U32.or(U32.shln(x, 1n+p), U32.shrn(x, Nat.sub(32n, 1n+p)))

def Bits.rotl32(+x: U32, n: Nat) -> U32:
  Bits.rotl32.norm(x, Nat.mod(n, 32n))

def Bits.add3(a: U32, b: U32, c: U32) -> U32:
  U32.add(U32.add(a, b), c)

def Bits.add4(a: U32, b: U32, c: U32, d: U32) -> U32:
  U32.add(U32.add(a, b), U32.add(c, d))

def Bits.add5(a: U32, b: U32, c: U32, d: U32, e: U32) -> U32:
  U32.add(U32.add(U32.add(a, b), U32.add(c, d)), e)

# W64 helpers
# -----------

def W64.zero() -> W64:
  W64{0, 0}

# Exact conversion for Bend Nat values that fit in 64 bits. Bend's current
# native runtime limit is below this, so every representable list length fits.
def W64.from_nat(+n: Nat) -> W64:
  W64{
    U32.from_nat(Nat.div(n, Nat.add(4294967295n, 1n))),
    U32.from_nat(Nat.mod(n, Nat.add(4294967295n, 1n)))
  }

# Convert a byte count to a 64-bit bit count without first multiplying in
# Nat. This matters near Bend's native Nat ceiling: n may be representable
# while n*8 is not, even though the 64-bit result is perfectly valid.
def W64.shl3(x: W64) -> W64:
  match x:
    case W64{+hi, +lo}:
      W64{
        U32.or(U32.shln(hi, 3n), U32.shrn(lo, 29n)),
        U32.shln(lo, 3n)
      }

def W64.bits_from_bytes(n: Nat) -> W64:
  W64.shl3(W64.from_nat(n))

def W64.xor(+a: W64, +b: W64) -> W64:
  match a b:
    case W64{ah, al} W64{bh, bl}:
      W64{U32.xor(ah, bh), U32.xor(al, bl)}

def W64.and(+a: W64, +b: W64) -> W64:
  match a b:
    case W64{ah, al} W64{bh, bl}:
      W64{U32.and(ah, bh), U32.and(al, bl)}

def W64.or(+a: W64, +b: W64) -> W64:
  match a b:
    case W64{ah, al} W64{bh, bl}:
      W64{U32.or(ah, bh), U32.or(al, bl)}

def W64.not(a: W64) -> W64:
  match a:
    case W64{hi, lo}:
      W64{U32.not(hi), U32.not(lo)}

def W64.add(+a: W64, +b: W64) -> W64:
  match a b:
    case W64{ah, al} W64{bh, bl}:
      +lo = U32.add(al, bl)
      carry = Bool.to_u32(U32.is_lt(lo, al))
      W64{U32.add(U32.add(ah, bh), carry), lo}

def W64.add3(a: W64, b: W64, c: W64) -> W64:
  W64.add(W64.add(a, b), c)

def W64.add4(a: W64, b: W64, c: W64, d: W64) -> W64:
  W64.add(W64.add(a, b), W64.add(c, d))

def W64.add5(a: W64, b: W64, c: W64, d: W64, e: W64) -> W64:
  W64.add(W64.add(W64.add(a, b), W64.add(c, d)), e)


def W64.swap(x: W64) -> W64:
  match x:
    case W64{hi, lo}:
      W64{lo, hi}

def W64.shr32(x: W64) -> W64:
  match x:
    case W64{hi, lo}:
      W64{0, hi}

def W64.shr.gt32(x: W64, n: Nat) -> W64:
  match x:
    case W64{hi, lo}:
      W64{0, U32.shrn(hi, Nat.sub(n, 32n))}

def W64.rotr.lt32(+x: W64, +n: Nat) -> W64:
  match x:
    case W64{+hi, +lo}:
      +m = Nat.sub(32n, n)
      W64{
        U32.or(U32.shrn(hi, n), U32.shln(lo, m)),
        U32.or(U32.shrn(lo, n), U32.shln(hi, m))
      }

def W64.rotr.gt32(+x: W64, +n: Nat) -> W64:
  match x:
    case W64{+hi, +lo}:
      +m = Nat.sub(n, 32n)
      +q = Nat.sub(32n, m)
      W64{
        U32.or(U32.shrn(lo, m), U32.shln(hi, q)),
        U32.or(U32.shrn(hi, m), U32.shln(lo, q))
      }

def W64.rotr.ge32(+x: W64, +n: Nat, eq32: Bool) -> W64:
  match eq32:
    case True{}:
      W64.swap(x)
    case False{}:
      W64.rotr.gt32(x, n)

def W64.rotr.nonzero(+x: W64, +n: Nat, lt: Bool) -> W64:
  match lt:
    case True{}:
      W64.rotr.lt32(x, n)
    case False{}:
      W64.rotr.ge32(x, n, Nat.is_eq(n, 32n))

def W64.rotr.norm(+x: W64, n: Nat) -> W64:
  match n:
    case 0n:
      x
    case 1n+ +p:
      W64.rotr.nonzero(x, 1n+p, Nat.is_lt(1n+p, 32n))

def W64.rotr(+x: W64, n: Nat) -> W64:
  W64.rotr.norm(x, Nat.mod(n, 64n))

def W64.rotl.norm(+x: W64, n: Nat) -> W64:
  match n:
    case 0n:
      x
    case 1n+p:
      W64.rotr.norm(x, Nat.sub(64n, 1n+p))

def W64.rotl(+x: W64, n: Nat) -> W64:
  W64.rotl.norm(x, Nat.mod(n, 64n))

def W64.shr.lt32(+x: W64, +n: Nat) -> W64:
  match x:
    case W64{+hi, +lo}:
      W64{
        U32.shrn(hi, n),
        U32.or(U32.shrn(lo, n), U32.shln(hi, Nat.sub(32n, n)))
      }

def W64.shr.mid(+x: W64, +n: Nat, eq32: Bool) -> W64:
  match eq32:
    case True{}:
      W64.shr32(x)
    case False{}:
      W64.shr.gt32(x, n)

def W64.shr.ge32(+x: W64, +n: Nat, ge64: Bool) -> W64:
  match ge64:
    case True{}:
      W64.zero()
    case False{}:
      W64.shr.mid(x, n, Nat.is_eq(n, 32n))

def W64.shr.nonzero(+x: W64, +n: Nat, lt32: Bool) -> W64:
  match lt32:
    case True{}:
      W64.shr.lt32(x, n)
    case False{}:
      W64.shr.ge32(x, n, Nat.is_ge(n, 64n))

def W64.shr(+x: W64, n: Nat) -> W64:
  match n:
    case 0n:
      x
    case 1n+ +p:
      W64.shr.nonzero(x, 1n+p, Nat.is_lt(1n+p, 32n))

# Bytes
# -----

def Bytes.byte(x: U32) -> U32:
  U32.and(x, 255)

def Bytes.length_nat.go(xs: List<&2, U32>, acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      Bytes.length_nat.go(t, Nat.add(acc, 1n))

# Tail-recursive length avoids linear call-stack growth on the JavaScript
# backend, where Base.List.length is structurally recursive on return.
def Bytes.length_nat(xs: List<&2, U32>) -> Nat:
  Bytes.length_nat.go(xs, 0n)


# Correct UTF-8 encoding. Invalid scalar values become U+FFFD in the raw
# scalar helper. Public text(...) receives Bend String values; a backend may
# reject an invalid Char before this library sees it.
def Bytes.utf8.three(+cp: U32, tail: List<&2, U32>) -> List<&2, U32>:
  U32.or(224, U32.and(U32.shrn(cp, 12n), 15)) <>
  U32.or(128, U32.and(U32.shrn(cp, 6n), 63)) <>
  U32.or(128, U32.and(cp, 63)) <>
  tail

def Bytes.utf8.four(+cp: U32, tail: List<&2, U32>) -> List<&2, U32>:
  U32.or(240, U32.and(U32.shrn(cp, 18n), 7)) <>
  U32.or(128, U32.and(U32.shrn(cp, 12n), 63)) <>
  U32.or(128, U32.and(U32.shrn(cp, 6n), 63)) <>
  U32.or(128, U32.and(cp, 63)) <>
  tail

def Bytes.utf8.bmp(+cp: U32, tail: List<&2, U32>, surrogate: Bool) -> List<&2, U32>:
  match surrogate:
    case True{}:
      239 <> 191 <> 189 <> tail
    case False{}:
      Bytes.utf8.three(cp, tail)

def Bytes.utf8.u21(+cp: U32, tail: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      Bytes.utf8.four(cp, tail)
    case False{}:
      239 <> 191 <> 189 <> tail

def Bytes.utf8.u16(+cp: U32, tail: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      Bytes.utf8.bmp(
        cp,
        tail,
        Bool.and(U32.is_ge(cp, 55296), U32.is_le(cp, 57343))
      )
    case False{}:
      Bytes.utf8.u21(cp, tail, U32.is_le(cp, 1114111))

def Bytes.utf8.u11(+cp: U32, tail: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      U32.or(192, U32.and(U32.shrn(cp, 6n), 31)) <>
      U32.or(128, U32.and(cp, 63)) <>
      tail
    case False{}:
      Bytes.utf8.u16(cp, tail, U32.is_le(cp, 65535))

def Bytes.utf8.u7(+cp: U32, tail: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      cp <> tail
    case False{}:
      Bytes.utf8.u11(cp, tail, U32.is_le(cp, 2047))

def Bytes.utf8.code(+cp: U32, tail: List<&2, U32>) -> List<&2, U32>:
  Bytes.utf8.u7(cp, tail, U32.is_le(cp, 127))

# Reverse-order encoder used by the tail-recursive String traversal. Each
# scalar is prepended in reverse byte order; one final List.reverse restores
# the complete UTF-8 byte stream.
def Bytes.utf8.rev.three(+cp: U32, acc: List<&2, U32>) -> List<&2, U32>:
  U32.or(128, U32.and(cp, 63)) <>
  U32.or(128, U32.and(U32.shrn(cp, 6n), 63)) <>
  U32.or(224, U32.and(U32.shrn(cp, 12n), 15)) <>
  acc

def Bytes.utf8.rev.four(+cp: U32, acc: List<&2, U32>) -> List<&2, U32>:
  U32.or(128, U32.and(cp, 63)) <>
  U32.or(128, U32.and(U32.shrn(cp, 6n), 63)) <>
  U32.or(128, U32.and(U32.shrn(cp, 12n), 63)) <>
  U32.or(240, U32.and(U32.shrn(cp, 18n), 7)) <>
  acc

def Bytes.utf8.rev.bmp(+cp: U32, acc: List<&2, U32>, surrogate: Bool) -> List<&2, U32>:
  match surrogate:
    case True{}:
      189 <> 191 <> 239 <> acc
    case False{}:
      Bytes.utf8.rev.three(cp, acc)

def Bytes.utf8.rev.u21(+cp: U32, acc: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      Bytes.utf8.rev.four(cp, acc)
    case False{}:
      189 <> 191 <> 239 <> acc

def Bytes.utf8.rev.u16(+cp: U32, acc: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      Bytes.utf8.rev.bmp(
        cp,
        acc,
        Bool.and(U32.is_ge(cp, 55296), U32.is_le(cp, 57343))
      )
    case False{}:
      Bytes.utf8.rev.u21(cp, acc, U32.is_le(cp, 1114111))

def Bytes.utf8.rev.u11(+cp: U32, acc: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      U32.or(128, U32.and(cp, 63)) <>
      U32.or(192, U32.and(U32.shrn(cp, 6n), 31)) <>
      acc
    case False{}:
      Bytes.utf8.rev.u16(cp, acc, U32.is_le(cp, 65535))

def Bytes.utf8.rev.u7(+cp: U32, acc: List<&2, U32>, le: Bool) -> List<&2, U32>:
  match le:
    case True{}:
      cp <> acc
    case False{}:
      Bytes.utf8.rev.u11(cp, acc, U32.is_le(cp, 2047))

def Bytes.utf8.rev.code(+cp: U32, acc: List<&2, U32>) -> List<&2, U32>:
  Bytes.utf8.rev.u7(cp, acc, U32.is_le(cp, 127))

def Bytes.utf8.go(s: String, acc: List<&2, U32>) -> List<&2, U32>:
  match s:
    case SNil{}:
      List.reverse(&2, U32, acc)
    case SCon{head, tail}:
      Bytes.utf8.go(tail, Bytes.utf8.rev.code(Char.to_u32(head), acc))

def Bytes.utf8(s: String) -> List<&2, U32>:
  Bytes.utf8.go(s, Nil{})

# Lower-case hexadecimal.
def Hex.nibble.if(x: U32, low: Bool) -> Char:
  match low:
    case True{}:
      Char.from_u32(U32.add(48, x))
    case False{}:
      Char.from_u32(U32.add(87, x))

def Hex.nibble(+x: U32) -> Char:
  Hex.nibble.if(x, U32.is_lt(x, 10))

def Hex.bytes.go(xs: List<&2, U32>, acc: String) -> String:
  match xs:
    case Nil{}:
      String.reverse(acc)
    case h <> t:
      +b = Bytes.byte(h)
      # The accumulator is reversed: low nibble first, then high nibble.
      Hex.bytes.go(
        t,
        SCon{
          Hex.nibble(U32.and(b, 15)),
          SCon{Hex.nibble(U32.shrn(b, 4n)), acc}
        }
      )

def Hex.bytes(xs: List<&2, U32>) -> String:
  Hex.bytes.go(xs, SNil{})

# Prefix a U32 to a byte list in either endian order.
def Bytes.u32be(+x: U32, tail: List<&2, U32>) -> List<&2, U32>:
  U32.and(U32.shrn(x, 24n), 255) <>
  U32.and(U32.shrn(x, 16n), 255) <>
  U32.and(U32.shrn(x, 8n), 255) <>
  U32.and(x, 255) <>
  tail

def Bytes.u32le(+x: U32, tail: List<&2, U32>) -> List<&2, U32>:
  U32.and(x, 255) <>
  U32.and(U32.shrn(x, 8n), 255) <>
  U32.and(U32.shrn(x, 16n), 255) <>
  U32.and(U32.shrn(x, 24n), 255) <>
  tail

def Bytes.u64be(x: W64, tail: List<&2, U32>) -> List<&2, U32>:
  match x:
    case W64{hi, lo}:
      Bytes.u32be(hi, Bytes.u32be(lo, tail))

def Bytes.u64le(x: W64, tail: List<&2, U32>) -> List<&2, U32>:
  match x:
    case W64{hi, lo}:
      Bytes.u32le(lo, Bytes.u32le(hi, tail))

# Random-access byte/word reads. Indexes outside the list read as zero.
# Hash algorithms only use fixed, in-range offsets on complete padded blocks.
def Bytes.at(+xs: List<&2, U32>, n: Nat) -> U32:
  Bytes.byte(Maybe.default(&2, U32, List.get(&2, U32, xs, n), 0))

def Bytes.u32be_at(+xs: List<&2, U32>, +n: Nat) -> U32:
  U32.or(
    U32.or(U32.shln(Bytes.at(xs, n), 24n), U32.shln(Bytes.at(xs, Nat.add(n, 1n)), 16n)),
    U32.or(U32.shln(Bytes.at(xs, Nat.add(n, 2n)), 8n), Bytes.at(xs, Nat.add(n, 3n))))

def Bytes.u32le_at(+xs: List<&2, U32>, +n: Nat) -> U32:
  U32.or(
    U32.or(Bytes.at(xs, n), U32.shln(Bytes.at(xs, Nat.add(n, 1n)), 8n)),
    U32.or(U32.shln(Bytes.at(xs, Nat.add(n, 2n)), 16n), U32.shln(Bytes.at(xs, Nat.add(n, 3n)), 24n)))

def Bytes.u64be_at(+xs: List<&2, U32>, +n: Nat) -> W64:
  W64{Bytes.u32be_at(xs, n), Bytes.u32be_at(xs, Nat.add(n, 4n))}

def Bytes.u64le_at(+xs: List<&2, U32>, +n: Nat) -> W64:
  W64{Bytes.u32le_at(xs, Nat.add(n, 4n)), Bytes.u32le_at(xs, n)}

def Words32.block_be.go(+xs: List<&2, U32>, n: Nat, +i: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      List.reverse(&2, U32, acc)
    case 1n+p:
      Words32.block_be.go(xs, p, Nat.add(i, 4n), Bytes.u32be_at(xs, i) <> acc)

def Words32.block_be(xs: List<&2, U32>, n: Nat) -> List<&2, U32>:
  Words32.block_be.go(xs, n, 0n, Nil{})

def Words32.block_le.go(+xs: List<&2, U32>, n: Nat, +i: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      List.reverse(&2, U32, acc)
    case 1n+p:
      Words32.block_le.go(xs, p, Nat.add(i, 4n), Bytes.u32le_at(xs, i) <> acc)

def Words32.block_le(xs: List<&2, U32>, n: Nat) -> List<&2, U32>:
  Words32.block_le.go(xs, n, 0n, Nil{})

def Words64.block_be.go(+xs: List<&2, U32>, n: Nat, +i: Nat, acc: List<&2, W64>) -> List<&2, W64>:
  match n:
    case 0n:
      List.reverse(&2, W64, acc)
    case 1n+p:
      Words64.block_be.go(xs, p, Nat.add(i, 8n), Bytes.u64be_at(xs, i) <> acc)

def Words64.block_be(xs: List<&2, U32>, n: Nat) -> List<&2, W64>:
  Words64.block_be.go(xs, n, 0n, Nil{})

def Words64.block_le.go(+xs: List<&2, U32>, n: Nat, +i: Nat, acc: List<&2, W64>) -> List<&2, W64>:
  match n:
    case 0n:
      List.reverse(&2, W64, acc)
    case 1n+p:
      Words64.block_le.go(xs, p, Nat.add(i, 8n), Bytes.u64le_at(xs, i) <> acc)

def Words64.block_le(xs: List<&2, U32>, n: Nat) -> List<&2, W64>:
  Words64.block_le.go(xs, n, 0n, Nil{})

# Fixed-size zero lists used only for padding; n is always small.
def Bytes.zeros(n: U32) -> List<&2, U32>:
  List.replicate(U32, U32.to_nat(n), 0)

# Extract a reusable list element with a defined zero default. Internal callers
# only use in-range fixed indexes; the default prevents partial functions.
def Words32.get(+xs: List<&2, U32>, n: Nat) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, xs, n), 0)

def Words64.get(+xs: List<&2, W64>, n: Nat) -> W64:
  Maybe.default(&2, W64, List.get(&2, W64, xs, n), W64.zero())
