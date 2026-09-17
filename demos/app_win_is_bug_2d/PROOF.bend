# Winning Is Impossible -- the certificate.
#
# The proofs. This file imports the game (as Game) and the claims (as
# Laws) and fills every law they state -- an unfilled law is an
# error, so `bend PROOF.bend` is the whole verification. Everything here
# is AI-written scaffolding for two defs: Laws.you_cant_win and
# Laws.never_on_flag.
#
# The shape of the argument: an invariant ("the player stands on a safe
# cell: on the map, not in the room, not on a wall") holds at the start
# and survives every action. The finite geometry is computed, not
# argued: chk_all enumerates the whole map and evaluates to True, and
# the *_at lemmas index that certificate at open coordinates. A step off
# the flag never sets `won` (the flag's cell is in the room), and a
# second certificate, fchk_all, walks the board the page draws and finds
# no flag on any safe cell.

import Base
import ./main.bend as Game
import ./LAWS.bend as Laws

# Proof kit
# ---------
# Boolean reflection: T(b) is the truth of b as a type (Unit when True,
# Empty when False), so a computed check becomes a proof by conversion.
# The rest are the eliminators the affine core asks to be spelled out:
# every split is a def whose match consumes a parameter, and every
# equation is spent by one rewrite.

def T(b: Bool) -> Data:
  match b:
    case True{}:
      Unit
    case False{}:
      Empty

def sym(-A: Type, -a: A, -b: A, e: {a == b : A}) -> {b == a : A}:
  %e : {_ == a : A}
  {==}

def and_split(+a: Bool, -b: Bool, w: T(a && b), -P: Type,
  f: T(a) -> T(b) -> P) -> P:
  match a:
    case True{}:
      f(Unit{}, w)
    case False{}:
      Empty.absurd(P, w)

def and_intro(+a: Bool, -b: Bool, wa: T(a), wb: T(b)) -> T(a && b):
  match a:
    case True{}:
      wb
    case False{}:
      Empty.absurd(T(False{} && b), wa)

def not_elim(+a: Bool, wn: T(Bool.not(a)), wa: T(a)) -> Empty:
  match a:
    case True{}:
      wn
    case False{}:
      wa

def imp(a: Bool, b: Bool) -> Bool:
  Bool.not(a) || b

def imp_elim(+a: Bool, -b: Bool, wi: T(imp(a, b)), wa: T(a)) -> T(b):
  match a:
    case True{}:
      wi
    case False{}:
      Empty.absurd(T(b), wa)

def bool_case(+b: Bool, -P: Bool -> Type,
  t: {True{} == b : Bool} -> P(True{}),
  f: {False{} == b : Bool} -> P(False{})) -> P(b):
  match b:
    case True{}:
      t({==})
    case False{}:
      f({==})

def pick_split(-A: Type, -P: A -> Type, +c: Bool, -a: A, -b: A,
  t: {True{} == c : Bool} -> P(a),
  f: {False{} == c : Bool} -> P(b)) -> P(Game.pick(A, c, a, b)):
  match c:
    case True{}:
      t({==})
    case False{}:
      f({==})

def or_case(-A: Type, -B: Type, o: Or(A, B), -P: Type,
  f: A -> P, g: B -> P) -> P:
  match o:
    case Inl{l}:
      f(l)
    case Inr{r}:
      g(r)

def eq_sound(a: Nat, b: Nat, w: T(Game.nat_eq(a, b))) -> {a == b : Nat}:
  match a:
    case 0n:
      match b:
        case 0n:
          {==}
        case 1n+q:
          Empty.absurd({0n == 1n+q : Nat}, w)
    case 1n+p:
      match b:
        case 0n:
          Empty.absurd({1n+p == 0n : Nat}, w)
        case 1n+q:
          %eq_sound(p, q, w) : {1n+p == 1n+_ : Nat}
          {==}

def le_split(a: Nat, b: Nat, w: T(Game.nat_le(a, b)))
  -> Or(T(Game.nat_le(1n+a, b)), {a == b : Nat}):
  match a:
    case 0n:
      match b:
        case 0n:
          Inr{{==}}
        case 1n+q:
          Inl{w}
    case 1n+p:
      match b:
        case 0n:
          Empty.absurd(Or(T(Game.nat_le(2n+p, 0n)), {1n+p == 0n : Nat}), w)
        case 1n+q:
          or_case(T(Game.nat_le(1n+p, q)), {p == q : Nat}, le_split(p, q, w),
            Or(T(Game.nat_le(2n+p, 1n+q)), {1n+p == 1n+q : Nat}),
            l => Inl{l},
            e => Inr{%e : {1n+p == 1n+_ : Nat}
                     {==}})

# Invariant
# ---------
# The safe cells: on the map, not inside the room, not on a wall. The
# proof shows every action keeps the player on a safe cell, and that a
# grab on a safe cell never raises the flag (the flag is in the room).
#
# The geometric heart is finite, so it is not argued -- it is computed:
# chk_all(a, 11n) enumerates every cell of the map and checks that a
# step in direction `a` from a safe cell lands on a wall or on a safe
# cell. The term evaluates to True, so its truth is Unit by conversion,
# and chk_row_at/chk_all_at index that certificate at any coordinates.

def room(+x: Nat, +y: Nat) -> Bool:
  Game.nat_le(x, 2n) && Game.nat_le(y, 2n)

def okpos(+x: Nat, +y: Nat) -> Bool:
  (Game.nat_le(x, 11n) && Game.nat_le(y, 7n))
    && (Bool.not(room(x, y)) && Bool.not(Game.wall(x, y)))

def tx(+a: Game.Move, +x: Nat, +y: Nat) -> Nat:
  match a:
    case Game.Up{}:
      x
    case Game.Down{}:
      x
    case Game.Left{}:
      Game.warp_left(x)
    case Game.Right{}:
      Game.warp_right(x)

def ty(+a: Game.Move, +x: Nat, +y: Nat) -> Nat:
  match a:
    case Game.Up{}:
      Game.warp_up(y)
    case Game.Down{}:
      Game.warp_down(y)
    case Game.Left{}:
      y
    case Game.Right{}:
      y

def chk(+a: Game.Move, +x: Nat, +y: Nat) -> Bool:
  imp(okpos(x, y) && Bool.not(Game.wall(tx(a, x, y), ty(a, x, y))),
    okpos(tx(a, x, y), ty(a, x, y)))

def chk_row(+a: Game.Move, +x: Nat, y: Nat) -> Bool:
  match y:
    case 0n:
      chk(a, x, 0n)
    case 1n++q0:
      chk(a, x, 1n+q0) && chk_row(a, x, q0)

def chk_all(+a: Game.Move, x: Nat) -> Bool:
  match x:
    case 0n:
      chk_row(a, 0n, 7n)
    case 1n++p0:
      chk_row(a, 1n+p0, 7n) && chk_all(a, p0)

def chk_row_at(+a: Game.Move, +x: Nat, y: Nat, j: Nat, wr: T(chk_row(a, x, y)),
  wj: T(Game.nat_le(j, y))) -> T(chk(a, x, j)):
  match y j:
    case 0n 0n:
      wr
    case 0n 1n+jp:
      Empty.absurd(T(chk(a, x, 1n+jp)), wj)
    case 1n++q0 0n:
      and_split(chk(a, x, 1n+q0), chk_row(a, x, q0), wr, T(chk(a, x, 0n)),
        wp => wt => chk_row_at(a, x, q0, 0n, wt, Unit{}))
    case 1n++q0 1n++jp0:
      and_split(chk(a, x, 1n+q0), chk_row(a, x, q0), wr, T(chk(a, x, 1n+jp0)),
        wp => wt =>
          or_case(T(Game.nat_le(1n+jp0, q0)), {jp0 == q0 : Nat},
            le_split(jp0, q0, wj), T(chk(a, x, 1n+jp0)),
            l => chk_row_at(a, x, q0, 1n+jp0, wt, l),
            e => %sym(Nat, jp0, q0, e) : T(chk(a, x, 1n+_))
                 wp))

def chk_all_at(+a: Game.Move, x: Nat, i: Nat, wa: T(chk_all(a, x)),
  wi: T(Game.nat_le(i, x))) -> T(chk_row(a, i, 7n)):
  match x i:
    case 0n 0n:
      wa
    case 0n 1n+ip:
      Empty.absurd(T(chk_row(a, 1n+ip, 7n)), wi)
    case 1n++p0 0n:
      and_split(chk_row(a, 1n+p0, 7n), chk_all(a, p0), wa,
        T(chk_row(a, 0n, 7n)),
        wp => wt => chk_all_at(a, p0, 0n, wt, Unit{}))
    case 1n++p0 1n++ip0:
      and_split(chk_row(a, 1n+p0, 7n), chk_all(a, p0), wa,
        T(chk_row(a, 1n+ip0, 7n)),
        wp => wt =>
          or_case(T(Game.nat_le(1n+ip0, p0)), {ip0 == p0 : Nat},
            le_split(ip0, p0, wi), T(chk_row(a, 1n+ip0, 7n)),
            l => chk_all_at(a, p0, 1n+ip0, wt, l),
            e => %sym(Nat, ip0, p0, e) : T(chk_row(a, 1n+_, 7n))
                 wp))

def cert(+a: Game.Move, +x: Nat, +y: Nat, ca: T(chk_all(a, 11n)),
  lx: T(Game.nat_le(x, 11n)), ly: T(Game.nat_le(y, 7n))) -> T(chk(a, x, y)):
  chk_row_at(a, x, 7n, y, chk_all_at(a, 11n, x, ca, lx), ly)

# the safe target: from a safe cell, a step lands on a wall or stays safe
def go_ok(+a: Game.Move, +x: Nat, +y: Nat, +hp: T(okpos(x, y)),
  ca: T(chk_all(a, 11n)), e: {False{} == Game.wall(tx(a, x, y), ty(a, x, y)) : Bool})
  -> T(okpos(tx(a, x, y), ty(a, x, y))):
  and_split(Game.nat_le(x, 11n) && Game.nat_le(y, 7n),
    Bool.not(room(x, y)) && Bool.not(Game.wall(x, y)), hp,
    T(okpos(tx(a, x, y), ty(a, x, y))),
    wb => wnr =>
      and_split(Game.nat_le(x, 11n), Game.nat_le(y, 7n), wb,
        T(okpos(tx(a, x, y), ty(a, x, y))),
        lx => ly =>
          imp_elim(okpos(x, y) && Bool.not(Game.wall(tx(a, x, y), ty(a, x, y))),
            okpos(tx(a, x, y), ty(a, x, y)),
            cert(a, x, y, ca, lx, ly),
            and_intro(okpos(x, y),
              Bool.not(Game.wall(tx(a, x, y), ty(a, x, y))),
              hp,
              %e : T(Bool.not(_))
              Unit{}))))

# grabbing off the flag never wins; on the flag is impossible from safety
def no_flag(+x: Nat, +y: Nat, +hp: T(okpos(x, y)),
  e: {True{} == Game.nat_eq(x, Game.flag_x()) && Game.nat_eq(y, Game.flag_y()) : Bool}) -> Empty:
  and_split(Game.nat_eq(x, 1n), Game.nat_eq(y, 1n),
    %e : T(_)
    Unit{},
    Empty,
    wex => wey =>
      and_split(Game.nat_le(x, 11n) && Game.nat_le(y, 7n),
        Bool.not(room(x, y)) && Bool.not(Game.wall(x, y)), hp,
        Empty,
        wb => wrw =>
          and_split(Bool.not(room(x, y)), Bool.not(Game.wall(x, y)), wrw, Empty,
            wnr => wnw =>
              not_elim(room(x, y), wnr,
                %sym(Nat, x, 1n, eq_sound(x, 1n, wex)) : T(Game.nat_le(_, 2n) && Game.nat_le(y, 2n))
                %sym(Nat, y, 1n, eq_sound(y, 1n, wey)) : T(Game.nat_le(1n, 2n) && Game.nat_le(_, 2n))
                Unit{}))))

# The board the page draws, certified: fchk_all(s, 11n) checks every
# cell of the map, and finds no flag drawn on a safe one. The board is
# passed in, so it is computed once for the whole walk.

def fchk(+s: String, +x: Nat, +y: Nat) -> Bool:
  imp(okpos(x, y), Bool.not(Laws.flag_at(y, x, s)))

def fchk_row(+s: String, +x: Nat, y: Nat) -> Bool:
  match y:
    case 0n:
      fchk(s, x, 0n)
    case 1n++q0:
      fchk(s, x, 1n+q0) && fchk_row(s, x, q0)

def fchk_all(+s: String, x: Nat) -> Bool:
  match x:
    case 0n:
      fchk_row(s, 0n, 7n)
    case 1n++p0:
      fchk_row(s, 1n+p0, 7n) && fchk_all(s, p0)

def fchk_row_at(+s: String, +x: Nat, y: Nat, j: Nat, wr: T(fchk_row(s, x, y)),
  wj: T(Game.nat_le(j, y))) -> T(fchk(s, x, j)):
  match y j:
    case 0n 0n:
      wr
    case 0n 1n+jp:
      Empty.absurd(T(fchk(s, x, 1n+jp)), wj)
    case 1n++q0 0n:
      and_split(fchk(s, x, 1n+q0), fchk_row(s, x, q0), wr, T(fchk(s, x, 0n)),
        wp => wt => fchk_row_at(s, x, q0, 0n, wt, Unit{}))
    case 1n++q0 1n++jp0:
      and_split(fchk(s, x, 1n+q0), fchk_row(s, x, q0), wr, T(fchk(s, x, 1n+jp0)),
        wp => wt =>
          or_case(T(Game.nat_le(1n+jp0, q0)), {jp0 == q0 : Nat},
            le_split(jp0, q0, wj), T(fchk(s, x, 1n+jp0)),
            l => fchk_row_at(s, x, q0, 1n+jp0, wt, l),
            e => %sym(Nat, jp0, q0, e) : T(fchk(s, x, 1n+_))
                 wp))

def fchk_all_at(+s: String, x: Nat, i: Nat, wa: T(fchk_all(s, x)),
  wi: T(Game.nat_le(i, x))) -> T(fchk_row(s, i, 7n)):
  match x i:
    case 0n 0n:
      wa
    case 0n 1n+ip:
      Empty.absurd(T(fchk_row(s, 1n+ip, 7n)), wi)
    case 1n++p0 0n:
      and_split(fchk_row(s, 1n+p0, 7n), fchk_all(s, p0), wa,
        T(fchk_row(s, 0n, 7n)),
        wp => wt => fchk_all_at(s, p0, 0n, wt, Unit{}))
    case 1n++p0 1n++ip0:
      and_split(fchk_row(s, 1n+p0, 7n), fchk_all(s, p0), wa,
        T(fchk_row(s, 1n+ip0, 7n)),
        wp => wt =>
          or_case(T(Game.nat_le(1n+ip0, p0)), {ip0 == p0 : Nat},
            le_split(ip0, p0, wi), T(fchk_row(s, 1n+ip0, 7n)),
            l => fchk_all_at(s, p0, 1n+ip0, wt, l),
            e => %sym(Nat, ip0, p0, e) : T(fchk_row(s, 1n+_, 7n))
                 wp))

def fcert(+s: String, +x: Nat, +y: Nat, ca: T(fchk_all(s, 11n)),
  lx: T(Game.nat_le(x, 11n)), ly: T(Game.nat_le(y, 7n))) -> T(fchk(s, x, y)):
  fchk_row_at(s, x, 7n, y, fchk_all_at(s, 11n, x, ca, lx), ly)

# on a safe cell the page draws no flag: the certificate says so
def off_F(+x: Nat, +y: Nat, +hp: T(okpos(x, y)))
  -> {False{} == Laws.flag_at(y, x, Laws.drawn()) : Bool}:
  and_split(Game.nat_le(x, 11n) && Game.nat_le(y, 7n),
    Bool.not(room(x, y)) && Bool.not(Game.wall(x, y)), hp,
    {False{} == Laws.flag_at(y, x, Laws.drawn()) : Bool},
    wb => wnr =>
      and_split(Game.nat_le(x, 11n), Game.nat_le(y, 7n), wb,
        {False{} == Laws.flag_at(y, x, Laws.drawn()) : Bool},
        lx => ly =>
          bool_case(Laws.flag_at(y, x, Laws.drawn()), z => {False{} == z : Bool},
            et => Empty.absurd({False{} == True{} : Bool},
              not_elim(Laws.flag_at(y, x, Laws.drawn()),
                imp_elim(okpos(x, y), Bool.not(Laws.flag_at(y, x, Laws.drawn())),
                  fcert(Laws.drawn(), x, y, Unit{}, lx, ly), hp),
                %et : T(_)
                Unit{})),
            ef => {==})))

# on a safe cell the flag test computes to False
def off_flag(+x: Nat, +y: Nat, +hp: T(okpos(x, y)))
  -> {False{} == Game.on_flag(x, y) : Bool}:
  bool_case(Game.on_flag(x, y), z => {False{} == z : Bool},
    et => Empty.absurd({False{} == True{} : Bool}, no_flag(x, y, hp, et)),
    ef => {==})

# the chosen cell: a step from a safe cell lands somewhere safe (or stays),
# and lands unwon, since a safe cell is off the flag
def go_pos(+a: Game.Move, +x: Nat, +y: Nat, +hp: T(okpos(x, y)),
  ca: T(chk_all(a, 11n)))
  -> &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
   & {Game.Game{nx, ny, False{}}
      == Game.move(tx(a, x, y), ty(a, x, y), Game.Game{x, y, False{}}) : Game.Game}:
  pick_split(Game.Game,
    gz => &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
        & {Game.Game{nx, ny, False{}} == gz : Game.Game},
    Game.wall(tx(a, x, y), ty(a, x, y)),
    Game.Game{x, y, False{}},
    Game.Game{tx(a, x, y), ty(a, x, y), Game.on_flag(tx(a, x, y), ty(a, x, y))},
    et => (x, (y, (hp, {==}))),
    ef =>
      +safe = go_ok(a, x, y, hp, ca, ef)
      (tx(a, x, y), (ty(a, x, y), (safe,
        %off_flag(tx(a, x, y), ty(a, x, y), safe)
          : {Game.Game{tx(a, x, y), ty(a, x, y), False{}}
             == Game.Game{tx(a, x, y), ty(a, x, y), _} : Game.Game}
        {==}))))

def use4(-a: Game.Move, -x: Nat, -y: Nat,
  w: &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
   & {Game.Game{nx, ny, False{}}
      == Game.move(tx(a, x, y), ty(a, x, y), Game.Game{x, y, False{}}) : Game.Game},
  -P: Type,
  k: @nx: Nat -> @ny: Nat -> @hq: T(okpos(nx, ny))
   -> @eq: {Game.Game{nx, ny, False{}}
            == Game.move(tx(a, x, y), ty(a, x, y), Game.Game{x, y, False{}}) : Game.Game}
   -> P) -> P:
  (nx, w1) = w
  (ny, w2) = w1
  (hq, eq) = w2
  k(nx, ny, hq, eq)

# The engine of both laws: from a safe unwon cell, any list of moves ends
# on a safe unwon cell. Each arm: the step lands safe (go_pos), then the
# rest of the list runs from there.
def run_safe(t: List<Game.Move>, +x: Nat, +y: Nat, hp: T(okpos(x, y)))
  -> &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
   & {Game.run(t, Game.Game{x, y, False{}}) == Game.Game{nx, ny, False{}} : Game.Game}:
  match t:
    case Nil{}:
      (x, (y, (hp, {==})))
    case Game.Up{} <> as0:
      use4(Game.Up{}, x, y, go_pos(Game.Up{}, x, y, hp, Unit{}),
        &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
         & {Game.run(as0, Game.move(tx(Game.Up{}, x, y), ty(Game.Up{}, x, y),
            Game.Game{x, y, False{}})) == Game.Game{nx, ny, False{}} : Game.Game},
        mx => my => hq => eq =>
          %eq : &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
              & {Game.run(as0, _) == Game.Game{nx, ny, False{}} : Game.Game}
          run_safe(as0, mx, my, hq))
    case Game.Down{} <> as0:
      use4(Game.Down{}, x, y, go_pos(Game.Down{}, x, y, hp, Unit{}),
        &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
         & {Game.run(as0, Game.move(tx(Game.Down{}, x, y), ty(Game.Down{}, x, y),
            Game.Game{x, y, False{}})) == Game.Game{nx, ny, False{}} : Game.Game},
        mx => my => hq => eq =>
          %eq : &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
              & {Game.run(as0, _) == Game.Game{nx, ny, False{}} : Game.Game}
          run_safe(as0, mx, my, hq))
    case Game.Left{} <> as0:
      use4(Game.Left{}, x, y, go_pos(Game.Left{}, x, y, hp, Unit{}),
        &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
         & {Game.run(as0, Game.move(tx(Game.Left{}, x, y), ty(Game.Left{}, x, y),
            Game.Game{x, y, False{}})) == Game.Game{nx, ny, False{}} : Game.Game},
        mx => my => hq => eq =>
          %eq : &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
              & {Game.run(as0, _) == Game.Game{nx, ny, False{}} : Game.Game}
          run_safe(as0, mx, my, hq))
    case Game.Right{} <> as0:
      use4(Game.Right{}, x, y, go_pos(Game.Right{}, x, y, hp, Unit{}),
        &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
         & {Game.run(as0, Game.move(tx(Game.Right{}, x, y), ty(Game.Right{}, x, y),
            Game.Game{x, y, False{}})) == Game.Game{nx, ny, False{}} : Game.Game},
        mx => my => hq => eq =>
          %eq : &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
              & {Game.run(as0, _) == Game.Game{nx, ny, False{}} : Game.Game}
          run_safe(as0, mx, my, hq))

# opens run_safe's answer for a goal
def use_safe(-t: List<Game.Move>, -x: Nat, -y: Nat,
  w: &nx: Nat -> &ny: Nat -> T(okpos(nx, ny))
   & {Game.run(t, Game.Game{x, y, False{}}) == Game.Game{nx, ny, False{}} : Game.Game},
  -P: Type,
  k: @nx: Nat -> @ny: Nat -> @hq: T(okpos(nx, ny))
   -> @eq: {Game.run(t, Game.Game{x, y, False{}}) == Game.Game{nx, ny, False{}} : Game.Game}
   -> P) -> P:
  (nx, w1) = w
  (ny, w2) = w1
  (hq, eq) = w2
  k(nx, ny, hq, eq)

# The laws, filled. The start cell is safe (checked by computation), and
# run_safe carries that through any list of moves: the final board is
# some Game{nx, ny, False{}} with (nx, ny) safe. Unwon, so the first law;
# no flag drawn there (the certificate), so the second.
def Laws.you_cant_win(moves):
  use_safe(moves, Game.start_x(), Game.start_y(),
    run_safe(moves, Game.start_x(), Game.start_y(), Unit{}),
    {Game.is_won(Game.replay(Game.start(), moves)) == False{} : Bool},
    nx => ny => hq => eq =>
      %sym(Game.Game, Game.run(moves, Game.Game{Game.start_x(), Game.start_y(), False{}}),
        Game.Game{nx, ny, False{}}, eq) : {Game.is_won(_) == False{} : Bool}
      {==})

def Laws.never_on_flag(moves):
  use_safe(moves, Game.start_x(), Game.start_y(),
    run_safe(moves, Game.start_x(), Game.start_y(), Unit{}),
    {Laws.at_flag(Game.replay(Game.start(), moves)) == False{} : Bool},
    nx => ny => hq => eq =>
      %sym(Game.Game, Game.run(moves, Game.Game{Game.start_x(), Game.start_y(), False{}}),
        Game.Game{nx, ny, False{}}, eq) : {Laws.at_flag(_) == False{} : Bool}
      %off_F(nx, ny, hq) : {_ == False{} : Bool}
      {==})
