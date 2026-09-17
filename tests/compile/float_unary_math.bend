# the exp and log family reaches its native: exp, log, log2, log10 and
# sqrt are one libm call each, and the inverse pair closes on 1.0
import Base

law main.out:
  String

def main.out():
  a = F32.show(F32.exp(1.0))
  b = F32.show(F32.log(F32.exp(1.0)))
  c = F32.show(F32.log2(8.0))
  d = F32.show(F32.log10(1000.0))
  e = F32.show(F32.sqrt(2.0))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|2.7182817 0.99999994 3 3 1.4142135
