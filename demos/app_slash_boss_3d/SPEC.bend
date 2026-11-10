# Specification helpers for LAWS.bend, not part of the editable game.
# Keep this file and LAWS.bend unchanged when rewriting main.bend or PROOF.bend.

import Base
import ./bend3d.bend as R
import ./main.bend as Slash

# n ticks of the game, as the loop's Live.steps runs them
def steps(n: Nat, +g: Slash.Game) -> Slash.Game:
  match n:
    case 0n:
      g
    case 1n+k:
      steps(k, Slash.Game.step(g))

# the game a live state holds
def game_of(l: Slash.Live) -> Slash.Game:
  Slash.Live{game, prev, stamp, debt, begin, frames, cues} = l
  game

# the game a frame leaves, or None when the frame ends the game
def frame_game(m: Maybe<Slash.Live>) -> Maybe<Slash.Game>:
  match m:
    case None{}:
      None{}
    case Some{l}:
      Some{game_of(l)}

# the ticks a frame owes: 60 a second of the time since stamp, at most
# 100 ms of it, on top of the debt (thousandths of a tick)
def owed(+stamp: Nat, +debt: U32, +now: Nat) -> Nat:
  +ms = U32.from_nat(Nat.sub(now, stamp))
  U32.to_nat(((debt + R.word((ms < 100 : U32), ms, 100) * 60 : U32) / 1000 : U32))

# a countdown's tick: down by one, never below 0
def dec(+x: U32) -> U32:
  R.word((x > 0 : U32), (x - 1 : U32), 0)

# n fades of a countdown
def fade(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+k:
      fade(k, dec(x))

# a frame's events joined
def cat(a: List<Event>, b: List<Event>) -> List<Event>:
  match a:
    case Nil{}:
      b
    case e <> rest:
      e <> cat(rest, b)

# whether a frame's events hold no Esc and no Close: Unit when they
# hold none, Empty when they hold one
def Calm.key(esc: Bool, rest: Type) -> Type:
  match esc:
    case True{}:
      Empty
    case False{}:
      rest

def Calm(es: List<Event>) -> Type:
  match es:
    case Nil{}:
      Unit
    case Key{code, down} <> rest:
      Calm.key(U32.is_eq(code, 27), Calm(rest))
    case Close{} <> rest:
      Empty
    case e <> rest:
      Calm(rest)
