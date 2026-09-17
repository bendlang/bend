# audit: a zero-constructor datatype is `type Void:` -- the next
# def/type-headed entry ends it.
# ported from bend3: the match moves behind a def (no literal-ctor
# scrutinee), the empty match eliminates the empty type (an applied
# bare \{} is a banned form)
type Void is Data:

type Uu1 is Data:
  One{}

law absurd:
  for v: Void
  Uu1

def absurd(v):
  match v:

law pick:
  for u: Uu1
  Uu1

def pick(u):
  match u:
    case One{}:
      One{}

law main:
  Uu1

def main():
  pick(One{})

#|One{}
