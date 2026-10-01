import Base

def State() -> Data:
  Sigma<&2, &2, U32, _ => U32>

# Duplicable private tuple values exercise distinct aliases of one old state.
# The final loop argument is scalarized; the earlier alias must retain old fields.
def state.step(+stamp: U32, +st: State) -> State:
  (x, y) = st
  (U32.add(y, stamp), U32.xor(x, stamp))

def state.score(+st: State) -> U32:
  (x, y) = st
  U32.add(U32.mul(x, 65599), y)

def state.walk(+n: Nat, +stamp: U32, +older: State, +st: State) -> U32:
  match n:
    case 0n:
      U32.xor(state.score(older), U32.mul(state.score(st), 17))
    case 1n+q:
      state.walk(q, U32.inc(stamp), st, state.step(stamp, st))

def bench(+n: U32, +seed: U32) -> U32:
  state.walk(U32.to_nat(n), seed, (U32.inc(seed), seed), (seed, U32.inc(seed)))

def main() -> IO(Unit):
  IO.print(U32.show(bench(0, 0)))
