import Base
import ./internal/core.bend as C

# BLAKE2b-512
# ===========

def B2B.iv() -> List<&2,C.W64>:
  [C.W64{1779033703, 4089235720}, C.W64{3144134277, 2227873595}, C.W64{1013904242, 4271175723}, C.W64{2773480762, 1595750129}, C.W64{1359893119, 2917565137}, C.W64{2600822924, 725511199}, C.W64{528734635, 4215389547}, C.W64{1541459225, 327033209}]

def B2B.sigmas() -> List<&2,List<&2,U32>>:
  [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3], [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4], [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8], [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13], [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9], [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11], [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10], [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5], [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3]]

def B2B.msg(+m: List<&2,C.W64>, +sig: List<&2,U32>, pos: Nat) -> C.W64:
  C.Words64.get(m,U32.to_nat(C.Words32.get(sig,pos)))

def B2B.g(+v: List<&2,C.W64>, +a: Nat, +b: Nat, +c: Nat, +d: Nat, x: C.W64, y: C.W64) -> List<&2,C.W64>:
  +va0 = C.Words64.get(v,a)
  +vb0 = C.Words64.get(v,b)
  +vc0 = C.Words64.get(v,c)
  +vd0 = C.Words64.get(v,d)
  +va1 = C.W64.add3(va0,vb0,x)
  +vd1 = C.W64.rotr(C.W64.xor(vd0,va1),32n)
  +vc1 = C.W64.add(vc0,vd1)
  +vb1 = C.W64.rotr(C.W64.xor(vb0,vc1),24n)
  +va2 = C.W64.add3(va1,vb1,y)
  +vd2 = C.W64.rotr(C.W64.xor(vd1,va2),16n)
  +vc2 = C.W64.add(vc1,vd2)
  vb2 = C.W64.rotr(C.W64.xor(vb1,vc2),63n)
  v1 = List.set(&2,C.W64,v,a,va2)
  v2 = List.set(&2,C.W64,v1,b,vb2)
  v3 = List.set(&2,C.W64,v2,c,vc2)
  List.set(&2,C.W64,v3,d,vd2)

def B2B.round(+v: List<&2,C.W64>, +m: List<&2,C.W64>, +s: List<&2,U32>) -> List<&2,C.W64>:
  v0 = B2B.g(v,0n,4n,8n,12n,B2B.msg(m,s,0n),B2B.msg(m,s,1n))
  v1 = B2B.g(v0,1n,5n,9n,13n,B2B.msg(m,s,2n),B2B.msg(m,s,3n))
  v2 = B2B.g(v1,2n,6n,10n,14n,B2B.msg(m,s,4n),B2B.msg(m,s,5n))
  v3 = B2B.g(v2,3n,7n,11n,15n,B2B.msg(m,s,6n),B2B.msg(m,s,7n))
  v4 = B2B.g(v3,0n,5n,10n,15n,B2B.msg(m,s,8n),B2B.msg(m,s,9n))
  v5 = B2B.g(v4,1n,6n,11n,12n,B2B.msg(m,s,10n),B2B.msg(m,s,11n))
  v6 = B2B.g(v5,2n,7n,8n,13n,B2B.msg(m,s,12n),B2B.msg(m,s,13n))
  B2B.g(v6,3n,4n,9n,14n,B2B.msg(m,s,14n),B2B.msg(m,s,15n))

def B2B.rounds(ss: List<&2,List<&2,U32>>, +m: List<&2,C.W64>, v: List<&2,C.W64>) -> List<&2,C.W64>:
  match ss:
    case Nil{}:
      v
    case s <> st:
      B2B.rounds(st,m,B2B.round(v,m,s))

def B2B.init() -> List<&2,C.W64>:
  +iv = B2B.iv()
  [C.W64.xor(C.Words64.get(iv,0n),C.W64{0,16842816}), C.Words64.get(iv,1n), C.Words64.get(iv,2n), C.Words64.get(iv,3n),
   C.Words64.get(iv,4n), C.Words64.get(iv,5n), C.Words64.get(iv,6n), C.Words64.get(iv,7n)]

def B2B.mix_flag(+h: List<&2,C.W64>, +iv: List<&2,C.W64>, counter: C.W64, last: Bool) -> List<&2,C.W64>:
  match last:
    case False{}:
      [C.Words64.get(h,0n),C.Words64.get(h,1n),C.Words64.get(h,2n),C.Words64.get(h,3n),
       C.Words64.get(h,4n),C.Words64.get(h,5n),C.Words64.get(h,6n),C.Words64.get(h,7n),
       C.Words64.get(iv,0n),C.Words64.get(iv,1n),C.Words64.get(iv,2n),C.Words64.get(iv,3n),
       C.W64.xor(C.Words64.get(iv,4n),counter),C.Words64.get(iv,5n),C.Words64.get(iv,6n),C.Words64.get(iv,7n)]
    case True{}:
      [C.Words64.get(h,0n),C.Words64.get(h,1n),C.Words64.get(h,2n),C.Words64.get(h,3n),
       C.Words64.get(h,4n),C.Words64.get(h,5n),C.Words64.get(h,6n),C.Words64.get(h,7n),
       C.Words64.get(iv,0n),C.Words64.get(iv,1n),C.Words64.get(iv,2n),C.Words64.get(iv,3n),
       C.W64.xor(C.Words64.get(iv,4n),counter),C.Words64.get(iv,5n),C.W64.not(C.Words64.get(iv,6n)),C.Words64.get(iv,7n)]

def B2B.mix_init(+h: List<&2,C.W64>, counter: C.W64, last: Bool) -> List<&2,C.W64>:
  B2B.mix_flag(h,B2B.iv(),counter,last)

def B2B.finish(+h: List<&2,C.W64>, +v: List<&2,C.W64>) -> List<&2,C.W64>:
  [
    C.W64.xor(C.W64.xor(C.Words64.get(h,0n),C.Words64.get(v,0n)),C.Words64.get(v,8n)),
    C.W64.xor(C.W64.xor(C.Words64.get(h,1n),C.Words64.get(v,1n)),C.Words64.get(v,9n)),
    C.W64.xor(C.W64.xor(C.Words64.get(h,2n),C.Words64.get(v,2n)),C.Words64.get(v,10n)),
    C.W64.xor(C.W64.xor(C.Words64.get(h,3n),C.Words64.get(v,3n)),C.Words64.get(v,11n)),
    C.W64.xor(C.W64.xor(C.Words64.get(h,4n),C.Words64.get(v,4n)),C.Words64.get(v,12n)),
    C.W64.xor(C.W64.xor(C.Words64.get(h,5n),C.Words64.get(v,5n)),C.Words64.get(v,13n)),
    C.W64.xor(C.W64.xor(C.Words64.get(h,6n),C.Words64.get(v,6n)),C.Words64.get(v,14n)),
    C.W64.xor(C.W64.xor(C.Words64.get(h,7n),C.Words64.get(v,7n)),C.Words64.get(v,15n))
  ]

def B2B.compress(+h: List<&2,C.W64>, +block: List<&2,U32>, counter: C.W64, last: Bool) -> List<&2,C.W64>:
  m = C.Words64.block_le(block,16n)
  v = B2B.mix_init(h,counter,last)
  B2B.finish(h,B2B.rounds(B2B.sigmas(),m,v))

def B2B.pad(+rest: List<&2,U32>, +n: U32) -> List<&2,U32>:
  List.append(&2,U32,rest,C.Bytes.zeros(U32.sub(128,n)))

def B2B.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, +done: Nat, h: List<&2,C.W64>) -> List<&2,C.W64>:
  match n:
    case 0n:
      left = U32.from_nat(Nat.sub(total,done))
      B2B.compress(h,B2B.pad(xs,left),C.W64.from_nat(total),True{})
    case 1n+p:
      +next_done = Nat.add(done,128n)
      next = B2B.compress(h,xs,C.W64.from_nat(next_done),False{})
      B2B.blocks(p,List.drop(&2,U32,xs,128n),total,next_done,next)

def B2B.state.if(+xs: List<&2,U32>, +n: Nat, empty: Bool) -> List<&2,C.W64>:
  match empty:
    case True{}:
      B2B.blocks(0n,xs,n,0n,B2B.init())
    case False{}:
      nonfinal = Nat.div(Nat.sub(n,1n),128n)
      B2B.blocks(nonfinal,xs,n,0n,B2B.init())

def B2B.state(+xs: List<&2,U32>) -> List<&2,C.W64>:
  +n = C.Bytes.length_nat(xs)
  B2B.state.if(xs,n,Nat.is_eq(n,0n))

def BLAKE2b.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  +h = B2B.state(xs)
  C.Bytes.u64le(C.Words64.get(h,0n),C.Bytes.u64le(C.Words64.get(h,1n),C.Bytes.u64le(C.Words64.get(h,2n),C.Bytes.u64le(C.Words64.get(h,3n),
  C.Bytes.u64le(C.Words64.get(h,4n),C.Bytes.u64le(C.Words64.get(h,5n),C.Bytes.u64le(C.Words64.get(h,6n),C.Bytes.u64le(C.Words64.get(h,7n),Nil{}))))))))

def BLAKE2b.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(BLAKE2b.bytes(xs))

def BLAKE2b.text(s: String) -> String:
  BLAKE2b.hex_bytes(C.Bytes.utf8(s))
