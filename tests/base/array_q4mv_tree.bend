# Array.q4mv's summation tree: 5 rows of 2176 weights (34 groups, so groups
# 32 and 33 wrap onto partials 0 and 1), then rows 1 .. 4 alone. Lanes 0 and
# 4 of every group hold +-2^25 that cancel only when lane j sums its own
# nibble over the words before the lanes meet; x-sums of +-2^24 in groups 0
# and 16 cancel only in the fold p[l] += p[l + 16]. Summed in index order
# (or with another lane pairing, partial count or fold) every row differs.
import Base

def bits(+v: F32) -> U32:
  match v:
    case F32{+w}:
      U32{w}

def wset(n: Nat, a: Array<U32>, +i: U32) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      +s = (15360 + (i % 8) * 17 + ((15488 + (i % 5) * 19) << 16n) : U32)
      wset(p, Array.set(U32, Array.set(U32, a, (1360 + i : U32), s), (1445 + i : U32), 1065369472), (i + 1 : U32))

def cset(n: Nat, a: Array<U32>, +i: U32) -> Array<U32>:
  match n:
    case 0n:
      wset(85n, a, 0)
    case 1n+p:
      cset(p, Array.set(U32, a, i, ((1 + i % 3) * 286331153 : U32)), (i + 1 : U32))

def pick(b: Bool, +t: F32, +e: F32) -> F32:
  match b:
    case True{}:
      t
    case False{}:
      e

def xv(+j: U32) -> F32:
  pick(U32.is_eq((j % 8 : U32), 0), 33554432.0,
    pick(U32.is_eq((j % 8 : U32), 4), (0.0 - 33554432.0 : F32), (U32.to_f32((j % 5 : U32)) + 0.5 : F32)))

def sv(+g: U32) -> F32:
  pick(U32.is_eq(g, 0), 16777216.0, pick(U32.is_eq(g, 16), (0.0 - 16777216.0 : F32), pick(U32.is_eq(g, 32), 3.0,
    pick(U32.is_eq(g, 1), 2.0, (U32.to_f32((g % 5 : U32)) + 0.25 : F32)))))

def sset(n: Nat, a: Array<F32>, +g: U32) -> Array<F32>:
  match n:
    case 0n:
      a
    case 1n+p:
      sset(p, Array.set(F32, a, (2176 + g : U32), sv(g)), (g + 1 : U32))

def xset(n: Nat, a: Array<F32>, +j: U32) -> Array<F32>:
  match n:
    case 0n:
      sset(34n, a, 0)
    case 1n+p:
      xset(p, Array.set(F32, a, j, xv(j)), (j + 1 : U32))

def show(q: (Array<U32> & Array<F32>) & Array<F32>) -> String:
  ((w, x), y) = q
  List.show(~&1, ~U32, ~(v => U32.show(v)), Array.to_list(~U32, Array.map(~F32, ~U32, ~(v => bits(v)), y)))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(Array.q4mv(cset(1360n, Array.new(U32, 11n, 0), 0), xset(2176n, Array.new(F32, 12n, 0.0), 0), Array.new(F32, 3n, 7.0), 0, 5, 2176, 5)))
    IO.print(show(Array.q4mv(cset(1360n, Array.new(U32, 11n, 0), 0), xset(2176n, Array.new(F32, 12n, 0.0), 0), Array.new(F32, 3n, 7.0), 1, 4, 2176, 5)))

#|[1128857600, 1128988672, 1128988672, 1128988672, 1129185280, 1088421888, 1088421888, 1088421888]
#|[1088421888, 1128988672, 1128988672, 1128988672, 1129185280, 1088421888, 1088421888, 1088421888]
