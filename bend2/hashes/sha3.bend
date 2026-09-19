import Base
import ./internal/core.bend as C

# Keccak-f[1600], SHA-3 and SHAKE
# ================================

def Keccak.zero() -> List<&2,C.W64>:
  List.replicate(C.W64,25n,C.W64.zero())

def Keccak.xor5(a: C.W64,b: C.W64,c: C.W64,d: C.W64,e: C.W64) -> C.W64:
  C.W64.xor(C.W64.xor(C.W64.xor(a,b),C.W64.xor(c,d)),e)

def Keccak.columns(+s: List<&2,C.W64>) -> List<&2,C.W64>:
  [
    Keccak.xor5(C.Words64.get(s,0n),C.Words64.get(s,5n),C.Words64.get(s,10n),C.Words64.get(s,15n),C.Words64.get(s,20n)),
    Keccak.xor5(C.Words64.get(s,1n),C.Words64.get(s,6n),C.Words64.get(s,11n),C.Words64.get(s,16n),C.Words64.get(s,21n)),
    Keccak.xor5(C.Words64.get(s,2n),C.Words64.get(s,7n),C.Words64.get(s,12n),C.Words64.get(s,17n),C.Words64.get(s,22n)),
    Keccak.xor5(C.Words64.get(s,3n),C.Words64.get(s,8n),C.Words64.get(s,13n),C.Words64.get(s,18n),C.Words64.get(s,23n)),
    Keccak.xor5(C.Words64.get(s,4n),C.Words64.get(s,9n),C.Words64.get(s,14n),C.Words64.get(s,19n),C.Words64.get(s,24n))
  ]

def Keccak.ds(+c: List<&2,C.W64>) -> List<&2,C.W64>:
  [
    C.W64.xor(C.Words64.get(c,4n),C.W64.rotl(C.Words64.get(c,1n),1n)),
    C.W64.xor(C.Words64.get(c,0n),C.W64.rotl(C.Words64.get(c,2n),1n)),
    C.W64.xor(C.Words64.get(c,1n),C.W64.rotl(C.Words64.get(c,3n),1n)),
    C.W64.xor(C.Words64.get(c,2n),C.W64.rotl(C.Words64.get(c,4n),1n)),
    C.W64.xor(C.Words64.get(c,3n),C.W64.rotl(C.Words64.get(c,0n),1n))
  ]

def Keccak.rhopi(+s: List<&2,C.W64>, +ds: List<&2,C.W64>) -> List<&2,C.W64>:
  [
    C.W64.rotl(C.W64.xor(C.Words64.get(s,0n),C.Words64.get(ds,0n)),0n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,6n),C.Words64.get(ds,1n)),44n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,12n),C.Words64.get(ds,2n)),43n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,18n),C.Words64.get(ds,3n)),21n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,24n),C.Words64.get(ds,4n)),14n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,3n),C.Words64.get(ds,3n)),28n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,9n),C.Words64.get(ds,4n)),20n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,10n),C.Words64.get(ds,0n)),3n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,16n),C.Words64.get(ds,1n)),45n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,22n),C.Words64.get(ds,2n)),61n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,1n),C.Words64.get(ds,1n)),1n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,7n),C.Words64.get(ds,2n)),6n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,13n),C.Words64.get(ds,3n)),25n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,19n),C.Words64.get(ds,4n)),8n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,20n),C.Words64.get(ds,0n)),18n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,4n),C.Words64.get(ds,4n)),27n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,5n),C.Words64.get(ds,0n)),36n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,11n),C.Words64.get(ds,1n)),10n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,17n),C.Words64.get(ds,2n)),15n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,23n),C.Words64.get(ds,3n)),56n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,2n),C.Words64.get(ds,2n)),62n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,8n),C.Words64.get(ds,3n)),55n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,14n),C.Words64.get(ds,4n)),39n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,15n),C.Words64.get(ds,0n)),41n),
    C.W64.rotl(C.W64.xor(C.Words64.get(s,21n),C.Words64.get(ds,1n)),2n)
  ]

def Keccak.chi_iota(+b: List<&2,C.W64>, rc: C.W64) -> List<&2,C.W64>:
  [
    C.W64.xor(C.W64.xor(C.Words64.get(b,0n),C.W64.and(C.W64.not(C.Words64.get(b,1n)),C.Words64.get(b,2n))),rc),
    C.W64.xor(C.Words64.get(b,1n),C.W64.and(C.W64.not(C.Words64.get(b,2n)),C.Words64.get(b,3n))),
    C.W64.xor(C.Words64.get(b,2n),C.W64.and(C.W64.not(C.Words64.get(b,3n)),C.Words64.get(b,4n))),
    C.W64.xor(C.Words64.get(b,3n),C.W64.and(C.W64.not(C.Words64.get(b,4n)),C.Words64.get(b,0n))),
    C.W64.xor(C.Words64.get(b,4n),C.W64.and(C.W64.not(C.Words64.get(b,0n)),C.Words64.get(b,1n))),
    C.W64.xor(C.Words64.get(b,5n),C.W64.and(C.W64.not(C.Words64.get(b,6n)),C.Words64.get(b,7n))),
    C.W64.xor(C.Words64.get(b,6n),C.W64.and(C.W64.not(C.Words64.get(b,7n)),C.Words64.get(b,8n))),
    C.W64.xor(C.Words64.get(b,7n),C.W64.and(C.W64.not(C.Words64.get(b,8n)),C.Words64.get(b,9n))),
    C.W64.xor(C.Words64.get(b,8n),C.W64.and(C.W64.not(C.Words64.get(b,9n)),C.Words64.get(b,5n))),
    C.W64.xor(C.Words64.get(b,9n),C.W64.and(C.W64.not(C.Words64.get(b,5n)),C.Words64.get(b,6n))),
    C.W64.xor(C.Words64.get(b,10n),C.W64.and(C.W64.not(C.Words64.get(b,11n)),C.Words64.get(b,12n))),
    C.W64.xor(C.Words64.get(b,11n),C.W64.and(C.W64.not(C.Words64.get(b,12n)),C.Words64.get(b,13n))),
    C.W64.xor(C.Words64.get(b,12n),C.W64.and(C.W64.not(C.Words64.get(b,13n)),C.Words64.get(b,14n))),
    C.W64.xor(C.Words64.get(b,13n),C.W64.and(C.W64.not(C.Words64.get(b,14n)),C.Words64.get(b,10n))),
    C.W64.xor(C.Words64.get(b,14n),C.W64.and(C.W64.not(C.Words64.get(b,10n)),C.Words64.get(b,11n))),
    C.W64.xor(C.Words64.get(b,15n),C.W64.and(C.W64.not(C.Words64.get(b,16n)),C.Words64.get(b,17n))),
    C.W64.xor(C.Words64.get(b,16n),C.W64.and(C.W64.not(C.Words64.get(b,17n)),C.Words64.get(b,18n))),
    C.W64.xor(C.Words64.get(b,17n),C.W64.and(C.W64.not(C.Words64.get(b,18n)),C.Words64.get(b,19n))),
    C.W64.xor(C.Words64.get(b,18n),C.W64.and(C.W64.not(C.Words64.get(b,19n)),C.Words64.get(b,15n))),
    C.W64.xor(C.Words64.get(b,19n),C.W64.and(C.W64.not(C.Words64.get(b,15n)),C.Words64.get(b,16n))),
    C.W64.xor(C.Words64.get(b,20n),C.W64.and(C.W64.not(C.Words64.get(b,21n)),C.Words64.get(b,22n))),
    C.W64.xor(C.Words64.get(b,21n),C.W64.and(C.W64.not(C.Words64.get(b,22n)),C.Words64.get(b,23n))),
    C.W64.xor(C.Words64.get(b,22n),C.W64.and(C.W64.not(C.Words64.get(b,23n)),C.Words64.get(b,24n))),
    C.W64.xor(C.Words64.get(b,23n),C.W64.and(C.W64.not(C.Words64.get(b,24n)),C.Words64.get(b,20n))),
    C.W64.xor(C.Words64.get(b,24n),C.W64.and(C.W64.not(C.Words64.get(b,20n)),C.Words64.get(b,21n)))
  ]

def Keccak.round(+s: List<&2,C.W64>, rc: C.W64) -> List<&2,C.W64>:
  d = Keccak.ds(Keccak.columns(s))
  Keccak.chi_iota(Keccak.rhopi(s,d),rc)

def Keccak.rcs() -> List<&2,C.W64>:
  [C.W64{0, 1}, C.W64{0, 32898}, C.W64{2147483648, 32906}, C.W64{2147483648, 2147516416}, C.W64{0, 32907}, C.W64{0, 2147483649}, C.W64{2147483648, 2147516545}, C.W64{2147483648, 32777}, C.W64{0, 138}, C.W64{0, 136}, C.W64{0, 2147516425}, C.W64{0, 2147483658}, C.W64{0, 2147516555}, C.W64{2147483648, 139}, C.W64{2147483648, 32905}, C.W64{2147483648, 32771}, C.W64{2147483648, 32770}, C.W64{2147483648, 128}, C.W64{0, 32778}, C.W64{2147483648, 2147483658}, C.W64{2147483648, 2147516545}, C.W64{2147483648, 32896}, C.W64{0, 2147483649}, C.W64{2147483648, 2147516424}]

def Keccak.permute.go(rcs: List<&2,C.W64>, st: List<&2,C.W64>) -> List<&2,C.W64>:
  match rcs:
    case Nil{}:
      st
    case rc <> rt:
      Keccak.permute.go(rt,Keccak.round(st,rc))

def Keccak.permute(st: List<&2,C.W64>) -> List<&2,C.W64>:
  Keccak.permute.go(Keccak.rcs(),st)

def Keccak.xor_rate.go(n: Nat, state: List<&2,C.W64>, words: List<&2,C.W64>, acc: List<&2,C.W64>) -> List<&2,C.W64>:
  match n state words:
    case 0n s w:
      List.append(&2,C.W64,List.reverse(&2,C.W64,acc),s)
    case 1n+p sh <> st wh <> wt:
      Keccak.xor_rate.go(p,st,wt,C.W64.xor(sh,wh) <> acc)
    case 1n+p s w:
      List.append(&2,C.W64,List.reverse(&2,C.W64,acc),s)

def Keccak.xor_rate(state: List<&2,C.W64>, +block: List<&2,U32>, +lanes: Nat) -> List<&2,C.W64>:
  Keccak.xor_rate.go(lanes,state,C.Words64.block_le(block,lanes),Nil{})

def Keccak.absorb_blocks(n: Nat, +rate: Nat, +lanes: Nat, +xs: List<&2,U32>, state: List<&2,C.W64>) -> List<&2,C.W64>:
  match n:
    case 0n:
      state
    case 1n+p:
      mixed = Keccak.xor_rate(state,xs,lanes)
      Keccak.absorb_blocks(p,rate,lanes,List.drop(&2,U32,xs,rate),Keccak.permute(mixed))

def Keccak.pad.if(+rest: List<&2,U32>, +rem: U32, +rate: U32, domain: U32, one: Bool) -> List<&2,U32>:
  match one:
    case True{}:
      List.append(&2,U32,rest,[U32.or(domain,128)])
    case False{}:
      zeros = U32.sub(U32.sub(rate,rem),2)
      List.append(&2,U32,rest,domain <> List.append(&2,U32,C.Bytes.zeros(zeros),[128]))

def Keccak.pad(+rest: List<&2,U32>, +rem: U32, +rate: U32, +domain: U32) -> List<&2,U32>:
  Keccak.pad.if(rest,rem,rate,domain,U32.is_eq(rem,U32.sub(rate,1)))

def Keccak.sponge(+xs: List<&2,U32>, +rate: U32, +rate_n: Nat, +lanes: Nat, domain: U32) -> List<&2,C.W64>:
  +length = C.Bytes.length_nat(xs)
  +full = Nat.div(length,rate_n)
  rem = U32.from_nat(Nat.mod(length,rate_n))
  before = Keccak.absorb_blocks(full,rate_n,lanes,xs,Keccak.zero())
  rest = List.drop(&2,U32,xs,Nat.mul(full,rate_n))
  padded = Keccak.pad(rest,rem,rate,domain)
  Keccak.permute(Keccak.xor_rate(before,padded,lanes))

def Keccak.state_bytes.go(+state: List<&2,C.W64>, n: Nat, +i: Nat) -> List<&2,U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      C.Bytes.u64le(C.Words64.get(state,i),Keccak.state_bytes.go(state,p,Nat.add(i,1n)))

def Keccak.state_bytes(state: List<&2,C.W64>, lanes: Nat) -> List<&2,U32>:
  Keccak.state_bytes.go(state,lanes,0n)

# Prepend one normal-order byte block into an accumulator that stores the
# complete output in reverse order. The recursion is tail-recursive, so block
# assembly does not consume JavaScript call stack proportional to output size.
def Keccak.prepend_reverse(xs: List<&2,U32>, acc: List<&2,U32>) -> List<&2,U32>:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      Keccak.prepend_reverse(t,h <> acc)

def Keccak.squeeze.go(n: Nat, +state: List<&2,C.W64>, +lanes: Nat, rem: U32, acc: List<&2,U32>) -> List<&2,U32>:
  match n:
    case 0n:
      tail = List.take(&2,U32,Keccak.state_bytes(state,lanes),U32.to_nat(rem))
      List.reverse(&2,U32,Keccak.prepend_reverse(tail,acc))
    case 1n+p:
      block = Keccak.state_bytes(state,lanes)
      next_acc = Keccak.prepend_reverse(block,acc)
      Keccak.squeeze.go(p,Keccak.permute(state),lanes,rem,next_acc)

def Keccak.squeeze(+state: List<&2,C.W64>, +out_len: U32, +rate: U32, +lanes: Nat) -> List<&2,U32>:
  full = U32.div(out_len,rate)
  rem = U32.mod(out_len,rate)
  Keccak.squeeze.go(U32.to_nat(full),state,lanes,rem,Nil{})

# SHA3 fixed-output variants

def SHA3_224.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,144,144n,18n,6),28,144,18n)

def SHA3_256.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,136,136n,17n,6),32,136,17n)

def SHA3_384.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,104,104n,13n,6),48,104,13n)

def SHA3_512.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,72,72n,9n,6),64,72,9n)

def SHA3_224.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA3_224.bytes(xs))

def SHA3_256.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA3_256.bytes(xs))

def SHA3_384.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA3_384.bytes(xs))

def SHA3_512.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA3_512.bytes(xs))

def SHA3_224.text(s: String) -> String:
  SHA3_224.hex_bytes(C.Bytes.utf8(s))

def SHA3_256.text(s: String) -> String:
  SHA3_256.hex_bytes(C.Bytes.utf8(s))

def SHA3_384.text(s: String) -> String:
  SHA3_384.hex_bytes(C.Bytes.utf8(s))

def SHA3_512.text(s: String) -> String:
  SHA3_512.hex_bytes(C.Bytes.utf8(s))

# SHAKE XOF variants; out_len is in bytes.
def SHAKE128.bytes(xs: List<&2,U32>, out_len: U32) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,168,168n,21n,31),out_len,168,21n)

def SHAKE256.bytes(xs: List<&2,U32>, out_len: U32) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,136,136n,17n,31),out_len,136,17n)

def SHAKE128.hex_bytes(xs: List<&2,U32>, out_len: U32) -> String:
  C.Hex.bytes(SHAKE128.bytes(xs,out_len))

def SHAKE256.hex_bytes(xs: List<&2,U32>, out_len: U32) -> String:
  C.Hex.bytes(SHAKE256.bytes(xs,out_len))

def SHAKE128.text(s: String, out_len: U32) -> String:
  SHAKE128.hex_bytes(C.Bytes.utf8(s),out_len)

def SHAKE256.text(s: String, out_len: U32) -> String:
  SHAKE256.hex_bytes(C.Bytes.utf8(s),out_len)

# Original Keccak fixed-output variants
# =====================================
#
# These use the pre-SHA-3 Keccak domain suffix 0x01. They are intentionally
# named KECCAK_* to avoid confusing them with the standardized SHA3_* family,
# whose domain suffix is 0x06.

def KECCAK_224.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,144,144n,18n,1),28,144,18n)

def KECCAK_256.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,136,136n,17n,1),32,136,17n)

def KECCAK_384.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,104,104n,13n,1),48,104,13n)

def KECCAK_512.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  Keccak.squeeze(Keccak.sponge(xs,72,72n,9n,1),64,72,9n)

def KECCAK_224.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(KECCAK_224.bytes(xs))

def KECCAK_256.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(KECCAK_256.bytes(xs))

def KECCAK_384.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(KECCAK_384.bytes(xs))

def KECCAK_512.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(KECCAK_512.bytes(xs))

def KECCAK_224.text(s: String) -> String:
  KECCAK_224.hex_bytes(C.Bytes.utf8(s))

def KECCAK_256.text(s: String) -> String:
  KECCAK_256.hex_bytes(C.Bytes.utf8(s))

def KECCAK_384.text(s: String) -> String:
  KECCAK_384.hex_bytes(C.Bytes.utf8(s))

def KECCAK_512.text(s: String) -> String:
  KECCAK_512.hex_bytes(C.Bytes.utf8(s))
