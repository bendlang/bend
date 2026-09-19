import Base
import ./internal/core.bend as C

type S512 is Data:
  S512{a: C.W64, b: C.W64, c: C.W64, d: C.W64, e: C.W64, f: C.W64, g: C.W64, h: C.W64}

def SHA2_64.ch(+x: C.W64, +y: C.W64, +z: C.W64) -> C.W64:
  C.W64.xor(C.W64.and(x,y), C.W64.and(C.W64.not(x),z))

def SHA2_64.maj(+x: C.W64, +y: C.W64, +z: C.W64) -> C.W64:
  C.W64.xor(C.W64.xor(C.W64.and(x,y),C.W64.and(x,z)),C.W64.and(y,z))

def SHA2_64.big0(+x: C.W64) -> C.W64:
  C.W64.xor(C.W64.xor(C.W64.rotr(x,28n),C.W64.rotr(x,34n)),C.W64.rotr(x,39n))

def SHA2_64.big1(+x: C.W64) -> C.W64:
  C.W64.xor(C.W64.xor(C.W64.rotr(x,14n),C.W64.rotr(x,18n)),C.W64.rotr(x,41n))

def SHA2_64.small0(+x: C.W64) -> C.W64:
  C.W64.xor(C.W64.xor(C.W64.rotr(x,1n),C.W64.rotr(x,8n)),C.W64.shr(x,7n))

def SHA2_64.small1(+x: C.W64) -> C.W64:
  C.W64.xor(C.W64.xor(C.W64.rotr(x,19n),C.W64.rotr(x,61n)),C.W64.shr(x,6n))

def SHA2_64.ks() -> List<&2, C.W64>:
  [C.W64{1116352408, 3609767458}, C.W64{1899447441, 602891725}, C.W64{3049323471, 3964484399}, C.W64{3921009573, 2173295548}, C.W64{961987163, 4081628472}, C.W64{1508970993, 3053834265}, C.W64{2453635748, 2937671579}, C.W64{2870763221, 3664609560}, C.W64{3624381080, 2734883394}, C.W64{310598401, 1164996542}, C.W64{607225278, 1323610764}, C.W64{1426881987, 3590304994}, C.W64{1925078388, 4068182383}, C.W64{2162078206, 991336113}, C.W64{2614888103, 633803317}, C.W64{3248222580, 3479774868}, C.W64{3835390401, 2666613458}, C.W64{4022224774, 944711139}, C.W64{264347078, 2341262773}, C.W64{604807628, 2007800933}, C.W64{770255983, 1495990901}, C.W64{1249150122, 1856431235}, C.W64{1555081692, 3175218132}, C.W64{1996064986, 2198950837}, C.W64{2554220882, 3999719339}, C.W64{2821834349, 766784016}, C.W64{2952996808, 2566594879}, C.W64{3210313671, 3203337956}, C.W64{3336571891, 1034457026}, C.W64{3584528711, 2466948901}, C.W64{113926993, 3758326383}, C.W64{338241895, 168717936}, C.W64{666307205, 1188179964}, C.W64{773529912, 1546045734}, C.W64{1294757372, 1522805485}, C.W64{1396182291, 2643833823}, C.W64{1695183700, 2343527390}, C.W64{1986661051, 1014477480}, C.W64{2177026350, 1206759142}, C.W64{2456956037, 344077627}, C.W64{2730485921, 1290863460}, C.W64{2820302411, 3158454273}, C.W64{3259730800, 3505952657}, C.W64{3345764771, 106217008}, C.W64{3516065817, 3606008344}, C.W64{3600352804, 1432725776}, C.W64{4094571909, 1467031594}, C.W64{275423344, 851169720}, C.W64{430227734, 3100823752}, C.W64{506948616, 1363258195}, C.W64{659060556, 3750685593}, C.W64{883997877, 3785050280}, C.W64{958139571, 3318307427}, C.W64{1322822218, 3812723403}, C.W64{1537002063, 2003034995}, C.W64{1747873779, 3602036899}, C.W64{1955562222, 1575990012}, C.W64{2024104815, 1125592928}, C.W64{2227730452, 2716904306}, C.W64{2361852424, 442776044}, C.W64{2428436474, 593698344}, C.W64{2756734187, 3733110249}, C.W64{3204031479, 2999351573}, C.W64{3329325298, 3815920427}, C.W64{3391569614, 3928383900}, C.W64{3515267271, 566280711}, C.W64{3940187606, 3454069534}, C.W64{4118630271, 4000239992}, C.W64{116418474, 1914138554}, C.W64{174292421, 2731055270}, C.W64{289380356, 3203993006}, C.W64{460393269, 320620315}, C.W64{685471733, 587496836}, C.W64{852142971, 1086792851}, C.W64{1017036298, 365543100}, C.W64{1126000580, 2618297676}, C.W64{1288033470, 3409855158}, C.W64{1501505948, 4234509866}, C.W64{1607167915, 987167468}, C.W64{1816402316, 1246189591}]

def SHA2_64.schedule.next(+ring: List<&2,C.W64>) -> C.W64:
  C.W64.add4(
    SHA2_64.small1(C.Words64.get(ring,14n)),
    C.Words64.get(ring,9n),
    SHA2_64.small0(C.Words64.get(ring,1n)),
    C.Words64.get(ring,0n))

def SHA2_64.schedule.go(+initial: List<&2,C.W64>, n: Nat, +ring: List<&2,C.W64>, acc: List<&2,C.W64>) -> List<&2,C.W64>:
  match n:
    case 0n:
      List.append(&2,C.W64,initial,List.reverse(&2,C.W64,acc))
    case 1n+p:
      +word = SHA2_64.schedule.next(ring)
      next = List.append(&2,C.W64,List.drop(&2,C.W64,ring,1n),[word])
      SHA2_64.schedule.go(initial,p,next,word <> acc)

def SHA2_64.schedule(+block: List<&2,C.W64>) -> List<&2,C.W64>:
  SHA2_64.schedule.go(block,64n,block,Nil{})

def SHA2_64.step(st: S512, w: C.W64, k: C.W64) -> S512:
  match st:
    case S512{+a,+b,+c,d,+e,+f,+g,h}:
      +t1 = C.W64.add5(h,SHA2_64.big1(e),SHA2_64.ch(e,f,g),k,w)
      t2 = C.W64.add(SHA2_64.big0(a),SHA2_64.maj(a,b,c))
      S512{C.W64.add(t1,t2),a,b,c,C.W64.add(d,t1),e,f,g}

def SHA2_64.rounds(ws: List<&2,C.W64>, ks: List<&2,C.W64>, st: S512) -> S512:
  match ws ks:
    case w <> wt k <> kt:
      SHA2_64.rounds(wt,kt,SHA2_64.step(st,w,k))
    case Nil{} Nil{}:
      st
    case _ _:
      st

def SHA2_64.add(+x: S512, y: S512) -> S512:
  match x y:
    case S512{a,b,c,d,e,f,g,h} S512{i,j,k,l,m,n,o,p}:
      S512{C.W64.add(a,i),C.W64.add(b,j),C.W64.add(c,k),C.W64.add(d,l),C.W64.add(e,m),C.W64.add(f,n),C.W64.add(g,o),C.W64.add(h,p)}

def SHA2_64.compress(+st: S512, +bytes: List<&2,U32>) -> S512:
  block = C.Words64.block_be(bytes,16n)
  SHA2_64.add(st,SHA2_64.rounds(SHA2_64.schedule(block),SHA2_64.ks(),st))

# SHA-384/SHA-512 use a 128-bit encoded bit length. Bend 2.0.10's native
# runtime limits Nat to 2^48-1, so every representable byte length has a bit
# length below 2^51 and the upper 64 bits are necessarily zero.
def SHA2_64.length_tail(+length: Nat) -> List<&2,U32>:
  +bits = C.W64.bits_from_bytes(length)
  C.Bytes.u64be(C.W64.zero(),C.Bytes.u64be(bits,Nil{}))

def SHA2_64.pad.go(+rest: List<&2,U32>, +rem: U32, tail: List<&2,U32>, short: Bool) -> List<&2,U32>:
  match short:
    case True{}:
      zeros = U32.sub(111,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),tail))
    case False{}:
      zeros = U32.sub(239,rem)
      List.append(&2,U32,rest,128 <> List.append(&2,U32,C.Bytes.zeros(zeros),tail))

def SHA2_64.pad(+rest: List<&2,U32>, +length: Nat, short: Bool) -> List<&2,U32>:
  SHA2_64.pad.go(rest,U32.from_nat(Nat.mod(length,128n)),SHA2_64.length_tail(length),short)

def SHA2_64.final.blocks(+st: S512, +padded: List<&2,U32>, one: Bool) -> S512:
  match one:
    case True{}:
      SHA2_64.compress(st,padded)
    case False{}:
      first = SHA2_64.compress(st,padded)
      SHA2_64.compress(first,List.drop(&2,U32,padded,128n))

def SHA2_64.final(+rest: List<&2,U32>, +length: Nat, st: S512) -> S512:
  +short = U32.is_le(U32.from_nat(Nat.mod(length,128n)),111)
  padded = SHA2_64.pad(rest,length,short)
  SHA2_64.final.blocks(st,padded,short)

def SHA2_64.blocks(n: Nat, +xs: List<&2,U32>, +total: Nat, st: S512) -> S512:
  match n:
    case 0n:
      SHA2_64.final(xs,total,st)
    case 1n+p:
      next = SHA2_64.compress(st,xs)
      SHA2_64.blocks(p,List.drop(&2,U32,xs,128n),total,next)

def SHA512.iv() -> S512:
  S512{C.W64{1779033703, 4089235720},C.W64{3144134277, 2227873595},C.W64{1013904242, 4271175723},C.W64{2773480762, 1595750129},C.W64{1359893119, 2917565137},C.W64{2600822924, 725511199},C.W64{528734635, 4215389547},C.W64{1541459225, 327033209}}

def SHA384.iv() -> S512:
  S512{C.W64{3418070365, 3238371032},C.W64{1654270250, 914150663},C.W64{2438529370, 812702999},C.W64{355462360, 4144912697},C.W64{1731405415, 4290775857},C.W64{2394180231, 1750603025},C.W64{3675008525, 1694076839},C.W64{1203062813, 3204075428}}

def SHA512.digest(st: S512) -> List<&2,U32>:
  match st:
    case S512{a,b,c,d,e,f,g,h}:
      C.Bytes.u64be(a,C.Bytes.u64be(b,C.Bytes.u64be(c,C.Bytes.u64be(d,
      C.Bytes.u64be(e,C.Bytes.u64be(f,C.Bytes.u64be(g,C.Bytes.u64be(h,Nil{}))))))))

def SHA384.digest(st: S512) -> List<&2,U32>:
  match st:
    case S512{a,b,c,d,e,f,g,h}:
      C.Bytes.u64be(a,C.Bytes.u64be(b,C.Bytes.u64be(c,C.Bytes.u64be(d,C.Bytes.u64be(e,C.Bytes.u64be(f,Nil{}))))))

def SHA512.bytes(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  SHA512.digest(SHA2_64.blocks(Nat.div(n,128n),xs,n,SHA512.iv()))

def SHA384.bytes(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  SHA384.digest(SHA2_64.blocks(Nat.div(n,128n),xs,n,SHA384.iv()))

def SHA512.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA512.bytes(xs))

def SHA384.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA384.bytes(xs))

def SHA512.text(s: String) -> String:
  SHA512.hex_bytes(C.Bytes.utf8(s))

def SHA384.text(s: String) -> String:
  SHA384.hex_bytes(C.Bytes.utf8(s))

# SHA-512/224 and SHA-512/256
# ===========================

# FIPS 180-4 initial values for the truncated SHA-512 variants.
def SHA512_224.iv() -> S512:
  S512{
    C.W64{2352822216,424955298}, C.W64{1944164710,2312950998},
    C.W64{502970286,855612546}, C.W64{1738396948,1479516111},
    C.W64{258812777,2077511080}, C.W64{2011393907,79989058},
    C.W64{1067287976,1780299464}, C.W64{286451373,2446758561}
  }

def SHA512_256.iv() -> S512:
  S512{
    C.W64{573645204,4230739756}, C.W64{2673172387,3360449730},
    C.W64{596883563,1867755857}, C.W64{2520282905,1497426621},
    C.W64{2519219938,2827943907}, C.W64{3193839141,1401305490},
    C.W64{721525244,746961066}, C.W64{246885852,2177182882}
  }

# SHA-512/224 is the leftmost 224 bits: A || B || C || high32(D).
def SHA512_224.digest(st: S512) -> List<&2,U32>:
  match st:
    case S512{a,b,c,d,e,f,g,h}:
      match d:
        case C.W64{hi,lo}:
          C.Bytes.u64be(a,C.Bytes.u64be(b,C.Bytes.u64be(c,C.Bytes.u32be(hi,Nil{}))))

# SHA-512/256 is the leftmost 256 bits: A || B || C || D.
def SHA512_256.digest(st: S512) -> List<&2,U32>:
  match st:
    case S512{a,b,c,d,e,f,g,h}:
      C.Bytes.u64be(a,C.Bytes.u64be(b,C.Bytes.u64be(c,C.Bytes.u64be(d,Nil{}))))

def SHA512_224.bytes(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  SHA512_224.digest(SHA2_64.blocks(Nat.div(n,128n),xs,n,SHA512_224.iv()))

def SHA512_256.bytes(+xs: List<&2,U32>) -> List<&2,U32>:
  +n = C.Bytes.length_nat(xs)
  SHA512_256.digest(SHA2_64.blocks(Nat.div(n,128n),xs,n,SHA512_256.iv()))

def SHA512_224.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA512_224.bytes(xs))

def SHA512_256.hex_bytes(xs: List<&2,U32>) -> String:
  C.Hex.bytes(SHA512_256.bytes(xs))

def SHA512_224.text(s: String) -> String:
  SHA512_224.hex_bytes(C.Bytes.utf8(s))

def SHA512_256.text(s: String) -> String:
  SHA512_256.hex_bytes(C.Bytes.utf8(s))
