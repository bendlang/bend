# A tic-tac-toe app keeps its move log as a stack, newest move on top,
# and replays it from the empty board: a move takes a free cell for the
# player whose turn it is; an illegal move is skipped. Undo has two ways:
# the honest way drops moves from the log and replays it; the cheap way
# frees their cells and hands the turn back. LAWS: on a legal log, k cheap
# undos give the honest board, and redoing the k dropped moves restores it.

import Base

type Player is Data:
  X{}
  O{}

type Cell is Data:
  Free{}
  Mark{p: Player}

# whose turn it is, and the rows of the board
type Game is Data:
  Game{turn: Player, rows: +List<+List<Cell>>}

# a move names a position on the board
type Move is Data:
  Pos{row: Nat, col: Nat}

def other(p: Player) -> Player:
  match p:
    case X{}:
      O{}
    case O{}:
      X{}

def is_free(c: Cell) -> Bool:
  match c:
    case Free{}:
      True{}
    case Mark{p}:
      False{}

# the cell at column c of a row; Free past the end
def get_cell(row: +List<Cell>, c: Nat) -> Cell:
  match row:
    case Nil{}:
      Free{}
    case h <> t:
      match c:
        case 0n:
          h
        case 1n+p:
          get_cell(t, p)

def set_cell(row: +List<Cell>, c: Nat, v: Cell) -> +List<Cell>:
  match row:
    case Nil{}:
      Nil{}
    case h <> t:
      match c:
        case 0n:
          v <> t
        case 1n+p:
          h <> set_cell(t, p, v)

def get(rows: +List<+List<Cell>>, r: Nat, c: Nat) -> Cell:
  match rows:
    case Nil{}:
      Free{}
    case row <> rest:
      match r:
        case 0n:
          get_cell(row, c)
        case 1n+p:
          get(rest, p, c)

def set(rows: +List<+List<Cell>>, r: Nat, c: Nat, v: Cell) -> +List<+List<Cell>>:
  match rows:
    case Nil{}:
      Nil{}
    case row <> rest:
      match r:
        case 0n:
          set_cell(row, c, v) <> rest
        case 1n+p:
          row <> set(rest, p, c, v)

# the cell a move names
def at(g: Game, m: Move) -> Cell:
  Game{turn, rows} = g
  Pos{r, c} = m
  get(rows, r, c)

# marks the cell when ok says it is free; else skips the move
def place(g: Game, m: Move, ok: Bool) -> Game:
  Game{+turn, rows} = g
  Pos{r, c} = m
  match ok:
    case True{}:
      Game{other(turn), set(rows, r, c, Mark{turn})}
    case False{}:
      Game{turn, rows}

def play(+g: Game, +m: Move) -> Game:
  place(g, m, is_free(at(g, m)))

# the cheap undo of one move: frees its cell and hands the turn back
def unplay(g: Game, m: Move) -> Game:
  Game{turn, rows} = g
  Pos{r, c} = m
  Game{other(turn), set(rows, r, c, Free{})}

def start() -> Game:
  Game{X{}, [[Free{}, Free{}, Free{}], [Free{}, Free{}, Free{}], [Free{}, Free{}, Free{}]]}

# plays a log onto g, oldest move first
def play_all(log: +List<Move>, g: Game) -> Game:
  match log:
    case Nil{}:
      g
    case m <> older:
      play(play_all(older, g), m)

def replay(log: +List<Move>) -> Game:
  play_all(log, start())

# the k newest moves
def take(k: Nat, log: +List<Move>) -> +List<Move>:
  match k:
    case 0n:
      Nil{}
    case 1n+p:
      match log:
        case Nil{}:
          Nil{}
        case m <> older:
          m <> take(p, older)

# the log without its k newest moves
def drop(k: Nat, log: +List<Move>) -> +List<Move>:
  match k:
    case 0n:
      log
    case 1n+p:
      match log:
        case Nil{}:
          Nil{}
        case m <> older:
          drop(p, older)

# k cheap undos: pops k moves from the log and unplays them on g
def undo(k: Nat, log: +List<Move>, g: Game) -> Game:
  match k:
    case 0n:
      g
    case 1n+p:
      match log:
        case Nil{}:
          g
        case m <> older:
          undo(p, older, unplay(g, m))

# a log is legal when every move found its cell free
def Legal(log: +List<Move>) -> Type:
  match log:
    case Nil{}:
      Unit
    case m <> older:
      ({Free{} == at(replay(older), m) : Cell} & Legal(older))

# LAW: k cheap undos give the board of the log without its k newest moves
law undo_ok:
  for +k: Nat
  for +log: +List<Move>
  for  e: Legal(log)
  {replay(drop(k, log)) == undo(k, log, replay(log)) : Game}

# LAW: replaying the k dropped moves onto the undone board restores it
law redo_ok:
  for +k: Nat
  for +log: +List<Move>
  for  e: Legal(log)
  {replay(log) == play_all(take(k, log), undo(k, log, replay(log))) : Game}

# solution

def other_other(p: Player) -> {p == other(other(p)) : Player}:
  match p:
    case X{}:
      {==}
    case O{}:
      {==}

# marking a free cell and freeing it again restores the row
def clear_set_cell(row: +List<Cell>, c: Nat, -v: Cell, e: {Free{} == get_cell(row, c) : Cell}) -> {row == set_cell(set_cell(row, c, v), c, Free{}) : +List<Cell>}:
  match row:
    case Nil{}:
      {==}
    case h <> t:
      match c:
        case 0n:
          %e : {_ <> t == Free{} <> t : +List<Cell>}
          {==}
        case 1n+p:
          %clear_set_cell(t, p, v, e) : {h <> t == h <> _ : +List<Cell>}
          {==}

# the same on the grid: the row at r is restored, the rest is untouched
def clear_set(rows: +List<+List<Cell>>, r: Nat, c: Nat, -v: Cell, e: {Free{} == get(rows, r, c) : Cell}) -> {rows == set(set(rows, r, c, v), r, c, Free{}) : +List<+List<Cell>>}:
  match rows:
    case Nil{}:
      {==}
    case row <> rest:
      match r:
        case 0n:
          %clear_set_cell(row, c, v, e) : {row <> rest == _ <> rest : +List<+List<Cell>>}
          {==}
        case 1n+p:
          %clear_set(rest, p, c, v, e) : {row <> rest == row <> _ : +List<+List<Cell>>}
          {==}

# the cheap undo of a legal move restores the game: the cell goes back
# to Free and the turn flips twice
def unplay_play(g: Game, m: Move, +e: {Free{} == at(g, m) : Cell}) -> {g == unplay(play(g, m), m) : Game}:
  Game{turn, rows} = g
  Pos{r, c} = m
  %e : {Game{turn, rows} == unplay(place(Game{turn, rows}, Pos{r, c}, is_free(_)), Pos{r, c}) : Game}
  %clear_set(rows, r, c, Mark{turn}, e) : {Game{turn, rows} == Game{other(other(turn)), _} : Game}
  %other_other(turn) : {Game{turn, rows} == Game{_, rows} : Game}
  {==}

# the step of undo_redo: the cheap undo of a legal move restores the
# board, so the induction hypothesis closes both halves
def undo_redo.step(-p: Nat, +m: Move, +older: +List<Move>, fr: {Free{} == at(replay(older), m) : Cell}, ih: {replay(drop(p, older)) == undo(p, older, replay(older)) : Game} & {replay(older) == play_all(take(p, older), undo(p, older, replay(older))) : Game}) -> {replay(drop(1n+p, m <> older)) == undo(1n+p, m <> older, replay(m <> older)) : Game} & {replay(m <> older) == play_all(take(1n+p, m <> older), undo(1n+p, m <> older, replay(m <> older))) : Game}:
  (u, r) = ih
  %unplay_play(replay(older), m, fr) : {replay(drop(p, older)) == undo(p, older, _) : Game} & {play(replay(older), m) == play(play_all(take(p, older), undo(p, older, _)), m) : Game}
  %r : {replay(drop(p, older)) == undo(p, older, replay(older)) : Game} & {play(replay(older), m) == play(_, m) : Game}
  (u, {==})

# both laws at once, by one induction on k and the log
def undo_redo(+k: Nat, +log: +List<Move>, e: Legal(log)) -> {replay(drop(k, log)) == undo(k, log, replay(log)) : Game} & {replay(log) == play_all(take(k, log), undo(k, log, replay(log))) : Game}:
  match k:
    case 0n:
      ({==}, {==})
    case 1n+p:
      match log:
        case Nil{}:
          ({==}, {==})
        case m <> older:
          (fr, le) = e
          undo_redo.step(p, m, older, fr, undo_redo(p, older, le))

def undo_redo.fst(-k: Nat, -log: +List<Move>, ur: {replay(drop(k, log)) == undo(k, log, replay(log)) : Game} & {replay(log) == play_all(take(k, log), undo(k, log, replay(log))) : Game}) -> {replay(drop(k, log)) == undo(k, log, replay(log)) : Game}:
  (u, r) = ur
  u

def undo_redo.snd(-k: Nat, -log: +List<Move>, ur: {replay(drop(k, log)) == undo(k, log, replay(log)) : Game} & {replay(log) == play_all(take(k, log), undo(k, log, replay(log))) : Game}) -> {replay(log) == play_all(take(k, log), undo(k, log, replay(log))) : Game}:
  (u, r) = ur
  r

def undo_ok(k, log, e):
  undo_redo.fst(k, log, undo_redo(k, log, e))

def redo_ok(k, log, e):
  undo_redo.snd(k, log, undo_redo(k, log, e))
