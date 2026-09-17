# a case body may share the case line: bend layout is shape-delimited
# (whitespace is irrelevant beyond the case-column law), so the inline
# form parses the same as the newline form.
# ported from bend3: bend3 rejected the inline body; bend pins the
# opposite (layout-free) law
type Bb is Data:
  Tt{}
  Ff{}

law f:
  for b: Bb
  Bb

def f(b):
  match b:
    case Tt{}: Ff{}
    case Ff{}:
      Tt{}

law main:
  Bb

def main(): f(Tt{})

#|Ff{}
