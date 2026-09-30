# Independent checked source for native Nat self-tail worker boundaries.
import Base

@unsafe
def count(n: Nat, +acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p: count(p, U32.inc(acc))

@unsafe
def swap(n: Nat, +a: U32, +b: U32) -> U32:
  match n:
    case 0n: U32.add(U32.mul(a, 1000), b)
    case 1n+p: swap(p, b, a)

@unsafe
def shifted(n: Nat, +x: U32, +y: U32) -> U32:
  match n:
    case 0n: U32.add(U32.mul(x, 1000), y)
    case 1n+p:
      +old = x
      +x = U32.add(x, y)
      shifted(p, x, old)

@unsafe
def nat_carried(n: Nat, +m: Nat, +x: U32) -> U32:
  match n:
    case 0n: x
    case 1n+p: nat_carried(p, Nat.add(m, 1n), U32.from_nat(m))

@unsafe
def float_carried(n: Nat, +x: F32) -> F32:
  match n:
    case 0n: x
    case 1n+p: float_carried(p, F32.add(x, 0.5))

@unsafe
def bool_carried(n: Nat, +b: Bool, +x: U32) -> U32:
  match n:
    case 0n:
      match b:
        case True{}: U32.inc(x)
        case False{}: x
    case 1n+p: bool_carried(p, Bool.not(b), U32.inc(x))

@unsafe
def remember(+f: Unit -> U32) -> U32:
  f(Unit{})

@unsafe
def capture(n: Nat, +x: U32) -> U32:
  match n:
    case 0n: x
    case 1n+p:
      +seen = remember(u => x)
      capture(p, U32.inc(seen))

@unsafe
def at_zero(n: Nat, +x: U32) -> U32:
  match n:
    case 0n: remember(u => x)
    case 1n+p: at_zero(p, U32.inc(x))

@unsafe
def step_left(+x: U32) -> U32:
  U32.inc(x)

@unsafe
def step_right(+x: U32) -> U32:
  U32.inc(x)

@unsafe
def transition(n: Nat, +x: U32, +y: U32) -> U32:
  match n:
    case 0n: U32.add(x, y)
    case 1n+p: transition(p, step_left(x), step_right(y))

# These are meaningful fallback controls: recursion needs work after the call,
# or the next counter is an expression rather than the selected predecessor.
@unsafe
def non_tail(n: Nat, +x: U32) -> U32:
  match n:
    case 0n: x
    case 1n+p: U32.inc(non_tail(p, x))

@unsafe
def changed_counter(n: Nat, +x: U32) -> U32:
  match n:
    case 0n: x
    case 1n+p: changed_counter(Nat.sub(p, 1n), U32.inc(x))
