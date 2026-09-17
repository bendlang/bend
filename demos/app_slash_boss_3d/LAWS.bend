# Slash Boss 3D -- the laws. Claims about the sim's pure logic, the
# part the interpreter can evaluate without F32 arithmetic: the pause
# freezes the world for any number of ticks, pausing twice restores
# the pause state of any game, an Esc anywhere in a frame's events
# quits, and the closed facts about the countdown, the key bits, the
# pause toggle and the route back to the title. PROOF.bend proves
# them.

import Base
import ./bend3d.bend as R
import ./main.bend as Slash

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
  {Slash.Game.steps(n, Slash.Game{time, held, 0, 4, hero, boss, flash, cloth, garb, lens, blast})
    == Slash.Game{time, held, 0, 4, hero, boss, Slash.Sim.fade(n, flash), cloth, garb, lens, blast}
    : Slash.Game}

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
  {Slash.Game.events(Slash.Game.cat(pre, Key{27, True{}} <> post), g) == None{}
    : Maybe<Slash.Game>}

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

# LAW: w a s d are the bits 1 2 4 8 of the held word, and the arrow
# keys (up 63232, left 63234, down 63233, right 63235) are the same
# four bits (sanity).
law arrows_are_wasd:
  {(Slash.Key.mask(119), Slash.Key.mask(97), Slash.Key.mask(115), Slash.Key.mask(100),
    Slash.Key.mask(63232), Slash.Key.mask(63234), Slash.Key.mask(63233), Slash.Key.mask(63235))
   == (1, 2, 4, 8, 1, 2, 4, 8) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}
