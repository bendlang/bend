# A regional field-science planner audits chronological station visits.
# Replaying a journey increments a saved visit count once per station identifier.
# Prove that replay adds exactly the journey's length to every saved count.
import Base

def visits(stations: +List<Nat>) -> Nat:
  match stations:
    case Nil{}:
      0n
    case Con{station, rest}:
      1n+visits(rest)

def replay(stations: +List<Nat>, saved: Nat) -> Nat:
  match stations:
    case Nil{}:
      saved
    case Con{station, rest}:
      replay(rest, 1n+saved)

law replay_count:
  for stations: +List<Nat>
  for +saved: Nat
  {replay(stations, saved) == Nat.add(visits(stations), saved) : Nat}

# solution

def add_successor(+n: Nat, +m: Nat) -> {Nat.add(n, 1n+m) == 1n+Nat.add(n, m) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_successor(p, m) : {1n+Nat.add(p, 1n+m) == 1n+_ : Nat}
      {==}

def replay_count(stations, saved):
  match stations:
    case Nil{}:
      {==}
    case Con{station, +rest}:
      %add_successor(visits(rest), saved) : {replay(rest, 1n+saved) == _ : Nat}
      replay_count(rest, 1n+saved)
