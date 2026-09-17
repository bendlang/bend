# Pong -- the laws: what a frame does with Esc, and how the keys remember.
import Base
import ./main.bend as Game

# LAW: an Esc key-down quits, whatever follows it and whatever the state.
law esc_quits:
  for rest: List<Event>
  for g: Game.Pong
  {Game.Pong.events(Key{27, True{}} <> rest, g) == None{} : Maybe<Game.Pong>}

# LAW: the last press of a key wins: pressing or releasing a key twice
# leaves the keys as the second press alone would, whatever the key.
law last_press:
  for +code: U32
  for d1: Bool
  for +d2: Bool
  for +keys: Game.Pong.Keys
  {Game.Pong.press(code, d2, Game.Pong.press(code, d1, keys))
    == Game.Pong.press(code, d2, keys) : Game.Pong.Keys}
