# The laws. The human states them; PROOF.bend must prove them.

import Base
import ./main.bend as Game
import ./BOARD.bend as Board

# LAW: for any sequence of moves, replaying them
# from the start can never lead to victory.
law you_cant_win:
  for moves: List<Game.Move>
  board = Game.replay(Game.start(), moves)
  {Game.is_won(board) == False{} : Bool}

# LAW: the player never stands on the flag: no sequence of moves puts
# the player on an 'F' cell of the board the page draws.
law never_on_flag:
  for moves: List<Game.Move>
  board = Game.replay(Game.start(), moves)
  {Board.at_flag(board) == False{} : Bool}

# LAW: replay composes: replaying `a`, then `b` from where `a` ends, is
# replaying `a` then `b` from the start. A front end that plays one move at
# a time from its current board stays inside the two laws above.
law replay_composes:
  for g: Game.Game
  for a: List<Game.Move>
  for b: List<Game.Move>
  {Game.replay(Game.replay(g, a), b) == Game.replay(g, List.append(&1, Game.Move, a, b)) : Game.Game}
