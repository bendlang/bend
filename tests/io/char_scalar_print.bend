# io (io_char_scalar_print): a String is a chain of Unicode scalar
# values (lit_of says so: a JS string holds scalars only, so a literal
# that spells a surrogate is its chain), so a Char at a code past
# U+10FFFF or a surrogate is the one refusal every lane makes, spelled
# as char_new spells it. marshal_char_scalar already pins that law at
# the FFI seam, where the compiled leg is JS alone; this golden is the
# lane it leaves open. A String built in Bend and handed to IO.print
# goes out as bytes through io_utf8, and io_utf8 encoded the raw code
# point: Chr{55296} left as ED A0 80, not UTF-8, with exit 0, so the
# same program refused on the interpreter and on JS and succeeded here
# with output no reader can decode. The three boundary scalars
# (55295, 57344, 1114111) cross first, as they do in
# marshal_char_scalar, so a guard misfiring on any of them names that
# code in the refusal instead of 55296. halt_utf8_law is the same
# writer with scalars only.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    IO.print(SCon{Chr{55295}, SCon{Chr{57344}, SCon{Chr{1114111}, SNil{}}}})
    IO.print(SCon{Chr{55296}, SNil{}})
    IO.print("unreachable")
    return 0

#|퟿􏿿
#|bend: 55296 is not a Unicode scalar value
#|exit 1
