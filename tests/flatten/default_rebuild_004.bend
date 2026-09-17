# a default arm below a DEEP rigid row rebuilds the scrutinee: the var
# row rides into the S subgroup and reconstructs what it dropped
type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for a: Nat
  Nat

def main(a):
  match a:
    case S{S{p}}:
      p
    case n:
      n

#|\{S: \{S: (p => p); (_5 => S{_5})}; (a => a)}
