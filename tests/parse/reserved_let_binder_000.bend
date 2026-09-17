# math names are ordinary let binders: KEYWORDS is the only reserved
# set, so `sqrt` binds like any name.
# ported from bend3: the let RHS carries an annotation (a bare ctor
# cannot infer)
type Vq0 is Data:
  Qv0{}

law f:
  Vq0

def f():
  sqrt = {Qv0{} : Vq0}
  sqrt

law main:
  Vq0

def main(): f()

#|Qv0{}
