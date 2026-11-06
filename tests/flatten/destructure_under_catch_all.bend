# a catch-all row lands in both branches of the ctr split above it, and
# each copy destructures w under its own substitutions
type Nat is Data:
  Z{}
  S{p: Nat}

type Pair is Data:
  P{a: Nat, b: Nat}

law main:
  for n: Nat
  for w: Pair
  Nat

def main(n, w):
  match n:
    case S{Z{}}:
      P{a, b} = w
      a
    case m:
      P{a, b} = w
      S{m}
#|\{S: \{Z: \{P: (a => b => a)}; (_12 => \{P: (a => b => S{S{_12}})})}; (n => \{P: (a => b => S{n})})}
