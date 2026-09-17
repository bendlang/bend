# io (io_text_utf8): a String reaches the OS as UTF-8, one sequence per
# Char, in every lane -- the C kit's io_cstr binds the JS kit's io_bytes
# and both event loops, on stdout AND stderr. Before this pin the
# writers cast each code point to a byte, so Chr{233} wrote E9, a byte
# no UTF-8 terminal can show; now it writes C3 A9 on every lane, and a
# lane that re-encoded the bytes would print "Ã©" where the law prints
# one character.
import Base

law txt:
  String

def txt():
  SCon{Chr{101}, SCon{Chr{233}, SNil{}}}

law acc:
  String

def acc():
  SCon{Chr{233}, SNil{}}

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    u : Unit <- IO.write(txt())
    v : Unit <- IO.print(acc())
    w : Unit <- IO.print_err(acc())
    IO.die(Unit, 7, acc())

#|eéé
#|é
#|é
#|exit 7
