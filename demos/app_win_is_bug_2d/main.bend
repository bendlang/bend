# Winning Is Impossible -- the game.
#
# The whole game, and nothing else: a torus map, a walled room, a flag, four
# moves, and the level as text (the front end asks `grid` for it). Stepping onto
# the flag's cell is the win. The claims about this game live in LAWS.bend;
# their proofs live in PROOF.bend. This file is AI-written and may be rewritten
# at will -- the laws hold or the book stops checking.

import Base

type Move is Data:
  Up{}
  Down{}
  Left{}
  Right{}

type Game is Data:
  Game{x: Nat, y: Nat, won: Bool}

# Map
# ---

def map_w() -> Nat:
  12n

def map_h() -> Nat:
  8n

def room_w() -> Nat:
  3n

def room_h() -> Nat:
  3n

def flag_x() -> Nat:
  1n

def flag_y() -> Nat:
  1n

def start_x() -> Nat:
  8n

def start_y() -> Nat:
  5n

def nat_eq(a: Nat, b: Nat) -> Bool:
  match a:
    case 0n:
      match b:
        case 0n:
          True{}
        case 1n+q:
          False{}
    case 1n+p:
      match b:
        case 0n:
          False{}
        case 1n+q:
          nat_eq(p, q)

def nat_le(a: Nat, b: Nat) -> Bool:
  match a:
    case 0n:
      True{}
    case 1n+p:
      match b:
        case 0n:
          False{}
        case 1n+q:
          nat_le(p, q)

def wall(+x: Nat, +y: Nat) -> Bool:
  east  = nat_eq(x, room_w()) && nat_le(y, room_h())
  south = nat_le(x, room_w()) && nat_eq(y, room_h())
  north = nat_le(x, room_w()) && nat_eq(y, Nat.sub(map_h(), 1n))
  west  = nat_eq(x, Nat.sub(map_w(), 1n)) && nat_le(y, room_h())
  (east || south) || (north || west)

# Step
# ----

def pick(-A: Type, c: Bool, a: A, b: A) -> A:
  match c:
    case True{}:
      a
    case False{}:
      b

def warp_up(y: Nat) -> Nat:
  match y:
    case 0n:
      Nat.sub(map_h(), 1n)
    case 1n+p:
      p

def warp_down(+y: Nat) -> Nat:
  pick(Nat, nat_eq(1n+y, map_h()), 0n, 1n+y)

def warp_left(x: Nat) -> Nat:
  match x:
    case 0n:
      Nat.sub(map_w(), 1n)
    case 1n+p:
      p

def warp_right(+x: Nat) -> Nat:
  pick(Nat, nat_eq(1n+x, map_w()), 0n, 1n+x)

def on_flag(+x: Nat, +y: Nat) -> Bool:
  nat_eq(x, flag_x()) && nat_eq(y, flag_y())

def move(+tx: Nat, +ty: Nat, g: Game) -> Game:
  Game{x, y, +w0} = g
  pick(Game, wall(tx, ty), Game{x, y, w0}, Game{tx, ty, w0 || on_flag(tx, ty)})

def step(a: Move, g: Game) -> Game:
  match a:
    case Up{}:
      Game{+x0, +y0, w} = g
      move(x0, warp_up(y0), Game{x0, y0, w})
    case Down{}:
      Game{+x0, +y0, w} = g
      move(x0, warp_down(y0), Game{x0, y0, w})
    case Left{}:
      Game{+x0, +y0, w} = g
      move(warp_left(x0), y0, Game{x0, y0, w})
    case Right{}:
      Game{+x0, +y0, w} = g
      move(warp_right(x0), y0, Game{x0, y0, w})

def start() -> Game:
  Game{start_x(), start_y(), False{}}

# Keys
# ----
# The front end sends every key press as its character code (`w` is 119;
# the arrows arrive as w, a, s, d) and plays the move this answers, so a
# new key is one more line here and one more Move.

def key(+k: U32) -> Maybe<Move>:
  pick(Maybe<Move>, U32.is_eq(k, 119), Some{Up{}},
    pick(Maybe<Move>, U32.is_eq(k, 115), Some{Down{}},
      pick(Maybe<Move>, U32.is_eq(k, 97), Some{Left{}},
        pick(Maybe<Move>, U32.is_eq(k, 100), Some{Right{}}, None{}))))

# The worker takes the list first: the guard wants the shrinking argument
# in the first live column. `replay` is the API: a board, then its moves.
def run(moves: List<Move>, g: Game) -> Game:
  match moves:
    case Nil{}:
      g
    case m <> ms:
      run(ms, step(m, g))

def replay(g: Game, moves: List<Move>) -> Game:
  run(moves, g)

def is_won(g: Game) -> Bool:
  Game{x, y, w} = g
  w

# Show
# ----
# The map, printed: '#' wall, 'F' flag, 'P' the starting cell, '.' floor.
# The front end asks `grid` for this exact text, so the level is defined
# once, here.

def cell(+x: Nat, +y: Nat) -> String:
  is_flag  = on_flag(x, y)
  is_start = nat_eq(x, start_x()) && nat_eq(y, start_y())
  pick(String, wall(x, y), "#",
    pick(String, is_flag, "F",
      pick(String, is_start, "P", ".")))

def row(x: Nat, +y: Nat) -> String:
  match x:
    case 0n:
      cell(0n, y)
    case 1n++p0:
      row(p0, y) ++ cell(1n+p0, y)

def grid(y: Nat) -> String:
  match y:
    case 0n:
      row(Nat.sub(map_w(), 1n), 0n)
    case 1n++p0:
      grid(p0) ++ "\n" ++ row(Nat.sub(map_w(), 1n), 1n+p0)

def main() -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print(grid(Nat.sub(map_h(), 1n)))
    IO.print(pick(String, is_won(replay(start(), [Left{}, Left{}, Up{}])),
      "WON (this line is unreachable)", "still not won"))
