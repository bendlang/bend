# a root stuck on a specialized parameter splits at its constructors
# (run3, #1175; run4; dup), rebuilt each time (two_split, tag_id,
# res_root, res_pt, nest); a Quant one only when read (q_unread goes out
# once). The laws check the emitted book's values
import Base

type Box is Type:
  Mk{fn: Nat -> Nat}

def q1(f: Box) -> Quant:
  match f:
    case Mk{g}: &1

def run3(f: Box, -A: Kind(q1(f)), +x: Nat) -> Nat:
  match f:
    case Mk{g}:
      match x:
        case 0n: g(x)
        case 1n+p: g(p)

def q0(f: Box) -> Quant:
  &1

def run4(f: Box, -A: Kind(q0(f)), +x: Nat) -> Nat:
  match f:
    case Mk{g}: g(x)

type Mode is Data:
  Shared{}
  Owned{}

type Cfg is Data:
  Cfg{len: Nat, mode: Mode}

def elem_q(c: Cfg) -> Quant:
  match c:
    case Cfg{n, Shared{}}: &2
    case Cfg{n, Owned{}}: &1

def dup(c: Cfg, -A: Kind(elem_q(c)), x: A, d: A) -> (A & A):
  match c:
    case Cfg{n, Shared{}}:
      +y = x
      (y, y)
    case Cfg{n, Owned{}}:
      (x, d)

def pick(p: Nat & Nat) -> Nat:
  match p:
    case (a, b): Nat.add(a, b)

def qb(b: Bool, m: Mode) -> Quant:
  match b:
    case False{}: &1
    case True{}: &1

def g(m: Mode, -A: Kind(elem_m(m)), x: Nat) -> Nat:
  x

def elem_m(m: Mode) -> Quant:
  match m:
    case Shared{}: &2
    case Owned{}: &1

def two_split(b: Bool, m: Mode, -A: Kind(qb(b, m)), x: Nat) -> Nat:
  g(m, Nat, x)

def Sel(m: Mode) -> Data:
  match m:
    case Shared{}: Nat
    case Owned{}: Mode

type Tag is Data:
  Tag{mode: Mode, val: Sel(mode)}

def tag_q(c: Tag) -> Quant:
  match c:
    case Tag{Shared{}, v}: &2
    case Tag{Owned{}, v}: &1

def tag_id(c: Tag, -A: Kind(tag_q(c)), x: Nat) -> Tag:
  c

type Res<m: Mode> is Kind(elem_m(m)):
  Res{n: Nat}

def res_root(m: Mode, -A: Kind(q0b(m)), r: Res<m>) -> Nat:
  0n

def q0b(m: Mode) -> Quant:
  &1

def Pt(f: Box, -A: Kind(q1(f))) -> Type:
  Nat

def res_pt(m: Mode, -A: Kind(q0b(m)), w: Pt(Mk{(y: Nat) => 1n}, Nat), r: Res<m>) -> Nat:
  0n

type Two<-A: Data, -B: Data> is Data:
  Two{a: A, b: B}

def nest_q(c: Two<Two<Mode, Mode>, Mode>) -> Quant:
  match c:
    case Two{Two{Shared{}, y}, z}: &2
    case Two{Two{Owned{}, y}, z}: &1

def nest(c: Two<Two<Mode, Mode>, Mode>, -A: Kind(nest_q(c)), x: Nat) -> Nat:
  x

def q_unread(a: Quant, x: Nat) -> Nat:
  x

def main() -> Nat:
  Nat.add(Nat.add(run3(Mk{(y: Nat) => 1n}, Nat, 0n), run4(Mk{(y: Nat) => 2n}, Nat, 0n)),
    pick(dup(Cfg{3n, Shared{}}, Nat, 4n, 9n)))

law main_is_11:
  {main() == 11n : Nat}

def main_is_11():
  {==}

#|11n
