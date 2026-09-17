# computed-match twin: the scrutinee is a call, the hypothesis h
# mentions it, and the binder k still measures at the branch join --
# computed and variable matches price identically.
# ported from bend3: bend statement-lets cannot precede a match, so k
# spends inside the arms
type Ne is Data:
  Ze{}
  Se{p: Ne}

law fe:
  for n: Ne
  Ne

def fe(n):
  match n:
    case Ze{}:
      Ze{}
    case Se{p}:
      Se{p}

law use.go:
  for k: Ne -> Ne
  for w: Ne
  Ne

def use.go(k, w):
  match w:
    case Ze{}:
      k(Ze{})
    case Se{p}:
      k(Se{p})

law use:
  for n: Ne
  for h: {fe(n) == Ze{} : Ne}
  for k: Ne -> Ne
  Ne

def use(n, h, k):
  use.go(k, fe(n))

law main:
  Ne

def main():
  Ze{}

#|Ze{}
