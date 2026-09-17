# the full spec pipeline: forall evidence + exists sigma, filled by
# induction -- absurd arm via the empty match, witness built through a
# cong lemma, IH destructured from the recursive call; the witness
# computes.
# ported from bend3: bend3's `forall x where IsEven(x)` interleaved the
# evidence as its own parameter, which bend spells as a second forall
# clause; the explicit-motive cong closes the step
import Base

type N is Data:
  Z{}
  S{p: N}

law double:
  for n: N
  N

def double(n):
  match n:
    case Z{}:
      Z{}
    case S{p}:
      S{S{double(p)}}

law IsEven:
  for n: N
  Type

def IsEven(n):
  match n:
    case Z{}:
      Unit
    case S{Z{}}:
      Empty
    case S{S{p}}:
      IsEven(p)

law half_exists:
  for x: N
  for e: IsEven(x)
  exs y: N
  {double(y) == x : N}

law cong_ss:
  for -a: N
  for -b: N
  for  e: {a == b : N}
  {S{S{a}} == S{S{b}} : N}

def cong_ss(a, b, e):
  %e : {S{S{a}} == S{S{_}} : N}
  {==}

law half_exists.step:
  for -p: N
  for  w: (&y: N -> {double(y) == p : N})
  exs  y: N
  {double(y) == S{S{p}} : N}

def half_exists.step(p, w):
  (y, pf) = w
  (S{y}, cong_ss(double(y), p, pf))

def half_exists(x, e):
  match x:
    case Z{}:
      (Z{}, {==})
    case S{Z{}}:
      match e:
    case S{S{p}}:
      half_exists.step(p, half_exists(p, e))

law sample:
  &y: N -> {double(y) == S{S{S{S{Z{}}}}} : N}

def sample(): half_exists(S{S{S{S{Z{}}}}}, Unit{})

law main:
  &y: N -> {double(y) == S{S{S{S{Z{}}}}} : N}

def main(): sample()

#|(S{S{Z{}}}, {==})
