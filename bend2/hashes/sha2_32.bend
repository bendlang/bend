import Base
import ./internal/core.bend as C

# SHA-224 / SHA-256
# =================

type S256 is Data:
  S256{a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32, h: U32}

def SHA2_32.ch(+x: U32, +y: U32, +z: U32) -> U32:
  U32.xor(U32.and(x, y), U32.and(U32.not(x), z))

def SHA2_32.maj(+x: U32, +y: U32, +z: U32) -> U32:
  U32.xor(U32.xor(U32.and(x, y), U32.and(x, z)), U32.and(y, z))

def SHA2_32.big0(+x: U32) -> U32:
  U32.xor(U32.xor(C.Bits.rotr32(x, 2n), C.Bits.rotr32(x, 13n)), C.Bits.rotr32(x, 22n))

def SHA2_32.big1(+x: U32) -> U32:
  U32.xor(U32.xor(C.Bits.rotr32(x, 6n), C.Bits.rotr32(x, 11n)), C.Bits.rotr32(x, 25n))

def SHA2_32.small0(+x: U32) -> U32:
  U32.xor(U32.xor(C.Bits.rotr32(x, 7n), C.Bits.rotr32(x, 18n)), U32.shrn(x, 3n))

def SHA2_32.small1(+x: U32) -> U32:
  U32.xor(U32.xor(C.Bits.rotr32(x, 17n), C.Bits.rotr32(x, 19n)), U32.shrn(x, 10n))

def SHA2_32.ks() -> List<&2, U32>:
  [1116352408, 1899447441, 3049323471, 3921009573, 961987163, 1508970993, 2453635748, 2870763221, 3624381080, 310598401, 607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580, 3835390401, 4022224774, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986, 2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711, 113926993, 338241895, 666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037, 2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909, 275423344, 430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779, 1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298]

def SHA2_32.schedule.next(+ring: List<&2, U32>) -> U32:
  C.Bits.add4(
    SHA2_32.small1(C.Words32.get(ring, 14n)),
    C.Words32.get(ring, 9n),
    SHA2_32.small0(C.Words32.get(ring, 1n)),
    C.Words32.get(ring, 0n))

def SHA2_32.schedule.go(+initial: List<&2, U32>, n: Nat, +ring: List<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      List.append(&2, U32, initial, List.reverse(&2, U32, acc))
    case 1n+p:
      +w = SHA2_32.schedule.next(ring)
      next = List.append(&2, U32, List.drop(&2, U32, ring, 1n), [w])
      SHA2_32.schedule.go(initial, p, next, w <> acc)

def SHA2_32.schedule(+block: List<&2, U32>) -> List<&2, U32>:
  SHA2_32.schedule.go(block, 48n, block, Nil{})

def SHA2_32.step(st: S256, w: U32, k: U32) -> S256:
  match st:
    case S256{+a, +b, +c, d, +e, +f, +g, h}:
      +t1 = C.Bits.add5(h, SHA2_32.big1(e), SHA2_32.ch(e, f, g), k, w)
      t2 = U32.add(SHA2_32.big0(a), SHA2_32.maj(a, b, c))
      S256{U32.add(t1, t2), a, b, c, U32.add(d, t1), e, f, g}

def SHA2_32.rounds(ws: List<&2, U32>, ks: List<&2, U32>, st: S256) -> S256:
  match ws ks:
    case w <> wt k <> kt:
      SHA2_32.rounds(wt, kt, SHA2_32.step(st, w, k))
    case Nil{} Nil{}:
      st
    case Nil{} k <> kt:
      st
    case w <> wt Nil{}:
      st

def SHA2_32.add(+x: S256, y: S256) -> S256:
  match x y:
    case S256{xa, xb, xc, xd, xe, xf, xg, xh} S256{ya, yb, yc, yd, ye, yf, yg, yh}:
      S256{U32.add(xa, ya), U32.add(xb, yb), U32.add(xc, yc), U32.add(xd, yd), U32.add(xe, ye), U32.add(xf, yf), U32.add(xg, yg), U32.add(xh, yh)}

def SHA2_32.compress(+st: S256, +bytes: List<&2, U32>) -> S256:
  block = C.Words32.block_be(bytes, 16n)
  SHA2_32.add(st, SHA2_32.rounds(SHA2_32.schedule(block), SHA2_32.ks(), st))

def SHA2_32.pad.go(+rest: List<&2,U32>, +rem: U32, bits: C.W64, short: Bool) -> List<&2,U32>:
  match short:
    case True{}:
      zeros = U32.sub(55,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64be(bits,Nil{})))
    case False{}:
      zeros = U32.sub(119,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),C.Bytes.u64be(bits,Nil{})))

def SHA2_32.pad(+rest: List<&2,U32>, +length: Nat, short: Bool) -> List<&2,U32>:
  SHA2_32.pad.go(rest,U32.from_nat(Nat.mod(length,64n)),C.W64.bits_from_bytes(length),short)

def SHA2_32.final.blocks(+st: S256, +padded: List<&2, U32>, one: Bool) -> S256:
  match one:
    case True{}:
      SHA2_32.compress(st, padded)
    case False{}:
      first = SHA2_32.compress(st, padded)
      SHA2_32.compress(first, List.drop(&2, U32, padded, 64n))

def SHA2_32.final(+rest: List<&2,U32>, +length: Nat, st: S256) -> S256:
  +short = U32.is_le(U32.from_nat(Nat.mod(length,64n)),55)
  padded = SHA2_32.pad(rest,length,short)
  SHA2_32.final.blocks(st,padded,short)

def SHA2_32.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, st: S256) -> S256:
  match n:
    case 0n:
      SHA2_32.final(xs,total,st)
    case 1n+p:
      next = SHA2_32.compress(st,xs)
      SHA2_32.blocks(p,List.drop(&2,U32,xs,64n),total,next)

def SHA2_32.run(+xs: List<&2,U32>, iv: S256) -> S256:
  +n = C.Bytes.length_nat(xs)
  SHA2_32.blocks(Nat.div(n,64n),xs,n,iv)

def SHA256.iv() -> S256:
  S256{1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225}

def SHA224.iv() -> S256:
  S256{3238371032, 914150663, 812702999, 4144912697, 4290775857, 1750603025, 1694076839, 3204075428}

def SHA256.digest(st: S256) -> List<&2, U32>:
  match st:
    case S256{a,b,c,d,e,f,g,h}:
      C.Bytes.u32be(a, C.Bytes.u32be(b, C.Bytes.u32be(c, C.Bytes.u32be(d,
      C.Bytes.u32be(e, C.Bytes.u32be(f, C.Bytes.u32be(g, C.Bytes.u32be(h, Nil{}))))))))

def SHA224.digest(st: S256) -> List<&2, U32>:
  match st:
    case S256{a,b,c,d,e,f,g,h}:
      C.Bytes.u32be(a, C.Bytes.u32be(b, C.Bytes.u32be(c, C.Bytes.u32be(d,
      C.Bytes.u32be(e, C.Bytes.u32be(f, C.Bytes.u32be(g, Nil{})))))))

def SHA256.bytes(xs: List<&2, U32>) -> List<&2, U32>:
  SHA256.digest(SHA2_32.run(xs, SHA256.iv()))

def SHA224.bytes(xs: List<&2, U32>) -> List<&2, U32>:
  SHA224.digest(SHA2_32.run(xs, SHA224.iv()))

def SHA256.hex_bytes(xs: List<&2, U32>) -> String:
  C.Hex.bytes(SHA256.bytes(xs))

def SHA224.hex_bytes(xs: List<&2, U32>) -> String:
  C.Hex.bytes(SHA224.bytes(xs))

def SHA256.text(s: String) -> String:
  SHA256.hex_bytes(C.Bytes.utf8(s))

def SHA224.text(s: String) -> String:
  SHA224.hex_bytes(C.Bytes.utf8(s))
