# a pair not written alike spends fuel only for its own walk: twelve
# fields equal only after a step (1n + 1n against 2n) leave the last
# field its fuel, so big() still meets its copy as written
import Base

type Wide is Data:
  Wide{a0: Nat, a1: Nat, a2: Nat, a3: Nat, a4: Nat, a5: Nat, a6: Nat, a7: Nat, a8: Nat, a9: Nat, a10: Nat, a11: Nat, z: Nat}

def big() -> Nat:
  Nat.pow(2n, 30n)

def wide() -> Wide:
  Wide{Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), Nat.add(1n, 1n), big()}

def t() -> {wide() == Wide{2n, 2n, 2n, 2n, 2n, 2n, 2n, 2n, 2n, 2n, 2n, 2n, big()} : Wide}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
