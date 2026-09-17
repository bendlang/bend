# bend3's ++ died un-opened inside inferred types; bend's ++ opens to
# String.append at parse, so an equation SPELLED with ++ meets its
# rewrite motive written on the opened call -- the append identity
# closes by induction through it (the comp ~ half of the original died
# with comp, pinned by the spec_comp refusals)
import Base

law append_id:
  for s: String
  {s ++ "" == s : String}

def append_id(s):
  match s:
    case SNil{}:
      {==}
    case SCon{c, t}:
      %append_id(t) : {SCon{c, String.append(t, "")} == SCon{c, _} : String}
      {==}

law main.out:
  Nat

def main.out():
  0n

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
