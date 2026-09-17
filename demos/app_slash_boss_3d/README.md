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
a pause freezes the world for any number of ticks, P twice restores the
pause state of any game, an Esc anywhere in a frame's events quits; plus
closed sanity facts about the route back to the title, the pause toggle,
the countdown floor and the arrow keys. Check: `bend PROOF.bend`.

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
