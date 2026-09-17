# Fly -- the laws: what a frame does with Esc, and how the held keys
# remember a press. The F32 scene is not claimed.
import Base
import ./main.bend as Ray

# LAW: an Esc key-down quits, whatever follows it and whatever the state.
law esc_quits:
  for rest: List<Event>
  for s: Ray.Fly
  {Ray.Fly.events(Key{27, True{}} <> rest, s) == None{} : Maybe<Ray.Fly>}

# LAW: after a key is pressed (or released), that key reads pressed (or
# released), for any slot and any held keys.
law press_reads:
  for held: List<&2, Bool>
  for +k: Nat
  for +v: Bool
  {Ray.Fly.get(Ray.Fly.set(held, k, v), k) == v : Bool}
