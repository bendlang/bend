# The laws. The human states them; PROOF.bend must prove them.

import Base
import ./main.bend as Game

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
  {Game.at_flag(board) == False{} : Bool}
