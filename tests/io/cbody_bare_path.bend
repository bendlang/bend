# io pin (io_cbody_bare_path): bend3 read a bare C-body link through
# the install-rooted id and refused the local decoy at COMPILE time.
# bend has no C-bodied defs at all -- imports are leading lines only,
# so the effect-body spelling pins bend's own parse refusal.
import Base

law window:
  for title: String
  for w: U32
  for h: U32
  IO(Unit)

def window(title, w, h):
  import path_bare.c

law main:
  IO(Unit)

def main():
  window("x", 1, 1)

#|Error:
#|- expected : '"'
#|- observed : 'p'
#|Location:
#|13 | def window(title, w, h):
#|14>|   import path_bare.c
#|   |          ^
#|15 |
#|exit 1
