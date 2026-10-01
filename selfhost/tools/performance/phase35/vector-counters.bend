import Base

def CountState() -> Data:
  Sigma<&2, &2, U32, _ => U32>

def NatState() -> Data:
  Sigma<&2, &2, Nat, _ => U32>

def count.step(+i: U32, st: CountState) -> CountState:
  (x, y) = st
  (U32.add(y, i), U32.xor(x, i))

def count.score(st: CountState) -> U32:
  (x, y) = st
  U32.add(U32.mul(x, 65599), y)

# Only this vector-loop predecessor is an unobservable control variable.
def count.keep(+n: Nat, +i: U32, st: CountState) -> U32:
  match n:
    case 0n: count.score(st)
    case 1n+q: count.keep(q, U32.inc(i), count.step(i, st))

# An ordinary source conversion of the predecessor must retain its Nat ABI.
def count.observe(+n: Nat, +i: U32, st: CountState) -> U32:
  match n:
    case 0n: count.score(st)
    case 1n++q:
      count.observe(q, U32.inc(i), count.step(U32.add(i, U32.from_nat(q)), st))

# A final state field containing the predecessor makes the representation visible.
def count.nat.score(st: NatState) -> U32:
  (n, x) = st
  U32.xor(U32.from_nat(n), x)

def count.store.step(n: Nat, st: NatState) -> NatState:
  (old, x) = st
  (n, U32.add(x, U32.from_nat(old)))

def count.store(+n: Nat, +i: U32, st: NatState) -> U32:
  match n:
    case 0n: count.nat.score(st)
    case 1n++q:
      count.store(q, U32.inc(i), count.store.step(q, st))

# No private vector state: deliberately outside the first implementation scope.
def count.scalar(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+q: count.scalar(q, U32.inc(acc))

# A predecessor alias does not match the exact self-tail admission rule.
def count.alias(+n: Nat, +i: U32, st: CountState) -> U32:
  match n:
    case 0n: count.score(st)
    case 1n+q:
      +rest = q
      count.alias(rest, U32.inc(i), count.step(i, st))

def benchKeep(+n: U32, +seed: U32) -> U32:
  count.keep(U32.to_nat(n), seed, (seed, U32.inc(seed)))

def benchObserve(+n: U32, +seed: U32) -> U32:
  count.observe(U32.to_nat(n), seed, (seed, U32.inc(seed)))

def benchStore(+n: U32, +seed: U32) -> U32:
  count.store(U32.to_nat(n), seed, (0n, seed))

def benchScalar(+n: U32, +seed: U32) -> U32:
  count.scalar(U32.to_nat(n), seed)

def benchAlias(+n: U32, +seed: U32) -> U32:
  count.alias(U32.to_nat(n), seed, (seed, U32.inc(seed)))

def bench(+n: U32, +seed: U32) -> U32:
  U32.xor(U32.xor(benchKeep(n, seed), benchObserve(n, seed)),
    U32.xor(benchStore(n, seed), benchScalar(n, seed)))

def main() -> IO(Unit):
  IO.print(U32.show(bench(7, 17)))
