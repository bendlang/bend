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
    case First{x}: Succ{x}
    case Second{x}: Succ{x}

# Native Nat constructor overflow is admitted by JPure. Native Nat.add is not.
def guard.opaque(value: Nat) -> U32:
  U32.from_nat(guard.consume(guard.make(True{}, value)))

def guard.direct(value: U32) -> U32:
  U32.add(value, 1)

def guard.walk(+depth: Nat, +value: Nat) -> U32:
  match depth:
    case 0n: U32.add(guard.opaque(value), guard.direct(1))
    case 1n+p:
      left right = guard.walk(p, value) guard.walk(p, value)
      U32.add(left, right)

def main() -> U32:
  guard.walk(1n, 3n)
