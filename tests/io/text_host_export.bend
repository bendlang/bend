# An exported def takes and answers host strings: its caller's text comes
# in through str_in, so a lone surrogate is U+FFFD and a lone DC00 never
# reads as the head of a packed Char ("a", DC00, "bcd" counts 5), and a
# Char or String it answers leaves through str_out, so Chr{55296} reaches
# the caller as U+FFFD. Valid text, astral included, round-trips.
import Base

def Text.host_export() -> IO(U32):
  import "./text_host_export.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Text.host_export()
    IO.print(U32.show(value))

#|0
