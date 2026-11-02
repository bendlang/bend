# Specification helpers for LAWS.bend, not part of the editable game.
# Keep this file and LAWS.bend unchanged when rewriting main.bend or PROOF.bend.

import Base
import ./main.bend as Game

def drawn() -> String:
  Game.grid(Nat.sub(Game.map_h(), 1n))

def flag_at(y: Nat, x: Nat, s: String) -> Bool:
  row = Maybe.default(&2, String, List.get(&2, String, String.lines(s), y), "")
  cell = Maybe.default(&2, Char, String.get(row, x), Chr{0})
  Char.is_eq(cell, Chr{70})

def at_flag(g: Game.Game) -> Bool:
  Game.Game{x, y, won} = g
  flag_at(y, x, drawn())
