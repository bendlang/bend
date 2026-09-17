# a rewrite under dependent hypotheses about the same equation checks
# clean -- no ill-typed-rebind page exists (bend's rewrite is
# goal-only J, so h2/h3 are never rebound)
import Base
type N is Data:
  NZ{}
  NS{p: N}

law add:
  for a: N
  for b: N
  N

def add(a, b):
  match a:
    case NZ{}:
      b
    case NS{p}:
      NS{add(p, b)}

law f:
  for n  : N
  for e  : {add(n, NZ{}) == NZ{} : N}
  for h2 : {add(n, NZ{}) == NZ{} : N}
  for h3 : {h2 == h2 : {add(n, NZ{}) == NZ{} : N}}
  N

def f(n, e, h2, h3):
  %e : N
  NZ{}

#|All terms check.
