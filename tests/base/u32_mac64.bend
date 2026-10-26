import Base

# U32.mac64 against a schoolbook reference over 32-bit words built from
# U32.mac_hi / U32.add_hi, all four words, on edge cases and 2^16 random
# tuples, on CPU and (via !) GPU.

type W4 is Data:
  W4{w0: U32, w1: U32, w2: U32, w3: U32}

def ref(+al: U32, +ah: U32, +bl: U32, +bh: U32, +cl: U32, +ch: U32, +dl: U32, +dh: U32) -> W4:
  +s0 = (cl + dl : U32)
  +k0 = U32.add_hi(cl, dl)
  +u = (ch + dh : U32)
  +s1 = (u + k0 : U32)
  +s2 = (U32.add_hi(ch, dh) + U32.add_hi(u, k0) : U32)
  +r0 = (al * bl + s0 : U32)
  +c0 = U32.mac_hi(al, bl, s0, 0)
  +r1 = (al * bh + s1 + c0 : U32)
  +c1 = U32.mac_hi(al, bh, s1, c0)
  +r2 = (s2 + c1 : U32)
  +c2 = U32.add_hi(s2, c1)
  +q1 = (ah * bl + r1 : U32)
  +d0 = U32.mac_hi(ah, bl, r1, 0)
  +q2 = (ah * bh + r2 + d0 : U32)
  +d1 = U32.mac_hi(ah, bh, r2, d0)
  W4{r0, q1, q2, (d1 + c2 : U32)}

def got(+al: U32, +ah: U32, +bl: U32, +bh: U32, +cl: U32, +ch: U32, +dl: U32, +dh: U32) -> W4:
  W4{U32.mac64(0, al, ah, bl, bh, cl, ch, dl, dh), U32.mac64(1, al, ah, bl, bh, cl, ch, dl, dh), U32.mac64(2, al, ah, bl, bh, cl, ch, dl, dh), U32.mac64(3, al, ah, bl, bh, cl, ch, dl, dh)}

def diff(a: W4, b: W4) -> U32:
  W4{+a0, +a1, +a2, +a3} = a
  W4{+b0, +b1, +b2, +b3} = b
  Bool.to_u32(Bool.not(Bool.and(Bool.and(U32.is_eq(a0, b0), U32.is_eq(a1, b1)), Bool.and(U32.is_eq(a2, b2), U32.is_eq(a3, b3)))))

def xs(+x: U32) -> U32:
  +a = (x .^. (x << 13n) : U32)
  +b = (a .^. (a >> 17n) : U32)
  (b .^. (b << 5n) : U32)

def check(+x1: U32, +x2: U32, +x3: U32, +x4: U32, +x5: U32, +x6: U32, +x7: U32, +x8: U32) -> U32:
  diff(got(x1, x2, x3, x4, x5, x6, x7, x8), ref(x1, x2, x3, x4, x5, x6, x7, x8))

def step(+x: U32) -> U32:
  +x2 = xs(x)
  +x3 = xs(x2)
  +x4 = xs(x3)
  +x5 = xs(x4)
  +x6 = xs(x5)
  +x7 = xs(x6)
  +x8 = xs(x7)
  check(x, x2, x3, x4, x5, x6, x7, x8)

def run(n: Nat, +x: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      run(p, xs(xs(xs(xs(xs(xs(xs(xs(x)))))))), (acc + step(x) : U32))

def par(+d: Nat, +seed: U32) -> U32:
  match d:
    case 0n:
      run(256n, (seed * 2654435761 + 1 : U32), 0)
    case 1n+p:
      a b = par(p, (seed * 2 : U32)) par(p, (seed * 2 + 1 : U32))
      (a + b : U32)

def show(w: W4) -> String:
  W4{a, b, c, d} = w
  U32.show(a) ++ " " ++ U32.show(b) ++ " " ++ U32.show(c) ++ " " ++ U32.show(d)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(got(4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295)))
    IO.print(show(got(1, 0, 1, 0, 0, 0, 0, 0)))
    IO.print(show(got(0, 1, 0, 1, 0, 0, 0, 0)))
    IO.print(show(got(0, 0, 0, 0, 4294967295, 4294967295, 1, 0)))
    IO.print("edge mismatches " ++ U32.show((check(4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295, 4294967295) + check(0, 2147483648, 0, 2147483648, 0, 0, 0, 0) + check(0, 0, 0, 0, 4294967295, 4294967295, 1, 0) : U32)))
    IO.print("cpu mismatches " ++ U32.show(par(8n, 7)))
    IO.print("gpu mismatches " ++ U32.show(par!(8n, 7)))

#|4294967295 4294967295 4294967295 4294967295
#|1 0 0 0
#|0 0 1 0
#|0 0 1 0
#|edge mismatches 0
#|cpu mismatches 0
#|gpu mismatches 0
