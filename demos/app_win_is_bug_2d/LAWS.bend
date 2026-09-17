# The laws. The human states them; PROOF.bend must prove them.

import Base
import ./main.bend as Game

# LAW: for any sequence of moves, replaying them
# from the start can never lead to victory.
law you_cant_win:
  for moves: List<Game.Move>
  board = Game.replay(Game.start(), moves)
  {Game.is_won(board) == False{} : Bool}

# The board the page draws: grid(map_h() - 1), one row per line, and
# the page's reading of it: the character at column x of row y, 'F'
# where it draws the flag. Both laws bind exactly what the page shows.
def drawn() -> String:
  Game.grid(Nat.sub(Game.map_h(), 1n))

def ch(c: Char, k: U32) -> Bool:
  Chr{code} = c
  U32.is_eq(code, k)

def pick(-A: Type, c: Bool, a: A, b: A) -> A:
  match c:
    case True{}:
      a
    case False{}:
      b

# the text after the first line
def next_row(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{c, +rest}:
      pick(String, ch(c, 10), rest, next_row(rest))

# whether column x of the first line is 'F'
def flag_in_row(s: String, x: Nat) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{c, rest}:
      match x:
        case 0n:
          ch(c, 70)
        case 1n+p:
          pick(Bool, ch(c, 10), False{}, flag_in_row(rest, p))

# whether the page draws a flag at row y, column x of s
def flag_at(y: Nat, x: Nat, s: String) -> Bool:
  match y:
    case 0n:
      flag_in_row(s, x)
    case 1n+q:
      flag_at(q, x, next_row(s))

# a board with the player on a drawn flag
def at_flag(g: Game.Game) -> Bool:
  Game.Game{x, y, won} = g
  flag_at(y, x, drawn())

# LAW: the player never stands on the flag: no sequence of moves puts
# the player on an 'F' cell of the board the page draws.
law never_on_flag:
  for moves: List<Game.Move>
  board = Game.replay(Game.start(), moves)
  {at_flag(board) == False{} : Bool}
