# match on row pattern variables, nested; expands to plain rows
# ported from bend3: numeric columns become ctor columns, arm values
# become ctor builds (bend has no number patterns)
type W is Data:
  Z{}
  S{p: W}

type R is Data:
  K100{}
  KP{p: W}
  KN{n: W}
  KM{n: W, m: W}

law main:
  for a: W
  for b: W
  R

def main(a, b):
  match a:
    case Z{}:
      match b:
        case Z{}:
          K100{}
        case n:
          KP{S{n}}
    case n:
      match b:
        case Z{}:
          KN{n}
        case m:
          KM{n, m}

#|\{Z: \{Z: K100{}; (b => KP{S{b}})}; (a => \{Z: KN{a}; (b => KM{a, b})})}
