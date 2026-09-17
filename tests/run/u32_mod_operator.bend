# a spaced % is U32.mod and %. is F32.mod: the glued % still heads a
# rewrite, which is why the operator demands the space. a zero divisor
# answers the dividend, as U32.mod does everywhere
import Base

law main.out:
  String

def main.out():
  a = U32.show((17 % 5 : U32))
  b = U32.show((17 % 0 : U32))
  c = F32.show((7.5 % 2.0 : F32))
  a ++ " " ++ b ++ " " ++ c

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|2 17 1.5
