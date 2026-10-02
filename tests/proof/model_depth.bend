import Base
def Vec(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Nat & Vec(p)
def reflexive(~v: Vec(130n)) -> {v == v : Vec(130n)}:
  {==}

def reflexive_400(~v: Vec(400n)) -> {v == v : Vec(400n)}:
  {==}

def reflexive_600(~v: Vec(600n)) -> {v == v : Vec(600n)}:
  {==}

def reflexive_2000(~v: Vec(2000n)) -> {v == v : Vec(2000n)}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
