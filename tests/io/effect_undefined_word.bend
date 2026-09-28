# io (io_effect_undefined_word): an effect's C source may say the word
# undefined, in a comment or a string. The C emitter refuses its output
# when the word shows up there, since in the C it generates the word can
# only be a JS undefined that leaked; it read the effect sources spliced
# into that output too, so the twin's comment failed the native build
# with "an unbound name in the emitted C" while the other lanes ran. The
# guard now reads the generated C alone.
import Base

law word.len:
  U32 -> IO(U32)

def word.len(n):
  import "./effect_undefined_word.c"
  import "./effect_undefined_word.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : U32 <- word.len(2)
    IO.print(U32.show(a))

#|18
