import Base

# U32.mul_hi against an independent reference built from 16-bit halves with
# plain U32 ops, on edge cases and 2^16 xorshift pairs, on CPU and (via !) GPU.

def ref(+a: U32, +b: U32) -> U32:
  +al = (a .&. 65535 : U32)
  +ah = (a >> 16n : U32)
  +bl = (b .&. 65535 : U32)
  +bh = (b >> 16n : U32)
  +lh = (al * bh : U32)
  +hl = (ah * bl : U32)
  +mid = ((al * bl : U32) >> 16n : U32)
  +mid2 = (mid + (lh .&. 65535 : U32) + (hl .&. 65535 : U32) : U32)
  (ah * bh + (lh >> 16n : U32) + (hl >> 16n : U32) + (mid2 >> 16n : U32) : U32)

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

def bad(+a: U32, +b: U32) -> U32:
  miss(U32.is_eq(U32.mul_hi(a, b), ref(a, b)))

def run(n: Nat, +x: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +y = xs(x)
      run(p, xs(y), (acc + bad(x, y) : U32))

def par(+d: Nat, +seed: U32) -> U32:
  match d:
    case 0n:
      run(256n, (seed * 2654435761 + 1 : U32), 0)
    case 1n+p:
      a b = par(p, (seed * 2 : U32)) par(p, (seed * 2 + 1 : U32))
      (a + b : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(U32.mul_hi(123456789, 987654321)))
    IO.print(U32.show(U32.mul_hi(4294967295, 4294967295)))
    IO.print(U32.show(U32.mul_hi(2147483648, 2147483648)))
    IO.print(U32.show(U32.mul_hi(3735928559, 3405691582)))
    IO.print(U32.show(U32.mul_hi(0, 4294967295)))
    IO.print(U32.show(U32.mul_hi(1, 4294967295)))
    IO.print(U32.show(U32.mul_hi(2147483648, 2)))
    IO.print("cpu mismatches " ++ U32.show(par(8n, 7)))
    IO.print("gpu mismatches " ++ U32.show(par!(8n, 7)))

#|28389652
#|4294967294
#|1073741824
#|2962402171
#|0
#|0
#|1
#|cpu mismatches 0
#|gpu mismatches 0
