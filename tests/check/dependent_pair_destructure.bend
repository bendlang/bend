# destructuring a DEPENDENT pair: (v, e) = q binds the witness and a
# proof whose type mentions it; the erased proof rides along.
# ported from bend3
import Base

law use:
  for q: &x:U32 -> {x == 3 : U32}
  U32

def use(q):
  (v, e) = q
  v

law main:
  U32

def main(): use((3, {==}))

#|3
