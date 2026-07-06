def double(x: u24) -> u24:
  return x * 2

def add(a: u24, b: u24) -> u24:
  return a + b

def is_even(x: u24) -> u24:
  return (x % 2) == 0

def gt3(x: u24) -> u24:
  return x > 3

def sum_pair(p: (u24, u24)) -> u24:
  (x, y) = p
  return x + y

def main() -> List(u24):
  xs = List/range(1, 6)
  a = List/sum(List/map(xs, double))
  b = List/fold(xs, 0, add)
  c = List/sum(xs)
  d = List/all(xs, is_even)
  e = List/any(xs, is_even)
  f = List/contains(xs, 3)
  g = List/contains(xs, 99)
  h = List/sum(List/take(xs, 2))
  i = List/sum(List/drop(xs, 2))
  j = Maybe/unwrap(List/find(xs, gt3))
  k = Maybe/unwrap(List/at(xs, 1))
  l = List/sum(List/take(xs, 99))
  m = List/sum(List/map(List/zip(xs, xs), sum_pair))
  return [a, b, c, d, e, f, g, h, i, j, k, l, m]
