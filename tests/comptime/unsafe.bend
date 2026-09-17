# an @unsafe template: its instance carries the mark (the self-call
# skips descent; --check counts it as unsafe, see reg_import_walls)
import Base

@unsafe
def loop(~f: Nat -> Nat, x: Nat) -> Nat:
  match x:
    case 0n:
      0n
    case 1n+p:
      f(loop(~f, p))

def main() -> IO(Unit):
  IO.print(Nat.show(loop(~(n => 1n+n), 3n)))

#|3
