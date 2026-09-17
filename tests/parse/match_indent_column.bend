# a match after => owns its case rows wherever they sit: bend's one
# layout law is the case-column rule for NESTED matches, so a top match
# takes shallower case rows too.
# ported from bend3: bend3 rejected cases left of the match keyword;
# bend pins the opposite (ownership by innermost match)
type Bb7 is Data:
  Tt7{}
  Ff7{}

law notb:
  for b: Bb7
  Bb7

def notb(b): match b:
  case Tt7{}:
    Ff7{}
  case Ff7{}:
    Tt7{}

law main:
  Bb7

def main(): notb(Tt7{})

#|Ff7{}
