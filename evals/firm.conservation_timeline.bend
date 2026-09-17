# A museum conservator records labeled phases and their durations in ticks.
# Produce each phase's completion time, measured from the start of the work.
# Prove that appending phases splices their timeline after the first total duration.
import Base

type Phases is Data:
  EndPhases{}
  Phase{label: Nat, ticks: Nat, rest: Phases}

def join(xs: Phases, ys: Phases) -> Phases:
  match xs:
    case EndPhases{}:
      ys
    case Phase{label, ticks, rest}:
      Phase{label, ticks, join(rest, ys)}

def elapsed(xs: Phases) -> Nat:
  match xs:
    case EndPhases{}:
      0n
    case Phase{label, ticks, rest}:
      Nat.add(ticks, elapsed(rest))

def delay(+ticks: Nat, xs: Phases) -> Phases:
  match xs:
    case EndPhases{}:
      EndPhases{}
    case Phase{label, time, rest}:
      Phase{label, Nat.add(ticks, time), delay(ticks, rest)}

law timeline:
  for xs: Phases
  Phases

law timeline_empty:
  {timeline(EndPhases{}) == EndPhases{} : Phases}

law timeline_phase:
  for label: Nat
  for ticks: Nat
  for rest: Phases
  {timeline(Phase{label, ticks, rest}) ==
    Phase{label, ticks, delay(ticks, timeline(rest))} : Phases}

law timeline_splice:
  for xs: Phases
  for +ys: Phases
  {timeline(join(xs, ys)) ==
    join(timeline(xs), delay(elapsed(xs), timeline(ys))) : Phases}

# solution

def timeline(xs):
  match xs:
    case EndPhases{}:
      EndPhases{}
    case Phase{label, +ticks, rest}:
      Phase{label, ticks, delay(ticks, timeline(rest))}

def timeline_empty():
  {==}

def timeline_phase(label, ticks, rest):
  {==}

def add_assoc(+a: Nat, +b: Nat, +c: Nat) ->
    {Nat.add(a, Nat.add(b, c)) == Nat.add(Nat.add(a, b), c) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_assoc(p, b, c) :
        {1n+Nat.add(p, Nat.add(b, c)) == 1n+_ : Nat}
      {==}

def delay_zero(+xs: Phases) -> {xs == delay(0n, xs) : Phases}:
  match xs:
    case EndPhases{}:
      {==}
    case Phase{label, time, rest}:
      %delay_zero(rest) : {Phase{label, time, rest} == Phase{label, time, _} : Phases}
      {==}

def delay_join(+d: Nat, +xs: Phases, +ys: Phases) ->
    {delay(d, join(xs, ys)) == join(delay(d, xs), delay(d, ys)) : Phases}:
  match xs:
    case EndPhases{}:
      {==}
    case Phase{label, time, rest}:
      %delay_join(d, rest, ys) :
        {Phase{label, Nat.add(d, time), delay(d, join(rest, ys))} ==
         Phase{label, Nat.add(d, time), _} : Phases}
      {==}

def delay_twice(+a: Nat, +b: Nat, +xs: Phases) ->
    {delay(a, delay(b, xs)) == delay(Nat.add(a, b), xs) : Phases}:
  match xs:
    case EndPhases{}:
      {==}
    case Phase{+label, +time, +rest}:
      +lhs = delay(a, delay(b, Phase{label, time, rest}))
      %add_assoc(a, b, time) :
        {lhs ==
         Phase{label, _, delay(Nat.add(a, b), rest)} : Phases}
      %delay_twice(a, b, rest) :
        {lhs ==
         Phase{label, Nat.add(a, Nat.add(b, time)), _} : Phases}
      {==}

def timeline_splice(xs, ys):
  match xs:
    case EndPhases{}:
      delay_zero(timeline(ys))
    case Phase{+label, +ticks, +rest}:
      +lhs = timeline(join(Phase{label, ticks, rest}, ys))
      %delay_twice(ticks, elapsed(rest), timeline(ys)) :
        {lhs ==
          Phase{label, ticks, join(delay(ticks, timeline(rest)), _)} : Phases}
      %delay_join(ticks, timeline(rest), delay(elapsed(rest), timeline(ys))) :
        {lhs ==
          Phase{label, ticks, _} : Phases}
      %timeline_splice(rest, ys) :
        {lhs ==
          Phase{label, ticks, delay(ticks, _)} : Phases}
      {==}
