# comp-splice pin (spec_comp_capture_erase): bend3 took a capture's
# quantity from the specialized body's own uses, so an all-erased
# capture erased at the caller too. bend has no comp surface; the ~
# binder pins bend's own parse refusal. (bend3's () Unit literal is
# respelled Unit{}: bend has no unit literal.)
import Base

type D is Data:
  Da{f0: F32, -f1: U32}

law cp:
  for ~f: Unit -> (F32 & D)
  for x: Unit
  (F32 & D)

def cp(f, x):
  f(x)

law mk:
  for -n: U32
  Unit

def mk(n):
  Unit{}

law rd:
  for x: (F32 & D)
  U32

def rd(x):
  match x:
    case (a, b):
      F32.to_u32(a)

law main:
  U32

def main():
  rd(cp(z => (19.0, Da{3.0, 7}), mk(7)))

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|11 | law cp:
#|12>|   for ~f: Unit -> (F32 & D)
#|13 |   for x: Unit
#|exit 1
