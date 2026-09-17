# bend3 refused '_' in rewrite motives ('a defined name'); bend binds
# '_' there by design, so the natural sym and cong spellings CHECK --
# the inverted law, pinned positively
import Base

law sym3:
  for -a: Type
  for -x: a
  for -y: a
  for  e: {x == y : a}
  {y == x : a}

def sym3(a, x, y, e):
  %e : {_ == x : a}
  {==}

law cong3:
  for -a: Type
  for -b: Type
  for -f: a -> b
  for -u: a
  for -v: a
  for  e: {u == v : a}
  {f(u) == f(v) : b}

def cong3(a, b, f, u, v, e):
  %e : {f(u) == f(_) : b}
  {==}

law main.out:
  U32

def main.out():
  0

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|0
