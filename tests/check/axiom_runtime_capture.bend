# comp pin (check_axiom_runtime_capture): bend3 smuggled an axiom into
# runtime through a comp-lambda capture and died at erasure. bend has
# no comp surface to open that door -- the ~ binder pins bend's own
# parse refusal (the runtime-axiom wall itself is pinned by
# compile_axiom_runtime).
import Base

law magic:
  U32

law tpl:
  for ~f: U32 -> U32
  for x: U32
  U32

def tpl(f, x):
  f(x)

law main:
  U32

def main():
  tpl(y => (y + magic : U32), 1)

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|11 | law tpl:
#|12>|   for ~f: U32 -> U32
#|13 |   for x: U32
#|exit 1
