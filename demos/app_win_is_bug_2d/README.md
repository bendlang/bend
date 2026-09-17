# Winning Is Impossible

A tiny game with one rule: step on the flag and you win. And one feature: it
ships with a **formal proof** that you can't. Not "we tested it a lot" —
a machine-checked theorem, over every input sequence of every length:

```python
# LAW: for any sequence of moves, replaying them
# from the start can never lead to victory.
law you_cant_win:
  for moves: List<Game.Move>
  board = Game.replay(Game.start(), moves)
  {Game.is_won(board) == False{} : Bool}
```

If you ever see the win screen, the type checker is broken. File a bug.

**Play it:** https://bend-lang.com/#lab

## How to work with Bend

This demo is a working example of the intended division of labor:

- [`main.bend`](main.bend) — the **game**. The whole program, nothing
  else.
- [`LAWS.bend`](LAWS.bend) — the **claims**. The human's file: it
  imports the game and asserts what must be true about it. Asserts only;
  it proves nothing.
- [`PROOF.bend`](PROOF.bend) — the **proofs**. The AI's file: it must fill
  every law it states — Bend rejects an unfilled law — so
  `bend PROOF.bend` is the whole verification, and it fails the moment a
  law stops holding.

The human maintains the wall; the machine does anything it wants on the
other side of it, except lie.

## How it runs

There is no build script and no generated glue. The browser UI
([`web/main.js`](web/main.js)) imports the game directly:

```js
import Game from "../main.bend";
```

The loader in [bend2/main.ts](../../bend2/main.ts) compiles `.bend`
imports on the fly — under bun (dev server and bundler) and under node
(`node --import`). Every def becomes a function on
`Game`; the UI asks `Game.grid` for the level and sends every keypress
through `Game.replay`. The browser never decides anything.

```bash
cd web
bun index.html              # serves the page, .bend imports and all
bend index.html -o out      # bundles it (needs bend on the PATH)
bend ../PROOF.bend          # every law must be filled
```

## The level

The map is a torus: walk off one edge, come back on the opposite one. The
flag sits in a room on the top-left corner, sealed by two walls. Where are
the room's other two walls? On the far edges of the screen — on a torus,
that IS the other side of the room.

```
...#.......#
.F.#.......#
...#.......#
####.......#
............
........P...
............
####........
```

## The proof

An invariant — *the player stands on a safe cell: on the map, not in the
room, not on a wall* — holds at the start and survives every move. The
geometric heart (every step from a safe cell lands on a wall or on a safe
cell) is finite, so it is not argued: `chk_all` enumerates the whole map
and the checker evaluates it to `True`. Reflection lemmas index that
certificate at arbitrary coordinates, and a safe cell is off the flag,
because the flag's cell is in the room, so a step never sets `won`.
`run_safe` carries the invariant through any list of moves and answers
the final cell; both laws (never won, never on the flag) read off it. No
axioms, no TODOs, no `unsafe`: `bend PROOF.bend` answers "All terms
check."
