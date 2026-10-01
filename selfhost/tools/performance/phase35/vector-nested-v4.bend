import Base

def InnerState() -> Data:
  Sigma<&2, &2, U32, _ => U32>

def OuterState() -> Data:
  Sigma<&2, &2, InnerState, _ => U32>

def inner.step(+i: U32, st: InnerState) -> InnerState:
  (x, y) = st
  (U32.add(y, i), U32.xor(x, i))

def inner.walk(+n: Nat, +i: U32, st: InnerState) -> InnerState:
  match n:
    case 0n: st
    case 1n+q: inner.walk(q, U32.inc(i), inner.step(i, st))

def outer.step(+stamp: U32, st: OuterState) -> OuterState:
  (pair, z) = st
  outer.step.pair(stamp, z, pair)

def outer.step.pair(+stamp: U32, z: U32, pair: InnerState) -> OuterState:
  (x, y) = pair
  +old_x = x
  +old_y = y
  +next = inner.walk(U32.to_nat(U32.and(stamp, 3)), stamp, (old_x, old_y))
  (next, U32.add(z, U32.xor(old_x, old_y)))

def outer.walk(+n: Nat, +stamp: U32, st: OuterState) -> OuterState:
  match n:
    case 0n: st
    case 1n+q: outer.walk(q, U32.inc(stamp), outer.step(stamp, st))

def nested.score(st: OuterState) -> U32:
  (pair, z) = st
  nested.score.pair(z, pair)

def nested.score.pair(z: U32, pair: InnerState) -> U32:
  (x, y) = pair
  U32.xor(U32.add(U32.mul(x, 65599), y), U32.mul(z, 17))

def bench(+n: U32, +seed: U32) -> U32:
  nested.score(outer.walk(U32.to_nat(n), seed, ((seed, U32.inc(seed)), U32.xor(seed, 85))))

def main() -> IO(Unit):
  IO.print(U32.show(bench(7, 17)))
