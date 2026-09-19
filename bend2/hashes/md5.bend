import Base
import ./internal/core.bend as C

type MD5State is Data:
  MD5State{a: U32, b: U32, c: U32, d: U32}

type MD5Mode is Data:
  M0{}
  M1{}
  M2{}
  M3{}

def MD5.ks() -> List<&2, U32>:
  [3614090360, 3905402710, 606105819, 3250441966, 4118548399, 1200080426, 2821735955, 4249261313, 1770035416, 2336552879, 4294925233, 2304563134, 1804603682, 4254626195, 2792965006, 1236535329, 4129170786, 3225465664, 643717713, 3921069994, 3593408605, 38016083, 3634488961, 3889429448, 568446438, 3275163606, 4107603335, 1163531501, 2850285829, 4243563512, 1735328473, 2368359562, 4294588738, 2272392833, 1839030562, 4259657740, 2763975236, 1272893353, 4139469664, 3200236656, 681279174, 3936430074, 3572445317, 76029189, 3654602809, 3873151461, 530742520, 3299628645, 4096336452, 1126891415, 2878612391, 4237533241, 1700485571, 2399980690, 4293915773, 2240044497, 1873313359, 4264355552, 2734768916, 1309151649, 4149444226, 3174756917, 718787259, 3951481745]

def MD5.ss() -> List<&2, U32>:
  [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]

def MD5.gs() -> List<&2, U32>:
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 6, 11, 0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 5, 8, 11, 14, 1, 4, 7, 10, 13, 0, 3, 6, 9, 12, 15, 2, 0, 7, 14, 5, 12, 3, 10, 1, 8, 15, 6, 13, 4, 11, 2, 9]

def MD5.modes() -> List<&2, MD5Mode>:
  [M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M0{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M1{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M2{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}, M3{}]

def MD5.f(mode: MD5Mode, +b: U32, +c: U32, +d: U32) -> U32:
  match mode:
    case M0{}:
      U32.or(U32.and(b,c), U32.and(U32.not(b),d))
    case M1{}:
      U32.or(U32.and(d,b), U32.and(U32.not(d),c))
    case M2{}:
      U32.xor(U32.xor(b,c),d)
    case M3{}:
      U32.xor(c, U32.or(b, U32.not(d)))

def MD5.step(+words: List<&2, U32>, st: MD5State, k: U32, s: U32, g: U32, mode: MD5Mode) -> MD5State:
  match st:
    case MD5State{a,+b,+c,+d}:
      x = C.Bits.add4(a, MD5.f(mode,b,c,d), k, C.Words32.get(words, U32.to_nat(g)))
      MD5State{d, U32.add(b, C.Bits.rotl32(x, U32.to_nat(s))), b, c}

def MD5.rounds(+words: List<&2, U32>, ks: List<&2,U32>, ss: List<&2,U32>, gs: List<&2,U32>, modes: List<&2,MD5Mode>, st: MD5State) -> MD5State:
  match ks ss gs modes:
    case k <> kt s <> stail g <> gt m <> mt:
      MD5.rounds(words, kt, stail, gt, mt, MD5.step(words, st, k, s, g, m))
    case Nil{} Nil{} Nil{} Nil{}:
      st
    case _ _ _ _:
      st

def MD5.add(+x: MD5State, y: MD5State) -> MD5State:
  match x y:
    case MD5State{a,b,c,d} MD5State{e,f,g,h}:
      MD5State{U32.add(a,e),U32.add(b,f),U32.add(c,g),U32.add(d,h)}

def MD5.compress(+st: MD5State, +bytes: List<&2,U32>) -> MD5State:
  words = C.Words32.block_le(bytes, 16n)
  MD5.add(st, MD5.rounds(words, MD5.ks(), MD5.ss(), MD5.gs(), MD5.modes(), st))

def MD5.pad.go(+rest: List<&2,U32>, +rem: U32, bits: C.W64, short: Bool) -> List<&2,U32>:
  match short:
    case True{}:
      zeros = U32.sub(55,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64le(bits,Nil{})))
    case False{}:
      zeros = U32.sub(119,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64le(bits,Nil{})))

def MD5.pad(+rest: List<&2,U32>, +length: Nat, short: Bool) -> List<&2,U32>:
  MD5.pad.go(rest,U32.from_nat(Nat.mod(length,64n)),C.W64.bits_from_bytes(length),short)

def MD5.final.blocks(+st: MD5State, +padded: List<&2,U32>, one: Bool) -> MD5State:
  match one:
    case True{}:
      MD5.compress(st,padded)
    case False{}:
      first = MD5.compress(st,padded)
      MD5.compress(first,List.drop(&2,U32,padded,64n))

def MD5.final(+rest: List<&2,U32>, +length: Nat, st: MD5State) -> MD5State:
  +short = U32.is_le(U32.from_nat(Nat.mod(length,64n)),55)
  padded = MD5.pad(rest,length,short)
  MD5.final.blocks(st,padded,short)

def MD5.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, st: MD5State) -> MD5State:
  match n:
    case 0n:
      MD5.final(xs,total,st)
    case 1n+p:
      next = MD5.compress(st,xs)
      MD5.blocks(p,List.drop(&2,U32,xs,64n),total,next)

def MD5.iv() -> MD5State:
  MD5State{1732584193,4023233417,2562383102,271733878}

def MD5.digest(st: MD5State) -> List<&2,U32>:
  match st:
    case MD5State{a,b,c,d}:
      C.Bytes.u32le(a,C.Bytes.u32le(b,C.Bytes.u32le(c,C.Bytes.u32le(d,Nil{}))))

def MD5.bytes(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  MD5.digest(MD5.blocks(Nat.div(n,64n),xs,n,MD5.iv()))

def MD5.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(MD5.bytes(xs))

def MD5.text(s: String) -> String:
  MD5.hex_bytes(C.Bytes.utf8(s))
