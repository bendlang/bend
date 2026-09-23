# def f?(..) is @unsafe def f(..): the ? after the name skips the
# descent check and lets f call a def written below it
import Base

type Term is Type:
  TRef{k: String}
  TLam{f: Term -> Term}
  TApp{f: Term, x: Term}

def wnf?(x: Term) -> Term:
  match x:
    case TApp{f, a}:
      wnf_app(wnf(f), a)
    case term:
      term

def wnf_app?(f: Term, x: Term) -> Term:
  match f:
    case TLam{b}:
      wnf(b(x))
    case g:
      TApp{g, x}

def show(t: Term) -> String:
  match t:
    case TRef{k}:
      k
    case TLam{f}:
      "lam"
    case TApp{f, x}:
      "app"

def main() -> String:
  show(wnf(TApp{TLam{x => TApp{x, TRef{"y"}}}, TLam{z => z}}))

#|"y"
