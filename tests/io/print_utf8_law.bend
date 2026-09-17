# io (io_print_utf8_law): the kit's text law on the writers -- a String
# is code points, and print, write and print_err emit each Char as its
# UTF-8 bytes on every lane, never as its low byte. Chr{232} (e-grave)
# is C3 A8, Chr{10049} (a florette) is E2 9D 81 and Chr{128578} (a
# smile) is F0 9F 99 82: a lane that cast the code point to a byte
# would print "\xe8AB" where the law prints three characters.
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    a : Unit <- IO.write(SCon{Chr{232}, SNil{}})
    b : Unit <- IO.print(SCon{Chr{10049}, SCon{Chr{128578}, SNil{}}})
    c : Unit <- IO.print_err(SCon{Chr{233}, SNil{}})
    return Unit{}

#|è❁🙂
#|é
