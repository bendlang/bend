# regression witness: carbonize lifted a Rwt node verbatim, so binders
# crossing a statement rewrite (params, let binds, fork results) went
# stale at emission -- C died "an unbound binder" / "an under-applied
# def value" and the JS build threw ReferenceError at run. The rewrite
# now dies at carbonize (evidence and motive erased, body carbonized in
# place) and an unused live let drops with it, so a spent equation's
# proof (add_comm's Word walk below) never reaches the emitters.
import Base

type Nt is Data:
  Ntz{}
  Nts{p: Nt}

law add:
  for a: Nt
  for b: Nt
  Nt

def add(a, b):
  match a:
    case Ntz{}:
      b
    case Nts{p}:
      Nts{add(p, b)}

def th(a: Nt, -b: Nt) -> {add(a, Nts{b}) == Nts{add(a, b)} : Nt}:
  match a:
    case Ntz{}:
      {==}
    case Nts{p}:
      %th(p, b) : {Nts{add(p, Nts{b})} == Nts{_} : Nt};
      {==}

def cast(e: {1 == 1 : U32}, w: U32) -> U32:
  %e : U32; w

def tw(+n: Nat, +a0: U32) -> U32:
  match n:
    case 0n:
      a0
    case 1n+p:
      tw(p, (a0 * 3 + 1 : U32))

def go(+k: U32) -> U32:
  na = {Nts{Nts{Ntz{}}} : Nt}
  nb = {Ntz{} : Nt}
  p1 p2 = tw(3n, k) tw(2n, (k + 1 : U32))
  e = U32.add_comm(k, 7)
  %e : U32;
  %th(na, nb) : U32;
  ((k + p1) * p2 + cast({==}, k) : U32)

law main.out:
  U32

def main.out():
  go(5)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|8879
