# record ladder, complete: destructuring the record computes both
# projections away; the value refolds to the ref (main replaces --eval)
type MN is Data:
  Z{}
  S{p: MN}

type P3 is Data:
  Mk{x: MN, y: MN, z: MN}

law rot:
  for p: P3
  P3

def rot(p):
  match p:
    case Mk{x, y, z}:
      Mk{y, z, x}

law getx:
  for p: P3
  MN

def getx(p):
  match p:
    case Mk{x, y, z}:
      x

law gety:
  for p: P3
  MN

def gety(p):
  match p:
    case Mk{x, y, z}:
      y

law rot_x:
  for p: P3
  {getx(rot(p)) == gety(p) : MN}

def rot_x(p):
  match p:
    case Mk{x, y, z}:
      {==}

law main:
  @p: P3 -> {getx(rot(p)) == gety(p) : MN}

def main():
  p => rot_x(p)

#|p => rot_x(p)
