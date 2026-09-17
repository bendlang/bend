# bend3's io_main peeled the telescope and refused an IO main with
# parameters at COMPILE time; bend's event loop calls main with no
# arguments, so a parameterized main is not an IO<T> main and the
# compiler refuses it, while the interp prints the stuck ref
import Base

law main:
  for x: U32
  IO(U32)

def main(x):
  R => k => k(x)

#|x => R => k => k(x)
