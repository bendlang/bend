# the rest of the surface, each op one native: %. is fmod, neg is the
# unary minus, pow and atan2 take two operands, the inverse trig trio
# closes on its own answer, and to_u32 truncates toward zero
import Base

law main.out:
  String

def main.out():
  a = F32.show((7.5 % 2.0 : F32))
  b = F32.show(F32.neg(1.25))
  c = F32.show(F32.pow(2.0, 10.0))
  d = F32.show(F32.atan2(1.0, 1.0))
  e = F32.show(F32.asin(1.0))
  f = F32.show(F32.acos(1.0))
  g = F32.show(F32.atan(1.0))
  h = U32.show(F32.to_u32(3.9))
  i = F32.show(U32.to_f32(7))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e ++ " " ++ f ++ " " ++ g
    ++ " " ++ h ++ " " ++ i

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|1.5 -1.25 1024 0.7853982 1.5707964 0 0.7853982 3 7
