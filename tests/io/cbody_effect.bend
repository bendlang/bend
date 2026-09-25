# io pin (io_cbody_effect): bend3's C-BODIED DEF -- a def whose body is
# `import ./x.c` minted an Op constructor and the driver ran the
# effect natively. bend has no C-bodied defs -- imports are leading
# lines only, so the effect-body spelling pins bend's own parse
# refusal.
import Base

law beep:
  for times: U32
  IO(U32)

def beep(times):
  import ./lib/eff.c

law main:
  IO(U32)

def main():
  do IO<U32>:
    x : U32 <- beep(3)
    return x

#|Error:
#|- expected : '"'
#|- observed : '.'
#|Location:
#|12 | def beep(times):
#|13>|   import ./lib/eff.c
#|   |          ^
#|14 |
#|exit 1
