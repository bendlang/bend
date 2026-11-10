# Slash Boss 3D

A one-on-one duel in 3D, written in Bend over the Bend3D library
([`bend3d.bend`](bend3d.bend)): you, THE BLADE, against THE SEVERANT.
WASD or the arrows move, I jumps, J and K attack, L guards or dodges,
P pauses, R restarts, Esc quits. The game builds its scene each frame,
mixes its own sound, and ships laws over the pure sim.

**Run it** from the repo root (the sounds resolve from `media/slash_boss_3d`
or `../../media/slash_boss_3d`, so the working directory must be the repo
root or this directory):

```
bend demos/app_slash_boss_3d/main.bend -o slash && ./slash
```

**Laws** ([`LAWS.bend`](LAWS.bend), proved in [`PROOF.bend`](PROOF.bend)):
a pause freezes the world for any number of ticks, the loop's ticks are
the game's and a frame runs the ticks it owes (60 a second of at most
100 ms), a frame whose events end the game ends the loop, P twice restores the pause state of any game, an Esc anywhere
in a frame's events quits, a frame with no Esc and no Close does not end
the game and a frame with no events keeps it as it is, and the game's
countdown is the spec's; plus closed sanity facts about the route back to the
title, the pause toggle, the countdown floor and the arrow keys. What the
laws measure with (n ticks, the ticks a frame owes, n fades, a frame's
events joined) is in [`SPEC.bend`](SPEC.bend). Keep it fixed with
`LAWS.bend` when rewriting the game or its proofs: a claim must not rely
on an editable helper to say what it means. The loop laws read only the
game a frame leaves: the rest of the loop's state and its IO are not
pinned, and the top of `LAWS.bend` lists what the laws leave open.
Check: `bend PROOF.bend`.

## Audio

All clips in `media/slash_boss_3d` are CC0 (public domain) from
[Kenney](https://kenney.nl), converted to WAV with ffmpeg:

- `blade.wav`, `whoosh.wav` — `knifeSlice.ogg`, `knifeSlice2.ogg` from
  [RPG Audio](https://kenney.nl/assets/rpg-audio)
- `dash.wav` — `cloth1.ogg` from [RPG Audio](https://kenney.nl/assets/rpg-audio)
- `parry.wav` — `impactMetal_heavy_000.ogg` from
  [Impact Sounds](https://kenney.nl/assets/impact-sounds)
- `bell_a.wav`, `bell_b.wav`, `bell_c.wav` — `impactBell_heavy_000.ogg` from
  [Impact Sounds](https://kenney.nl/assets/impact-sounds), cut in three
  0.5 s parts that play as one clip

Licence: [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/).
