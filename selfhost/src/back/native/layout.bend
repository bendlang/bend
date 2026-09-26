@unsafe
def nl_c_type(+k: N_WordKind) -> String:
  match k:
    case N_W32{}: "u32"
    case N_W64{}: "Term"
    case N_Box{}: "Term"

