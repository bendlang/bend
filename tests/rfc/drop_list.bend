# drop of lists: term_drop frees a node whose only box is its last field
# as it walks, without a stop on its stack. KL is such a list of words and
# U1 a chain of one-field nodes. PL's item is a box that is KNil in every
# other node, so the walk leaves and re-enters that path node by node. RL
# has its box first, which is not that path. HL's node ends in an Array of
# lists and is affine. Each round drops a fresh copy of each whole, then
# shares one of each Data list, sums it through one holder and drops it
# through the other, and last drops two fresh heads over one shared tail,
# one before the tail is summed and one after. A node freed early or
# twice would read back wrong from reused memory in a later round. Build
# with CCC_OVERRIDE_OPTIONS=+-DBEND_POISON to also fail a read of a freed
# block within one drop. Expect 3 rounds of the same sum.
import Base

type KL is Data:
  KNil{}
  KCons{k: U32, t: KL}

type U1 is Data:
  UEnd{}
  UOne{u: U1}

type PL is Data:
  PNil{}
  PCons{item: KL, rest: PL}

type RL is Data:
  RNil{}
  RCons{rest: RL, k: U32}

type HL is Type:
  HNil{}
  HCons{k: U32, a: Array<KL>}

def kl(n: Nat, +x: U32, acc: KL) -> KL:
  match n:
    case 0n:
      acc
    case 1n+p:
      kl(p, U32.inc(x), KCons{x, acc})

def u1(n: Nat, acc: U1) -> U1:
  match n:
    case 0n:
      acc
    case 1n+p:
      u1(p, UOne{acc})

def item.of(odd: Bool, +x: U32) -> KL:
  match odd:
    case False{}:
      KNil{}
    case True{}:
      kl(3n, x, KNil{})

def item(+x: U32) -> KL:
  item.of(U32.is_eq(U32.and(x, 1), 1), x)

def pl(n: Nat, +x: U32, acc: PL) -> PL:
  match n:
    case 0n:
      acc
    case 1n+p:
      pl(p, U32.inc(x), PCons{item(x), acc})

def rl(n: Nat, +x: U32, acc: RL) -> RL:
  match n:
    case 0n:
      acc
    case 1n+p:
      rl(p, U32.inc(x), RCons{acc, x})

def hl(+x: U32) -> HL:
  HCons{x, Array.set(KL, [KNil{} : KL*4n], x, kl(5n, x, KNil{}))}

def kl_sum(c: KL, acc: U32) -> U32:
  match c:
    case KNil{}:
      acc
    case KCons{h, t}:
      kl_sum(t, U32.add(acc, h))

def u1_sum(c: U1, acc: U32) -> U32:
  match c:
    case UEnd{}:
      acc
    case UOne{u}:
      u1_sum(u, U32.inc(acc))

def pl_sum(c: PL, acc: U32) -> U32:
  match c:
    case PNil{}:
      acc
    case PCons{i, r}:
      pl_sum(r, kl_sum(i, acc))

def rl_sum(c: RL, acc: U32) -> U32:
  match c:
    case RNil{}:
      acc
    case RCons{r, k}:
      rl_sum(r, U32.add(acc, k))

def cell(+k: U32, r: Array<KL> & KL) -> U32:
  (a, c) = r
  kl_sum(c, k)

def read(+k: U32, a: Array<KL>) -> U32:
  cell(k, Array.get(KL, a, k))

def hl_sum(c: HL) -> U32:
  match c:
    case HNil{}:
      0
    case HCons{k, a}:
      read(k, a)

def waste(w: KL, u: U1, p: PL, r: RL, h: HL, x: U32) -> U32:
  x

def lose(w: KL, x: U32) -> U32:
  x

# two heads over one shared tail: one head dropped, the tail read, the
# other head dropped
def tails(+n: Nat) -> U32:
  +t = kl(n, 1, KNil{})
  a = lose(KCons{7, KCons{8, t}}, 0)
  b = kl_sum(t, a)
  lose(KCons{9, t}, b)

def round(+n: Nat) -> U32:
  a = waste(kl(n, 1, KNil{}), u1(n, UEnd{}), pl(n, 1, PNil{}),
    rl(n, 1, RNil{}), hl(2), 0)
  +w = kl(n, 1, KNil{})
  +u = u1(n, UEnd{})
  +p = pl(n, 1, PNil{})
  +r = rl(n, 1, RNil{})
  b = U32.add(U32.add(kl_sum(w, a), u1_sum(u, 0)),
    U32.add(U32.add(pl_sum(p, 0), rl_sum(r, 0)), hl_sum(hl(2))))
  U32.add(tails(n), waste(w, u, p, r, hl(3), b))

def main() -> IO(Unit):
  IO.print(U32.show(round(20000n)) ++ " " ++ U32.show(round(20000n))
    ++ " " ++ U32.show(round(20000n)))

#|900080022 900080022 900080022
