# direction pin: the residual order stays in LE. A match rest-arm
# wants (D - A) -> Unit; a whole-D fallback fits (removing more
# constructors fits removing fewer, swapped through the domain), so
# layer-by-layer lambda-match checking keeps working.
type D is Data:
  A{}
  B{}
type Unit is Data:
  Unit{}

law fallback: D -> Unit
def fallback(d): Unit{}

law matcher: D -> Unit
def matcher(): \{A: Unit{}; fallback}

law main: Unit
def main(): matcher(B{})

#|Unit{}
