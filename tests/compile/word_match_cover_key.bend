# word_match_cover_key (#892): a word match's default covers a deeper
# default only when the two are the same term. The cover test once
# compared printed terms, and term_show is not injective: an F32 whose
# bits are inf or nan prints as the name of a def called inf or nan, so
# the odd arm, which returns the constant, folded into the default,
# which returns the def, and both lanes gave 0 for an odd word. The key
# is now the lowered term without spans and annotations.
import Base

def inf() -> F32:
  0.0

def nan() -> F32:
  0.0

def bits(f: F32) -> U32:
  F32{w} = f
  U32{w}

def id(x: F32) -> F32:
  x

def odd_inf(n: U32) -> F32:
  match n:
    case U32{WCon{True{}, _}}:
      id(F32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}})
    case _:
      id(inf())

def odd_nan(n: U32) -> F32:
  match n:
    case U32{WCon{True{}, _}}:
      id(F32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}})
    case _:
      id(nan())

def show(ns: List<U32>) -> String:
  match ns:
    case []:
      ""
    case +n <> ns:
      String.append(U32.show(bits(odd_inf(n))), String.append(" ",
        String.append(U32.show(bits(odd_nan(n))), String.append(" ", show(ns)))))

def main() -> IO(Unit):
  IO.print(show([1, 0, 3]))

#|2139095040 2143289344 0 0 2139095040 2143289344 
