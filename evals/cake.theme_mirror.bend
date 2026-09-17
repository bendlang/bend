# A theme switcher keeps the page theme, Light or Dark, and logs the
# user's clicks: Toggle flips the theme, SetLight and SetDark force one,
# Reset returns to the default, Light. replay folds a log from a start
# theme into the final theme. The dark build of the app swaps the themes,
# so it mirrors a log: SetLight and SetDark swap, Reset becomes SetDark,
# Toggle stays. Prove the dark build always ends opposite the light build.

import Base

type Theme is Data:
  Light{}
  Dark{}

type Click is Data:
  Toggle{}
  SetLight{}
  SetDark{}
  Reset{}

def flip(t: Theme) -> Theme:
  match t:
    case Light{}:
      Dark{}
    case Dark{}:
      Light{}

def replay(xs: List<Click>, s: Theme) -> Theme:
  match xs:
    case Nil{}:
      s
    case Toggle{} <> t:
      replay(t, flip(s))
    case SetLight{} <> t:
      replay(t, Light{})
    case SetDark{} <> t:
      replay(t, Dark{})
    case Reset{} <> t:
      replay(t, Light{})

def mirror(xs: List<Click>) -> List<Click>:
  match xs:
    case Nil{}:
      Nil{}
    case Toggle{} <> t:
      Toggle{} <> mirror(t)
    case SetLight{} <> t:
      SetDark{} <> mirror(t)
    case SetDark{} <> t:
      SetLight{} <> mirror(t)
    case Reset{} <> t:
      SetDark{} <> mirror(t)

# LAW: a mirrored log, replayed from the flipped start, ends on the flipped theme
law mirror_replay:
  for xs: List<Click>
  for s: Theme
  {replay(mirror(xs), flip(s)) == flip(replay(xs, s)) : Theme}

# solution

def mirror_replay(xs, s):
  match xs:
    case Nil{}:
      {==}
    case Toggle{} <> t:
      mirror_replay(t, flip(s))
    case SetLight{} <> t:
      mirror_replay(t, Light{})
    case SetDark{} <> t:
      mirror_replay(t, Dark{})
    case Reset{} <> t:
      mirror_replay(t, Light{})
