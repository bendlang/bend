# --verdict must preserve the types of a template function and its proof.
import Base

law via:
  for ~f: U32 -> U32
  for ~ok: (@x: U32 -> {f(x) == f(x) : U32})
  for x: U32
  {f(x) == f(x) : U32}

def via(f, ok, x):
  ok(x)

law use:
  for x: U32
  {(x + 1 : U32) == (x + 1 : U32) : U32}

def use(x):
  via(~(y => (y + 1 : U32)), ~(z => {==}), x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
