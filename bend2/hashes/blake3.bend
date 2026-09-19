import Base
import ./internal/core.bend as C

# BLAKE3 (unkeyed hash mode)
# =========================
# Standard 32-byte digest. The core keeps the Output object so root finalization
# follows the BLAKE3 specification rather than treating the root CV as a digest.

type B3Output is Data:
  B3Output{cv: List<&2,U32>, block: List<&2,U32>, counter: C.W64, block_len: U32, flags: U32}

def B3.iv() -> List<&2,U32>:
  [1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225]

def B3.sigmas() -> List<&2,List<&2,U32>>:
  [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8], [3, 4, 10, 12, 13, 2, 7, 14, 6, 5, 9, 0, 11, 15, 8, 1], [10, 7, 12, 9, 14, 3, 13, 15, 4, 0, 11, 2, 5, 8, 1, 6], [12, 13, 9, 11, 15, 10, 14, 8, 7, 2, 5, 3, 0, 1, 6, 4], [9, 14, 11, 5, 8, 12, 15, 1, 13, 3, 0, 10, 2, 6, 4, 7], [11, 15, 5, 0, 1, 9, 8, 6, 14, 10, 2, 12, 3, 4, 7, 13]]

def B3.msg(+m: List<&2,U32>, +sig: List<&2,U32>, pos: Nat) -> U32:
  C.Words32.get(m,U32.to_nat(C.Words32.get(sig,pos)))

def B3.g(+v: List<&2,U32>, +a: Nat, +b: Nat, +c: Nat, +d: Nat, x: U32, y: U32) -> List<&2,U32>:
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

def B3.round(+v: List<&2,U32>, +m: List<&2,U32>, +s: List<&2,U32>) -> List<&2,U32>:
  v0 = B3.g(v,0n,4n,8n,12n,B3.msg(m,s,0n),B3.msg(m,s,1n))
  v1 = B3.g(v0,1n,5n,9n,13n,B3.msg(m,s,2n),B3.msg(m,s,3n))
  v2 = B3.g(v1,2n,6n,10n,14n,B3.msg(m,s,4n),B3.msg(m,s,5n))
  v3 = B3.g(v2,3n,7n,11n,15n,B3.msg(m,s,6n),B3.msg(m,s,7n))
  v4 = B3.g(v3,0n,5n,10n,15n,B3.msg(m,s,8n),B3.msg(m,s,9n))
  v5 = B3.g(v4,1n,6n,11n,12n,B3.msg(m,s,10n),B3.msg(m,s,11n))
  v6 = B3.g(v5,2n,7n,8n,13n,B3.msg(m,s,12n),B3.msg(m,s,13n))
  B3.g(v6,3n,4n,9n,14n,B3.msg(m,s,14n),B3.msg(m,s,15n))

def B3.rounds(ss: List<&2,List<&2,U32>>, +m: List<&2,U32>, v: List<&2,U32>) -> List<&2,U32>:
  match ss:
    case Nil{}:
      v
    case s <> st:
      B3.rounds(st,m,B3.round(v,m,s))

def B3.finish(+cv: List<&2,U32>, +v: List<&2,U32>) -> List<&2,U32>:
  [
    U32.xor(C.Words32.get(v,0n),C.Words32.get(v,8n)),
    U32.xor(C.Words32.get(v,1n),C.Words32.get(v,9n)),
    U32.xor(C.Words32.get(v,2n),C.Words32.get(v,10n)),
    U32.xor(C.Words32.get(v,3n),C.Words32.get(v,11n)),
    U32.xor(C.Words32.get(v,4n),C.Words32.get(v,12n)),
    U32.xor(C.Words32.get(v,5n),C.Words32.get(v,13n)),
    U32.xor(C.Words32.get(v,6n),C.Words32.get(v,14n)),
    U32.xor(C.Words32.get(v,7n),C.Words32.get(v,15n)),
    U32.xor(C.Words32.get(v,8n),C.Words32.get(cv,0n)),
    U32.xor(C.Words32.get(v,9n),C.Words32.get(cv,1n)),
    U32.xor(C.Words32.get(v,10n),C.Words32.get(cv,2n)),
    U32.xor(C.Words32.get(v,11n),C.Words32.get(cv,3n)),
    U32.xor(C.Words32.get(v,12n),C.Words32.get(cv,4n)),
    U32.xor(C.Words32.get(v,13n),C.Words32.get(cv,5n)),
    U32.xor(C.Words32.get(v,14n),C.Words32.get(cv,6n)),
    U32.xor(C.Words32.get(v,15n),C.Words32.get(cv,7n))
  ]

def B3.compress.counter(+cv: List<&2,U32>, +block: List<&2,U32>, counter_hi: U32, counter_lo: U32, block_len: U32, flags: U32) -> List<&2,U32>:
  +iv = B3.iv()
  +m = block
  B3.finish(cv,B3.rounds(B3.sigmas(),m,
    [C.Words32.get(cv,0n),C.Words32.get(cv,1n),C.Words32.get(cv,2n),C.Words32.get(cv,3n),
     C.Words32.get(cv,4n),C.Words32.get(cv,5n),C.Words32.get(cv,6n),C.Words32.get(cv,7n),
     C.Words32.get(iv,0n),C.Words32.get(iv,1n),C.Words32.get(iv,2n),C.Words32.get(iv,3n),
     counter_lo,counter_hi,block_len,flags]))

def B3.compress(+cv: List<&2,U32>, +block: List<&2,U32>, counter: C.W64, block_len: U32, flags: U32) -> List<&2,U32>:
  match counter:
    case C.W64{hi,lo}:
      B3.compress.counter(cv,block,hi,lo,block_len,flags)

def B3.cv(words: List<&2,U32>) -> List<&2,U32>:
  List.take(&2,U32,words,8n)

def B3.output_cv(out: B3Output) -> List<&2,U32>:
  match out:
    case B3Output{cv,block,counter,block_len,flags}:
      B3.cv(B3.compress(cv,block,counter,block_len,flags))

def B3.start_flag(zero: Bool) -> U32:
  match zero:
    case True{}:
      1
    case False{}:
      0

def B3.nonfinal(+cv: List<&2,U32>, +block: List<&2,U32>, counter: C.W64, done: U32) -> List<&2,U32>:
  flag = B3.start_flag(U32.is_zero(done))
  B3.cv(B3.compress(cv,C.Words32.block_le(block,16n),counter,64,flag))

def B3.final_flags(zero: Bool) -> U32:
  match zero:
    case True{}:
      3
    case False{}:
      2

def B3.pad(+rest: List<&2,U32>, +n: U32) -> List<&2,U32>:
  # rest may still point at later chunks. Only the final n bytes belong to this
  # block; truncating here avoids rebuilding the entire remaining message in
  # List.append and keeps chunk finalization linear in input size.
  List.append(
    &2,
    U32,
    List.take(&2,U32,rest,U32.to_nat(n)),
    C.Bytes.zeros(U32.sub(64,n))
  )

def B3.chunk_blocks(n: Nat, +xs: List<&2,U32>, +total: U32, +done: U32, cv: List<&2,U32>, +counter: C.W64) -> B3Output:
  match n:
    case 0n:
      +left = U32.sub(total,done)
      flags = B3.final_flags(U32.is_zero(done))
      B3Output{cv,C.Words32.block_le(B3.pad(xs,left),16n),counter,left,flags}
    case 1n+p:
      next = B3.nonfinal(cv,xs,counter,done)
      B3.chunk_blocks(p,List.drop(&2,U32,xs,64n),total,U32.add(done,64),next,counter)

def B3.chunk_output.if(+xs: List<&2,U32>, +length: U32, counter: C.W64, empty: Bool) -> B3Output:
  match empty:
    case True{}:
      B3.chunk_blocks(0n,xs,length,0,B3.iv(),counter)
    case False{}:
      blocks = U32.div(U32.sub(length,1),64)
      B3.chunk_blocks(U32.to_nat(blocks),xs,length,0,B3.iv(),counter)

def B3.chunk_output(+xs: List<&2,U32>, +length: U32, +counter: C.W64) -> B3Output:
  B3.chunk_output.if(xs,length,counter,U32.is_zero(length))

def B3.parent_output(left: List<&2,U32>, right: List<&2,U32>) -> B3Output:
  B3Output{B3.iv(),List.append(&2,U32,left,right),C.W64.zero(),64,4}

def B3.parent_cv(left: List<&2,U32>, right: List<&2,U32>) -> List<&2,U32>:
  B3.output_cv(B3.parent_output(left,right))

# Build chunk CVs into a reversed accumulator. The old direct
#   cv <> B3.chunk_cvs(...)
# form retained one JavaScript call frame per 1024-byte chunk and could exhaust
# the Node stack on multi-megabyte inputs. This version is tail-recursive.
def B3.chunk_cvs.go(n: Nat, +xs: List<&2,U32>, +index: Nat, acc: List<&2,List<&2,U32>>) -> List<&2,List<&2,U32>>:
  match n:
    case 0n:
      List.reverse(&2,List<&2,U32>,acc)
    case 1n:
      length = U32.from_nat(C.Bytes.length_nat(xs))
      cv = B3.output_cv(B3.chunk_output(xs,length,C.W64.from_nat(index)))
      List.reverse(&2,List<&2,U32>,cv <> acc)
    case 1n+p:
      cv = B3.output_cv(B3.chunk_output(xs,1024,C.W64.from_nat(index)))
      B3.chunk_cvs.go(p,List.drop(&2,U32,xs,1024n),Nat.add(index,1n),cv <> acc)

def B3.chunk_cvs(n: Nat, +xs: List<&2,U32>, +index: Nat) -> List<&2,List<&2,U32>>:
  B3.chunk_cvs.go(n,xs,index,Nil{})

def B3.reduce_level(cvs: List<&2,List<&2,U32>>, acc: List<&2,List<&2,U32>>) -> List<&2,List<&2,U32>>:
  match cvs:
    case Nil{}:
      List.reverse(&2,List<&2,U32>,acc)
    case a <> Nil{}:
      # acc stores completed parents in reverse order. Prepending the odd CV and
      # reversing once yields the correct normal order without unbounded
      # non-tail List.append recursion on the JavaScript backend.
      List.reverse(&2,List<&2,U32>,a <> acc)
    case a <> b <> rest:
      B3.reduce_level(rest,B3.parent_cv(a,b) <> acc)

def B3.reduce(fuel: Nat, cvs: List<&2,List<&2,U32>>) -> B3Output:
  match fuel cvs:
    case 1n+p +a <> +b <> Nil{}:
      B3.parent_output(a,b)
    case 1n+p +a <> +b <> +c <> rest:
      B3.reduce(p,B3.reduce_level(a <> b <> c <> rest,Nil{}))
    case 1n+p +a <> Nil{}:
      B3.parent_output(a,a)
    case 1n+p Nil{}:
      B3.parent_output(B3.iv(),B3.iv())
    case 0n +xs:
      B3.parent_output(B3.iv(),B3.iv())

def B3.chunk_count.if(n: Nat, zero: Bool) -> Nat:
  match zero:
    case True{}:
      1n
    case False{}:
      Nat.add(Nat.div(Nat.sub(n,1n),1024n),1n)

def B3.chunk_count(+n: Nat) -> Nat:
  B3.chunk_count.if(n,Nat.is_eq(n,0n))

def B3.root.multi(+xs: List<&2,U32>, +chunks: Nat) -> B3Output:
  cvs = B3.chunk_cvs(chunks,xs,0n)
  B3.reduce(chunks,cvs)

def B3.root.if(+xs: List<&2,U32>, +n: Nat, +chunks: Nat, one: Bool) -> B3Output:
  match one:
    case True{}:
      B3.chunk_output(xs,U32.from_nat(n),C.W64.zero())
    case False{}:
      B3.root.multi(xs,chunks)

def B3.root(+xs: List<&2,U32>) -> B3Output:
  +n = C.Bytes.length_nat(xs)
  +chunks = B3.chunk_count(n)
  B3.root.if(xs,n,chunks,Nat.is_eq(chunks,1n))

def B3.words_le(words: List<&2,U32>) -> List<&2,U32>:
  match words:
    case Nil{}:
      Nil{}
    case h <> t:
      C.Bytes.u32le(h,B3.words_le(t))

def B3.root_bytes(out: B3Output) -> List<&2,U32>:
  match out:
    case B3Output{cv,block,counter,block_len,flags}:
      all = B3.compress(cv,block,C.W64.zero(),block_len,U32.or(flags,8))
      List.take(&2,U32,B3.words_le(all),32n)

def BLAKE3.bytes(xs: List<&2,U32>) -> List<&2,U32>:
  B3.root_bytes(B3.root(xs))

def BLAKE3.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(BLAKE3.bytes(xs))

def BLAKE3.text(s: String) -> String:
  BLAKE3.hex_bytes(C.Bytes.utf8(s))
