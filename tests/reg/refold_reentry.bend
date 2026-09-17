# regression (AUDIT 1): a completed call's answer never refolds to the
# call -- the wnf once kept the def's exhausted equation active while
# entering the returned value, so a stuck match inside the result
# rebuilt as the finished call (id2(Type, sel(b)) instead of sel(b))
# and a legal proof failed conversion. Both value doors are pinned:
# the forced-thunk result (id_delta) and a bound variable's value
# applied to an argument (ap_delta). the stuck match rides a def call
# (sel), since a bare applied match is a banned form.
import Base

law id2:
  for -A: Type
  for  x: A
  A

def id2(A, x):
  x

law sel:
  for b: Bool
  Type

def sel(b):
  match b:
    case True{}:
      Type
    case False{}:
      Type

law id_delta:
  for -b: Bool
  {id2(Type, sel(b)) == sel(b) : Type}

def id_delta(b):
  {==}

law ap:
  for -A: Type
  for -B: Type
  for  f: @x: A -> B
  for  a: A
  B

def ap(A, B, f, a):
  f(a)

law ap_delta:
  for -b: Bool
  {ap(Bool, Type, x => sel(x), b) == sel(b) : Type}

def ap_delta(b):
  {==}

def Bool.text(b: Bool) -> String:
  match b:
    case True{}:
      "True"
    case False{}:
      "False"

law main:
  IO(Unit)

def main():
  IO.print(Bool.text(True{}))

#|True
