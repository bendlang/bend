import Base

type Box is Data:
  Box{v: Nat}

def pair(a: Nat, b: Nat, c: Nat, d: Nat) -> Nat:
  0n

def dag(n: Nat, +y: Nat) -> Box:
  match n:
    case 0n: Box{y}
    case 1n+p: dag(p, pair(y, y, 0n, 0n))

def wrap(n: Nat, +y: Nat) -> Box:
  dag(n, y)

def shared_30(+z: Nat) -> {dag(30n, z) == wrap(30n, z) : Box}:
  {==}

def shared_32(+z: Nat) -> {dag(32n, z) == wrap(32n, z) : Box}:
  {==}

def shared_38(+z: Nat) -> {dag(38n, z) == wrap(38n, z) : Box}:
  {==}

def shared_40(+z: Nat) -> {dag(40n, z) == wrap(40n, z) : Box}:
  {==}
