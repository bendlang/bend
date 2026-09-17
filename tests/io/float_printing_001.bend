# float printing: an IO main prints 1/3 through F32.show as the shortest
# digits that read back to the same binary32, the same on every lane
# (the interpreter runs an IO main through the JS runtime, so F32.div
# computes there too; a pure F32 main is stuck on the bodiless law)
import Base

law main:
  IO(Unit)

def main():
  IO.print(F32.show((1.0 / 3.0 : F32)))

#|0.33333334
