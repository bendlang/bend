# regression (AUDIT 2b, the legal half), repurposed: the framed match
# is gone, and its telescope lives in a worker def's assert -- a later
# parameter whose TYPE mentions an earlier one checks, because the
# assert's clauses are a real telescope. The import line carries AUDIT
# 6a's witness: extra spaces and a trailing comment lex like the rest.
import   Base  # the import head obeys the lexer

law dup_eq.go:
  for  n: Nat
  for -e: {n == n : Nat}
  Nat

def dup_eq.go(n, e):
  n

law dup_eq:
  for m: Nat
  Nat

def dup_eq(m):
  dup_eq.go(m, {==})

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(dup_eq(3n)))

#|3
