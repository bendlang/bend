# the textbook HOAS evaluator: beta is closure application, wnf feeds
# bod(arg), snf rebuilds under a fresh binder. bend3's linear-descent
# ledger certified this; bend's descent law cannot (bod(arg) shrinks
# no column), so a Nat fuel rides ahead of every self-call, and each
# computed decision becomes a state constructor matched structurally
# one fuel step later (a computed match is a banned form); the
# runtime pins survive: closures as ctor fields, capture, and the
# rebuilt-binder path.
# ported from bend3: bare ctors, the U32 answer reads back via
# U32.to_nat
import Base

type Trm is Type:
  Lm{bod: Trm -> Trm}
  Ap{fun: Trm, arg: Trm}
  Nm{val: U32}

type WK is Type:
  Ev{t: Trm}
  Bt{arg: Trm, h: Trm}

law wk.halt:
  for k: WK
  Trm

def wk.halt(k):
  match k:
    case Ev{t}:
      t
    case Bt{arg, h}:
      Ap{h, arg}

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
            case Ap{fun, arg}:
              wnf(g, Bt{arg, wnf(g, Ev{fun})})
            case t:
              t
        case Bt{arg, h}:
          match h:
            case Lm{bod}:
              wnf(g, Ev{bod(arg)})
            case h:
              Ap{h, arg}

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

law snf:
  for +f: Nat
  for  k: SK
  Trm

def snf(f, k):
  match f:
    case 0n:
      sk.halt(k)
    case 1n+g:
      match k:
        case Go{t}:
          snf(g, Sp{wnf(g, Ev{t})})
        case Sp{h}:
          match h:
            case Lm{bod}:
              Lm{x => snf(g, Go{bod(x)})}
            case Ap{fun, arg}:
              Ap{snf(g, Go{fun}), snf(g, Go{arg})}
            case h:
              h

law main.out:
  Nat

law main.rd:
  for t: Trm
  Nat

def main.rd(t):
  match t:
    case Nm{val}:
      U32.to_nat(val)
    case t:
      0n

def main.out():
  main.rd(snf(9n, Go{Ap{Lm{x => Ap{Lm{y => y}, x}}, Nm{42}}}))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|42n
