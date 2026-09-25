# io pin (io_cbody_needs_io): bend3 refused a C-bodied def pairing
# with no constructor on the install Op. bend has no C-bodied defs --
# imports are leading lines only, so the effect-body spelling pins
# bend's own parse refusal.
import Base

law beep:
  for times: U32
  U32

def beep(times):
  import ./lib/eff.c

law main:
  U32

def main():
  beep(3)

#|Error:
#|- expected : '"'
#|- observed : '.'
#|Location:
#|11 | def beep(times):
#|12>|   import ./lib/eff.c
#|   |          ^
#|13 |
#|exit 1
