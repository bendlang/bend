# Array.q4mv: 13 rows of 128 weights (one block of eight rows and a tail
# of five), then rows 3 .. 8 alone; outputs as F32 bits, slots it does not
# write keep 7.0 (1088421888)
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
      +b = (48128 + (i % 6) * 23 + ((15232 + (i % 7) * 13) << 16n) : U32)
      wset(p, Array.set(U32, Array.set(U32, a, (208 + i : U32), s), (221 + i : U32), b), (i + 1 : U32))

def cset(n: Nat, a: Array<U32>, +i: U32) -> Array<U32>:
  match n:
    case 0n:
      wset(13n, a, 0)
    case 1n+p:
      cset(p, Array.set(U32, a, i, (i * 2654435761 + 12345 : U32)), (i + 1 : U32))

def xset(n: Nat, a: Array<F32>, +j: U32) -> Array<F32>:
  match n:
    case 0n:
      Array.set(F32, Array.set(F32, a, 128, 1.5), 129, 2.5)
    case 1n+p:
      xset(p, Array.set(F32, a, j, ((U32.to_f32((j % 7 : U32)) - 3.0) * 0.25 : F32)), (j + 1 : U32))

def show(q: (Array<U32> & Array<F32>) & Array<F32>) -> String:
  ((w, x), y) = q
  List.show(~&1, ~U32, ~(v => U32.show(v)), Array.to_list(~U32, Array.map(~F32, ~U32, ~(v => bits(v)), y)))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(Array.q4mv(cset(208n, Array.new(U32, 8n, 0), 0), xset(128n, Array.new(F32, 8n, 0.0), 0), Array.new(F32, 4n, 7.0), 0, 13, 128, 13)))
    IO.print(show(Array.q4mv(cset(208n, Array.new(U32, 8n, 0), 0), xset(128n, Array.new(F32, 8n, 0.0), 0), Array.new(F32, 4n, 7.0), 3, 6, 128, 13)))

#|[3190161408, 1045233664, 1059061760, 3189637120, 3178823680, 1039532032, 1043202048, 3171614720, 3194748928, 3205890048, 1055129600, 1045954560, 3183542272, 1088421888, 1088421888, 1088421888]
#|[1088421888, 1088421888, 1088421888, 3189637120, 3178823680, 1039532032, 1043202048, 3171614720, 3194748928, 1088421888, 1088421888, 1088421888, 1088421888, 1088421888, 1088421888, 1088421888]
