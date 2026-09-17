# bend3's under-binder normalization of a partial application had no
# stable golden here once (the trusted HOAS normalizer overflowed the
# host); bend's iterative print path renders it deterministically --
# the rebuilt binders carry their deferred snf thunk spelled as the
# bare stuck call, bend's own shape. The evaluator's recursion rides
# a Nat fuel matched ahead of every self-call, and each computed
# decision becomes a state constructor matched structurally one fuel
# step later (a computed match is a banned form); the thunk sticks
# where wnf matches a free variable, fuel in hand.
import Base

type Trm is Type:
  TLam{bod: Trm -> Trm}
  TApp{fun: Trm, arg: Trm}
  TNum{val: U32}

type WK is Type:
  Ev{t: Trm}
  Ap{arg: Trm, h: Trm}

law wk.halt:
  for k: WK
  Trm

def wk.halt(k):
  match k:
    case Ev{t}:
      t
    case Ap{arg, h}:
      TApp{h, arg}

law wnf:
  for +f: Nat
  for  k: WK
  Trm

def wnf(f, k):
  match f:
    case 0n:
      wk.halt(k)
    case 1n+g:
      match k:
        case Ev{t}:
          match t:
            case TApp{fun, arg}:
              wnf(g, Ap{arg, wnf(g, Ev{fun})})
            case t:
              t
        case Ap{arg, h}:
          match h:
            case TLam{bod}:
              wnf(g, Ev{bod(arg)})
            case h:
              TApp{h, arg}

type SK is Type:
  Go{t: Trm}
  Sp{h: Trm}

law sk.halt:
  for k: SK
  Trm

def sk.halt(k):
  match k:
    case Go{t}:
      t
    case Sp{h}:
      h

law snf9:
  for +f: Nat
  for  k: SK
  Trm

def snf9(f, k):
  match f:
    case 0n:
      sk.halt(k)
    case 1n+g:
      match k:
        case Go{t}:
          snf9(g, Sp{wnf(g, Ev{t})})
        case Sp{h}:
          match h:
            case TLam{bod}:
              TLam{x => snf9(g, Go{bod(x)})}
            case TApp{fun, arg}:
              TApp{snf9(g, Go{fun}), snf9(g, Go{arg})}
            case h:
              h

law compose:
  Trm

def compose():
  TLam{f => TLam{g => TLam{x => TApp{f, TApp{g, x}}}}}

law main:
  Trm

def main():
  snf9(9n, Go{TApp{compose(), TLam{y => y}}})

#|TLam{x => TLam{x => snf9(4n, Sp{wnf(1n, Ap{x, wnf(1n, Ev{x^0})})})}}
