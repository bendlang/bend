# ordinary math names are ordinary binders: KEYWORDS is the only
# reserved set, so `floor` binds like any name.
# ported from bend3: the let RHS carries an annotation (a bare ctor
# cannot infer)
type Vv9 is Data:
  Ok9{}

law main:
  Vv9

def main():
  floor = {Ok9{} : Vv9}
  floor

#|Ok9{}
