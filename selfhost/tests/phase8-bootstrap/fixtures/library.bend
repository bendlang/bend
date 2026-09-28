import Base

type Packet is Data:
  Packet{size: Nat, items: List<&2, Nat>}

def private_step(n: Nat) -> Nat:
  Nat.add(n, 1n)

def selected(n: Nat) -> Nat:
  private_step(n)

def packet_identity(x: Packet) -> Packet:
  x

def list_identity(xs: List<&2, Nat>) -> List<&2, Nat>:
  xs

def apply_nat(f: Nat -> Nat, n: Nat) -> Nat:
  f(n)

def make_adder(n: Nat) -> (Nat -> Nat):
  x => Nat.add(n, x)

def add(a: Nat, b: Nat) -> Nat:
  Nat.add(a, b)

def wrap(n: U32) -> U32:
  U32.add(n, 1)

def countdown(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      countdown(p)

def io_root() -> IO(Unit):
  IO.pure(Unit, Unit{})

def template_root(~n: Nat, x: Nat) -> Nat:
  Nat.add(n, x)

def foreign_root() -> IO(Unit):
  import "./foreign.js"
