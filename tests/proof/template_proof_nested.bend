# Substitute earlier template arguments into later argument types.
import Base

law via:
  for ~A: Type
  for ~f: A -> A
  for ~ok: (@x: A -> {f(x) == x : A})
  for x: A
  {f(x) == x : A}

def via(A, f, ok, x):
  ok(x)

law relay:
  for ~A: Type
  for x: A
  {x == x : A}

def relay(A, x):
  via(~A, ~(y => y), ~(z => {==}), x)

law use:
  for x: U32
  {x == x : U32}

def use(x):
  relay(~U32, x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
