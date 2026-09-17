# io (io_array_depth_bound): the Array depth wall is ONE law. The C
# backend stores a word Array as a flat block whose cell class ends
# at 31, so buf_new refuses a deeper build loud (error 10) - but the
# JS lanes built the same Array as a structurally shared ANode tree
# in O(depth) and RAN: [7 : U32^32n] printed 7 and exited 0 on
# the interpreter and --js while every C binary fail-stopped, a
# backend acceptance divergence of the launch-blocker class (SPEC
# 1.8; natives behave identically in every lane, SPEC 1.7). The C
# side cannot widen - a 2^32-cell block does not exist - so the wall
# joins the lanes on the refusal side: runtime.js array_new refuses
# a depth past 31 by throw, the char_new spelling (the interpreter
# runs in-process, so a refusal must throw, never exit). Depth 31
# itself stays legal in both walls: its C build is an honest heap
# exhaustion, machine capacity, not this law. The compiled-JS leg
# exits through io_exit, whose catch fail-stops the escaped throw
# as the interpreter's own one-line spelling on stderr, exit 1.
import Base

law main:
  IO(U32)

law main.go:
  for r: Array<U32> & U32
  IO(U32)

def main.go(r):
  (a, x) = r
  do IO<U32>:
    u : Unit <- IO.print(U32.show(x))
    return 0

def main():
  main.go(Array.get(U32, [7 : U32^32n], 5))

#|bend: an array past the deepest block class 31
#|exit 1
