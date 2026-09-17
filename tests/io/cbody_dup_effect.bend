# io pin (io_cbody_dup_effect): bend3 minted io_<name> from a C-bodied
# def's bare name and refused two defs claiming one C symbol. bend
# has no C-bodied defs -- imports are leading lines only, so the
# effect-body spelling pins bend's own parse refusal.
import Base

law print:
  for x: U32
  IO(Unit)

def print(x):
  import ./lib/eff.c

law main:
  IO(Unit)

def main():
  IO.print("hi")

#|Error:
#|- expected : '"'
#|- observed : '.'
#|Location:
#|11 | def print(x):
#|12>|   import ./lib/eff.c
#|13 |
#|exit 1
