# a foreign fill closes its name like a body does: parse_def took a
# def holding only import lines for an open assert (v null) and let a
# second def fill it again, so the book checked with both a foreign
# path and a body on one def; the JS lane then died on the missing
# .js (raw ENOENT) and the C emitter on a raw TypeError (k.replace).
# the second def is now the duplicate declaration it always was
import Base

law f:
  IO(Unit)

def f():
  import "./nothing.js"

def f():
  IO.print("body")

def main() -> IO(Unit):
  f()

#|Error:
#|- expected : a fresh name (duplicate declaration: f)
#|- observed : 'f'
#|Location:
#|14 | 
#|15>| def f():
#|   |     ^
#|16 |   IO.print("body")
#|exit 1
