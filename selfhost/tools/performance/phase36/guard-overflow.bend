import Base

type GuardChoice is Data:
  First{value: Nat}
  Second{value: Nat}

def guard.make(flag: Bool, value: Nat) -> GuardChoice:
  match flag:
    case False{}: Second{value}
    case True{}: First{value}

def guard.consume(value: GuardChoice) -> Nat:
  match value:
    case First{x}: Nat.add(x, 1n)
    case Second{x}: Nat.add(x, 2n)

# A complete pure residual graph, with a deliberately throwable native Nat
# operation. The tagged sum prevents lowering the whole graph as scalar code.
def guard.opaque(value: Nat) -> Nat:
  guard.consume(guard.make(True{}, value))

def guard.direct(value: Nat) -> Nat:
  Nat.add(value, 1n)

def guard.walk(+depth: Nat, +value: Nat) -> Nat:
  match depth:
    case 0n: Nat.add(guard.opaque(value), guard.direct(1n))
    case 1n+p:
      left right = guard.walk(p, value) guard.walk(p, value)
      Nat.add(left, right)

def main() -> Nat:
  guard.walk(1n, 3n)
