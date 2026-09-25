# bend3's C27 let a def between an assert and its fill call the
# asserted name; bend refuses by design -- a def may not use a
# demanded name (only asserts may), and the refusal names the law
import Base

law foo:
  for x: U32
  U32

law bar:
  U32

def bar():
  foo(1)

def foo(x):
  x

law main:
  U32

def main():
  0

#|Error:
#|- expected : a filled definition (an unfilled law is a dead claim: live code cannot use it)
#|- observed : foo
#|Location: bar
#|13 | def bar():
#|14>|   foo(1)
#|   |   ^^^
#|15 |
#|exit 1
