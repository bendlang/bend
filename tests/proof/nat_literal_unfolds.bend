# a nat literal is one Lit node in the checker; it unfolds a Succ at a
# time where a chain is read: a comparison sees 300n as Succ{299n} and
# 0n as Zero{}, a match reads a literal pattern past 256 and a literal
# scrutinee, a self-call on a smaller literal descends, and the
# evaluator steps through a literal's count. the laws hold the patterns
# past 256: a compiled match on one rebuilds its scrutinee 300 deep,
# past clang's bracket nesting.
import Base

law big_is_succ:
  {300n == Succ{299n} : Nat}

def big_is_succ():
  {==}

law zero_is_zero:
  {0n == Zero{} : Nat}

def zero_is_zero():
  {==}

law add_lits:
  {Nat.add(999n, 1n) == 1000n : Nat}

def add_lits():
  {==}

def classify(n: Nat) -> Nat:
  match n:
    case 300n:
      1n
    case 5n:
      2n
    case _:
      0n

law classify_big:
  {classify(300n) == 1n : Nat}

def classify_big():
  {==}

def down(n: Nat) -> Nat:
  match n:
    case 300n:
      down(299n)
    case _:
      n

law down_steps:
  {down(300n) == 299n : Nat}

def down_steps():
  {==}

def small(n: Nat) -> Nat:
  match n:
    case 5n:
      2n
    case _:
      0n

def bound() -> Nat:
  4294967295n

def main() -> List<Nat>:
  [small(5n), small(7n), Nat.add(299n, 1n), Nat.add(0n, bound())]

#|[2n, 0n, 300n, 4294967295n]
