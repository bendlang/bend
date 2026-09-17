# AUDIT 17, residual claim, updated by the lambda-match application
# ban: a match cannot scrutinize a local binder at all now (erased or
# not), so the erased local's live-spend-by-match is refused one stage
# earlier, at the flattener (AUDIT 4a's repair, match shape)
type Bit is Data:
  On{}
  Off{}

law erase_then_match:
  for z: Bit
  Bit

def erase_then_match(z):
  -x = {z : Bit}
  match x:
    case On{}: On{}
    case Off{}: Off{}

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)
#|Location:
#|13 | def erase_then_match(z):
#|14>|   -x = {z : Bit}
#|15 |   match x:
#|exit 1
