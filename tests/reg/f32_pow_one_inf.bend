# regression witness: Math.pow(±1, ±Infinity) is NaN, and so is
# Math.pow(1, NaN). libm pow returns 1, so JS and C took opposite
# branches of F32.is_eq (#1060). pow(-1, 3) stays -1, and pow(-1, NaN)
# stays NaN.
import Base

def show(+x: F32) -> String:
  Bool.show(F32.is_eq(x, 1.0)) ++ (" " ++ U32.show(F32.bits(x)))

def main.out() -> String:
  +inf = F32.div(1.0, 0.0)
  +ninf = F32.neg(inf)
  +neg = F32.neg(1.0)
  +nan = F32.div(0.0, 0.0)
  show(F32.pow(1.0, inf)) ++ (" " ++ show(F32.pow(1.0, ninf)))
    ++ (" " ++ show(F32.pow(neg, inf)))
    ++ (" " ++ show(F32.pow(neg, ninf)))
    ++ (" " ++ show(F32.pow(1.0, nan)))
    ++ (" " ++ U32.show(F32.bits(F32.pow(neg, 3.0))))
    ++ (" " ++ U32.show(F32.bits(F32.pow(neg, nan))))

def main() -> IO(Unit):
  IO.print(main.out())

#|True 1065353216 True 1065353216 True 1065353216 True 1065353216 True 1065353216 3212836864 2143289344
