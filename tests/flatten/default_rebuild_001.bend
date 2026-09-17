type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{x: Nat}
  C{x: Nat}

law main:
  for a: Nat
  R

def main(a):
  match a:
    case Z{}:
      A{}
    case S{S{S{a}}}:
      B{a}
    case S{a}:
      C{a}

#|\{Z: A{}; S: \{S: \{S: (a => B{a}); (_4 => C{S{_4}})}; (_3 => C{_3})}}
