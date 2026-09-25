# io pin (io_gfx_opaque_term): bend3 crossed a Data-kinded Image term
# OPAQUE through the GFX effect boundary (Pix unboxed, no marshalling
# anywhere in the emitted C). bend has no IO driver, no GFX and no
# Image -- the do block dies on the missing surface (the frame
# respells through walled GFX builders: Image's ctors have no bend
# declaration to spell).
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    a : Unit <- GFX.window("term kind", 8, 8)
    b : Unit <- GFX.blit(GFX.from_fn(1, x => y => (x + y : U32)))
    ws : List<U32> <- GFX.gfx_events()
    GFX.blit(GFX.qua(GFX.pix(1), GFX.pix(2), GFX.pix(3), GFX.qua(GFX.pix(4), GFX.pix(5), GFX.pix(6), GFX.pix(7))))

#|Error:
#|- expected : a defined name
#|- observed : GFX.window
#|Location: main
#|13 |   do IO<Unit>:
#|14>|     a : Unit <- GFX.window("term kind", 8, 8)
#|   |                 ^^^^^^^^^^
#|15 |     b : Unit <- GFX.blit(GFX.from_fn(1, x => y => (x + y : U32)))
#|exit 1
