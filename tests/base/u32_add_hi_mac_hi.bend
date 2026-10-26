import Base

# U32.add_hi and U32.mac_hi against independent references built from plain U32
# ops (a bitwise carry formula and 16-bit halves), on edge cases and 2^16
# xorshift tuples, on CPU and (via !) GPU.

def carry(+a: U32, +b: U32) -> U32:
  +s = (a + b : U32)
  (((a .&. b) .|. ((a .|. b) .&. (s .^. 4294967295))) >> 31n : U32)

def mulhi_ref(+a: U32, +b: U32) -> U32:
  +al = (a .&. 65535 : U32)
  +ah = (a >> 16n : U32)
  +bl = (b .&. 65535 : U32)
  +bh = (b >> 16n : U32)
  +lh = (al * bh : U32)
  +hl = (ah * bl : U32)
  +mid = ((al * bl : U32) >> 16n : U32)
  +mid2 = (mid + (lh .&. 65535 : U32) + (hl .&. 65535 : U32) : U32)
  (ah * bh + (lh >> 16n : U32) + (hl >> 16n : U32) + (mid2 >> 16n : U32) : U32)

def mac_ref(+a: U32, +b: U32, +c: U32, +d: U32) -> U32:
  +lo = (a * b : U32)
  +s = (lo + c : U32)
  (mulhi_ref(a, b) + carry(lo, c) + carry(s, d) : U32)

def xs(+x: U32) -> U32:
  +a = (x .^. (x << 13n) : U32)
  +b = (a .^. (a >> 17n) : U32)
  (b .^. (b << 5n) : U32)

def miss(ok: Bool) -> U32:
  match ok:
    case True{}:
      0
    case False{}:
      1

def bad(+a: U32, +b: U32, +c: U32, +d: U32) -> U32:
  (miss(U32.is_eq(U32.add_hi(a, b), carry(a, b))) + miss(U32.is_eq(U32.mac_hi(a, b, c, d), mac_ref(a, b, c, d))) : U32)

def step(+x: U32, +y: U32, +z: U32) -> U32:
  bad(x, y, z, xs(z))

def run(n: Nat, +x: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +y = xs(x)
      +z = xs(y)
      run(p, xs(z), (acc + step(x, y, z) : U32))

def par(+d: Nat, +seed: U32) -> U32:
  match d:
    case 0n:
      run(256n, (seed * 2654435761 + 1 : U32), 0)
    case 1n+p:
      a b = par(p, (seed * 2 : U32)) par(p, (seed * 2 + 1 : U32))
      (a + b : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(U32.add_hi(123456789, 987654321)))
    IO.print(U32.show(U32.add_hi(4294967295, 1)))
    IO.print(U32.show(U32.add_hi(4294967295, 4294967295)))
    IO.print(U32.show(U32.add_hi(2147483648, 2147483648)))
    IO.print(U32.show(U32.add_hi(0, 0)))
    IO.print(U32.show(U32.add_hi(2147483647, 2147483648)))
    IO.print(U32.show(U32.mac_hi(4294967295, 4294967295, 4294967295, 4294967295)))
    IO.print(U32.show(U32.mac_hi(123456789, 987654321, 3735928559, 3405691582)))
    IO.print(U32.show(U32.mac_hi(0, 0, 4294967295, 4294967295)))
    IO.print(U32.show(U32.mac_hi(1, 4294967295, 1, 0)))
    IO.print(U32.show(U32.mac_hi(2147483648, 2, 0, 0)))
    IO.print("cpu mismatches " ++ U32.show(par(8n, 7)))
    IO.print("gpu mismatches " ++ U32.show(par!(8n, 7)))

#|0
#|1
#|1
#|1
#|0
#|0
#|4294967295
#|28389654
#|1
#|1
#|1
#|cpu mismatches 0
#|gpu mismatches 0
