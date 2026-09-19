import Base
import ./internal/core.bend as C

type SHA1State is Data:
  SHA1State{a: U32, b: U32, c: U32, d: U32, e: U32}

type SHA1Mode is Data:
  M0{}
  M1{}
  M2{}
  M3{}

def SHA1.modes() -> List<&2, SHA1Mode>:
  [M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}]

def SHA1.ks() -> List<&2, U32>:
  [1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1518500249, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 1859775393, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 2400959708, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782, 3395469782]

def SHA1.f(mode: SHA1Mode, +b: U32, +c: U32, +d: U32) -> U32:
  match mode:
    case M0{}:
      U32.or(U32.and(b, c), U32.and(U32.not(b), d))
    case M1{}:
      U32.xor(U32.xor(b, c), d)
    case M2{}:
      U32.or(U32.or(U32.and(b, c), U32.and(b, d)), U32.and(c, d))
    case M3{}:
      U32.xor(U32.xor(b, c), d)

def SHA1.schedule.next(+ring: List<&2, U32>) -> U32:
  C.Bits.rotl32(
    U32.xor(U32.xor(C.Words32.get(ring, 13n), C.Words32.get(ring, 8n)),
      U32.xor(C.Words32.get(ring, 2n), C.Words32.get(ring, 0n))),
    1n)

def SHA1.schedule.go(+initial: List<&2, U32>, n: Nat, +ring: List<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      List.append(&2, U32, initial, List.reverse(&2, U32, acc))
    case 1n+p:
      +w = SHA1.schedule.next(ring)
      next = List.append(&2, U32, List.drop(&2, U32, ring, 1n), [w])
      SHA1.schedule.go(initial, p, next, w <> acc)

def SHA1.schedule(+block: List<&2, U32>) -> List<&2, U32>:
  SHA1.schedule.go(block, 64n, block, Nil{})

def SHA1.step(st: SHA1State, w: U32, k: U32, mode: SHA1Mode) -> SHA1State:
  match st:
    case SHA1State{+a, +b, +c, +d, e}:
      t = C.Bits.add5(C.Bits.rotl32(a, 5n), SHA1.f(mode, b, c, d), e, k, w)
      SHA1State{t, a, C.Bits.rotl32(b, 30n), c, d}

def SHA1.rounds(ws: List<&2, U32>, ks: List<&2, U32>, modes: List<&2, SHA1Mode>, st: SHA1State) -> SHA1State:
  match ws ks modes:
    case w <> wt k <> kt m <> mt:
      SHA1.rounds(wt, kt, mt, SHA1.step(st, w, k, m))
    case Nil{} Nil{} Nil{}:
      st
    case _ _ _:
      st

def SHA1.add(+x: SHA1State, y: SHA1State) -> SHA1State:
  match x y:
    case SHA1State{a,b,c,d,e} SHA1State{f,g,h,i,j}:
      SHA1State{U32.add(a,f),U32.add(b,g),U32.add(c,h),U32.add(d,i),U32.add(e,j)}

def SHA1.compress(+st: SHA1State, +bytes: List<&2, U32>) -> SHA1State:
  block = C.Words32.block_be(bytes, 16n)
  SHA1.add(st, SHA1.rounds(SHA1.schedule(block), SHA1.ks(), SHA1.modes(), st))

def SHA1.pad.go(+rest: List<&2,U32>, +rem: U32, bits: C.W64, short: Bool) -> List<&2,U32>:
  match short:
    case True{}:
      zeros = U32.sub(55,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64be(bits,Nil{})))
    case False{}:
      zeros = U32.sub(119,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64be(bits,Nil{})))

def SHA1.pad(+rest: List<&2,U32>, +length: Nat, short: Bool) -> List<&2,U32>:
  SHA1.pad.go(rest,U32.from_nat(Nat.mod(length,64n)),C.W64.bits_from_bytes(length),short)

def SHA1.final.blocks(+st: SHA1State, +padded: List<&2, U32>, one: Bool) -> SHA1State:
  match one:
    case True{}:
      SHA1.compress(st, padded)
    case False{}:
      first = SHA1.compress(st, padded)
      SHA1.compress(first, List.drop(&2, U32, padded, 64n))

def SHA1.final(+rest: List<&2,U32>, +length: Nat, st: SHA1State) -> SHA1State:
  +short = U32.is_le(U32.from_nat(Nat.mod(length,64n)),55)
  padded = SHA1.pad(rest,length,short)
  SHA1.final.blocks(st,padded,short)

def SHA1.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, st: SHA1State) -> SHA1State:
  match n:
    case 0n:
      SHA1.final(xs,total,st)
    case 1n+p:
      next = SHA1.compress(st,xs)
      SHA1.blocks(p,List.drop(&2,U32,xs,64n),total,next)

def SHA1.iv() -> SHA1State:
  SHA1State{1732584193, 4023233417, 2562383102, 271733878, 3285377520}

def SHA1.digest(st: SHA1State) -> List<&2, U32>:
  match st:
    case SHA1State{a,b,c,d,e}:
      C.Bytes.u32be(a,C.Bytes.u32be(b,C.Bytes.u32be(c,C.Bytes.u32be(d,C.Bytes.u32be(e,Nil{})))))

def SHA1.bytes(+xs: List<&2, U32>) -> List<&2, U32>:
  +n = C.Bytes.length_nat(xs)
  SHA1.digest(SHA1.blocks(Nat.div(n,64n), xs, n, SHA1.iv()))

def SHA1.hex_bytes(xs: List<&2, U32>) -> String:
  C.Hex.bytes(SHA1.bytes(xs))

def SHA1.text(s: String) -> String:
  SHA1.hex_bytes(C.Bytes.utf8(s))
