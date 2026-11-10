# Slash Boss 3D -- the laws. Claims about the sim's pure logic, the
# part the interpreter can evaluate without F32 arithmetic: the pause
# freezes the world for any number of ticks, the loop's ticks are the
# game's and a frame runs the ticks it owes, a frame whose events end
# the game ends the loop, pausing twice restores the pause state of
# any game, an Esc anywhere in a frame's events quits, a frame with no
# Esc and no Close does not end the game and a frame with no events
# keeps it as it is, the game's countdown is SPEC.bend's for any
# count, and the closed facts about the countdown, the key bits, the
# pause toggle and the route back to the title. PROOF.bend proves
# them.
#
# What they leave open: live_steps and live_after read only the game a
# Live holds, so its prev, stamp, debt, begin, frames and cues are not
# pinned (a Live.after that passes a debt of 0, or keeps the old
# stamp, still checks), and neither is the IO part of the loop,
# Play.*, that calls Live.after. A frame that holds events is pinned
# only by esc_quits and calm_keeps: one whose mouse move changes the
# game still checks.

import Base
import ./bend3d.bend as R
import ./main.bend as Slash
import ./SPEC.bend as Spec

# LAW: a pause freezes the world: with no key tapped, any number of
# ticks of a paused game (mode 4) leaves its time, its keys, the hero,
# the boss, the cape, the cloths, the lens and the last detonation as
# they were; only the hit flash fades, one per tick.
law pause_freezes:
  for n: Nat
  for +time: U32
  for +held: U32
  for +hero: Slash.Fighter
  for +boss: Slash.Boss
  for +flash: U32
  for +cloth: R.Cloth
  for +garb: Slash.Garb
  for +lens: Slash.Lens
  for +blast: Maybe<&2, Slash.Blast>
  {Spec.steps(n, Slash.Game{time, held, 0, 4, hero, boss, flash, cloth, garb, lens, blast})
    == Slash.Game{time, held, 0, 4, hero, boss, Spec.fade(n, flash), cloth, garb, lens, blast}
    : Slash.Game}

# LAW: the loop's ticks are the game's: n of them leave any game
# where n ticks of Game.step leave it, whatever the previous game and
# the cues.
law live_steps:
  for n: Nat
  for prev: Slash.Game
  for +g: Slash.Game
  for now: Nat
  for +debt: U32
  for begin: Nat
  for +frames: U32
  for cues: List<&2, Slash.Cue>
  {Spec.game_of(Slash.Live.steps(n, prev, g, now, debt, begin, frames, cues)) == Spec.steps(n, g)
    : Slash.Game}

# LAW: a frame that goes on with game g leaves g after the ticks it
# owes, counted by SPEC.bend's owed.
law live_after:
  for prev: Slash.Game
  for +g: Slash.Game
  for +stamp: Nat
  for +debt: U32
  for +now: Nat
  for begin: Nat
  for frames: U32
  for cues: List<&2, Slash.Cue>
  {Spec.frame_game(Slash.Live.after(Some{g}, prev, stamp, debt, now, begin, frames, cues))
    == Some{Spec.steps(Spec.owed(stamp, debt, now), g)} : Maybe<Slash.Game>}

# LAW: a frame whose events end the game ends the loop: Live.after
# hands None on, so an Esc or a Close quits rather than going on.
law frame_quits:
  for prev: Slash.Game
  for stamp: Nat
  for debt: U32
  for now: Nat
  for begin: Nat
  for frames: U32
  for cues: List<&2, Slash.Cue>
  {Spec.frame_game(Slash.Live.after(None{}, prev, stamp, debt, now, begin, frames, cues))
    == None{} : Maybe<Slash.Game>}

# LAW: P twice restores the pause state of any game: paused stays
# paused, unpaused stays unpaused, whatever the mode was.
law pause_twice:
  for +g: Slash.Game
  {Slash.Game.paused(Slash.Game.pause(Slash.Game.pause(g))) == Slash.Game.paused(g) : Bool}

# LAW: an Esc key-down anywhere in a frame's events quits, whatever
# the events before and after it and whatever the game.
law esc_quits:
  for pre: List<Event>
  for post: List<Event>
  for g: Slash.Game
  {Slash.Game.events(Spec.cat(pre, Key{27, True{}} <> post), g) == None{}
    : Maybe<Slash.Game>}

# LAW: a frame with no Esc and no Close does not end the game,
# whatever else it holds: the other side of esc_quits.
law calm_keeps:
  for es: List<Event>
  for g: Slash.Game
  for e: Spec.Calm(es)
  exs g2: Slash.Game
  {Slash.Game.events(es, g) == Some{g2} : Maybe<Slash.Game>}

# LAW: a frame with no events keeps the game as it is.
law empty_keeps:
  for g: Slash.Game
  {Slash.Game.events(Nil{}, g) == Some{g} : Maybe<Slash.Game>}

# LAW: K past the fight goes back to the title whatever else is
# tapped: the route on back = True is the initial game, for every
# other flag and every game (sanity).
law back_to_title:
  for fresh: Bool
  for pause: Bool
  for live: Bool
  for frozen: Bool
  for +g: Slash.Game
  {Slash.Game.route(True{}, fresh, pause, live, frozen, g) == Slash.Game.init() : Slash.Game}

# LAW: the pause toggles: P during a fight pauses it, P again resumes
# it, and P on the title does nothing (sanity).
law pause_toggles:
  {(Slash.Game.paused(Slash.Game.pause(Slash.Game.fresh(0, 1))),
    Slash.Game.paused(Slash.Game.pause(Slash.Game.pause(Slash.Game.fresh(0, 1)))),
    Slash.Game.paused(Slash.Game.pause(Slash.Game.init())))
   == (True{}, False{}, False{}) : Bool & Bool & Bool}

# LAW: a countdown never underflows: at 0 it stays 0, and a hit's
# flash (7) falls to 6 (sanity).
law dec_floor:
  {(Slash.Sim.dec(0), Slash.Sim.dec(7)) == (0, 6) : U32 & U32}

# LAW: the game's countdown is SPEC.bend's for any count, so the
# flash fades the way pause_freezes measures it.
law dec_is_spec:
  for +x: U32
  {Slash.Sim.dec(x) == Spec.dec(x) : U32}

# LAW: w a s d are the bits 1 2 4 8 of the held word, and the arrow
# keys (up 63232, left 63234, down 63233, right 63235) are the same
# four bits (sanity).
law arrows_are_wasd:
  {(Slash.Key.mask(119), Slash.Key.mask(97), Slash.Key.mask(115), Slash.Key.mask(100),
    Slash.Key.mask(63232), Slash.Key.mask(63234), Slash.Key.mask(63233), Slash.Key.mask(63235))
   == (1, 2, 4, 8, 1, 2, 4, 8) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}
