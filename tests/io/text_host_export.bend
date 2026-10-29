# An exported def takes and answers Bend's own text, as an effect does: no
# conversion either way, so the caller converts what it knows to need it.
# Valid text, astral included, is the same either way and round-trips.
# Chr{55296} is "\uDC00\0\u001B\0" (DC00, then its code in three 11-bit
# parts) going out and coming in: odd answers it, count reads that text
# plus "x" as 2 Chars, and code reads it back as 55296.
import Base

def Text.host_export() -> IO(U32):
  import "./text_host_export.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Text.host_export()
    IO.print(U32.show(value))

#|0
