# Specification helpers for LAWS.bend, not part of the editable program.
# Keep this file and LAWS.bend unchanged when rewriting main.bend or PROOF.bend.

import Base

# whether (b - a) x (p - a) is negative, read as a signed 32-bit number
def side(+ax: U32, +ay: U32, bx: U32, by: U32, px: U32, py: U32) -> Bool:
  ((bx - ax) * (py - ay) - (by - ay) * (px - ax) > 2147483647 : U32)

# the triangle with corners (256, 64), (64, 448) and (448, 448)
def inside(+x: U32, +y: U32) -> Bool:
  (side(256, 64, 64, 448, x, y) && side(64, 448, 448, 448, x, y)
    && side(448, 448, 256, 64, x, y))
