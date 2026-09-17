# printer fixpoint: a constructor's continuation prints as its trailing
# lambda; this main is written exactly as the printer spells it (an
# open Succ chain renders 1n+x), and shows back unchanged.
# ported from bend3: the local IO type renames to Eff with fresh ctor
# names (bend ctors are global), payloads become Nat
import Base

type Eff is Type:
  EDone{value: Nat}
  EPrint{text: Nat, cont: @k:Nat -> Eff}

law main:
  Eff

def main():
  EPrint{1n, x => EDone{1n+x}}

#|EPrint{1n, x => EDone{1n+x}}
