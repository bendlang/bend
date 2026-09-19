import Base
import ./internal/core.bend as C

# RIPEMD-160
# ==========

# Legacy-compatible 160-bit hash. RIPEMD-160 remains useful for formats and
# protocols that require it, but new designs should prefer SHA-2/SHA-3/BLAKE.

type R160State is Data:
  R160State{a: U32, b: U32, c: U32, d: U32, e: U32}

type R160Mode is Data:
  RF0{}
  RF1{}
  RF2{}
  RF3{}
  RF4{}

def RIPEMD160.f(mode: R160Mode, +x: U32, +y: U32, +z: U32) -> U32:
  match mode:
    case RF0{}:
      U32.xor(U32.xor(x,y),z)
    case RF1{}:
      U32.or(U32.and(x,y),U32.and(U32.not(x),z))
    case RF2{}:
      U32.xor(U32.or(x,U32.not(y)),z)
    case RF3{}:
      U32.or(U32.and(x,z),U32.and(y,U32.not(z)))
    case RF4{}:
      U32.xor(x,U32.or(y,U32.not(z)))

def RIPEMD160.r1() -> List<&2,U32>:
  [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,7,4,13,1,10,6,15,3,12,0,9,5,2,14,11,8,3,10,14,4,9,15,8,1,2,7,0,6,13,11,5,12,1,9,11,10,0,8,12,4,13,3,7,15,14,5,6,2,4,0,5,9,7,12,2,10,14,1,3,8,11,6,15,13]

def RIPEMD160.r2() -> List<&2,U32>:
  [5,14,7,0,9,2,11,4,13,6,15,8,1,10,3,12,6,11,3,7,0,13,5,10,14,15,8,12,4,9,1,2,15,5,1,3,7,14,6,9,11,8,12,2,10,0,4,13,8,6,4,1,3,11,15,0,5,12,2,13,9,7,10,14,12,15,10,4,1,5,8,7,6,2,13,14,0,3,9,11]

def RIPEMD160.s1() -> List<&2,U32>:
  [11,14,15,12,5,8,7,9,11,13,14,15,6,7,9,8,7,6,8,13,11,9,7,15,7,12,15,9,11,7,13,12,11,13,6,7,14,9,13,15,14,8,13,6,5,12,7,5,11,12,14,15,14,15,9,8,9,14,5,6,8,6,5,12,9,15,5,11,6,8,13,12,5,12,13,14,11,8,5,6]

def RIPEMD160.s2() -> List<&2,U32>:
  [8,9,9,11,13,15,15,5,7,7,8,11,14,14,12,6,9,13,15,7,12,8,9,11,7,7,12,7,6,15,13,11,9,7,15,11,8,6,6,14,12,13,5,14,13,13,7,5,15,5,8,11,14,14,6,14,6,9,12,9,12,5,15,8,8,5,12,9,12,5,14,6,8,13,6,5,15,13,11,11]

def RIPEMD160.m1() -> List<&2,R160Mode>:
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF0{}),
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF1{}),
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF2{}),
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF3{}),
  List.replicate(R160Mode,16n,RF4{})))))

def RIPEMD160.m2() -> List<&2,R160Mode>:
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF4{}),
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF3{}),
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF2{}),
  List.append(&2,R160Mode,List.replicate(R160Mode,16n,RF1{}),
  List.replicate(R160Mode,16n,RF0{})))))

def RIPEMD160.k1() -> List<&2,U32>:
  List.append(&2,U32,List.replicate(U32,16n,0),
  List.append(&2,U32,List.replicate(U32,16n,1518500249),
  List.append(&2,U32,List.replicate(U32,16n,1859775393),
  List.append(&2,U32,List.replicate(U32,16n,2400959708),
  List.replicate(U32,16n,2840853838)))))

def RIPEMD160.k2() -> List<&2,U32>:
  List.append(&2,U32,List.replicate(U32,16n,1352829926),
  List.append(&2,U32,List.replicate(U32,16n,1548603684),
  List.append(&2,U32,List.replicate(U32,16n,1836072691),
  List.append(&2,U32,List.replicate(U32,16n,2053994217),
  List.replicate(U32,16n,0)))))

def RIPEMD160.step(+words: List<&2,U32>, st: R160State, r: U32, s: U32, k: U32, mode: R160Mode) -> R160State:
  match st:
    case R160State{a,+b,+c,+d,+e}:
      x = C.Bits.add4(a,RIPEMD160.f(mode,b,c,d),C.Words32.get(words,U32.to_nat(r)),k)
      t = U32.add(C.Bits.rotl32(x,U32.to_nat(s)),e)
      R160State{e,t,b,C.Bits.rotl32(c,10n),d}

def RIPEMD160.rounds(+words: List<&2,U32>, rs: List<&2,U32>, ss: List<&2,U32>, ks: List<&2,U32>, modes: List<&2,R160Mode>, st: R160State) -> R160State:
  match rs ss ks modes:
    case r <> rt s <> stail k <> kt m <> mt:
      RIPEMD160.rounds(words,rt,stail,kt,mt,RIPEMD160.step(words,st,r,s,k,m))
    case Nil{} Nil{} Nil{} Nil{}:
      st
    case _ _ _ _:
      st

def RIPEMD160.combine(base: R160State, left: R160State, right: R160State) -> R160State:
  match base left right:
    case R160State{h0,h1,h2,h3,h4} R160State{a,b,c,d,e} R160State{aa,bb,cc,dd,ee}:
      R160State{
        C.Bits.add3(h1,c,dd),
        C.Bits.add3(h2,d,ee),
        C.Bits.add3(h3,e,aa),
        C.Bits.add3(h4,a,bb),
        C.Bits.add3(h0,b,cc)
      }

def RIPEMD160.compress(+st: R160State, +bytes: List<&2,U32>) -> R160State:
  +words = C.Words32.block_le(bytes,16n)
  left = RIPEMD160.rounds(words,RIPEMD160.r1(),RIPEMD160.s1(),RIPEMD160.k1(),RIPEMD160.m1(),st)
  right = RIPEMD160.rounds(words,RIPEMD160.r2(),RIPEMD160.s2(),RIPEMD160.k2(),RIPEMD160.m2(),st)
  RIPEMD160.combine(st,left,right)

def RIPEMD160.pad.go(+rest: List<&2,U32>, +rem: U32, bits: C.W64, short: Bool) -> List<&2,U32>:
  match short:
    case True{}:
      zeros = U32.sub(55,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64le(bits,Nil{})))
    case False{}:
      zeros = U32.sub(119,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64le(bits,Nil{})))

def RIPEMD160.pad(+rest: List<&2,U32>, +length: Nat, short: Bool) -> List<&2,U32>:
  RIPEMD160.pad.go(rest,U32.from_nat(Nat.mod(length,64n)),C.W64.bits_from_bytes(length),short)

def RIPEMD160.final.blocks(+st: R160State, +padded: List<&2,U32>, one: Bool) -> R160State:
  match one:
    case True{}:
      RIPEMD160.compress(st,padded)
    case False{}:
      first = RIPEMD160.compress(st,padded)
      RIPEMD160.compress(first,List.drop(&2,U32,padded,64n))

def RIPEMD160.final(+rest: List<&2,U32>, +length: Nat, st: R160State) -> R160State:
  +short = U32.is_le(U32.from_nat(Nat.mod(length,64n)),55)
  RIPEMD160.final.blocks(st,RIPEMD160.pad(rest,length,short),short)

def RIPEMD160.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, st: R160State) -> R160State:
  match n:
    case 0n:
      RIPEMD160.final(xs,total,st)
    case 1n+p:
      next = RIPEMD160.compress(st,xs)
      RIPEMD160.blocks(p,List.drop(&2,U32,xs,64n),total,next)

def RIPEMD160.iv() -> R160State:
  R160State{1732584193,4023233417,2562383102,271733878,3285377520}

def RIPEMD160.digest(st: R160State) -> List<&2,U32>:
  match st:
    case R160State{a,b,c,d,e}:
      C.Bytes.u32le(a,C.Bytes.u32le(b,C.Bytes.u32le(c,C.Bytes.u32le(d,C.Bytes.u32le(e,Nil{})))))

def RIPEMD160.bytes(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  RIPEMD160.digest(RIPEMD160.blocks(Nat.div(n,64n),xs,n,RIPEMD160.iv()))

def RIPEMD160.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(RIPEMD160.bytes(xs))

def RIPEMD160.text(s: String) -> String:
  RIPEMD160.hex_bytes(C.Bytes.utf8(s))
