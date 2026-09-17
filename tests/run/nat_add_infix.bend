# a chain with no ": T" is Nat: + is Nat.add at the additive level, a
# chain folds left, 1n + 2n + 3n answers 6n on every lane
import Base

law main.out:
  Nat

def main.out():
  1n + 2n + 3n

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|6n
