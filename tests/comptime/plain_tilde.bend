# ~ in a non-leading position of a plain def makes no template (only a
# leading ~ does): the binder is erased, and the call passes it at run time
import Base

def keep(x: Nat, ~k: Nat) -> Nat:
  x

def main() -> IO(Unit):
  IO.print(Nat.show(keep(3n, 5n)))

#|3
