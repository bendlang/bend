# THE JOINT-MATCH FUSION GUARD (Taelin order): a joint in-order match over
# params fuses into ONE point-free tree -- no applied spine, no aux mint. This
# pin is the canonical main tree, byte-exact. It must NEVER be regenerated to an
# applied (a => b => ...(a)) or minted (main~N) shape: that regression class
# felled bend-base whole (List.take's halt, the Bit.xor lemmas) and must be an
# instant, legible red here instead.
type Bool is Data:
  T{}
  F{}

type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for a: Nat
  for b: Nat
  Bool

def main(a, b):
  match a, b:
    case Z{}, y:
      T{}
    case S{p}, Z{}:
      F{}
    case S{p}, S{q}:
      main(p, q)

#|\{Z: (b => T{}); S: (p => \{Z: F{}; S: (q => main(p, q))})}
