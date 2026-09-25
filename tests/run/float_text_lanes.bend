# F32.read and F32.show answer as the C lane does on JS: read rounds the
# decimal once (JS once read a decimal just past an f32 midpoint, such as
# 16777217.00000000001, to the near side, and the largest decimal under
# the overflow threshold as inf), takes ASCII space only (NBSP once read
# as 1), and show rounds a decimal tie to even (23577.5625 once printed as
# 23577.563)
import Base

def bits(m: Maybe<&2, F32>) -> String:
  match m:
    case None{}:
      "None"
    case Some{v}:
      U32.show(F32.bits(v))

def main.out() -> String:
  bits(F32.read("16777217.00000000001"))
    ++ (" " ++ bits(F32.read("340282356779733661637539395458142568447")))
    ++ (" " ++ bits(F32.read("-7.0064923216240854e-46")))
    ++ (" " ++ bits(F32.read("\u{a0}1")))
    ++ (" " ++ bits(F32.read(" \t\u{b}\u{c}\r\n1")))
    ++ (" " ++ F32.show(23577.5625))
    ++ (" " ++ F32.show(F32.neg(2983783.25)))

def main() -> IO(Unit):
  IO.print(main.out())

#|1266679809 2139095039 2147483649 None 1065353216 23577.562 -2983783.2
