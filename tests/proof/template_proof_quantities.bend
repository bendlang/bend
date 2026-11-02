# Template function types must preserve shared and erased parameters.
import Base

law shared:
  for ~f: (@+x: U32 -> U32)
  for ~ok: (@+x: U32 -> {f(x) == f(x) : U32})
  for +x: U32
  {f(x) == f(x) : U32}

def shared(f, ok, x):
  ok(x)

law shared_use:
  for +x: U32
  {(x * x : U32) == (x * x : U32) : U32}

def shared_use(x):
  shared(~(+y => (y * y : U32)), ~(+z => {==}), x)

law erased:
  for ~f: (@-x: U32 -> U32)
  for ~ok: (@-x: U32 -> {f(x) == f(x) : U32})
  for -x: U32
  {f(x) == f(x) : U32}

def erased(f, ok, x):
  ok(x)

law erased_use:
  for -x: U32
  {7 == 7 : U32}

def erased_use(x):
  erased(~(y => 7), ~(z => {==}), x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
