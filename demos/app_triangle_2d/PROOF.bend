# Triangle -- the proofs. Esc quits by computation; the two click laws
# rewrite the inside test with the hypothesis, then compute.
import Base
import ./main.bend as App
import ./LAWS.bend as Laws

def Laws.esc_quits(rest, n):
  {==}

def Laws.click_inside(id, tool, x, y, time, button, n, hit):
  %hit : {Some{App.Tri.pick(_, (n + 1 : U32), n)} == Some{(n + 1 : U32)}
    : Maybe<U32>}
  {==}

def Laws.click_outside(id, tool, x, y, time, button, n, miss):
  %miss : {Some{App.Tri.pick(_, (n + 1 : U32), n)} == Some{n} : Maybe<U32>}
  {==}
