# Walkers: a multiplayer demo over rollback netcode. Every player is a
# colored square on a 480 x 480 torus; WASD or the arrow keys move yours,
# Esc quits. The game (the Sq, World and Input sections) is an offline one:
# a list of squares, an input (a player's held keys) with its text
# codec, and the pure World.step(world, inputs). Play puts it in a
# window over a net Client: a frame takes the client's two states and
# posts the keys that changed; your square is drawn from the local state
# (predicted), the others from the remote one (confirmed). Run the relay
# (server.bend), then this file once per player: your square appears at
# once, where your id puts it.
#
#   bend demos/io_rollback_netcode/walkers_demo.bend -o walkers && ./walkers
#
# The player's id is the clock at launch (or PID); the relay is
# SERVER:PORT (127.0.0.1:7777) and the room is ROOM (lobby).
import Base
import ./netcode.bend as Net

# Types
# =====

# A player's square: its id, position and held keys (bits 1 up, 2 down,
# 4 left, 8 right).
type Sq is Data:
  Sq{pid: U32, x: U32, y: U32, held: U32}

# A player's held keys changed.
type Input is Data:
  Input{pid: U32, held: U32}

def World() -> Data:
  List<&2, Sq>

# Sq
# ==

def Sq.wrap(v: U32) -> U32:
  U32.mod(v, 480)

# One tick of motion: 2 pixels per held direction, around the torus.
def Sq.move(s: Sq) -> Sq:
  Sq{pid, x, y, +held} = s
  Sq{pid, Sq.wrap((x + 480 + 2 * (held >> 3n .&. 1) - 2 * (held >> 2n .&. 1) : U32)),
    Sq.wrap((y + 480 + 2 * (held >> 1n .&. 1) - 2 * (held .&. 1) : U32)), held}

def Sq.of(+s: Sq, pid: U32) -> Bool:
  Sq{p, x, y, held} = s
  U32.is_eq(p, pid)

def Sq.hold(s: Sq, held: U32) -> Sq:
  Sq{pid, x, y, h} = s
  Sq{pid, x, y, held}

# A new square, where its id puts it.
def Sq.spawn(+pid: U32, held: U32) -> Sq:
  Sq{pid, U32.mod((pid * 97 : U32), 448), U32.mod((pid * 53 : U32), 448), held}

# Whether a quadrant (x0, y0, size s) is outside (0), across (1) or
# inside (2) the square.
def Sq.hit.go(out: Bool, in: Bool) -> Nat:
  match out in:
    case True{} _:
      0n
    case False{} True{}:
      2n
    case False{} False{}:
      1n

def Sq.hit(+x0: U32, +y0: U32, +s: U32, sq: Sq) -> Nat:
  Sq{pid, +x, +y, held} = sq
  Sq.hit.go(
    ((x0 + s <= x) || (x + 32 <= x0) || (y0 + s <= y) || (y + 32 <= y0) : U32),
    ((x <= x0) && (x0 + s <= x + 32) && (y <= y0) && (y0 + s <= y + 32) : U32))

def Sq.color(k: Nat) -> U32:
  match k:
    case 0n:
      15082059
    case 1n:
      3978315
    case 2n:
      16776960
    case 3n:
      4416472
    case 4n:
      16089649
    case 5n:
      9510580
    case 6n:
      4649200
    case _:
      15741670

# World
# =====

def World.input.go(hit: Bool, s: Sq, t: World(), held: U32, rest: Unit -> World())
  -> World():
  match hit:
    case True{}:
      Sq.hold(s, held) <> t
    case False{}:
      s <> rest(Unit{})

# An input reaches its player's square, or spawns it.
def World.input(+w: World(), +pid: U32, +held: U32) -> World():
  match w:
    case Nil{}:
      [Sq.spawn(pid, held)]
    case +s <> t:
      World.input.go(Sq.of(s, pid), s, t, held, u => World.input(t, pid, held))

def World.inputs(ins: List<&2, Input>, w: World()) -> World():
  match ins:
    case Nil{}:
      w
    case i <> t:
      Input{pid, held} = i
      World.inputs(t, World.input(w, pid, held))

def World.move(w: World()) -> World():
  match w:
    case Nil{}:
      []
    case s <> t:
      Sq.move(s) <> World.move(t)

# The whole game: apply the tick's inputs, then move every square.
def World.step(w: World(), ins: List<&2, Input>) -> World():
  World.move(World.inputs(ins, w))

def World.mine.go(hit: Bool, s: Sq, rest: Maybe<&2, Sq>) -> Maybe<&2, Sq>:
  match hit:
    case True{}:
      Some{s}
    case False{}:
      rest

def World.mine(w: World(), +pid: U32) -> Maybe<&2, Sq>:
  match w:
    case Nil{}:
      None{}
    case +s <> t:
      World.mine.go(Sq.of(s, pid), s, World.mine(t, pid))

def World.keep(hit: Bool, s: Sq, rest: World()) -> World():
  match hit:
    case True{}:
      s <> rest
    case False{}:
      rest

def World.others(w: World(), +pid: U32) -> World():
  match w:
    case Nil{}:
      []
    case +s <> t:
      World.keep(Bool.not(Sq.of(s, pid)), s, World.others(t, pid))

def World.blend.go(mine: Maybe<&2, Sq>, rest: World()) -> World():
  match mine:
    case None{}:
      rest
    case Some{s}:
      s <> rest

# What to draw: this player as predicted, the others as confirmed.
def World.blend(+pid: U32, local: World(), remote: World()) -> World():
  World.blend.go(World.mine(local, pid), World.others(remote, pid))

# The code of a quadrant: 0 background, 1 split, 2 + pid one square.
def World.code.go(hit: Nat, pid: U32, rest: Nat) -> Nat:
  match hit:
    case 0n:
      rest
    case 1n:
      1n
    case _:
      Nat.add(2n, U32.to_nat(pid))

def World.code(+x0: U32, +y0: U32, +s: U32, w: World()) -> Nat:
  match w:
    case Nil{}:
      0n
    case sq <> t:
      Sq{+pid, x, y, held} = sq
      World.code.go(Sq.hit(x0, y0, s, Sq{pid, x, y, held}), pid,
        World.code(x0, y0, s, t))

def World.paint(code: Nat) -> U32:
  match code:
    case 0n:
      2105376
    case 1n:
      2105376
    case 2n+pid:
      Sq.color(U32.to_nat(U32.mod(U32.from_nat(pid), 8)))

# A frame as an Image quadtree: a quadrant is one Pix the moment it is
# uniform, and splits otherwise.
def World.draw(+d: Nat, code: Nat, +x0: U32, +y0: U32, +w: World()) -> Image:
  match d:
    case 0n:
      Pix{World.paint(code)}
    case 1n+e:
      match code:
        case 1n:
          +h = U32.shln(1, e)
          +x1 = U32.add(x0, h)
          +y1 = U32.add(y0, h)
          tl tr bl br = World.draw(e, World.code(x0, y0, h, w), x0, y0, w)
            World.draw(e, World.code(x1, y0, h, w), x1, y0, w)
            World.draw(e, World.code(x0, y1, h, w), x0, y1, w)
            World.draw(e, World.code(x1, y1, h, w), x1, y1, w)
          Qua{tl, tr, bl, br}
        case other:
          Pix{World.paint(other)}

# Input
# =====

def Input.show(i: Input) -> String:
  Input{pid, held} = i
  U32.show(pid) ++ " " ++ U32.show(held)

def Input.from(pid: String, held: String) -> Maybe<&2, Input>:
  do Maybe<&2, Input>:
    p : U32 <- U32.read(pid)
    h : U32 <- U32.read(held)
    return Input{p, h}

def Input.read(s: String) -> Maybe<&2, Input>:
  Net.String.word(Maybe<&2, Input>, s, pid => held => Input.from(pid, held))

# Walkers
# =======

# 60 ticks per second; an input may land up to 200 ms in the past.
def Walkers.game() -> Net.Game<Input, World()>:
  Net.Game{World.step, Input.read, Input.show, 60n, 200n}

# Play
# ====

# The window's state: this player's id and held keys, the world to
# draw and the net client.
type Play is Type:
  Play{+pid: U32, +held: U32, world: World(), client: Net.Client<Input, World()>}

def Play.bit(b: Bool, v: U32) -> U32:
  match b:
    case True{}:
      v
    case False{}:
      0

# The key bit of a key code: W/Up 1, S/Down 2, A/Left 4, D/Right 8.
def Play.key(+code: U32) -> U32:
  (Play.bit(U32.is_eq(code, 119) || U32.is_eq(code, 63232), 1)
    .|. Play.bit(U32.is_eq(code, 115) || U32.is_eq(code, 63233), 2)
    .|. Play.bit(U32.is_eq(code, 97) || U32.is_eq(code, 63234), 4)
    .|. Play.bit(U32.is_eq(code, 100) || U32.is_eq(code, 63235), 8) : U32)

def Play.press(down: Bool, held: U32, bit: U32) -> U32:
  match down:
    case True{}:
      (held .|. bit : U32)
    case False{}:
      (held .&. U32.not(bit) : U32)

def Play.quit(c: Net.Client<Input, World()>) -> IO(Maybe<Play>):
  do IO<Maybe<Play>>:
    Unit <- Net.Client.close(Input, World(), c)
    return None{}

# Held keys that changed are posted; a key's repeat changes nothing.
def Play.post(
  changed: Bool, +pid: U32, +held: U32, world: World(), c: Net.Client<Input, World()>
) -> IO(Maybe<Play>):
  match changed:
    case False{}:
      IO.pure(Maybe<Play>, Some{Play{pid, held, world, c}})
    case True{}:
      do IO<Maybe<Play>>:
        c2 : Net.Client<Input, World()> <- Net.Client.post(~Input, ~World(),
          ~Walkers.game(), c, Input{pid, held})
        return Some{Play{pid, held, world, c2}}

def Play.keyed(
  esc: Bool, pid: U32, held: U32, +held2: U32, world: World(),
  c: Net.Client<Input, World()>
) -> IO(Maybe<Play>):
  match esc:
    case True{}:
      Play.quit(c)
    case False{}:
      Play.post(Bool.not(U32.is_eq(held, held2)), pid, held2, world, c)

def Play.event(e: Event, play: Play) -> IO(Maybe<Play>):
  match e play:
    case Key{+code, +down} Play{pid, held, world, c}:
      Play.keyed(Bool.and(down, U32.is_eq(code, 27)), pid, held,
        Play.press(down, held, Play.key(code)), world, c)
    case Close{} Play{pid, held, world, c}:
      Play.quit(c)
    case other play:
      IO.pure(Maybe<Play>, Some{play})

def Play.events(events: List<Event>, play: Play) -> IO(Maybe<Play>):
  match events:
    case Nil{}:
      IO.pure(Maybe<Play>, Some{play})
    case e <> rest:
      IO.bind(Maybe<Play>, Maybe<Play>, Play.event(e, play),
        App.more(Play, p => Play.events(rest, p)))

def Play.framed(
  +pid: U32, held: U32, css: Net.Client<Input, World()> & World() & World()
) -> Play:
  (c, (local, remote)) = css
  Play{pid, held, World.blend(pid, local, remote), c}

def Play.frame(play: Play) -> IO(Maybe<Play>):
  Play{pid, held, world, c} = play
  do IO<Maybe<Play>>:
    css : Net.Client<Input, World()> & World() & World() <-
      Net.Client.frame(~Input, ~World(), ~Walkers.game(), c)
    return Some{Play.framed(pid, held, css)}

# A frame: post the keys that changed, then take the net's two states
# (in this order, so a key shows in the frame that saw it).
def Play.tick(events: List<Event>, play: Play) -> IO(Maybe<Play>):
  IO.bind(Maybe<Play>, Maybe<Play>, Play.events(events, play),
    App.more(Play, Play.frame))

def Play.view(play: Play) -> Play & Image:
  Play{pid, held, +world, c} = play
  (Play{pid, held, world, c}, World.draw(9n, World.code(0, 0, 512, world), 0, 0, world))

# Join the room and spawn: an input with no key held makes the square
# exist.
def Play.open(host: String, port: U32, room: String, +pid: U32) -> IO(Play):
  do IO<Play>:
    c : Net.Client<Input, World()> <- Net.Client.open(~Input, ~World(),
      ~Walkers.game(), [], host, port, room, U32.show(pid))
    c2 : Net.Client<Input, World()> <- Net.Client.post(~Input, ~World(),
      ~Walkers.game(), c, Input{pid, 0})
    return Play{pid, 0, [], c2}

def Play.turn(
  shown: Window & Image & List<Event>, play: Play,
  rest: Window -> Play -> IO(Unit)
) -> IO(Unit):
  (window, image, events) = shown
  IO.bind(Maybe<Play>, Unit, Play.tick(events, play), App.next(Play, window, rest))

def Play.draw(
  window: Window, drawn: Play & Image, rest: Window -> Play -> IO(Unit)
) -> IO(Unit):
  (play, image) = drawn
  do IO<Unit>:
    shown : Window & Image & List<Event> <- Window.frame(window, image)
    Play.turn(shown, play, rest)

# The window loop. Base's App.run drops each frame with a `!`, and one
# `!` makes the binary compile its whole program for the GPU at launch
# (a minute); this game never needs the GPU, so it loops by itself and
# the window opens at once.
@unsafe
def Play.loop(window: Window, play: Play) -> IO(Unit):
  Play.draw(window, Play.view(play), w => p => Play.loop(w, p))

def Play.run(host: String, port: U32, room: String, pid: U32) -> IO(Unit):
  do IO<Unit>:
    play : Play <- Play.open(host, port, room, pid)
    window : Window <- IO.try(Window, Window.open("Walkers", 512, 512))
    Play.loop(window, play)

# Main
# ====

# The player's id: PID, or the clock at launch.
def Main.pid(text: String, now: Nat) -> U32:
  Net.Env.u32(text, U32.mod(U32.from_nat(now), 10000))

def main() -> IO(Unit):
  do IO<Unit>:
    host : String <- Net.Env.get("SERVER", "127.0.0.1")
    port : String <- Net.Env.get("PORT", "7777")
    room : String <- Net.Env.get("ROOM", "lobby")
    pid : String <- Net.Env.get("PID", "")
    now : Nat <- IO.now()
    Play.run(host, Net.Env.u32(port, 7777), room, Main.pid(pid, now))
