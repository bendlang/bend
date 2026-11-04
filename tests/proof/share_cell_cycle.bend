# regression: bare refls prove a list is its own head <> tail. Each
# {==} finds D's share cell equal to Hd(D) <> Tl(D), whose parts name D;
# conversion once gave D that value (rhs.v = lhs.v), so D named itself:
# --verdict's kernel pass overflowed on the cyclic term (split2), or the
# next whnf of D never ended (lift1, as ElMatch.bend's RestR.typed). Two
# equal cells now only join a class, and no value moves

import Base

def Both(-A: Data, -B: Data) -> Data:
  Sigma<&2, &2, A, _ => B>

def Hd(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{x, xs}:
      x

def Tl(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{x, xs}:
      xs

# D is G under z new entries
def Lb(z: Nat, -G: List<&2, Nat>, -D: List<&2, Nat>) -> Data:
  match z:
    case 0n:
      {G == D : List<&2, Nat>}
    case 1n+z:
      -L = List<&2, Nat>
      -e = {Hd(D) <> Tl(D) == D : L}
      Both(e, Lb(z, G, Tl(D)))

# D is G renamed past its d first entries, then under z new ones
def Ok(d: Nat, -G: List<&2, Nat>, -D: List<&2, Nat>, z: Nat) -> Data:
  match d:
    case 0n:
      Lb(z, G, D)
    case 1n+d:
      -L = List<&2, Nat>
      -A = Hd(G)
      -C = Tl(D)
      -g = {A <> Tl(G) == G : L}
      -h = {Nat.add(A, 1n) <> C == D : L}
      Both(g, Both(h, Ok(d, Tl(G), C, z)))

# split2: Lb's equations, bare
def split2(-a: Nat, -b: Nat, -G: List<&2, Nat>) -> Lb(2n, G, b <> a <> G):
  ({==}, ({==}, {==}))

# lift1: Ok's, bare, at a context grown by one entry
def lift1(-x: Nat, -a: Nat, -b: Nat, -G: List<&2, Nat>) -> Ok(1n, x <> G, Nat.add(x, 1n) <> b <> a <> G, 2n):
  ({==}, ({==}, ({==}, ({==}, {==}))))

law main:
  {[1n] == [1n] : List<&2, Nat>}

def main(): {==}

#|{==}
