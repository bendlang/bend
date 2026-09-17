# A pomodoro timer logs each day's intervals: Work, Rest and Pause, with
# their minutes. A Work interval of 25 minutes or more is a completed
# pomodoro; a shorter one was interrupted. A log is one day or two logs
# side by side, so the weekly tally runs in parallel and merges the
# halves. LAW: the tally's pomodoro count is the number of completed
# pomodoros the filter lists.

import Base

type Interval is Data:
  Work{mins: Nat}
  Rest{mins: Nat}
  Pause{mins: Nat}

type Stats is Data:
  Stats{done: Nat, focus: Nat, rest: Nat}

type Log is Data:
  Day{items: +List<Interval>}
  Split{l: Log, r: Log}

def Stats.done(s: Stats) -> Nat:
  Stats{done, focus, rest} = s
  done

# a short (interrupted) work interval adds focus minutes but no pomodoro
def tally.work(m: Nat, s: Stats, short: Bool) -> Stats:
  Stats{done, focus, rest} = s
  match short:
    case True{}:
      Stats{done, Nat.add(m, focus), rest}
    case False{}:
      Stats{1n+done, Nat.add(m, focus), rest}

def tally.rest(m: Nat, s: Stats) -> Stats:
  Stats{done, focus, rest} = s
  Stats{done, focus, Nat.add(m, rest)}

# folds a day's intervals into the stats s
def tally.day(items: +List<Interval>, s: Stats) -> Stats:
  match items:
    case Nil{}:
      s
    case Work{+m} <> t:
      tally.day(t, tally.work(m, s, (m < 25n)))
    case Rest{m} <> t:
      tally.day(t, tally.rest(m, s))
    case Pause{m} <> t:
      tally.day(t, s)

def merge(a: Stats, b: Stats) -> Stats:
  Stats{d1, f1, r1} = a
  Stats{d2, f2, r2} = b
  Stats{Nat.add(d1, d2), Nat.add(f1, f2), Nat.add(r1, r2)}

def tally(log: Log) -> Stats:
  match log:
    case Day{items}:
      tally.day(items, Stats{0n, 0n, 0n})
    case Split{l, r}:
      a b = tally(l) tally(r)
      merge(a, b)

# the minutes of every completed pomodoro, in order
def keep(m: Nat, rest: +List<Nat>, short: Bool) -> +List<Nat>:
  match short:
    case True{}:
      rest
    case False{}:
      m <> rest

def pomodoros.day(items: +List<Interval>) -> +List<Nat>:
  match items:
    case Nil{}:
      Nil{}
    case Work{+m} <> t:
      keep(m, pomodoros.day(t), (m < 25n))
    case Rest{m} <> t:
      pomodoros.day(t)
    case Pause{m} <> t:
      pomodoros.day(t)

def append(xs: +List<Nat>, ys: +List<Nat>) -> +List<Nat>:
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> append(t, ys)

def pomodoros(log: Log) -> +List<Nat>:
  match log:
    case Day{items}:
      pomodoros.day(items)
    case Split{l, r}:
      append(pomodoros(l), pomodoros(r))

def length(xs: +List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      1n+length(t)

# LAW: the tally counts exactly the completed pomodoros
law done_counts:
  for log: Log
  {Stats.done(tally(log)) == length(pomodoros(log)) : Nat}

# solution

def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_succ(a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {1n+1n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

# the Work arm, decided on the verdict b of m < 25n; rec is the IH over any stats
def day_done.work(t: +List<Interval>, -m: Nat, +d: Nat, -f: Nat, -r: Nat,
  rec: @d: Nat -> @-f: Nat -> @-r: Nat -> {Stats.done(tally.day(t, Stats{d, f, r})) == Nat.add(d, length(pomodoros.day(t))) : Nat}, b: Bool)
  -> {Stats.done(tally.day(t, tally.work(m, Stats{d, f, r}, b))) == Nat.add(d, length(keep(m, pomodoros.day(t), b))) : Nat}:
  match b:
    case True{}:
      rec(d, Nat.add(m, f), r)
    case False{}:
      %add_succ(d, length(pomodoros.day(t))) : {Stats.done(tally.day(t, Stats{1n+d, Nat.add(m, f), r})) == _ : Nat}
      rec(1n+d, Nat.add(m, f), r)

# the done count of a day's tally, over any starting stats
def day_done(items: +List<Interval>, d: Nat, -f: Nat, -r: Nat) -> {Stats.done(tally.day(items, Stats{d, f, r})) == Nat.add(d, length(pomodoros.day(items))) : Nat}:
  match items:
    case Nil{}:
      %add_zero(d) : {_ == Nat.add(d, 0n) : Nat}
      {==}
    case Work{m} <> +t:
      day_done.work(t, m, d, f, r, day_done(t), (m < 25n))
    case Rest{m} <> t:
      day_done(t, d, f, Nat.add(m, r))
    case Pause{m} <> t:
      day_done(t, d, f, r)

def length_append(xs: +List<Nat>, -ys: +List<Nat>) -> {Nat.add(length(xs), length(ys)) == length(append(xs, ys)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %length_append(t, ys) : {1n+Nat.add(length(t), length(ys)) == 1n+_ : Nat}
      {==}

# merging two halves whose counts are known
def merge_done(a: Stats, b: Stats, +xs: +List<Nat>, +ys: +List<Nat>, ea: {Stats.done(a) == length(xs) : Nat}, eb: {Stats.done(b) == length(ys) : Nat}) -> {Stats.done(merge(a, b)) == length(append(xs, ys)) : Nat}:
  Stats{d1, f1, r1} = a
  Stats{d2, f2, r2} = b
  %length_append(xs, ys) : {Nat.add(d1, d2) == _ : Nat}
  %ea : {Nat.add(d1, d2) == Nat.add(_, length(ys)) : Nat}
  %eb : {Nat.add(d1, d2) == Nat.add(d1, _) : Nat}
  {==}

def done_counts(log):
  match log:
    case Day{+items}:
      day_done(items, 0n, 0n, 0n)
    case Split{+l, +r}:
      merge_done(tally(l), tally(r), pomodoros(l), pomodoros(r), done_counts(l), done_counts(r))
