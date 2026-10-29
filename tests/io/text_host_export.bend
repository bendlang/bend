# An exported def gives and takes host text at any depth: str_in on the
# way in and str_out on the way out, whatever the declared type, so
# Bend's packing of a non-scalar Char never reaches the caller. Valid
# text, astral included, round-trips; a lone surrogate going in and
# Chr{55296} coming out both read as U+FFFD, in a list, a tuple, an
# array, through a polymorphic def, and through a closure either way.
# A value with no text to change crosses as itself, so an Array
# argument is still updated in place.
import Base

def Text.host_export() -> IO(U32):
  import "./text_host_export.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Text.host_export()
    IO.print(U32.show(value))

#|0
