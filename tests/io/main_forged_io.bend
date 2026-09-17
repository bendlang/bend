# io (io_main_forged_io): IO means BASE's IO -- the def wearing the b
# flag only base.bend mints, the foreign gate's own reading. io_type
# once matched main's head by NAME alone, so a main at a user family
# spelled IO was driven through the event loop: the interpreter
# refused 'an IO action (main is stuck)' and the compiled JS crashed
# with a raw TypeError applying a value as a function -- two divergent
# failures on a legal program. Now the forged IO is not IO at all: the
# interpreter's value lane prints the term, and the compiled backends,
# which SPEC 1.8 confines to IO mains, refuse it loud. This member
# spells its shard prefix t_io_main_forged_io on purpose: the shard
# rename is textual and skips base names, and this book OWNS one (IO),
# so it must build standalone.

type Box is Data: Full{}

law IO:
  for -A: Type
  Type

def IO(A):
  Box

law main:
  IO(Box)

def main():
  Full{}

#|Full{}
