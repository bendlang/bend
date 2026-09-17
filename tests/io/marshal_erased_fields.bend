# io (io_marshal_erased_fields): a ctor crosses the effect seam in
# the emitter's object shape -- {$: "Ctr", field: value, ...}, live
# fields under their declared names, erased fields absent. The .js
# body reads .val as the VALUE and never sees the erased tag, and a
# ctor it answers carries live fields only; the interpreter runs the
# compiled JS, so the shape is one by construction. Both lanes print
# the same bytes: the value out (42), the value in (99).
import Base

type Box is Data:
  MkBox{-tag: Nat, val: U32}

law box_val:
  for b: Box
  IO(U32)

def box_val(b):
  import "./marshal_erased_fields.js"

law box_new:
  IO(Box)

def box_new():
  import "./marshal_erased_fields.js"

law box_open:
  for b: Box
  U32

def box_open(b):
  match b:
    case MkBox{t, v}:
      v

law main:
  IO(U32)

def main():
  do IO<U32>:
    x : U32 <- box_val(MkBox{7n, 42})
    u : Unit <- IO.print(U32.show(x))
    b : Box <- box_new()
    w : Unit <- IO.print(U32.show(box_open(b)))
    return 0

#|42
#|99
