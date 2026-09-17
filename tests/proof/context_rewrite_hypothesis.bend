# Context rewriting: prove {x==b} from {x==a} and {a==b} by rewriting the HYPOTHESIS.
# ported from bend3: bend's rewrite is goal-only J with an explicit motive, and
# the goal motive {x == _} already closes this -- the hypothesis y proves the
# rewritten goal directly, no per-hypothesis context rewrite exists or is needed
type N is Data:
  Z{}
  S{p: N}

law trans:
  @-x: N -> @-a: N -> @-b: N -> {a == b : N} -> {x == a : N} -> {x == b : N}

def trans(): x => a => b => e => y => %e : {x == _ : N}; y

law main:
  N

def main(): Z{}

#|Z{}
