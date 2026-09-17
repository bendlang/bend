# io (io_halt_utf8_law): the loop's exit writer rides the kit's text
# law -- Halt prints its message on stderr as UTF-8, one sequence per
# Char, on every lane (the C loop, the JS runtime and the interpreter
# each spell the halt writer, so a drift in one was invisible through
# ASCII). Chr{232} is C3 A8 and Chr{10049} is E2 9D 81.
import Base

law main:
  IO(Unit)

def main():
  IO.die(Unit, 7, SCon{Chr{232}, SCon{Chr{10049}, SNil{}}})

#|è❁
#|exit 7
