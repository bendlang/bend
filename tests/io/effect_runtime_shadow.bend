# io (io_effect_runtime_shadow): an effect function named after a
# runtime.js helper reaches only its own def. The foreign splice laid
# raw function declarations in the runtime's own scope, so an effect
# def named Cmp.new (function cmp_new) REPLACED the helper cmp_new
# and corrupted every base op built on it: U32.cmp(1, 2) printed lt
# interpreted and gt compiled, silently. The splice now sits in one
# function scope behind a typeof-guarded table (the interpreter's
# eff_all shape), so the effect answers 8 AND the helper survives to
# answer lt, in both lanes.
import Base

law Cmp.new:
  for a: U32
  IO(U32)

def Cmp.new(a):
  import "./effect_runtime_shadow.js"

law show_cmp:
  for c: Cmp
  String

def show_cmp(c):
  match c:
    case LT{}:
      "lt"
    case EQ{}:
      "eq"
    case GT{}:
      "gt"

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    x : U32 <- Cmp.new(7)
    u : Unit <- IO.print(U32.show(x))
    IO.print(show_cmp(U32.cmp(1, 2)))

#|8
#|lt
