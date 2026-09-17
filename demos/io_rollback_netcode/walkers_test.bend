# Walkers, headless: a scripted player drives the demo's Play.tick with
# key events, as the window does, at 16 ms a frame. Two of these in one
# room (on one machine or two) must print the same lines. Every 30th
# frame the script presses a key (W, S, A, D in turn, offset by the
# player's id) and releases it 15 frames later. After FRAMES (480)
# scripted frames and IDLE (150) quiet ones it prints the room's post
# count and the hash of the confirmed world 900, 1200 and 2400 ticks
# after the room's birth: past the run, so every post is held. PID
# names the player (else the clock); SERVER, PORT and ROOM as in
# walkers_demo.bend.
#
#   bend demos/io_rollback_netcode/walkers_test.bend -o bot
#   PID=1 ROOM=t ./bot & PID=2 ROOM=t ./bot; wait
import Base
import ./netcode.bend as Net
import ./walkers_demo.bend as Game

# World
# =====

def World.mix(h: U32, v: U32) -> U32:
  U32.mul(U32.xor(h, v), 16777619)

# FNV-1a over the squares.
def World.hash.go(w: Game.World(), h: U32) -> U32:
  match w:
    case Nil{}:
      h
    case s <> t:
      Game.Sq{pid, x, y, held} = s
      World.hash.go(t,
        World.mix(World.mix(World.mix(World.mix(h, pid), x), y), held))

def World.hash(w: Game.World()) -> U32:
  World.hash.go(w, 2166136261)

# Bot
# ===

# W, S, A, D.
def Bot.code(k: Nat) -> U32:
  match k:
    case 0n:
      119
    case 1n:
      115
    case 2n:
      97
    case _:
      100

def Bot.key(pid: U32, k: Nat, down: Bool) -> List<Event>:
  [Key{Bot.code(U32.to_nat(U32.mod((pid + U32.from_nat(k) : U32), 4))), down}]

def Bot.events.go(pid: U32, kr: Nat & Nat) -> List<Event>:
  (k, r) = kr
  match r:
    case 15n:
      Bot.key(pid, k, True{})
    case 0n:
      Bot.key(pid, k, False{})
    case _:
      []

# The key events of a frame (frames count down).
def Bot.events(pid: U32, f: Nat) -> List<Event>:
  Bot.events.go(pid, Nat.divmod(f, 30n))

def Bot.more(m: Maybe<Game.Play>, rest: Game.Play -> IO(Unit)) -> IO(Unit):
  match m:
    case None{}:
      IO.print("the game closed")
    case Some{p}:
      rest(p)

# One frame, as the window plays it.
def Bot.frame(events: List<Event>, play: Game.Play, rest: Game.Play -> IO(Unit))
  -> IO(Unit):
  do IO<Unit>:
    m : Maybe<Game.Play> <- Game.Play.tick(events, play)
    Unit <- IO.sleep(16)
    Bot.more(m, rest)

def Bot.line(
  k: Nat, r: Net.Client<Game.Input, Game.World()> & Nat & Game.World()
) -> IO(Net.Client<Game.Input, Game.World()>):
  (c, (n, w)) = r
  do IO<Net.Client<Game.Input, Game.World()>>:
    Unit <- IO.print("posts=" ++ Nat.show(n) ++ " tick=" ++ Nat.show(k)
      ++ " hash=" ++ U32.show(World.hash(w)))
    return c

def Bot.report(ks: List<&2, Nat>, c: Net.Client<Game.Input, Game.World()>) ->
  IO(Unit):
  match ks:
    case Nil{}:
      Net.Client.close(Game.Input, Game.World(), c)
    case +k <> t:
      do IO<Unit>:
        c2 : Net.Client<Game.Input, Game.World()> <- Bot.line(k,
          Net.Client.at(~Game.Input, ~Game.World(), ~Game.Walkers.game(), c, k))
        Bot.report(t, c2)

def Bot.done(play: Game.Play) -> IO(Unit):
  Game.Play{pid, held, world, c} = play
  Bot.report([900n, 1200n, 2400n], c)

def Bot.idle(left: Nat, play: Game.Play) -> IO(Unit):
  match left:
    case 0n:
      Bot.done(play)
    case 1n+k:
      Bot.frame([], play, p => Bot.idle(k, p))

def Bot.run(+pid: U32, +frames: Nat, idle: Nat, play: Game.Play) -> IO(Unit):
  match frames:
    case 0n:
      Bot.idle(idle, play)
    case 1n+f:
      Bot.frame(Bot.events(pid, frames), play, p => Bot.run(pid, f, idle, p))

def Bot.start(
  host: String, port: U32, room: String, +pid: U32, frames: Nat, idle: Nat
) -> IO(Unit):
  do IO<Unit>:
    play : Game.Play <- Game.Play.open(host, port, room, pid)
    Bot.run(pid, frames, idle, play)

def main() -> IO(Unit):
  do IO<Unit>:
    host : String <- Net.Env.get("SERVER", "127.0.0.1")
    port : String <- Net.Env.get("PORT", "7777")
    room : String <- Net.Env.get("ROOM", "lobby")
    pid : String <- Net.Env.get("PID", "")
    frames : String <- Net.Env.get("FRAMES", "480")
    idle : String <- Net.Env.get("IDLE", "150")
    now : Nat <- IO.now()
    Bot.start(host, Net.Env.u32(port, 7777), room, Game.Main.pid(pid, now),
      U32.to_nat(Net.Env.u32(frames, 480)), U32.to_nat(Net.Env.u32(idle, 150)))
