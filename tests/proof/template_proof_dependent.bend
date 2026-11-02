# A template function's later argument can depend on its first argument.
import Base

law via:
  for ~f: (@n: Nat -> Word(n) -> Word(n))
  for ~ok: (@n: Nat -> @x: Word(n) -> {f(n, x) == x : Word(n)})
  for n: Nat
  for x: Word(n)
  {f(n, x) == x : Word(n)}

def via(f, ok, n, x):
  ok(n, x)

law use:
  for n: Nat
  for x: Word(n)
  {x == x : Word(n)}

def use(n, x):
  via(~(n => y => y), ~(n => z => {==}), n, x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
