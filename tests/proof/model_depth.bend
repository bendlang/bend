import Base
def Vec(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Nat & Vec(p)
def reflexive(~v: Vec(130n)) -> {v == v : Vec(130n)}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.

#>ALL PROOFS CHECK
