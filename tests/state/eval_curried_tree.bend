# accumulator ladder, complete: IH plus the shift lemma close the arm
# ported from bend3: the ~ comp param specializes into the ladder's
# own successor step (a recursive combinator cannot bind a closure: a
# function type is never Data); the shared accumulator
# wears + (MN is Data); the theorem is stated
# flipped (bend's rewrite folds right into left, so the eliminated
# call sits on the RIGHT)
import Base

type MN is Data:
  Z{}
  S{p: MN}

law each:
  for n: MN
  for x: MN
  MN

def each(n, x):
  match n:
    case Z{}:
      S{x}
    case S{p}:
      each(p, S{x})

law plus1:
  for n: MN
  for x: MN
  MN

def plus1(n, x):
  match n:
    case Z{}:
      S{x}
    case S{p}:
      S{plus1(p, x)}

law pshift:
  for p: MN
  for x: MN
  {S{plus1(p, x)} == plus1(p, S{x}) : MN}

def pshift(p, x):
  match p:
    case Z{}:
      {==}
    case S{q}:
      %pshift(q, x) : {S{S{plus1(q, x)}} == S{_} : MN}
      {==}

law spec_thm:
  for +n: MN
  for +x: MN
  {plus1(n, x) == each(n, x) : MN}

def spec_thm(n, x):
  match n:
    case Z{}:
      {==}
    case S{p}:
      %spec_thm(p, S{x}) : {S{plus1(p, x)} == _ : MN}
      %pshift(p, x) : {S{plus1(p, x)} == _ : MN}
      {==}

law main:
  @n: MN -> @x: MN -> {plus1(n, x) == each(n, x) : MN}

def main():
  n => x => spec_thm(n, x)

#|n => x => spec_thm(n, x)
