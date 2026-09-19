import Base
import ./internal/core.bend as C

# SM3
# ===
# Chinese national hash standard (GM/T 0004 / GB/T 32905), 256-bit output.

type SM3State is Data:
  SM3State{a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32, h: U32}

type SM3Mode is Data:
  SM3Early{}
  SM3Late{}

def SM3.p0(+x: U32) -> U32:
  U32.xor(U32.xor(x,C.Bits.rotl32(x,9n)),C.Bits.rotl32(x,17n))

def SM3.p1(+x: U32) -> U32:
  U32.xor(U32.xor(x,C.Bits.rotl32(x,15n)),C.Bits.rotl32(x,23n))

def SM3.ff(mode: SM3Mode, +x: U32, +y: U32, +z: U32) -> U32:
  match mode:
    case SM3Early{}:
      U32.xor(U32.xor(x,y),z)
    case SM3Late{}:
      U32.or(U32.or(U32.and(x,y),U32.and(x,z)),U32.and(y,z))

def SM3.gg(mode: SM3Mode, +x: U32, +y: U32, +z: U32) -> U32:
  match mode:
    case SM3Early{}:
      U32.xor(U32.xor(x,y),z)
    case SM3Late{}:
      U32.or(U32.and(x,y),U32.and(U32.not(x),z))

def SM3.modes() -> List<&2,SM3Mode>:
  List.append(&2,SM3Mode,List.replicate(SM3Mode,16n,SM3Early{}),List.replicate(SM3Mode,48n,SM3Late{}))

def SM3.ts() -> List<&2,U32>:
  List.append(&2,U32,List.replicate(U32,16n,2043430169),List.replicate(U32,48n,2055708042))

def SM3.schedule.next(+ring: List<&2,U32>) -> U32:
  x = U32.xor(U32.xor(C.Words32.get(ring,0n),C.Words32.get(ring,7n)),C.Bits.rotl32(C.Words32.get(ring,13n),15n))
  U32.xor(U32.xor(SM3.p1(x),C.Bits.rotl32(C.Words32.get(ring,3n),7n)),C.Words32.get(ring,10n))

def SM3.schedule.go(+initial: List<&2,U32>, n: Nat, +ring: List<&2,U32>, acc: List<&2,U32>) -> List<&2,U32>:
  match n:
    case 0n:
      List.append(&2,U32,initial,List.reverse(&2,U32,acc))
    case 1n+p:
      +w = SM3.schedule.next(ring)
      next = List.append(&2,U32,List.drop(&2,U32,ring,1n),[w])
      SM3.schedule.go(initial,p,next,w <> acc)

def SM3.schedule(+block: List<&2,U32>) -> List<&2,U32>:
  SM3.schedule.go(block,52n,block,Nil{})

def SM3.wprime.go(+ws: List<&2,U32>, n: Nat, +i: Nat, acc: List<&2,U32>) -> List<&2,U32>:
  match n:
    case 0n:
      List.reverse(&2,U32,acc)
    case 1n+p:
      wp = U32.xor(C.Words32.get(ws,i),C.Words32.get(ws,Nat.add(i,4n)))
      SM3.wprime.go(ws,p,Nat.add(i,1n),wp <> acc)

def SM3.wprime(+ws: List<&2,U32>) -> List<&2,U32>:
  SM3.wprime.go(ws,64n,0n,Nil{})

def SM3.step(st: SM3State, w: U32, wp: U32, t: U32, j: U32, +mode: SM3Mode) -> SM3State:
  match st:
    case SM3State{+a,+b,+c,d,+e,+f,+g,h}:
      +a12 = C.Bits.rotl32(a,12n)
      +ss1 = C.Bits.rotl32(C.Bits.add3(a12,e,C.Bits.rotl32(t,U32.to_nat(U32.and(j,31)))),7n)
      ss2 = U32.xor(ss1,a12)
      tt1 = C.Bits.add4(SM3.ff(mode,a,b,c),d,ss2,wp)
      tt2 = C.Bits.add4(SM3.gg(mode,e,f,g),h,ss1,w)
      SM3State{tt1,a,C.Bits.rotl32(b,9n),c,SM3.p0(tt2),e,C.Bits.rotl32(f,19n),g}

def SM3.rounds(ws: List<&2,U32>, wps: List<&2,U32>, ts: List<&2,U32>, modes: List<&2,SM3Mode>, +j: U32, st: SM3State) -> SM3State:
  match ws wps ts modes:
    case w <> wt wp <> wpt t <> tt m <> mt:
      SM3.rounds(wt,wpt,tt,mt,U32.add(j,1),SM3.step(st,w,wp,t,j,m))
    case Nil{} Nil{} Nil{} Nil{}:
      st
    case _ _ _ _:
      st

def SM3.feed(+base: SM3State, work: SM3State) -> SM3State:
  match base work:
    case SM3State{a,b,c,d,e,f,g,h} SM3State{i,j,k,l,m,n,o,p}:
      SM3State{U32.xor(a,i),U32.xor(b,j),U32.xor(c,k),U32.xor(d,l),U32.xor(e,m),U32.xor(f,n),U32.xor(g,o),U32.xor(h,p)}

def SM3.compress(+st: SM3State, +bytes: List<&2,U32>) -> SM3State:
  block = C.Words32.block_be(bytes,16n)
  +ws = SM3.schedule(block)
  wps = SM3.wprime(ws)
  SM3.feed(st,SM3.rounds(ws,wps,SM3.ts(),SM3.modes(),0,st))

def SM3.pad.go(+rest: List<&2,U32>, +rem: U32, bits: C.W64, short: Bool) -> List<&2,U32>:
  match short:
    case True{}:
      zeros = U32.sub(55,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64be(bits,Nil{})))
    case False{}:
      zeros = U32.sub(119,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64be(bits,Nil{})))

def SM3.pad(+rest: List<&2,U32>, +length: Nat, short: Bool) -> List<&2,U32>:
  SM3.pad.go(rest,U32.from_nat(Nat.mod(length,64n)),C.W64.bits_from_bytes(length),short)

def SM3.final.blocks(+st: SM3State, +padded: List<&2,U32>, one: Bool) -> SM3State:
  match one:
    case True{}:
      SM3.compress(st,padded)
    case False{}:
      first = SM3.compress(st,padded)
      SM3.compress(first,List.drop(&2,U32,padded,64n))

def SM3.final(+rest: List<&2,U32>, +length: Nat, st: SM3State) -> SM3State:
  +short = U32.is_le(U32.from_nat(Nat.mod(length,64n)),55)
  SM3.final.blocks(st,SM3.pad(rest,length,short),short)

def SM3.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, st: SM3State) -> SM3State:
  match n:
    case 0n:
      SM3.final(xs,total,st)
    case 1n+p:
      next = SM3.compress(st,xs)
      SM3.blocks(p,List.drop(&2,U32,xs,64n),total,next)

def SM3.iv() -> SM3State:
  SM3State{1937774191,1226093241,388252375,3666478592,2842636476,372324522,3817729613,2969243214}

def SM3.digest(st: SM3State) -> List<&2,U32>:
  match st:
    case SM3State{a,b,c,d,e,f,g,h}:
      C.Bytes.u32be(a,C.Bytes.u32be(b,C.Bytes.u32be(c,C.Bytes.u32be(d,C.Bytes.u32be(e,C.Bytes.u32be(f,C.Bytes.u32be(g,C.Bytes.u32be(h,Nil{}))))))))

def SM3.bytes(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  SM3.digest(SM3.blocks(Nat.div(n,64n),xs,n,SM3.iv()))

def SM3.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SM3.bytes(xs))

def SM3.text(s: String) -> String:
  SM3.hex_bytes(C.Bytes.utf8(s))
