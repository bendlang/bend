# a ! call forks two F64 fma sums and a U64 generator: CUDA runs the F64
# natives in place, Metal runs base.bend's F64 defs in integer arithmetic,
# and both print the bits the host prints
import Base

def term(+n: Nat) -> F64:
  F64.div(1.0f64, F64.add(U64.to_f64(U64.from_nat(n)), 1.0f64))

def sq(n: Nat, +i: Nat, acc: F64) -> F64:
  match n:
    case 0n:
      acc
    case 1n+p:
      +x = term(i)
      sq(p, Nat.add(i, 1n), F64.fma(x, x, acc))

def lcg(n: Nat, u: U64) -> U64:
  match n:
    case 0n:
      u
    case 1n+p:
      lcg(p, U64.add(U64.mul(u, 6364136223846793005u64), 1442695040888963407u64))

def both(+n: Nat) -> F64 & U64:
  a b = sq(32n, 0n, 0.0f64) sq(32n, 32n, 0.0f64)
  (F64.add(a, b), lcg(n, 0u64))

def show(r: F64 & U64) -> String:
  (s, u) = r
  F64.show(s) ++ " " ++ U64.show(u)

def main() -> IO(Unit):
  IO.print(show(both!(64n)))

#|1.6294305014088875 10607473198416945472
