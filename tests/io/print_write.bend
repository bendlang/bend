# io (io_print_write): print (newline) and write (raw) sequence in
# order through the event loop, and U32.show feeds a computed string
# to an effect. Ported from bend3; bend3's result-word exit code was
# bend3 CLI behavior -- bend's loop discards the Emit word, and the
# interp lane pins no exit line.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Unit <- IO.print("hello")
    b : Unit <- IO.write("num=")
    c : Unit <- IO.print(U32.show((40 + 2 : U32)))
    +text : String = U32.show(123) ++ " é🌍"
    d : Unit <- IO.print(text)
    e : Unit <- IO.print("prefix:" ++ text)
    f : Unit <- IO.print(text)
    return 7

#|hello
#|num=42
#|123 é🌍
#|prefix:123 é🌍
#|123 é🌍
