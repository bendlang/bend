# a loop's call to a large def with several call sites: run steps a 4x4
# Life torus through step, which classify also calls twice, so step is
# no single-site def and the C lane inlines it into run's loop itself
# (the step is bench/runtime/gameoflife's)
import Base

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def cell_get(board: U32, r: U32, c: U32) -> U32:
  U32.and(U32.shrn(board, U32.to_nat(U32.and(U32.add(U32.mul(U32.and(r, 3), 4), U32.and(c, 3)), 31))), 1)

def neighbor_count(+board: U32, +r: U32, +c: U32) -> U32:
  U32.add(cell_get(board, U32.sub(r, 1), U32.sub(c, 1)), U32.add(cell_get(board, U32.sub(r, 1), c), U32.add(cell_get(board, U32.sub(r, 1), U32.add(c, 1)), U32.add(cell_get(board, r, U32.sub(c, 1)), U32.add(cell_get(board, r, U32.add(c, 1)), U32.add(cell_get(board, U32.add(r, 1), U32.sub(c, 1)), U32.add(cell_get(board, U32.add(r, 1), c), cell_get(board, U32.add(r, 1), U32.add(c, 1)))))))))

def next_cell.go(+n: U32, z: Bool) -> U32:
  match z:
    case True{}:
      b2u(U32.is_eq(n, 3))
    case False{}:
      b2u(Bool.or(U32.is_eq(n, 2), U32.is_eq(n, 3)))

def step_cell(+board: U32, +pos: U32) -> U32:
  +rr = U32.shrn(pos, 2n)
  +cc = U32.and(pos, 3)
  alive = cell_get(board, rr, cc)
  neighbors = neighbor_count(board, rr, cc)
  U32.shln(next_cell.go(neighbors, U32.is_zero(alive)), U32.to_nat(U32.and(pos, 31)))

def step(+b: U32) -> U32:
  U32.or(step_cell(b, 0), U32.or(step_cell(b, 1), U32.or(step_cell(b, 2), U32.or(step_cell(b, 3), U32.or(step_cell(b, 4), U32.or(step_cell(b, 5), U32.or(step_cell(b, 6), U32.or(step_cell(b, 7), U32.or(step_cell(b, 8), U32.or(step_cell(b, 9), U32.or(step_cell(b, 10), U32.or(step_cell(b, 11), U32.or(step_cell(b, 12), U32.or(step_cell(b, 13), U32.or(step_cell(b, 14), step_cell(b, 15))))))))))))))))

def run(n: Nat, board: U32) -> U32:
  match n:
    case 0n:
      board
    case 1n+p:
      run(p, step(board))

# 0: a still life, 1: a period-2 oscillator, 2: neither
def classify.go(t: Bool, +n1: U32, +b: U32) -> U32:
  match t:
    case True{}:
      0
    case False{}:
      U32.sub(2, b2u(U32.is_eq(step(n1), b)))

def classify(+b: U32) -> U32:
  classify.go(U32.is_eq(step(b), b), step(b), b)

# the soups i .. i + j - 1, each run g steps: the boards hashed, the classes summed
def soups(+j: Nat, +i: U32, +g: Nat, mix: U32, cls: U32) -> U32:
  match j:
    case 0n:
      U32.add(U32.mul(mix, 2654435761), cls)
    case 1n+p:
      +bd = run(g, U32.and(U32.mul(U32.add(i, U32.from_nat(p)), 2654435761), 65535))
      soups(p, i, g, U32.xor(U32.mul(mix, 2654435761), bd), U32.add(cls, classify(bd)))

def mix(a: U32, b: U32) -> U32:
  U32.add(U32.mul(a, 2654435761), b)

def main.out() -> U32:
  mix(mix(mix(mix(mix(run(1n, 51), run(3n, 4660)), classify(51)), classify(4369)), soups(64n, 0, 2n, 0, 0)), soups(200n, 1000, 32n, 7, 0))

def main() -> IO(Unit):
  IO.print(U32.show(main.out()))

#|1233505334
