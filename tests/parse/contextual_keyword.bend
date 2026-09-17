# `as` is a contextual keyword: it marks an import alias only, and binds
# like any name in term positions.
# ported from bend3: bend3 reserved `as` everywhere; bend pins the
# opposite (contextual) law
type Vv is Data:
  Ok{}

law apply:
  for f: Vv -> Vv
  for v: Vv
  Vv

def apply(f, v): f(v)

law main:
  Vv

def main(): apply(as => as, Ok{})

#|Ok{}
