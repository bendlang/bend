import Base
import ./internal/core.bend as C

# BLAKE2s-256
# ===========

def B2S.iv() -> List<&2,U32>:
  [1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225]

def B2S.sigmas() -> List<&2,List<&2,U32>>:
  [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3], [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4], [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8], [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13], [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9], [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11], [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10], [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5], [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0]]

def B2S.msg(+m: List<&2,U32>, +sig: List<&2,U32>, pos: Nat) -> U32:
  C.Words32.get(m,U32.to_nat(C.Words32.get(sig,pos)))

def B2S.g(+v: List<&2,U32>, +a: Nat, +b: Nat, +c: Nat, +d: Nat, x: U32, y: U32) -> List<&2,U32>:
  +va0 = C.Words32.get(v,a)
  +vb0 = C.Words32.get(v,b)
  +vc0 = C.Words32.get(v,c)
  +vd0 = C.Words32.get(v,d)
  +va1 = C.Bits.add3(va0,vb0,x)
  +vd1 = C.Bits.rotr32(U32.xor(vd0,va1),16n)
  +vc1 = U32.add(vc0,vd1)
  +vb1 = C.Bits.rotr32(U32.xor(vb0,vc1),12n)
  +va2 = C.Bits.add3(va1,vb1,y)
  +vd2 = C.Bits.rotr32(U32.xor(vd1,va2),8n)
  +vc2 = U32.add(vc1,vd2)
  vb2 = C.Bits.rotr32(U32.xor(vb1,vc2),7n)
  v1 = List.set(&2,U32,v,a,va2)
  v2 = List.set(&2,U32,v1,b,vb2)
  v3 = List.set(&2,U32,v2,c,vc2)
  List.set(&2,U32,v3,d,vd2)

def B2S.round(+v: List<&2,U32>, +m: List<&2,U32>, +s: List<&2,U32>) -> List<&2,U32>:
  v0 = B2S.g(v,0n,4n,8n,12n,B2S.msg(m,s,0n),B2S.msg(m,s,1n))
  v1 = B2S.g(v0,1n,5n,9n,13n,B2S.msg(m,s,2n),B2S.msg(m,s,3n))
  v2 = B2S.g(v1,2n,6n,10n,14n,B2S.msg(m,s,4n),B2S.msg(m,s,5n))
  v3 = B2S.g(v2,3n,7n,11n,15n,B2S.msg(m,s,6n),B2S.msg(m,s,7n))
  v4 = B2S.g(v3,0n,5n,10n,15n,B2S.msg(m,s,8n),B2S.msg(m,s,9n))
  v5 = B2S.g(v4,1n,6n,11n,12n,B2S.msg(m,s,10n),B2S.msg(m,s,11n))
  v6 = B2S.g(v5,2n,7n,8n,13n,B2S.msg(m,s,12n),B2S.msg(m,s,13n))
  B2S.g(v6,3n,4n,9n,14n,B2S.msg(m,s,14n),B2S.msg(m,s,15n))

def B2S.rounds(ss: List<&2,List<&2,U32>>, +m: List<&2,U32>, v: List<&2,U32>) -> List<&2,U32>:
  match ss:
    case Nil{}:
      v
    case s <> st:
      B2S.rounds(st,m,B2S.round(v,m,s))

def B2S.init() -> List<&2,U32>:
  +iv = B2S.iv()
  [U32.xor(C.Words32.get(iv,0n),16842784), C.Words32.get(iv,1n), C.Words32.get(iv,2n), C.Words32.get(iv,3n),
   C.Words32.get(iv,4n), C.Words32.get(iv,5n), C.Words32.get(iv,6n), C.Words32.get(iv,7n)]

def B2S.mix_flag(+h: List<&2,U32>, +iv: List<&2,U32>, thi: U32, tlo: U32, last: Bool) -> List<&2,U32>:
  match last:
    case False{}:
      [C.Words32.get(h,0n),C.Words32.get(h,1n),C.Words32.get(h,2n),C.Words32.get(h,3n),
       C.Words32.get(h,4n),C.Words32.get(h,5n),C.Words32.get(h,6n),C.Words32.get(h,7n),
       C.Words32.get(iv,0n),C.Words32.get(iv,1n),C.Words32.get(iv,2n),C.Words32.get(iv,3n),
       U32.xor(C.Words32.get(iv,4n),tlo),U32.xor(C.Words32.get(iv,5n),thi),C.Words32.get(iv,6n),C.Words32.get(iv,7n)]
    case True{}:
      [C.Words32.get(h,0n),C.Words32.get(h,1n),C.Words32.get(h,2n),C.Words32.get(h,3n),
       C.Words32.get(h,4n),C.Words32.get(h,5n),C.Words32.get(h,6n),C.Words32.get(h,7n),
       C.Words32.get(iv,0n),C.Words32.get(iv,1n),C.Words32.get(iv,2n),C.Words32.get(iv,3n),
       U32.xor(C.Words32.get(iv,4n),tlo),U32.xor(C.Words32.get(iv,5n),thi),U32.not(C.Words32.get(iv,6n)),C.Words32.get(iv,7n)]


def B2S.mix_counter(+h: List<&2,U32>, thi: U32, tlo: U32, last: Bool) -> List<&2,U32>:
  B2S.mix_flag(h,B2S.iv(),thi,tlo,last)

def B2S.mix_init(+h: List<&2,U32>, t: C.W64, last: Bool) -> List<&2,U32>:
  match t:
    case C.W64{thi,tlo}:
      B2S.mix_counter(h,thi,tlo,last)


def B2S.finish(+h: List<&2,U32>, +v: List<&2,U32>) -> List<&2,U32>:
  [
    U32.xor(U32.xor(C.Words32.get(h,0n),C.Words32.get(v,0n)),C.Words32.get(v,8n)),
    U32.xor(U32.xor(C.Words32.get(h,1n),C.Words32.get(v,1n)),C.Words32.get(v,9n)),
    U32.xor(U32.xor(C.Words32.get(h,2n),C.Words32.get(v,2n)),C.Words32.get(v,10n)),
    U32.xor(U32.xor(C.Words32.get(h,3n),C.Words32.get(v,3n)),C.Words32.get(v,11n)),
    U32.xor(U32.xor(C.Words32.get(h,4n),C.Words32.get(v,4n)),C.Words32.get(v,12n)),
    U32.xor(U32.xor(C.Words32.get(h,5n),C.Words32.get(v,5n)),C.Words32.get(v,13n)),
    U32.xor(U32.xor(C.Words32.get(h,6n),C.Words32.get(v,6n)),C.Words32.get(v,14n)),
    U32.xor(U32.xor(C.Words32.get(h,7n),C.Words32.get(v,7n)),C.Words32.get(v,15n))
  ]

def B2S.compress(+h: List<&2,U32>, +block: List<&2,U32>, counter: C.W64, last: Bool) -> List<&2,U32>:
  m = C.Words32.block_le(block,16n)
  v = B2S.mix_init(h,counter,last)
  B2S.finish(h,B2S.rounds(B2S.sigmas(),m,v))

def B2S.pad(+rest: List<&2,U32>, +n: U32) -> List<&2,U32>:
  List.append(&2,U32,rest,C.Bytes.zeros(U32.sub(64,n)))

def B2S.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, +done: Nat, h: List<&2,U32>) -> List<&2,U32>:
  match n:
    case 0n:
      left = U32.from_nat(Nat.sub(total,done))
      B2S.compress(h,B2S.pad(xs,left),C.W64.from_nat(total),True{})
    case 1n+p:
      +next_done = Nat.add(done,64n)
      next = B2S.compress(h,xs,C.W64.from_nat(next_done),False{})
      B2S.blocks(p,List.drop(&2,U32,xs,64n),total,next_done,next)

def B2S.state.if(+xs: List<&2,U32>, +n: Nat, empty: Bool) -> List<&2,U32>:
  match empty:
    case True{}:
      B2S.blocks(0n,xs,n,0n,B2S.init())
    case False{}:
      nonfinal = Nat.div(Nat.sub(n,1n),64n)
      B2S.blocks(nonfinal,xs,n,0n,B2S.init())

def B2S.state(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  B2S.state.if(xs,n,Nat.is_eq(n,0n))

def BLAKE2s.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  +h = B2S.state(xs)
  C.Bytes.u32le(C.Words32.get(h,0n),C.Bytes.u32le(C.Words32.get(h,1n),C.Bytes.u32le(C.Words32.get(h,2n),C.Bytes.u32le(C.Words32.get(h,3n),
  C.Bytes.u32le(C.Words32.get(h,4n),C.Bytes.u32le(C.Words32.get(h,5n),C.Bytes.u32le(C.Words32.get(h,6n),C.Bytes.u32le(C.Words32.get(h,7n),Nil{}))))))))

def BLAKE2s.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(BLAKE2s.bytes(xs))

def BLAKE2s.text(s: String) -> String:
  BLAKE2s.hex_bytes(C.Bytes.utf8(s))
