# Triangle -- the laws: what a frame does with Esc and with a click.
import Base
import ./main.bend as App

# LAW: an Esc key-down quits, whatever follows it and whatever the count.
law esc_quits:
  for rest: List<Event>
  for n: U32
  {App.Tri.events(Key{27, True{}} <> rest, n) == None{} : Maybe<U32>}

# LAW: a mouse-down inside the triangle adds one to the count.
law click_inside:
  for +x: U32
  for +y: U32
  for button: U32
  for +n: U32
  for hit: {True{} == App.Tri.inside(x, y) : Bool}
  {App.Tri.event(Mouse{x, y, button, True{}}, n) == Some{(n + 1 : U32)}
    : Maybe<U32>}

# LAW: a mouse-down outside the triangle keeps the count.
law click_outside:
  for +x: U32
  for +y: U32
  for button: U32
  for +n: U32
  for miss: {False{} == App.Tri.inside(x, y) : Bool}
  {App.Tri.event(Mouse{x, y, button, True{}}, n) == Some{n} : Maybe<U32>}
