# bend3's `&x` share-binder let (`&y = v` binds y shared); bend's core
# is affine and & prefixes only the exists sugar, so the share-binder
# spelling pins bend's own refusal (the array statement half lives in
# flatten_array_statement)
type Nt is Data:
  Z{}
  S{p: Nt}

law main:
  for v: Nt
  Nt

def main(v):
  &y = v
  y

#|Error:
#|- expected : ':'
#|- observed : '='
#|Location:
#|13 | def main(v):
#|14>|   &y = v
#|15 |   y
#|exit 1
