# Slash Boss 3D over Bend3D (bend3d.bend): each frame the game builds
# the scene from the library's surfaces under its own camera and hands
# the library its lights, materials, sky and shapes as data and hooks
# (the Stage.* and Sky.* defs). The sim is the original's hero side at
# 60 Hz (WASD or arrows move, I jumps, J and K attack, L guards or
# dodges, P pauses, R restarts, Esc quits) against THE SEVERANT, with
# the effects and the sound; the view lies between the last two ticks;
# the title shows the frame rate. SLASH_PROBE=N runs N scripted frames
# headless and prints the state every 60 ticks, every cue and the
# microseconds a frame of each stage; SLASH_DUMP=T prints the frame at
# tick T as a tree; SLASH_MODE=M rigs the mode (9: the parry cue);
# SLASH_WAV=path writes the mix there as text; SLASH_VOICES=N adds N
# looping voices.
#
#   bend demos/app_slash_boss_3d/main.bend -o slash && ./slash
import Base
import ./bend3d.bend as R

# Camera
# ------

def Math.smooth(+x: F32) -> F32:
  +u = R.sat(x)
  (u * u * (3.0 - 2.0 * u) : F32)

# The lens: its target, its width and their speeds.
type Lens is Data:
  Lens{x: F32, y: F32, w: F32, vx: F32, vy: F32, vw: F32}

# The lens a tick later: it leads the hero's fall, frames him and the
# boss, and springs to the frame.
def Lens.follow(
  +l: Lens, +px: F32, +py: F32, +hvx: F32, +hvy: F32, +bx: F32, +by: F32,
  +byaw: F32
) -> Lens:
  Lens{x, y, w, vx, vy, vw} = l
  +cx = R.clamp((px * 0.55 + (bx - F32.cos(byaw)) * 0.45 : F32),
    (0.0 - 5.0 : F32), 5.0)
  +lead = (hvy * 3.0 : F32)
  +low = R.min((py + lead : F32), by)
  +high = R.max((py + 1.8 + lead : F32), (by + 5.1 : F32))
  +wide = R.clamp(R.max((F32.abs((px - bx : F32)) + 14.0 : F32),
      ((high - low + 2.2) * 2.0 : F32)), 19.0, 39.0)
  +cy = R.clamp(((low + high) * 0.5 - wide * 0.055 : F32), (0.0 - 4.5 : F32),
    8.0)
  +dx = R.clamp(((vx + (cx - x) * 0.06) * 0.68 : F32), (0.0 - 0.25 : F32), 0.25)
  +dy = R.clamp(((vy + (cy - y) * 0.06) * 0.68 : F32), (0.0 - 0.20 : F32), 0.20)
  +dw = ((vw + (wide - w) * 0.035) * 0.72 : F32)
  Lens{(x + dx : F32), (y + dy : F32), (w + dw : F32), dx, dy, dw}

# A frame's view, one flat record: the eye (3.2 over and 27 before the
# lens's target, shaken in a flash), the focal length, the contact
# light (0.7 before the contact point) and its strength ((150, 244,
# 255) x 12 in a flash, else 0.2).
type View is Data:
  View{eye: R.Vec, focal: F32, hit: R.Vec, k: F32}

def View.at(+l: Lens, +t: F32, +flash: U32, +hit: R.Vec) -> View:
  Lens{x, y, w, _, _, _} = l
  R.Vec{hx, hy, hz} = hit
  +shake = (U32.to_f32(flash) * 0.011 : F32)
  View{R.Vec{(x + F32.sin((t * 2.4 : F32)) * shake : F32),
      (y + 3.2 + F32.cos((t * 2.9 : F32)) * shake * 0.6 : F32), 27.0}, (51840.0 / w : F32),
    R.Vec{hx, hy, (hz + 0.7 : F32)}, R.pick((flash > 0 : U32), 12.0, 0.2)}

# The frame, 1920 x 1200.
def Screen.w() -> U32:
  1920

def Screen.h() -> U32:
  1200

# The camera hook: the original's tilt (0.1177 down), 51840 / width
# about (960, 581), the near plane 0.5.
def Stage.cam(+v: View) -> R.Cam:
  View{eye, focal, _, _} = v
  R.Cam{eye, R.Vec{1.0, 0.0, 0.0}, R.Vec{0.0, 0.99305, (0.0 - 0.1177 : F32)},
    R.Vec{0.0, (0.0 - 0.1177 : F32), (0.0 - 0.99305 : F32)}, focal, 960.0, 581.25, 0.5, Screen.w(),
    Screen.h()}

# Materials
# ---------

# The original's plain face (roughness 0.62), a painted part, a bead, a
# bone, a translucent face; tags 1 and 2 grain the stone and the moon.
def Mat.flat(+c: U32) -> R.Mat:
  R.Mat{c, 0.62, 0.0, 0.0, 0, 0, 1.0}

def Mat.paint(+c: U32, +rough: F32, +metal: F32, +glow: F32) -> R.Mat:
  R.Mat{c, rough, metal, glow, 0, 0, 1.0}

def Mat.bead(+c: U32, +glow: F32) -> R.Mat:
  Mat.paint(c, 0.24, 0.20, glow)

def Mat.bone(+c: U32) -> R.Mat:
  Mat.paint(c, 0.38, 0.30, 0.0)

# The tint by the material's tag: the stone's grain from the place,
# the moon's from (u, v), else the colour.
def Stage.tint(stone: Bool, moon: Bool, +c: U32, +p: R.Vec, +u: F32, +v: F32) -> R.Vec:
  match stone moon:
    case True{} _:
      R.Vec{x, y, z} = p
      +g = (F32.sin((x * 2.4 + z * 3.1 : F32)) * F32.cos((y * 2.3 - z * 1.7 : F32)) : F32)
      R.Vec.mix(R.Vec.rgb(2239030), R.Vec.rgb(7765633), (0.3 * R.sat((0.36 + g * 0.14
        + F32.sin((x * 7.8 + y * 3.2 + z * 5.4 : F32)) * 0.06 : F32)) : F32))
    case _ True{}:
      +g = (F32.sin((v * 34.0 + F32.sin((u * 41.0 : F32)) * 2.0 : F32))
        * F32.cos((u * 47.0 + F32.sin((v * 28.0 : F32)) : F32)) : F32)
      R.Vec.mix(R.Vec.rgb(7774082), R.Vec.rgb(14213066), (0.52 + 0.18 * g * g : F32))
    case _ _:
      R.Vec.rgb(c)

# The original's lights in linear light: the ambient, two suns, the
# lamp at (-5, 3, 4) over 18, the contact light over 8.
def Stage.lit(+l: R.Lit, +p: R.Vec, +f: View) -> R.Vec:
  View{_, _, hit, k} = f
  R.Vec{x, y, z} = hit
  R.Light.sum(l, R.Vec{0.1412, 0.1725, 0.2588},
    R.Vec.add(R.Vec.add(R.Light.one(l, R.Vec{0.3714, 0.7428, 0.5571}, R.Vec{2.4667, 2.84, 3.4}),
        R.Light.one(l, R.Vec{(0.0 - 0.5488 : F32), 0.3293, (0.0 - 0.7683 : F32)},
          R.Vec{1.2549, 1.598, 2.5})),
      R.Vec.add(R.Light.pt(l, p, R.Vec{(0.0 - 5.0 : F32), 3.0, 4.0}, R.Vec{5.0, 3.3725, 2.0392}, 18.0,
          0.08),
        R.Light.pt(l, p, R.Vec{x, y, z}, R.Vec{(0.5882 * k : F32), (0.9569 * k : F32), k}, 8.0,
          0.08))))

def Stage.shade.go(lit: Bool, mat: R.Mat, tint: R.Vec, +p: R.Vec, n: R.Vec, +f: View) -> R.Vec:
  match lit:
    case True{}:
      Stage.lit(R.Light.at(mat, tint, p, n, Stage.cam(f)), p, f)
    case False{}:
      tint

# The shade hook: an opaque vertex is lit, a transparent one is its
# tint.
def Stage.shade(+mat: R.Mat, +p: R.Vec, n: R.Vec, u: F32, v: F32, f: View) -> R.Vec:
  R.Mat{c, _, _, _, tag, m, _} = mat
  Stage.shade.go(U32.is_eq(m, 0), mat, Stage.tint(U32.is_eq(tag, 1), U32.is_eq(tag, 2), c, p, u, v), p,
    n, f)

# Surfaces
# --------

def Arch.x(+x: F32, +u: F32) -> F32:
  (x - F32.cos((3.1415927 * u : F32)) * 3.1 : F32)

# The vault over the columns: a half ellipse 3.1 wide and 4.0 high.
def Arch.y(+u: F32) -> F32:
  (4.3 + 4.0 * F32.sin((3.1415927 * u : F32)) : F32)

# The game's unit shapes: 0 the cliff under the arena and 1 the arch
# over x at z = -15 (both in an identity basis), 2 the horn, 3 the
# blade (tapered, curving in +x, root at y = 0).
def Stage.unit.go(low: Bool, even: Bool, +x: F32, +u: F32, +v: F32) -> R.Vec:
  match low even:
    case True{} True{}:
      +a = (6.2831853 * u : F32)
      +brk = (F32.sin((7.0 * a : F32)) * 0.15 + F32.cos((13.0 * a : F32)) * 0.08 : F32)
      +r = ((1.0 - v * 0.66 - v * v * v * v * 0.34)
        * (1.0 + brk * R.min(1.0, (v * 6.0 : F32))) : F32)
      R.Vec{(F32.cos(a) * r * 7.3 : F32),
        (0.0 - v * 3.55 - brk * F32.sin((3.1415927 * v : F32)) * 0.7 : F32),
        (F32.sin(a) * r * 3.5 : F32)}
    case True{} False{}:
      +px = Arch.x(x, u)
      +py = Arch.y(u)
      +tx = (Arch.x(x, (u + 0.002 : F32)) - px : F32)
      +ty = (Arch.y((u + 0.002 : F32)) - py : F32)
      +il = (0.19 / R.max(0.00001, F32.sqrt((tx * tx + ty * ty : F32))) : F32)
      +ca = F32.cos((0.7853982 - 6.2831853 * v : F32))
      +sa = F32.sin((0.7853982 - 6.2831853 * v : F32))
      +m = (1.0 / R.max(F32.abs(ca), F32.abs(sa)) : F32)
      R.Vec{(px - ty * il * ca * m : F32), (py + tx * il * ca * m : F32),
        (0.19 * sa * m - 15.0 : F32)}
    case False{} True{}:
      +a = (6.2831853 * u : F32)
      +w = (1.0 - v : F32)
      +r = (v * 0.18 : F32)
      R.Vec{(w * w * 0.45 + r * F32.cos(a) : F32), w, (r * F32.sin(a) : F32)}
    case False{} False{}:
      +a = (6.2831853 * u : F32)
      +w = (1.0 - v : F32)
      +tip = (1.0 - w * 0.985 : F32)
      R.Vec{(w * w * 0.2 + 0.064 * tip * F32.cos(a) : F32), w, (0.012 * tip * F32.sin(a) : F32)}

# Their patches on the screen: a horn or a blade by its section's
# sagitta and its length; the cliff and the arch keep their grids.
def Stage.unit(k: U32, +x: F32, +u: F32, +v: F32) -> R.Vec:
  +k = k
  Stage.unit.go((k < 2 : U32), U32.is_eq((k .&. 1 : U32), 0), x, u, v)

def Stage.size(k: U32, +r: F32, +fx: F32, +fy: F32, +fz: F32) -> R.Vec:
  +k = k
  +own = (k >= 2 : U32)
  R.Vec{R.pick(own, R.Grid.arc((r * R.pick(U32.is_eq(k, 2), 0.18, 0.064) : F32)), 9999.0),
    R.pick(own, R.Grid.len(fy), 9999.0), 0.0}

# An own shape in the identity basis.
def Stage.raw(+k: U32, +x: F32) -> R.Surf:
  R.Inst{R.Own{k, x}, R.Vec{0.0, 0.0, 0.0}, R.Vec{1.0, 0.0, 0.0}, R.Vec{0.0, 1.0, 0.0},
    R.Vec{0.0, 0.0, 1.0}}

# The library's mesher under the game's hooks (the cloths' mesher too).
def Mesh.of(+s: R.Surf, +mat: R.Mat, +nu: U32, +nv: U32, +f: View) -> R.Cells:
  R.Mesh.of(~View, ~Stage.cam, ~Stage.unit, ~Stage.size, ~Stage.shade, s, mat, nu, nv, f)

# Stage
# -----

# A box of half sizes hx, hz from y0 to y1: its sides (nu around) and
# its lid (on top at lid 1, underneath at -1).
def Box.build(
  +cx: F32, +y0: F32, +y1: F32, +cz: F32, +hx: F32, +hz: F32, +lid: F32, +mat: R.Mat,
  +nu: U32, +view: View
) -> R.Cells:
  +hy = ((y1 - y0) * 0.5 : F32)
  +cy = (y0 + hy : F32)
  a b = Mesh.of(R.Inst.ball(R.Box{}, R.Vec{cx, cy, cz}, hx, hy, hz), mat, nu, 1, view)
    Mesh.of(R.Inst.ball(R.Plate{}, R.Vec{cx, cy, cz}, hx, (hy * lid : F32), (hz * lid : F32)), mat,
      4, 1, view)
  R.Cells.merge(a, b)

# A horn strut from under a platform's edge at x to under its centre.
def Stage.strut(+x: F32, +px: F32, +py: F32, +view: View) -> R.Cells:
  Mesh.of(R.Inst.span(R.Own{2, 0.0}, R.Vec{x, (py - 0.23 : F32), 0.0}, R.Vec{px, (py - 0.73 : F32), 0.0},
    0.75, 0.72), Mat.paint(5658961, 0.75, 0.12, 0.0), 8, 4, view)

# A floating platform of half width r at (px, py): its slab, the
# underside, two struts, a bead on its front, a bright edge on top.
def Stage.platform(+px: F32, +py: F32, +r: F32, +view: View) -> R.Cells:
  a b c d e f = Box.build(px, (py - 0.16 : F32), py, 0.0, r, 0.36, 1.0, Mat.flat(5464411),
      8, view)
    Box.build(px, (py - 0.25 : F32), (py - 0.17 : F32), 0.0, (r - 0.08 : F32), 0.33,
      (0.0 - 1.0 : F32), Mat.flat(2699574), 8, view)
    Stage.strut((px - r * 0.72 : F32), px, py, view) Stage.strut((px + r * 0.72 : F32), px, py, view)
    Mesh.of(R.Inst.ball(R.Globe{}, R.Vec{px, (py - 0.31 : F32), 0.34}, 0.07, 0.07, 0.028),
      Mat.bead(7395267, 0.9), 8, 4, view)
    Mesh.of(R.Inst{R.Box{}, R.Vec{px, (py + 0.008 : F32), 0.36}, R.Vec{0.0, 0.011, 0.0},
      R.Vec{(0.0 - r : F32), 0.0, 0.0}, R.Vec{0.0, 0.0, 0.011}}, Mat.paint(11643817, 0.62, 0.0, 0.04),
      4, 1, view)
  R.Cells.merge(R.Cells.m4(a, b, c, d), R.Cells.merge(e, f))

# A column of a ruin at x, from -3 to 4.3 at z = -15.
def Stage.column(+x: F32, +view: View) -> R.Cells:
  Mesh.of(R.Inst.span(R.Tube{}, R.Vec{x, (0.0 - 3.0 : F32), (0.0 - 15.0 : F32)},
    R.Vec{x, 4.3, (0.0 - 15.0 : F32)}, 0.24, 0.24), Mat.flat(2239030), 8, 2, view)

# A ruined arch over x: the round vault, two columns and a low wall
# between them.
def Stage.arch(+x: F32, +view: View) -> R.Cells:
  a b c d = Mesh.of(Stage.raw(1, x), Mat.flat(2239030), 32, 4, view)
    Stage.column((x - 3.1 : F32), view) Stage.column((x + 3.1 : F32), view)
    Box.build(x, (0.0 - 3.1 : F32), (0.0 - 0.9 : F32), (0.0 - 15.0 : F32), 3.0, 0.25, 1.0,
      Mat.flat(1908268), 8, view)
  R.Cells.m4(a, b, c, d)

# A lamp of the grove at x (the original's stem at z = -0.8): base,
# pole, lantern, roof, glowing gem.
def Stage.stem(+x: F32, +view: View) -> R.Cells:
  +z = (0.0 - 0.8 : F32)
  a b c d e = Box.build(x, 0.0, 0.41, z, 0.065, 0.065, 1.0, Mat.flat(2961983), 4, view)
    Box.build(x, 0.403, 0.923, z, 0.052, 0.052, 1.0, Mat.flat(5462631), 4, view)
    Box.build(x, 0.871, 1.079, z, 0.143, 0.143, 1.0, Mat.flat(3356485), 4, view)
    Mesh.of(R.Inst.ball(R.Gem{}, R.Vec{x, 1.183, z}, 0.234, 0.104, 0.234), Mat.flat(3360328),
      4, 2, view)
    Mesh.of(R.Inst.ball(R.Gem{}, R.Vec{x, 0.9945, (0.0 - 0.644 : F32)}, 0.065, 0.078, 0.0195),
      Mat.paint(15253430, 0.62, 0.0, 0.7), 4, 2, view)
  R.Cells.merge(R.Cells.m4(a, b, c, d), e)

# The arena's top: the slab (an ellipse of 7.3 x 3.5) and its rim.
def Stage.top(+view: View) -> R.Cells:
  a b = Mesh.of(R.Ring{0.0, 0.001, 0.0, 7.3, 3.5, 0.0, 1.0}, Mat.flat(4083018), 64, 2, view)
    Mesh.of(R.Ring{0.0, 0.005, 0.0, 7.3, 3.5, 0.986, 0.996}, Mat.flat(9866105), 64, 1, view)
  R.Cells.merge(a, b)

# The arena's depths: its inner ring and the cliff beneath.
def Stage.deep(+view: View) -> R.Cells:
  a b = Mesh.of(R.Ring{0.0, 0.025, 0.0, 7.3, 3.5, 0.827, 0.83}, Mat.flat(6843496), 64, 1, view)
    Mesh.of(Stage.raw(0, 0.0), R.Mat{2239030, 0.62, 0.0, 0.0, 1, 0, 1.0}, 64, 12, view)
  R.Cells.merge(a, b)

# The middle and right arches.
def Stage.pair(+view: View) -> R.Cells:
  a b = Stage.arch(0.0, view) Stage.arch(9.5, view)
  R.Cells.merge(a, b)

# The rest of the stage: three platforms, the moon and four lamps.
def Stage.rest(+view: View) -> R.Cells:
  e f g h i j k l = Stage.platform((0.0 - 4.5 : F32), 2.15, 1.5, view)
    Stage.platform(4.5, 2.15, 1.5, view) Stage.platform(0.0, 3.65, 1.55, view)
    Mesh.of(R.Inst.ball(R.Globe{}, R.Vec{18.0, 9.0, (0.0 - 50.0 : F32)}, 5.0, 5.0, 5.0),
      R.Mat{7774082, 0.62, 0.0, 0.08, 2, 0, 1.0}, 24, 12, view)
    Stage.stem(6.4, view) Stage.stem(5.91, view) Stage.stem((0.0 - 6.4 : F32), view)
    Stage.stem((0.0 - 5.91 : F32), view)
  R.Cells.merge(R.Cells.m4(e, f, g, h), R.Cells.m4(i, j, k, l))

# The ground under (x, y): the top platform, a side one, the arena, or
# none (-100).
def Stage.level(+x: F32, +y: F32) -> F32:
  R.pick(((F32.abs(x) < 1.55) && (y >= 3.65) : F32), 3.65,
    R.pick(((F32.abs((F32.abs(x) - 4.5 : F32)) < 1.5) && (y >= 2.15) : F32), 2.15,
      R.pick(((F32.abs(x) <= 7.3) && (y >= 0.0) : F32), 0.0, (0.0 - 100.0 : F32))))

# A corner of a contact shadow: the ground point q projected, (u, v)
# (the rim at 1) times w in r and g, the tint (8, 12, 20) in b.
def Shadow.vert(+u: F32, +v: F32, +q: R.Vec) -> R.Vert:
  R.Vec{sx, sy, w} = q
  R.Vert{sx, sy, w, (u * w : F32), (v * w : F32), 527380.0}

# The shadow's quad (mode 3): sp by 0.48 sp about x on the ground lv,
# alpha 0.36 at the centre, spread and faded by the height h.
def Shadow.on(on: Bool, +x: F32, +lv: F32, +h: F32, +size: F32, +view: View) -> R.Cells:
  match on:
    case False{}:
      R.CNil{}
    case True{}:
      +cam = Stage.cam(view)
      +sp = (size * (1.0 + h * 0.05) : F32)
      +sz = (sp * 0.48 : F32)
      +y = (lv + 0.015 : F32)
      +al = (0.36 / (1.0 + h * 0.30 : F32) : F32)
      +a = Shadow.vert((0.0 - 1.0 : F32), (0.0 - 1.0 : F32),
        R.Cam.proj(cam, R.Vec{(x - sp : F32), y, (0.0 - sz : F32)}))
      +b = Shadow.vert(1.0, (0.0 - 1.0 : F32), R.Cam.proj(cam, R.Vec{(x + sp : F32), y, (0.0 - sz : F32)}))
      +c = Shadow.vert(1.0, 1.0, R.Cam.proj(cam, R.Vec{(x + sp : F32), y, sz}))
      +d = Shadow.vert((0.0 - 1.0 : F32), 1.0, R.Cam.proj(cam, R.Vec{(x - sp : F32), y, sz}))
      R.Mesh.raster(a, c, d, 3, al, 1919.0, 1199.0, R.Mesh.raster(a, b, c, 3, al, 1919.0, 1199.0, R.CNil{}))

# The soft shadow of a figure of a size at (x, y); none over the void.
def Shadow.build(+x: F32, +y: F32, +size: F32, +view: View) -> R.Cells:
  +lv = Stage.level(x, y)
  Shadow.on((lv > (0.0 - 99.0) : F32), x, lv, R.max(0.0, (y - lv : F32)), size, view)

# Cloth
# -----

# The scene's breeze: a sway in x by the particle, a fall, a sway in z.
def Stage.wind(+t: F32, i: U32) -> R.Vec:
  R.Vec{(0.0018 * F32.sin((t * 0.031 + U32.to_f32(i) * 0.7 : F32)) : F32), (0.0 - 0.005 : F32),
    (0.001 * F32.sin((t * 0.043 : F32)) : F32)}

# The hero's cape: a pointed mantle about the shoulders.
def Fit.cape() -> R.Fit:
  R.Fit{8, 8, 0, 0.16, 0.36, 0.16, 1.02, 0.78, 0.128, 3.0, 0.68, 1.0, 0.13, 0.35, 1.03, 0.035, 4}

# The boss's cloths: a long cloak from the shoulders, a mantle over
# the hood's back, six strands of hair (loose ropes); each about the
# anchor at its feet.
type Garb is Data:
  Garb{cloak: R.Cloth, hood: R.Cloth, hair: R.Cloth}

def Fit.cloak() -> R.Fit:
  R.Fit{8, 8, 0, 0.42, 0.75, 1.1, 3.15, 2.85, 0.128, 3.0, 0.6, 1.0, 0.45, 1.4, 3.3, 0.035, 4}

def Fit.hood() -> R.Fit:
  R.Fit{8, 8, 1, 0.62, 0.30, 0.15, 3.78, 1.2, 0.128, 3.0, 1.0, 1.0, 0.55, 2.4, 3.8, 0.035, 4}

def Fit.hair() -> R.Fit:
  R.Fit{6, 10, 1, 0.34, 0.0, 0.9, 3.55, 2.4, 0.128, 3.0, 1.0, 0.0, 0.5, 2.2, 3.7, 0.035, 4}

def Garb.seed(+o: R.Vec, +face: F32) -> Garb:
  Garb{R.Cloth.seed(3n, 0, Fit.cloak(), o, face), R.Cloth.seed(3n, 0, Fit.hood(), o, face),
    R.Cloth.seed(3n, 0, Fit.hair(), o, face)}

def Garb.step(+g: Garb, +o: R.Vec, +face: F32, +t: F32) -> Garb:
  Garb{cloak, hood, hair} = g
  a b c = R.Cloth.step(~Stage.wind, cloak, Fit.cloak(), o, face, t, 0.0)
    R.Cloth.step(~Stage.wind, hood, Fit.hood(), o, face, t, 0.0)
    R.Cloth.step(~Stage.wind, hair, Fit.hair(), o, face, t, 0.0)
  Garb{a, b, c}

def Garb.lerp(+a: Garb, +b: Garb, +u: F32) -> Garb:
  Garb{c0, h0, r0} = a
  Garb{cloak, hood, hair} = b
  Garb{R.Cloth.lerp(c0, cloak, u), R.Cloth.lerp(h0, hood, u), R.Cloth.lerp(r0, hair, u)}

def Garb.build(+g: Garb, +view: View) -> R.Cells:
  Garb{cloak, hood, hair} = g
  a b c = R.Cloth.mesh(~View, ~Stage.cam, ~Mesh.of, 3n, cloak, 0, Fit.cloak(), False{}, 1186352, 725024,
      0.84, 0.0, view)
    R.Cloth.mesh(~View, ~Stage.cam, ~Mesh.of, 3n, hood, 0, Fit.hood(), False{}, 725024, 1186352, 0.84,
      0.0, view)
    R.Cloth.mesh(~View, ~Stage.cam, ~Mesh.of, 3n, hair, 0, Fit.hair(), True{}, 3162206, 0, 0.7, 0.045,
      view)
  R.Cells.merge(a, R.Cells.merge(b, c))

# Sim
# ---

# The hero: place, speed, facing (0 is +x, pi is -x), damage, guard, the jump
# bits (two count jumps, 8 the air dodge spent, 16 the recovery), the action and
# its age, the invulnerable ticks, the lives, the grace, the jump buffer, the
# charge. Actions: 0 idle, 1 neutral, 2 neutral special, 3 guard, 4 hurt, 5
# landing, 6 air dodge, 7 crouch, 10-12 side/up/down, 13-17 air
# neutral/forward/back/up/down, 20-22 side/up/down special, 23-26 their air
# kinds, 30-32 smashes charging.
type Fighter is Data:
  Fighter{p: R.Vec, v: R.Vec, face: F32, damage: F32, guard: F32, jumps: U32, action: U32,
    age: U32, inv: U32, stocks: U32, grace: U32, queued: U32, charge: U32}

# The boss, THE SEVERANT: its place, speed, facing, vitality, stun
# ticks, strain, state (0 stalks, 1 cleaves, 2 sweeps, 3 lunges, 4
# leaps, 5 draws, 6 blocks and counters, 7 lands the slam), the
# state's age, the stalk's pause, the leap's mark, the last walk.
type Boss is Data:
  Boss{p: R.Vec, v: R.Vec, face: F32, hp: F32, stun: U32, strain: F32, state: U32, age: U32,
    hold: U32, mark: F32, gait: F32}

# A death's detonation: where, the tick it began and who died (1 the
# hero, 2 the boss).
type Blast is Data:
  Blast{x: F32, y: F32, born: U32, who: U32}

def Blast.over(+m: Maybe<&2, Blast>, +time: U32) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{b}:
      Blast{_, _, born, _} = b
      ((time - born : U32) >= 42 : U32)

# The game: the tick, the keys held and tapped since the last tick,
# the mode (0 title, 1 fight, 2 win, 3 loss, 4
# pause), the hero, the boss, the hitstop flash, the cape, the boss's
# cloths, the lens, the last detonation.
type Game is Data:
  Game{time: U32, held: U32, taps: U32, mode: U32, hero: Fighter, boss: Boss, flash: U32,
    cloth: R.Cloth, garb: Garb, lens: Lens, blast: Maybe<&2, Blast>}

def Sim.dec(+x: U32) -> U32:
  R.word((x > 0 : U32), (x - 1 : U32), 0)

def Sim.has(+held: U32, +bit: U32) -> Bool:
  U32.is_ne((held .&. bit : U32), 0)

def Sim.axis(+held: U32, +pos: U32, +neg: U32) -> F32:
  (R.pick(Sim.has(held, pos), 1.0, 0.0) - R.pick(Sim.has(held, neg), 1.0, 0.0) : F32)

def Vec.x(+p: R.Vec) -> F32:
  R.Vec{x, _, _} = p
  x

def Vec.y(+p: R.Vec) -> F32:
  R.Vec{x, y, z} = p
  y

def Vec.plane(+p: R.Vec) -> R.Vec:
  R.Vec{x, y, _} = p
  R.Vec{x, y, 0.0}

def Vec.dir(+a: R.Vec, +b: R.Vec) -> R.Vec:
  R.Vec{ax, _, az} = a
  R.Vec{bx, _, bz} = b
  R.Vec.unit(R.Vec{(bx - ax : F32), 0.0, (bz - az : F32)})

def Vec.facing(+v: R.Vec) -> F32:
  R.Vec{x, _, z} = v
  F32.atan2((0.0 - z : F32), x)

def Vec.dist(+a: R.Vec, +b: R.Vec) -> F32:
  R.Vec.len(R.Vec.sub(a, b))

# The distance from p to the segment a..b.
def Vec.seg(+p: R.Vec, +a: R.Vec, +b: R.Vec) -> F32:
  +ab = R.Vec.sub(b, a)
  +u = R.sat((R.Vec.dot(R.Vec.sub(p, a), ab) / R.max(0.0001, R.Vec.dot(ab, ab)) : F32))
  Vec.dist(p, R.Vec.add(a, R.Vec.scale(ab, u)))

# Past the blast zones.
def Vec.out(+p: R.Vec) -> Bool:
  R.Vec{x, y, _} = p
  ((y < (0.0 - 8.5)) || (y > 14.0) || (F32.abs(x) > 14.5) : F32)

def Act.in(+act: U32, +a: U32, +b: U32) -> Bool:
  ((act >= a) && (act <= b) : U32)

def Act.is(+act: U32, +a: U32, +b: U32, +c: U32, +d: U32) -> Bool:
  (U32.is_eq(act, a) || U32.is_eq(act, b) || U32.is_eq(act, c) || U32.is_eq(act, d))

# The upward attacks, the downward, the specials, every attack, the
# smashes charging, the crouching actions (1), an attack's length, the
# age its hit lands at, a charge's power.
def Act.up(+act: U32) -> Bool:
  Act.is(act, 11, 16, 21, 25)

def Act.down(+act: U32) -> Bool:
  Act.is(act, 12, 17, 22, 26)

def Act.special(+act: U32) -> Bool:
  Bool.or(U32.is_eq(act, 2), Act.in(act, 20, 29))

def Act.attack(+act: U32) -> Bool:
  Bool.or(U32.is_eq(act, 1), Bool.or(U32.is_eq(act, 2), Act.in(act, 10, 29)))

def Act.charging(+act: U32) -> Bool:
  Act.in(act, 30, 32)

def Act.crouch(+act: U32) -> F32:
  R.pick(Act.is(act, 7, 12, 32, 32), 1.0, 0.0)

def Act.length(+act: U32) -> U32:
  R.word(Act.special(act), R.word(Act.down(act), 42, 34),
    R.word(Bool.or(U32.is_eq(act, 12), U32.is_eq(act, 17)), 25,
      R.word(U32.is_eq(act, 1), 18, 21)))

def Act.hit(+act: U32) -> U32:
  (Act.length(act) - R.word(Act.special(act), 9, 5) : U32)

def Act.power(+charge: U32) -> F32:
  (1.0 + R.sat((U32.to_f32(charge) / 45.0 : F32)) * 1.3 : F32)

def Fighter.spawn(+p: R.Vec, +stocks: U32, +inv: U32) -> Fighter:
  Fighter{Vec.plane(p), R.Vec{0.0, 0.0, 0.0}, 0.0, 0.0, 100.0, 0, 0, 0, inv, stocks, 6, 0, 0}

# A fresh game: the hero at -3.4, the boss at 3.2 facing him, 360
# vitality.
def Game.fresh(+held: U32, +mode: U32) -> Game:
  +home = {R.Vec{(0.0 - 3.4 : F32), 0.0, 0.0} : R.Vec}
  Game{0, held, 0, mode, Fighter.spawn(home, 3, 0),
    Boss{R.Vec{3.2, 0.0, 0.0}, R.Vec{0.0, 0.0, 0.0}, 3.14159, 360.0, 0, 0.0, 0, 0, 40, 0.0, 0.0}, 0,
    R.Cloth.seed(3n, 0, Fit.cape(), home, 0.0), Garb.seed(R.Vec{3.2, 0.0, 0.0}, 3.14159),
    Lens{0.0, 2.6, 25.0, 0.0, 0.0, 0.0}, None{}}

def Game.init() -> Game:
  Game.fresh(0, 0)

# The bit of a key: w a s d j k i l r p, the arrows as w s a d.
def Key.bit(+c: U32, +code: U32, +bit: U32) -> U32:
  R.word(U32.is_eq(c, code), bit, 0)

# The bit of a key: w a s d j k i l r p, the arrows as w s a d.
def Key.mask(+c: U32) -> U32:
  (Key.bit(c, 119, 1) .|. Key.bit(c, 97, 2) .|. Key.bit(c, 115, 4) .|. Key.bit(c, 100, 8)
    .|. Key.bit(c, 106, 16) .|. Key.bit(c, 107, 32) .|. Key.bit(c, 105, 64)
    .|. Key.bit(c, 108, 128) .|. Key.bit(c, 63232, 1) .|. Key.bit(c, 63233, 4)
    .|. Key.bit(c, 63234, 2) .|. Key.bit(c, 63235, 8) .|. Key.bit(c, 114, 512)
    .|. Key.bit(c, 112, 1024) : U32)

def Game.key(+g: Game, +code: U32, +down: Bool) -> Game:
  Game{time, held, taps, mode, hero, boss, flash, cloth, garb, lens, blast} = g
  +m = Key.mask(R.word(((code >= 65) && (code <= 90) : U32), (code + 32 : U32), code))
  Game{time, R.word(down, (held .|. m : U32), (held .&. U32.not(m) : U32)),
    (taps .|. R.word((down && Bool.not(Sim.has(held, m))), m, 0) : U32), mode, hero, boss,
    flash, cloth, garb, lens, blast}

# The ground a fall from old to p lands on: the base at 0, the sides at
# 2.15, the top at 3.65, none (-100); S held drops through.
def Stage.landing(+p: R.Vec, +old: F32, +through: Bool) -> F32:
  R.Vec{x, y, _} = p
  +base = ((F32.abs(x) <= 7.3) && (old >= 0.0) && (y <= 0.0) : F32)
  +side = (Bool.not(through) && ((F32.abs((F32.abs(x) - 4.5 : F32)) < 1.5)
    && (old >= 2.15) && (y <= 2.15) : F32))
  +top = (Bool.not(through) && ((F32.abs(x) < 1.55) && (old >= 3.65) && (y <= 3.65) : F32))
  R.pick(top, 3.65, R.pick(side, 2.15, R.pick(base, 0.0, (0.0 - 100.0 : F32))))

def Vec.place(+p: R.Vec, +level: F32, +landed: Bool) -> R.Vec:
  R.Vec{x, y, _} = p
  R.Vec{x, R.pick(landed, level, y), 0.0}

def Fighter.air(+p: R.Vec, +v: R.Vec) -> Bool:
  ((F32.abs(Vec.y(v)) > 0.005 : F32) || (Vec.y(p) > (Stage.landing(R.Vec.add(p,
    R.Vec{0.0, (0.0 - 0.025 : F32), 0.0}), Vec.y(p), False{}) + 0.04 : F32) : F32))

# The attack the keys pick: K a special, J a normal; up, down, a side
# (back in the air when held against the facing) or neutral.
def Fighter.kind(+special: Bool, +air: Bool, +held: U32, +face: F32) -> U32:
  +up = Sim.has(held, 1)
  +down = Sim.has(held, 4)
  +side = (Sim.has(held, 2) || Sim.has(held, 8))
  +back = ((Sim.axis(held, 8, 2) * F32.cos(face) : F32) < (0.0 - 0.1 : F32) : F32)
  R.word(special,
    R.word(air, R.word(up, 25, R.word(down, 26, R.word(side, 24, 23))),
      R.word(up, 21, R.word(down, 22, R.word(side, 20, 2)))),
    R.word(air, R.word(up, 16, R.word(down, 17, R.word(side,
        R.word(back, 15, 14), 13))),
      R.word(up, 11, R.word(down, 12, R.word(side, 10, 1)))))

# The hero a tick later under the keys: his action and its timer, his
# facing, his speed, the ground, the guard, the jump bits, the grace,
# the buffer, the charge.
def Fighter.tick(+f: Fighter, +held: U32, +taps: U32) -> Fighter:
  Fighter{p, v, face, damage, guard, jumps, action, age, inv, stocks, grace, queued, charge} = f
  R.Vec{_, y, _} = p
  R.Vec{vx, vy, _} = v
  +air = Fighter.air(p, v)
  +broken = (U32.is_eq(action, 3) && (guard <= 1.0 : F32))
  +hurt = (U32.is_eq(action, 4) && (age > 0 : U32))
  +block = (Bool.not(air) && (Sim.has(held, 128) || Sim.has(taps, 128)) && (guard > 1.0 : F32)
    && Bool.not(hurt))
  +count = (jumps .&. 3 : U32)
  +used = R.word((air && U32.is_eq(grace, 0) && U32.is_eq(count, 0)), 1, count)
  +jump = ((Sim.has(taps, 64) || (queued > 0 : U32)) && (used < 2 : U32) && Bool.not(block)
    && Bool.not(hurt) && Bool.not(U32.is_eq(action, 6)) && Bool.not(U32.is_eq(action, 5))
    && Bool.not(Act.charging(action)))
  +free = ((age <= 1 : U32) || U32.is_eq(action, 3) || U32.is_eq(action, 7))
  +special = (Sim.has(taps, 32) && free && Bool.not(block) && Bool.not(hurt)
    && Bool.not((air && Sim.has(held, 1) && Sim.has(jumps, 16))))
  +attack = ((Sim.has(held, 16) || Sim.has(taps, 16)) && free && Bool.not(block)
    && Bool.not(special) && Bool.not(hurt))
  +chosen = Fighter.kind(special, air, held, face)
  +dodge = (air && Sim.has(taps, 128) && free && Bool.not(hurt) && Bool.not(Sim.has(jumps, 8)))
  +crouch = (Bool.not(air) && Sim.has(held, 4) && free && Bool.not(block))
  +winding = (Act.in(action, 10, 12) && Sim.has(held, 16)
    && U32.is_eq(age, (Act.length(action) - 2 : U32)))
  +loading = (Act.charging(action) && Sim.has(held, 16) && (charge < 60 : U32) && Bool.not(block))
  +release = (Act.charging(action) && Bool.not(loading) && Bool.not(block))
  +act = R.word(dodge, 6, R.word(winding, (action + 20 : U32), R.word(loading, action,
    R.word(release, (action - 20 : U32), R.word(block, 3, R.word((special || attack),
    chosen, R.word(((age > 1 : U32) && Bool.not(U32.is_eq(action, 3))), action,
    R.word(crouch, 7, 0))))))))
  +timer = R.word(dodge, 28, R.word((winding || loading), 61,
    R.word(release, (Act.hit((action - 20 : U32)) + 2 : U32),
      R.word(block, R.word(U32.is_eq(action, 3), (age + 1 : U32), 1),
        R.word((special || attack), Act.length(chosen),
          R.word(U32.is_eq(action, 3), 0, Sim.dec(age)))))))
  +dx = Sim.axis(held, 8, 2)
  +aim = R.pick(((F32.abs(dx) > 0.1 : F32) && Bool.not(air) && Bool.not(hurt)),
    Vec.facing(R.Vec{dx, 0.0, 0.0}), face)
  +side = (U32.is_eq(act, 20) || U32.is_eq(act, 24))
  +rise = (special && Act.up(act))
  +dive = (special && Act.down(act) && air)
  +burst = (side && (timer > 20 : U32))
  +speed = R.pick((loading || winding), 0.0, R.pick(crouch, 0.016, R.pick(block, 0.009,
    R.pick(hurt, 0.008, R.pick(air, 0.025, 0.061)))))
  +normal = R.clamp((vx * R.pick(hurt, 0.965, R.pick(air, 0.91, 0.77)) + dx * speed : F32),
    R.pick(hurt, (0.0 - 2.0 : F32), (0.0 - 0.31 : F32)), R.pick(hurt, 2.0, 0.31))
  +evading = (U32.is_eq(action, 6) && (age > 14 : U32))
  +escape = R.Vec.scale(R.Vec.unit(R.Vec{dx, Sim.axis(held, 1, 4), 0.0}), 0.40)
  +nx = R.pick(dodge, R.Vec.dot(escape, R.Vec{1.0, 0.0, 0.0}), R.pick(evading, (vx * 0.93 : F32),
    R.pick(burst, (R.pick((F32.abs(dx) > 0.1 : F32), dx, F32.cos(aim)) * 0.40 : F32),
      R.pick(rise, (dx * 0.12 : F32), normal))))
  +gravity = R.pick((Sim.has(held, 4) && (vy < 0.0 : F32)), 0.040, 0.020)
  +fall = R.max((0.0 - 0.65 : F32), (vy - gravity : F32))
  +hop = R.pick((Bool.not(Sim.has(held, 64)) && (vy > 0.19 : F32)
    && Bool.not(Act.special(action)) && Bool.not(hurt)), R.min(fall, 0.19), fall)
  +ny = R.pick(dodge, Vec.y(escape), R.pick(evading, (vy * 0.93 : F32),
    R.pick(jump, 0.39, R.pick(rise, 0.48, R.pick(dive, (0.0 - 0.52 : F32), hop)))))
  +next = R.Vec.add(Vec.plane(p), R.Vec{nx, ny, 0.0})
  +floor = Stage.landing(next, y, Sim.has(held, 4))
  +ground = (floor > (0.0 - 99.0 : F32) : F32)
  +landlag = (air && ground && (Act.attack(action) || U32.is_eq(action, 6)) && (age > 1 : U32))
  Fighter{Vec.place(next, floor, ground), R.Vec{nx, R.pick(ground, 0.0, ny), 0.0}, aim, damage,
    R.clamp((guard + R.pick(block, (0.0 - 0.65 : F32), 0.55) : F32), 0.0, 100.0),
    R.word(ground, 0, (R.word(jump, R.word((grace > 0 : U32), 1, (used + 1 : U32)), used)
      .|. (jumps .&. 24) .|. R.word(dodge, 8, 0) .|. R.word(rise, 16, 0) : U32)),
    R.word(broken, 4, R.word(landlag, 5, act)),
    R.word(broken, 45, R.word(landlag, 8, timer)), R.word(dodge, 12, Sim.dec(inv)),
    stocks, R.word(jump, 0, R.word(ground, 6, Sim.dec(grace))),
    R.word(jump, 0, R.word(Sim.has(taps, 64), 6, Sim.dec(queued))),
    R.word((loading || winding), (charge + 1 : U32),
      R.word((attack || special || U32.is_eq(act, 0)), 0, charge))}

def Boss.name() -> String:
  "THE SEVERANT"

def Boss.tab(
  +s: U32, +a: U32, +b: U32, +c: U32, +d: U32, +e: U32, +f: U32, +g: U32, +h: U32
) -> U32:
  R.word(U32.is_eq(s, 0), a, R.word(U32.is_eq(s, 1), b, R.word(U32.is_eq(s, 2), c,
    R.word(U32.is_eq(s, 3), d, R.word(U32.is_eq(s, 4), e, R.word(U32.is_eq(s, 5), f,
      R.word(U32.is_eq(s, 6), g, h)))))))

# A state's wind-up, active and recovery ticks (the leap's recovery
# lasts to the landing; the landing strikes at once), their sum, is
# its blade live.
def Boss.wind(+s: U32) -> U32:
  Boss.tab(s, 100000, 30, 18, 16, 12, 46, 6, 0)

def Boss.act(+s: U32) -> U32:
  Boss.tab(s, 0, 8, 8, 10, 10, 4, 6, 6)

def Boss.rec(+s: U32) -> U32:
  Boss.tab(s, 0, 26, 22, 24, 1000, 36, 14, 30)

def Boss.live(+s: U32, +age: U32) -> Bool:
  ((age >= Boss.wind(s)) && (age < (Boss.wind(s) + Boss.act(s) : U32)) : U32)

# A pose: the grip (local: x ahead, y up, z aside), the blade's pitch
# and yaw (0 ahead, pi behind), the hips' dip, the torso's lean.
type Pose is Data:
  Pose{gx: F32, gy: F32, gz: F32, th: F32, yw: F32, dip: F32, lean: F32}

# A generic pick loses the callee's borrow facts (two shares in
# Boss.pose), so the poses keep their own.
def Pose.pick(c: Bool, +a: Pose, +b: Pose) -> Pose:
  match c:
    case True{}:
      a
    case False{}:
      b

def Pose.mix(+a: Pose, +b: Pose, +t: F32) -> Pose:
  Pose{ax, ay, az, ath, ayw, adip, alean} = a
  Pose{bx, by, bz, bth, byw, bdip, blean} = b
  Pose{R.mix(ax, bx, t), R.mix(ay, by, t), R.mix(az, bz, t), R.mix(ath, bth, t),
    R.mix(ayw, byw, t), R.mix(adip, bdip, t), R.mix(alean, blean, t)}

# The keys: at rest (the blade over the shoulder), in flight, and of a
# state at the end of its wind-up and of its strike (the leap's is its
# flight; the landing's wind-up key is the flight's; the counter cuts
# low from the block).
def Pose.rest() -> Pose:
  Pose{0.35, 2.95, 0.35, 1.85, 0.2, 0.0, 0.0}

def Pose.flight() -> Pose:
  Pose{0.1, 4.0, 0.25, 2.3, 0.1, 0.0, (0.0 - 0.1 : F32)}

def Pose.wind(+s: U32) -> Pose:
  Pose.pick(U32.is_eq(s, 1), Pose{(0.0 - 0.35 : F32), 3.9, 0.3, 2.75, 0.1, 0.1, (0.0 - 0.25 : F32)},
    Pose.pick(U32.is_eq(s, 2), Pose{(0.0 - 0.4 : F32), 1.25, 0.55, 0.05, 2.5, 0.55, 0.1},
      Pose.pick(U32.is_eq(s, 3), Pose{(0.0 - 0.6 : F32), 2.35, 0.35, 0.0, 0.35, 0.25, (0.0 - 0.3 : F32)},
        Pose.pick(U32.is_eq(s, 4), Pose{0.2, 2.6, 0.3, 1.6, 0.2, 0.7, 0.2},
          Pose.pick(U32.is_eq(s, 5), Pose{(0.0 - 0.3 : F32), 1.5, 0.45, 0.0, 2.95, 0.3, 0.05},
            Pose.pick(U32.is_eq(s, 6), Pose{0.7, 2.3, 0.0, 1.5, 0.0, 0.15, 0.0},
              Pose.pick(U32.is_eq(s, 7), Pose.flight(), Pose.rest())))))))

def Pose.strike(+s: U32) -> Pose:
  Pose.pick(U32.is_eq(s, 1), Pose{1.1, 1.6, 0.15, (0.0 - 0.45 : F32), 0.0, 0.3, 0.5},
    Pose.pick(U32.is_eq(s, 2), Pose{0.9, 1.05, (0.0 - 0.3 : F32), 0.05, (0.0 - 0.7 : F32), 0.55, 0.35},
      Pose.pick(U32.is_eq(s, 3), Pose{1.3, 2.1, 0.1, (0.0 - 0.42 : F32), 0.0, 0.3, 0.7},
        Pose.pick(U32.is_eq(s, 4), Pose.flight(),
          Pose.pick(U32.is_eq(s, 5),
            Pose{0.8, 1.3, (0.0 - 0.2 : F32), (0.0 - 0.12 : F32), (0.0 - 1.1 : F32), 0.5, 0.5},
            Pose.pick(U32.is_eq(s, 6),
              Pose{1.1, 1.0, (0.0 - 0.2 : F32), (0.0 - 0.15 : F32), (0.0 - 0.3 : F32), 0.5, 0.45},
              Pose.pick(U32.is_eq(s, 7), Pose{1.0, 1.2, 0.2, (0.0 - 0.6 : F32), 0.0, 0.55, 0.5},
                Pose.rest())))))))

# The pose of a state at an age: from rest to the wind-up key, to the
# strike key, back to rest, each eased; reeling when stunned.
def Boss.pose(+s: U32, +age: U32, +stun: U32) -> Pose:
  +a = U32.to_f32(age)
  +w = U32.to_f32(Boss.wind(s))
  +n = U32.to_f32(Boss.act(s))
  +kw = Pose.wind(s)
  +ks = Pose.strike(s)
  +pose = Pose.pick((a < w : F32), Pose.mix(Pose.rest(), kw, Math.smooth((a / w : F32))),
    Pose.pick((a < (w + n : F32) : F32), Pose.mix(kw, ks, Math.smooth(((a - w) / n : F32))),
      Pose.mix(ks, Pose.rest(), Math.smooth(((a - w - n) / U32.to_f32(Boss.rec(s)) : F32)))))
  Pose.mix(pose, Pose{0.1, 1.7, 0.4, (0.0 - 1.1 : F32), 0.6, 0.25, (0.0 - 0.45 : F32)},
    R.sat((U32.to_f32(stun) * 0.2 : F32)))

# A pose's grip, blade direction, spine (u from the hips, 0, to the
# head, 1) and the cloths' anchor, all local.
def Pose.grip(+k: Pose) -> R.Vec:
  Pose{gx, gy, gz, _, _, _, _} = k
  R.Vec{gx, gy, gz}

def Pose.dir(+k: Pose) -> R.Vec:
  Pose{_, _, _, th, yw, _, _} = k
  R.Vec{(F32.cos(th) * F32.cos(yw) : F32), F32.sin(th), (0.0 - F32.cos(th) * F32.sin(yw) : F32)}

def Pose.spine(+k: Pose, +u: F32) -> R.Vec:
  Pose{_, _, _, _, _, dip, lean} = k
  R.Vec{(lean * (0.25 + 0.75 * u) + 0.1 * u : F32), (1.75 + 1.75 * u - dip * (1.0 + 0.15 * u) : F32), 0.0}

def Pose.root(+k: Pose) -> R.Vec:
  Pose{_, _, _, _, _, dip, lean} = k
  R.Vec{(lean * 0.75 : F32), (0.0 - dip : F32), 0.0}

# A local point of the boss in the world; the blade's hilt and tip
# (3.1 along its direction); the cloths' anchor.
def Boss.at(+p: R.Vec, +face: F32, +local: R.Vec) -> R.Vec:
  R.Vec.add(p, R.Vec.turn(local, face))

def Boss.hilt(+p: R.Vec, +face: F32, +k: Pose) -> R.Vec:
  Boss.at(p, face, Pose.grip(k))

def Boss.tip(+p: R.Vec, +face: F32, +k: Pose) -> R.Vec:
  Boss.at(p, face, R.Vec.add(Pose.grip(k), R.Vec.scale(Pose.dir(k), 3.1)))

def Boss.hash(+t: U32) -> U32:
  ((((t + 7) * 2654435761 : U32) >> 13n : U32) .&. 255 : U32)

# The next attack: a leap at a hero in the air; up close a cleave,
# sweep or draw (a leap or a sweep at a guard); at mid range a lunge,
# leap or draw; none far off.
def Boss.choose(+gap: F32, +rise: F32, +act: U32, +seed: U32) -> U32:
  +r = (seed .&. 7 : U32)
  +near = (gap < 3.6 : F32)
  +mid = (gap < 7.0 : F32)
  R.word(((rise > 1.2 : F32) && mid), 4,
    R.word(near, R.word(U32.is_eq(act, 3), R.word((r < 4 : U32), 4, 2),
        R.word((r < 5 : U32), 1, R.word((r < 7 : U32), 2, 5))),
      R.word(mid, R.word((r < 3 : U32), 3, R.word((r < 5 : U32), 4, 5)), 0)))

# The boss a tick later. Stunned, it reels; a leap lands into the slam;
# a finished attack chains (enraged under 160: cleave to sweep, sweep
# to lunge) or stalks with a pause; a stalk past its pause, grounded
# and in range, picks an attack; the age runs twice as fast enraged.
def Boss.tick(+b: Boss, +f: Fighter, +t: U32) -> Boss:
  Boss{p, v, face, hp, stun, strain, state, age, hold, mark, _} = b
  R.Vec{x, y, _} = p
  R.Vec{vx, vy, _} = v
  Fighter{q, _, _, _, _, _, action, _, _, _, _, _, _} = f
  R.Vec{hx, hy, _} = q
  +raging = (hp < 160.0 : F32)
  +step = R.word(raging, 2, 1)
  +stunned = ((stun > 0 : U32) || (hp <= 0.0 : F32))
  +air = Fighter.air(p, v)
  +dx = (hx - x : F32)
  +dist = F32.abs(dx)
  +seed = Boss.hash(t)
  +done = ((state > 0 : U32) && ((age + step : U32) >= (Boss.wind(state) + Boss.act(state)
    + Boss.rec(state) : U32) : U32))
  +landed = (U32.is_eq(state, 4) && (age > 14 : U32) && Bool.not(air))
  +ready = (U32.is_eq(state, 0) && (age >= hold : U32) && Bool.not(stunned) && Bool.not(air))
  +chain = R.word((raging && U32.is_eq(state, 1)), 2, R.word((raging && U32.is_eq(state, 2)), 3, 0))
  +s2 = R.word(stunned, 0, R.word(landed, 7, R.word(done, chain,
    R.word(ready, Boss.choose(dist, (hy - y : F32), action, seed), state))))
  +fresh = Bool.not(U32.is_eq(s2, state))
  +age2 = R.word(fresh, 0, (age + R.word(U32.is_eq(state, 0), 1, step) : U32))
  +hold2 = R.word((fresh && U32.is_eq(s2, 0)), (14 + (seed .&. 15) : U32), hold)
  +mark2 = R.pick((fresh && U32.is_eq(s2, 4)), R.clamp(hx, (0.0 - 6.5 : F32), 6.5), mark)
  +toward = R.pick((dx < 0.0 : F32), (0.0 - 1.0 : F32), 1.0)
  +walking = (U32.is_eq(s2, 0) && (age2 >= hold2 : U32) && Bool.not(stunned) && Bool.not(air))
  +walk = R.pick(walking, (toward * R.pick((dist > 3.5 : F32), 0.05,
    R.pick((dist < 2.7 : F32), (0.0 - 0.03 : F32), 0.0)) : F32), 0.0)
  +lunging = (U32.is_eq(s2, 3) && Boss.live(3, age2))
  +dash = R.pick(lunging, (F32.cos(face) * 0.6 : F32), 0.0)
  +leap = (U32.is_eq(s2, 4) && (age < 12 : U32) && (age2 >= 12 : U32))
  +vx2 = R.pick(leap, ((mark2 - x) / 11.8 : F32), vx)
  +vy2 = R.pick(leap, 0.34, vy)
  +lim = R.pick((lunging || U32.is_eq(s2, 4)), 7.0, 6.0)
  +next = {R.Vec{(R.clamp((x + walk + dash : F32), (0.0 - lim : F32), lim) + vx2 : F32),
    (y + vy2 : F32), 0.0} : R.Vec}
  +floor = Stage.landing(next, y, False{})
  +ground = (floor > (0.0 - 99.0 : F32) : F32)
  +pos = Vec.place(next, floor, ground)
  Boss{pos, R.Vec{(vx2 * 0.92 : F32), R.pick(ground, 0.0, R.max((0.0 - 0.65 : F32),
      (vy2 - 0.02 : F32))), 0.0},
    R.pick((U32.is_eq(s2, 0) && Bool.not(stunned)), Vec.facing(R.Vec{dx, 0.0, 0.0}), face),
    R.pick(Vec.out(pos), 0.0, hp), Sim.dec(stun), strain, s2, age2, hold2, mark2,
    (walk + dash : F32)}

# Does the boss's blade (live, within 0.7 of the hero's chest) or its
# slam (the hero grounded within 2.5 in its first 6 ticks) strike him?
# Not while invulnerable, stunned or dead.
def Boss.contact(+f: Fighter, +b: Boss) -> Bool:
  Fighter{q, _, _, _, _, _, _, _, inv, _, _, _, _} = f
  Boss{p, _, face, hp, stun, _, state, age, _, _, _} = b
  +k = Boss.pose(state, age, stun)
  +blade = (Boss.live(state, age) && (Vec.seg(R.Vec.add(q, R.Vec{0.0, 0.75, 0.0}),
    Vec.plane(Boss.hilt(p, face, k)), Vec.plane(Boss.tip(p, face, k))) < 0.7 : F32))
  +ring = (U32.is_eq(state, 7) && (age < 6 : U32) && (F32.abs((Vec.x(q) - Vec.x(p) : F32)) < 2.5 : F32)
    && ((Vec.y(q) - Vec.y(p) : F32) < 0.6 : F32))
  ((blade || ring) && U32.is_eq(inv, 0) && U32.is_eq(stun, 0) && (hp > 0.0 : F32))

# Does the strike a..b touch the boss's hips (0.75), chest (0.8), head
# (0.62), shins (0.6), hands (0.45) or forearms (0.4)? The sword is no
# hurtbox.
def Boss.touch(+b: Boss, +a: R.Vec, +tip: R.Vec) -> Bool:
  Boss{p, _, face, _, stun, _, state, age, _, _, _} = b
  +k = Boss.pose(state, age, stun)
  +chest = Boss.at(p, face, Pose.spine(k, 0.57))
  +grip = Boss.hilt(p, face, k)
  ((Vec.seg(Boss.at(p, face, Pose.spine(k, 0.0)), a, tip) < 0.75 : F32)
    || (Vec.seg(chest, a, tip) < 0.8 : F32)
    || (Vec.seg(Boss.at(p, face, Pose.spine(k, 1.0)), a, tip) < 0.62 : F32)
    || (Vec.seg(R.Vec.add(p, R.Vec{0.0, 0.6, 0.0}), a, tip) < 0.6 : F32)
    || (Vec.seg(grip, a, tip) < 0.45 : F32)
    || (Vec.seg(R.Vec.mix(chest, grip, 0.5), a, tip) < 0.4 : F32))

# The strike lands on its hit tick when the blade's segment (reach
# 2.15, 2.7 a side, 3.8 a special) touches the boss or a radial attack
# reaches its waist.
def Fighter.strike(+f: Fighter, +b: Boss) -> F32:
  Fighter{p, _, face, _, _, _, action, age, _, _, _, _, charge} = f
  Boss{q, _, _, _, _, _, _, _, _, _, _} = b
  +up = Act.up(action)
  +down = Act.down(action)
  +special = Act.special(action)
  +dx = (F32.cos(face) * R.pick((up || down), 0.3,
    R.pick(U32.is_eq(action, 15), (0.0 - 1.0 : F32), 1.0)) : F32)
  +dy = R.pick(up, 1.0, R.pick(down, (0.0 - 1.0 : F32), 0.1))
  +origin = R.Vec.add(p, R.Vec{0.0, 0.75, 0.0})
  +reach = R.pick(special, 3.8, R.pick(U32.is_eq(action, 10), 2.7, 2.15))
  +tip = R.Vec.add(origin, R.Vec.scale(R.Vec{dx, dy, 0.0}, reach))
  +near = (Boss.touch(b, origin, tip) || (Act.is(action, 13, 2, 23, 22)
    && (Vec.dist(origin, R.Vec.add(q, R.Vec{0.0, 1.6, 0.0})) < reach : F32)))
  +power = R.pick(special, R.pick(down, 32.0, 26.0),
    R.pick(down, 18.0, R.pick(up, 15.0, 13.0)))
  R.pick((Act.attack(action) && U32.is_eq(age, Act.hit(action)) && near),
    (power * Act.power(charge) : F32), 0.0)

# A down air that hits bounces the hero and gives a jump back.
def Fighter.pogo(+f: Fighter, +hit: F32) -> Fighter:
  Fighter{p, v, face, damage, guard, jumps, action, age, inv, stocks, grace, queued, charge} = f
  +bounce = ((hit > 0.0 : F32) && U32.is_eq(action, 17))
  Fighter{p, R.Vec.mix(v, R.Vec{0.0, 0.39, 0.0}, R.pick(bounce, 1.0, 0.0)), face, damage, guard,
    R.word(bounce, 1, jumps), action, age, inv, stocks, grace, queued, charge}

# Struck by the boss: launched by his damage and the attack (hurt 23
# ticks, invulnerable 48), or, guarding over 24, nudged (guard -24,
# none on a parry; invulnerable 24).
def Fighter.impact(hit: Bool, +f: Fighter, +b: Boss) -> Fighter:
  match hit:
    case False{}:
      f
    case True{}:
      Fighter{p, _, face, damage, guard, jumps, action, age, _, stocks, grace, queued, charge} = f
      Boss{q, _, _, _, _, strain, state, _, _, _, _} = b
      +block = (U32.is_eq(action, 3) && (guard > 24.0 : F32))
      +parry = (block && (age <= 6 : U32))
      # The state's knockback (its scale over 10) and its damage.
      +power = R.pick(block, 0.07, ((0.22 + damage * 0.0035)
        * (U32.to_f32(Boss.tab(state, 10, 10, 8, 10, 13, 15, 8, 13)) * 0.1 : F32) : F32))
      +launch = R.Vec.add(R.Vec.scale(Vec.dir(q, p), power), R.Vec{0.0, R.pick(block, 0.03, 0.29), 0.0})
      Fighter{p, launch, face,
        (damage + R.pick(block, 0.0, U32.to_f32(Boss.tab(state, 0, 17, 12, 14, 20, 24, 12, 20))) : F32),
        R.max(0.0, (guard - R.pick(parry, 0.0, 24.0) : F32)), jumps,
        R.word(block, action, 4), R.word(block, age, 23), R.word(block, 24, 48), stocks,
        grace, queued, charge}

# The boss struck for an amount, parried (struck in the guard's first
# 6 ticks, guard over 24) or blocking: its vitality falls, it is
# stunned, launched and strained; a block starts the counter.
def Boss.hurt(+b: Boss, +amount: F32, +struck: Bool, +block: Bool, +f: Fighter) -> Boss:
  Boss{p, v, face, hp, stun, strain, state, age, hold, mark, gait} = b
  Fighter{q, _, _, _, guard, _, action, hage, _, _, _, _, charge} = f
  +parry = (struck && U32.is_eq(action, 3) && (hage <= 6 : U32) && (guard > 24.0 : F32))
  +hit = ((amount > 0.0 : F32) || parry)
  +power = ((0.11 + strain * 0.0016) * Act.power(charge)
    * R.pick(Act.special(action), 1.4, 1.0) : F32)
  +lift = R.pick(Act.up(action), 0.85, R.pick(Act.down(action), (0.0 - 0.65 : F32), 0.40))
  +launch = R.Vec.add(R.Vec.scale(Vec.dir(q, p), power), R.Vec{0.0, (lift * power : F32), 0.0})
  +daze = R.word(parry, 65, R.word(hit, (10 + F32.to_u32((power * 32.0 : F32)) : U32), stun))
  Boss{p, R.Vec.mix(v, launch, R.pick(hit, 1.0, 0.0)), face,
    R.max(0.0, (hp - amount - R.pick(parry, 22.0, 0.0) : F32)), daze,
    (strain + amount * 0.85 + R.pick(parry, 18.0, 0.0) : F32),
    R.word(hit, 0, R.word(block, 6, state)), R.word((hit || block), 0, age),
    R.word(hit, (daze + 15 : U32), hold), mark, gait}

# Does the boss block: in its stalk past its pause, not stunned, three
# times in eight?
def Boss.blocks(+b: Boss, +amount: F32, +t: U32) -> Bool:
  Boss{_, _, _, _, stun, _, state, age, hold, _, _} = b
  ((amount > 0.0 : F32) && U32.is_eq(state, 0) && U32.is_eq(stun, 0) && (age >= hold : U32)
    && ((Boss.hash(t) .&. 7 : U32) < 3 : U32))

def Fighter.out(+f: Fighter) -> Bool:
  Fighter{p, _, _, _, _, _, _, _, _, _, _, _, _} = f
  Vec.out(p)

def Boss.dead(+b: Boss) -> Bool:
  Boss{_, _, _, hp, _, _, _, _, _, _, _} = b
  (hp <= 0.0 : F32)

# A life spent: a respawn at (-2.8, 4) invulnerable 120 ticks, or, on
# the last, dead where he fell.
def Fighter.spend(more: Bool, +f: Fighter) -> Fighter:
  match more:
    case True{}:
      Fighter{p, v, face, damage, guard, jumps, action, age, inv, stocks, grace, queued, charge} = f
      Fighter.spawn(R.Vec{(0.0 - 2.8 : F32), 4.0, 0.0}, (stocks - 1 : U32), 120)
    case False{}:
      Fighter{p, v, face, damage, guard, jumps, action, age, inv, _, grace, queued, charge} = f
      Fighter{p, v, face, damage, guard, jumps, action, age, inv, 0, grace, queued, charge}

def Fighter.life(out: Bool, +f: Fighter) -> Fighter:
  match out:
    case False{}:
      f
    case True{}:
      Fighter{_, _, _, _, _, _, _, _, _, stocks, _, _, _} = f
      Fighter.spend((stocks > 1 : U32), f)

# The hero at rest after a win or a loss.
def Fighter.rest(done: Bool, +f: Fighter) -> Fighter:
  match done:
    case False{}:
      f
    case True{}:
      Fighter{p, _, face, damage, guard, jumps, _, _, _, stocks, grace, queued, charge} = f
      Fighter{p, R.Vec{0.0, 0.0, 0.0}, face, damage, guard, jumps, 0, 0, 0, stocks, grace, queued, charge}

# The cape after a tick: kept (paused), seeded at the hero (a
# respawn), or stepped about his shoulders, lowered in a crouch.
def Game.cape(keep: Bool, reset: Bool, cloth: R.Cloth, +f: Fighter, +time: U32) -> R.Cloth:
  match keep reset:
    case True{} _:
      cloth
    case False{} True{}:
      Fighter{p, v, face, damage, guard, jumps, action, age, inv, stocks, grace, queued, charge} = f
      R.Cloth.seed(3n, 0, Fit.cape(), p, face)
    case False{} False{}:
      Fighter{p, _, face, _, _, _, action, _, _, _, _, _, _} = f
      R.Cloth.step(~Stage.wind, cloth, Fit.cape(), p, face, U32.to_f32(time), (Act.crouch(action) * 0.3 : F32))

# The boss's cloths after a tick: kept (paused), or stepped about its
# anchor.
def Game.garb(keep: Bool, +g: Garb, +b: Boss, +time: U32) -> Garb:
  match keep:
    case True{}:
      g
    case False{}:
      Boss{p, _, face, _, stun, _, state, age, _, _, _} = b
      Garb.step(g, Boss.at(p, face, Pose.root(Boss.pose(state, age, stun))), face, U32.to_f32(time))

# The lens after the hero and the boss (the hero alone once the boss
# is dead).
def Game.follow(+l: Lens, +f: Fighter, +b: Boss) -> Lens:
  Fighter{p, v, face, _, _, _, _, _, _, _, _, _, _} = f
  R.Vec{px, py, _} = p
  R.Vec{vx, vy, _} = v
  Boss{q, _, yaw, hp, _, _, _, _, _, _, _} = b
  R.Vec{bx, by, _} = q
  +dead = (hp <= 0.0 : F32)
  Lens.follow(l, px, py, vx, vy, R.pick(dead, px, bx), R.pick(dead, py, by),
    R.pick(dead, face, yaw))

# The detonation after a tick: the hero's where he fell out, the
# boss's where it died, else the last.
def Game.blast(
  out: Bool, killed: Bool, old: Maybe<&2, Blast>, +f: Fighter, +b: Boss, +time: U32
) -> Maybe<&2, Blast>:
  match out killed:
    case True{} _:
      Fighter{p, v, face, _, _, _, _, age, _, _, _, _, _} = f
      R.Vec{x, y, z} = p
      Some{Blast{x, y, time, 1}}
    case False{} True{}:
      Boss{p, _, _, _, _, _, _, _, _, _, _} = b
      R.Vec{x, y, _} = p
      Some{Blast{x, y, time, 2}}
    case False{} False{}:
      old

# The mode after a tick: 3 with the hero's lives out, 2 with the boss's
# vitality once its detonation (42 ticks) is over, else 1.
def Game.outcome(+f: Fighter, +b: Boss, blast: Maybe<&2, Blast>, +time: U32) -> U32:
  Fighter{_, _, _, _, _, _, _, _, _, stocks, _, _, _} = f
  Boss{_, _, _, hp, _, _, _, _, _, _, _} = b
  R.word(U32.is_eq(stocks, 0), 3, R.word(((hp <= 0.0 : F32) && Blast.over(blast, time)), 2, 1))

# A tick of the fight: both move, the boss's hit and the hero's strike
# land (or the boss blocks), the hero is launched (or pogos), falls
# out and respawns, the boss is hurt; a death detonates; a hit flashes
# 7; the cloths, the lens.
def Game.fight(+g: Game) -> Game:
  Game{time, held, taps, _, hero, boss, flash, cloth, garb, lens, blast} = g
  +p = Fighter.tick(hero, held, taps)
  +b = Boss.tick(boss, p, time)
  +hit = Boss.contact(p, b)
  +raw = Fighter.strike(p, b)
  +blocked = Boss.blocks(b, raw, time)
  +dmg = R.pick(blocked, 0.0, raw)
  +hurt = Fighter.pogo(Fighter.impact(hit, p, b), dmg)
  +out = Fighter.out(hurt)
  +next = Fighter.life(out, hurt)
  +enemy = Boss.hurt(b, dmg, hit, blocked, p)
  +boom = Game.blast(out, (Boss.dead(enemy) && Bool.not(Boss.dead(boss))), blast, hurt, enemy,
    time)
  Game{(time + 1 : U32), held, 0, Game.outcome(next, enemy, boom, (time + 1 : U32)), next,
    enemy, R.word((hit || blocked || (dmg > 0.0 : F32)), 7, Sim.dec(flash)),
    Game.cape(False{}, out, cloth, next, time), Game.garb(False{}, garb, enemy, time),
    Game.follow(lens, next, enemy), boom}

# A tick out of the fight: the time runs and the cape settles unless
# paused, the hero rests after a win or a loss, the flash fades.
def Game.rest(+g: Game) -> Game:
  Game{time, held, taps, mode, hero, boss, flash, cloth, garb, lens, blast} = g
  +paused = U32.is_eq(mode, 4)
  Game{R.word(paused, time, (time + 1 : U32)), held, 0, mode,
    Fighter.rest((U32.is_eq(mode, 2) || U32.is_eq(mode, 3)), hero), boss, Sim.dec(flash),
    Game.cape(paused, False{}, cloth, hero, time), Game.garb(paused, garb, boss, time), lens,
    blast}

# The mode toggled by P: a pause (4) resumes the fight (1), the fight
# pauses, any other mode stays; paused and fighting are the mode's
# tests, taken apart so LAWS.bend can split on them.
def Mode.toggle.go(paused: Bool, fighting: Bool, +mode: U32) -> U32:
  R.word(paused, 1, R.word(fighting, 4, mode))

def Mode.toggle(+mode: U32) -> U32:
  Mode.toggle.go(U32.is_eq(mode, 4), U32.is_eq(mode, 1), mode)

def Game.pause(+g: Game) -> Game:
  Game{time, held, _, mode, hero, boss, flash, cloth, garb, lens, blast} = g
  Game{time, held, 0, Mode.toggle(mode), hero, boss, flash, cloth, garb, lens, blast}

# K past the fight goes back to the title; R, or L outside the fight
# and the pause, starts a fresh fight; P (or L in a pause) toggles the
# pause; the fight runs, holds in hitstop, or rests.
def Game.route(back: Bool, fresh: Bool, pause: Bool, live: Bool, frozen: Bool, +g: Game) -> Game:
  match back fresh pause live frozen:
    case True{} _ _ _ _:
      Game.init()
    case False{} True{} _ _ _:
      Game{_, held, _, _, _, _, _, _, _, _, _} = g
      Game.fresh(held, 1)
    case False{} False{} True{} _ _:
      Game.pause(g)
    case False{} False{} False{} True{} False{}:
      Game.fight(g)
    case False{} False{} False{} True{} True{}:
      Game{time, held, taps, mode, hero, boss, flash, cloth, garb, lens, blast} = g
      Game{(time + 1 : U32), held, taps, mode, hero, boss, Sim.dec(flash), cloth, garb, lens, blast}
    case False{} False{} False{} False{} _:
      Game.rest(g)

def Game.step(+g: Game) -> Game:
  Game{_, _, taps, mode, _, _, flash, _, _, _, _} = g
  Game.route((Sim.has(taps, 32) && (mode >= 2 : U32)),
    (Sim.has(taps, 512) || (Sim.has(taps, 128) && Bool.not(U32.is_eq(mode, 1))
      && Bool.not(U32.is_eq(mode, 4)))),
    (Sim.has(taps, 1024) || (U32.is_eq(mode, 4) && Sim.has(taps, 128))), U32.is_eq(mode, 1),
    (flash >= 6 : U32), g)

# Spec
# ----
# What LAWS.bend measures: n ticks of the game (as the loop's
# Live.steps runs them), n fades of a countdown, and a frame's events
# joined.

def Game.steps(n: Nat, +g: Game) -> Game:
  match n:
    case 0n:
      g
    case 1n+k:
      Game.steps(k, Game.step(g))

def Sim.fade(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+k:
      Sim.fade(k, Sim.dec(x))

def Game.cat(a: List<Event>, b: List<Event>) -> List<Event>:
  match a:
    case Nil{}:
      b
    case e <> rest:
      e <> Game.cat(rest, b)

# Hero
# ----

# The blade's angle: a swing over the attack's progress (raised for
# an upward attack, straight down for a downward one, reversed for a
# back air), 2.2 charging, -0.32 at rest.
def Hero.angle(+act: U32, +age: U32) -> F32:
  +len = U32.to_f32(Act.length(act))
  +u = R.sat(((len - U32.to_f32(age)) / len : F32))
  +swing = R.mix(1.8, (0.0 - 0.8 : F32), Math.smooth((u * 2.5 : F32)))
  R.pick(Act.in(act, 30, 32), 2.2, R.pick(Act.attack(act),
    R.pick(Act.up(act), (swing + 1.25 : F32), R.pick(Act.down(act),
      (0.0 - 1.57 : F32), R.pick(U32.is_eq(act, 15), (swing + 3.14 : F32), swing))),
    (0.0 - 0.32 : F32)))

# A part of the hero: a surface in his frame, turned to his facing at
# his feet.
def Hero.part(
  s: R.Surf, +mat: R.Mat, +nu: U32, +nv: U32, +at: R.Vec, +face: F32, +view: View
) -> R.Cells:
  Mesh.of(R.Surf.turn(s, at, face), mat, nu, nv, view)

# A leg: hip to knee to foot, swung by the stride, lifted in the air,
# folded in a crouch, tucked in a dodge; a bead at the knee and foot.
def Hero.leg(
  +stride: F32, +side: F32, +air: F32, +crouch: F32, +dodge: F32, +at: R.Vec,
  +face: F32, +view: View
) -> R.Cells:
  +hip = {R.Vec{0.0, (0.69 - crouch * 0.28 : F32), (side * 0.10 : F32)} : R.Vec}
  +knee = {R.Vec{(stride * 0.45 + air * 0.15 + crouch * 0.20 : F32),
    (0.39 + F32.abs(stride) * 0.20 + air * 0.15 - crouch * 0.12 + dodge * 0.16 : F32),
    (side * 0.13 : F32)} : R.Vec}
  +foot = {R.Vec{(stride - air * side * 0.18 - crouch * 0.12 : F32),
    (0.045 + R.max(0.0, (stride * side : F32)) * 0.4 + air * 0.17 + dodge * 0.36 : F32),
    (side * 0.14 : F32)} : R.Vec}
  a b c d = Hero.part(R.Inst.span(R.Tube{}, hip, knee, 0.062, 0.062), Mat.bone(2039592),
      8, 2, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, knee, foot, 0.043, 0.043), Mat.bone(3226700), 8, 2,
      at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, knee, 0.066, 0.060, 0.060), Mat.bead(1320230, 0.0),
      8, 4, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec.add(foot, R.Vec{0.04, 0.0, 0.0}), 0.12, 0.044,
      0.052), Mat.bead(1519151, 0.0), 8, 4, at, face, view)
  R.Cells.m4(a, b, c, d)

# A horn of the crown on a side of the mask at (hx, hy).
def Hero.horn(
  +side: F32, +hx: F32, +hy: F32, +shell: R.Mat, +at: R.Vec, +face: F32, +view: View
) -> R.Cells:
  Hero.part(R.Inst.span(R.Own{2, 0.0}, R.Vec{(hx + side * 0.17 : F32), (hy + 0.13 : F32), 0.0},
    R.Vec{(hx + side * 0.24 : F32), (hy + 0.62 : F32), 0.0}, 0.60, 0.55), shell, 8, 4,
    at, face, view)

# The mask (white, or flashing) at (hx, hy), its horns, its chin, the
# eyes on the side seen.
def Hero.head(
  +hx: F32, +hy: F32, +white: U32, +at: R.Vec, +face: F32, +view: View
) -> R.Cells:
  +shell = Mat.paint(white, 0.46, 0.02, 0.0)
  +side = R.pick((F32.cos(face) >= 0.0 : F32), 0.184, (0.0 - 0.184 : F32))
  a b c d e f = Hero.part(R.Inst.ball(R.Globe{}, R.Vec{hx, hy, 0.0}, 0.235, 0.28, 0.21), shell,
      16, 8, at, face, view)
    Hero.horn(1.0, hx, hy, shell, at, face, view)
    Hero.horn((0.0 - 1.0 : F32), hx, hy, shell, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec{hx, (hy - 0.20 : F32), 0.0}, 0.13, 0.13, 0.13),
      shell, 8, 4, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec{(hx + 0.087 : F32), (hy + 0.014 : F32), side}, 0.044,
      0.082, 0.024), Mat.bead(593179, 0.0), 8, 4, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec{(hx - 0.087 : F32), (hy + 0.014 : F32), side}, 0.044,
      0.082, 0.024), Mat.bead(593179, 0.0), 8, 4, at, face, view)
  R.Cells.merge(R.Cells.m4(a, b, c, d), R.Cells.merge(e, f))

# The arm to the hand, the blade from the hand at its angle (glowing
# when charged), the hand's bead, the grip behind it.
def Hero.blade(
  +lean: F32, +crouch: F32, +theta: F32, +white: U32, +charge: U32, +at: R.Vec,
  +face: F32, +view: View
) -> R.Cells:
  +ct = F32.cos(theta)
  +st = F32.sin(theta)
  +hand = {R.Vec{(0.22 + ct * 0.16 : F32), (0.92 + st * 0.14 - crouch * 0.3 : F32), 0.24} : R.Vec}
  +hot = (charge > 10 : U32)
  a b c d = Hero.part(R.Inst.span(R.Tube{}, R.Vec{lean, (1.02 - crouch * 0.30 : F32), 0.12},
      hand, 0.045, 0.045), Mat.bone(1185307), 8, 2, at, face, view)
    Hero.part(R.Inst.span(R.Own{3, 0.0}, hand, R.Vec.add(hand, R.Vec{(ct * 1.65 : F32),
      (st * 1.65 : F32), 0.0}), 0.62, 0.6), Mat.paint(R.word(hot, 16768443, 15071203),
      0.16, 0.88, R.pick(hot, 0.18, 0.0)), 8, 8, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, hand, 0.061, 0.064, 0.050), Mat.bead(white, 0.0), 8, 4,
      at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, R.Vec.sub(hand, R.Vec{(ct * 0.18 : F32), (st * 0.18 : F32),
      0.0}), hand, 0.032, 0.032), Mat.bone(6774368), 8, 2, at, face, view)
  R.Cells.m4(a, b, c, d)

# The hero at a time: body and mask over the legs (a run cycle by his
# speed), leaning into his motion, the blade, his shadow.
def Hero.build(+f: Fighter, +t: F32, +view: View) -> R.Cells:
  Fighter{p, v, face, _, _, _, act, age, inv, _, _, _, charge} = f
  R.Vec{x, y, _} = p
  R.Vec{vx, _, _} = v
  +air = R.pick(Fighter.air(p, v), 1.0, 0.0)
  +crouch = Act.crouch(act)
  +dodge = R.pick(U32.is_eq(act, 6), 1.0, 0.0)
  +run = (F32.sin((t * 0.28 : F32)) * R.min(1.0, (F32.abs(vx) * 5.0 : F32)) * 0.38
    * (1.0 - air) : F32)
  +lean = (vx * F32.cos(face) * 0.26 + crouch * 0.07 : F32)
  +white = R.word(((inv > 0) && ((inv .&. 4) > 0) : U32), 13036021, 15790567)
  b a c d e g = Hero.head(lean, (1.34 - crouch * 0.30 + F32.abs(run) * 0.04 : F32), white, p,
      face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec{lean, (0.88 - crouch * 0.30 : F32), 0.0}, 0.13, 0.30, 0.115),
      Mat.paint(987159, 0.6, 0.0, 0.0), 12, 8, p, face, view)
    Hero.leg(run, 1.0, air, crouch, dodge, p, face, view)
    Hero.leg((0.0 - run : F32), (0.0 - 1.0 : F32), air, crouch, dodge, p, face, view)
    Hero.blade(lean, crouch, Hero.angle(act, age), white, charge, p, face, view)
    Shadow.build(x, y, 0.70, view)
  R.Cells.merge(R.Cells.m4(a, b, c, d), R.Cells.merge(e, g))

# Boss
# ----

# The boss's cloth (blue-black), its bone (the mask), its steel.
def Boss.cloth() -> R.Mat:
  Mat.paint(922660, 0.85, 0.0, 0.0)

# A leg: hip to knee to foot, swung by the stride, lifted in the air,
# folded by the dip.
def Boss.leg(
  +stride: F32, +side: F32, +air: F32, +dip: F32, +at: R.Vec, +face: F32, +view: View
) -> R.Cells:
  +hip = {R.Vec{0.05, (1.75 - dip : F32), (side * 0.30 : F32)} : R.Vec}
  +knee = {R.Vec{(stride * 0.9 + air * 0.3 + dip * 0.55 : F32),
    (0.92 + F32.abs(stride) * 0.25 + air * 0.35 - dip * 0.45 : F32), (side * 0.34 : F32)} : R.Vec}
  +foot = {R.Vec{(stride * 1.5 - air * side * 0.3 - dip * 0.2 : F32),
    (0.1 + R.max(0.0, (stride * side : F32)) * 0.7 + air * 0.4 : F32), (side * 0.36 : F32)} : R.Vec}
  a b c = Hero.part(R.Inst.span(R.Tube{}, hip, knee, 0.17, 0.17), Boss.cloth(), 8, 2, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, knee, foot, 0.13, 0.13), Boss.cloth(), 8, 2, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec.add(foot, R.Vec{0.14, 0.0, 0.0}), 0.30, 0.09, 0.14),
      Mat.bone(1778496), 8, 4, at, face, view)
  R.Cells.merge(a, R.Cells.merge(b, c))

# An arm from the shoulder (a ball) to the hand, bent at the elbow
# (out of the line, in the combat plane; 0.95 a bone).
def Boss.arm(+shoulder: R.Vec, +hand: R.Vec, +at: R.Vec, +face: F32, +view: View) -> R.Cells:
  +span = R.Vec.sub(hand, shoulder)
  +half = (R.Vec.len(span) * 0.5 : F32)
  +elbow = R.Vec.add(R.Vec.mix(shoulder, hand, 0.5), R.Vec.scale(R.Vec.unit(R.Vec.cross(span, R.Vec{0.0, 0.0, 1.0})),
    F32.sqrt(R.max(0.0, (0.9025 - half * half : F32)))))
  a b c d = Hero.part(R.Inst.span(R.Tube{}, shoulder, elbow, 0.14, 0.14), Boss.cloth(), 8, 2, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, elbow, hand, 0.11, 0.11), Boss.cloth(), 8, 2, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, shoulder, 0.27, 0.24, 0.27), Boss.cloth(), 8, 4, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, hand, 0.13, 0.11, 0.11), Mat.bone(1778496), 8, 4, at, face, view)
  R.Cells.m4(a, b, c, d)

# The katana at the grip g along d: the blade (3.1, curving to its
# right), the glowing edge (two tubes), the guard, the hilt, the
# pommel.
def Boss.sword(+g: R.Vec, +d: R.Vec, +at: R.Vec, +face: F32, +view: View) -> R.Cells:
  +right = R.Vec.unit(R.Vec.cross(d, R.Vec{0.002, 0.0, 1.0}))
  +tip = R.Vec.add(g, R.Vec.scale(d, 3.1))
  +mid = R.Vec.add(g, R.Vec.scale(d, 1.6))
  +edge = Mat.paint(10352639, 0.3, 0.0, 1.4)
  +root = R.Vec.add(R.Vec.add(g, R.Vec.scale(d, 0.2)), R.Vec.scale(right, (0.0 - 0.09 : F32)))
  +point = R.Vec.add(R.Vec.add(tip, R.Vec.scale(d, (0.0 - 0.08 : F32))), R.Vec.scale(right, 0.27))
  a b c dd e f = Hero.part(R.Inst.span(R.Own{3, 0.0}, g, tip, 1.5, 1.5), Mat.paint(13161184, 0.18, 0.9, 0.0),
      8, 8, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, root, mid, 0.022, 0.022), edge, 4, 1, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, mid, point, 0.022, 0.022), edge, 4, 1, at, face, view)
    Hero.part(R.Inst{R.Globe{}, g, R.Vec.scale(right, 0.24), R.Vec.scale(d, 0.035),
      R.Vec.scale(R.Vec.cross(d, right), 0.24)}, Mat.paint(1778496, 0.4, 0.6, 0.0), 8, 4, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, R.Vec.sub(g, R.Vec.scale(d, 0.62)), g, 0.055, 0.055),
      Mat.paint(1778496, 0.6, 0.2, 0.0), 6, 1, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec.sub(g, R.Vec.scale(d, 0.62)), 0.075, 0.075, 0.075),
      Mat.paint(13161184, 0.3, 0.8, 0.0), 6, 3, at, face, view)
  R.Cells.merge(R.Cells.m4(a, b, c, dd), R.Cells.merge(e, f))

# A point on the mask (an ellipsoid of 0.42, 0.46, 0.34 about the
# head, 0.05 ahead) at (x, y) on its side z, lifted by h.
def Boss.mask(+head: R.Vec, +x: F32, +y: F32, +z: F32, +h: F32) -> R.Vec:
  R.Vec.add(head, R.Vec{(x + 0.05 : F32), y, (z * ((0.34 + h) * F32.sqrt(R.max(0.0,
    (1.0 - (x * x) / 0.1764 - (y * y) / 0.2116 : F32))) : F32) : F32)})

# The head: the hood (dark, behind and over), the pale mask, a crack
# down the side seen (two dark threads), a glowing slit eye each side
# (red enraged).
def Boss.head(+head: R.Vec, +hot: Bool, +at: R.Vec, +face: F32, +view: View) -> R.Cells:
  +eye = Mat.paint(R.word(hot, 16726560, 2152703), 0.3, 0.0, 3.0)
  +dark = Mat.paint(659473, 0.9, 0.0, 0.0)
  +side = R.pick((F32.cos(face) >= 0.0 : F32), 1.0, (0.0 - 1.0 : F32))
  +top = Boss.mask(head, 0.06, 0.40, side, 0.01)
  +knot = Boss.mask(head, (0.0 - 0.02 : F32), 0.04, side, 0.01)
  +chin = Boss.mask(head, 0.16, (0.0 - 0.26 : F32), side, 0.01)
  a b c d e f = Hero.part(R.Inst.ball(R.Globe{}, R.Vec.add(head, R.Vec{(0.0 - 0.32 : F32), 0.14, 0.0}),
      0.52, 0.58, 0.50), dark, 10, 5, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, R.Vec.add(head, R.Vec{0.05, 0.0, 0.0}), 0.42, 0.46, 0.34),
      Mat.paint(15131350, 0.42, 0.05, 0.0), 12, 8, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, top, knot, 0.016, 0.016), dark, 4, 1, at, face, view)
    Hero.part(R.Inst.span(R.Tube{}, knot, chin, 0.016, 0.016), dark, 4, 1, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, Boss.mask(head, 0.2, 0.1, 1.0, 0.0), 0.17, 0.065, 0.05),
      eye, 6, 3, at, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, Boss.mask(head, 0.2, 0.1, (0.0 - 1.0 : F32), 0.0), 0.17,
      0.065, 0.05), eye, 6, 3, at, face, view)
  R.Cells.merge(R.Cells.m4(a, b, c, d), R.Cells.merge(e, f))

# Hips to chest, the chest, the hips, the neck.
def Boss.trunk(+hips: R.Vec, +chest: R.Vec, +head: R.Vec, +p: R.Vec, +face: F32, +view: View) -> R.Cells:
  a b c d = Hero.part(R.Inst.span(R.Tube{}, hips, chest, 0.36, 0.30), Boss.cloth(), 10, 2, p, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, chest, 0.46, 0.50, 0.38), Boss.cloth(), 10, 5, p, face, view)
    Hero.part(R.Inst.ball(R.Globe{}, hips, 0.38, 0.32, 0.32), Boss.cloth(), 10, 5, p, face, view)
    Hero.part(R.Inst.span(R.Tube{}, chest, head, 0.13, 0.13), Boss.cloth(), 6, 1, p, face, view)
  R.Cells.m4(a, b, c, d)

# The body at a pose: the trunk, the head, the legs (a stride, tucked
# in the air), the arms to the grip, the katana, the cloths, the
# shadow.
def Boss.body(
  +p: R.Vec, +face: F32, +k: Pose, +stride: F32, +air: F32, +hot: Bool, +garb: Garb, +view: View
) -> R.Cells:
  R.Vec{bx, by, _} = p
  Pose{_, _, _, _, _, dip, lean} = k
  +hips = Pose.spine(k, 0.0)
  +chest = Pose.spine(k, 0.57)
  +head = Pose.spine(k, 1.0)
  +grip = Pose.grip(k)
  +d = Pose.dir(k)
  +sy = (3.1 - dip * 1.12 : F32)
  +sx = (lean * 0.75 : F32)
  l a e f g h i j m = Garb.build(garb, view) Boss.trunk(hips, chest, head, p, face, view)
    Boss.head(head, hot, p, face, view)
    Boss.leg(stride, 1.0, air, dip, p, face, view)
    Boss.leg((0.0 - stride : F32), (0.0 - 1.0 : F32), air, dip, p, face, view)
    Boss.sword(grip, d, p, face, view)
    Boss.arm(R.Vec{sx, sy, 0.55}, R.Vec.add(grip, R.Vec{0.0, 0.0, 0.12}), p, face, view)
    Boss.arm(R.Vec{sx, sy, (0.0 - 0.55 : F32)},
      R.Vec.sub(grip, R.Vec.add(R.Vec.scale(d, 0.4), R.Vec{0.0, 0.0, 0.12})), p, face, view)
    Shadow.build(bx, by, 1.6, view)
  R.Cells.merge(a, R.Cells.merge(R.Cells.m4(e, f, g, h), R.Cells.m4(i, j, l, m)))

# The boss at a time: its pose by its state and age (reeling when
# stunned), a stride by its gait, its eyes red enraged; dead, its
# detonation stands for it.
def Boss.alive(dead: Bool, +b: Boss, +garb: Garb, +t: F32, +view: View) -> R.Cells:
  match dead:
    case True{}:
      R.CNil{}
    case False{}:
      Boss{p, v, face, hp, stun, _, state, age, _, _, gait} = b
      Boss.body(p, face, Boss.pose(state, age, stun),
        (F32.sin((t * 0.14 : F32)) * R.min(1.0, (F32.abs(gait) * 16.0 : F32)) * 0.55 : F32),
        R.pick(Fighter.air(p, v), 1.0, 0.0), (hp < 160.0 : F32), garb, view)

# View
# ----

# An angle u of the way from a to b, the short way round.
def Math.turn(+a: F32, +b: F32, +u: F32) -> F32:
  (a + F32.atan2(F32.sin((b - a : F32)), F32.cos((b - a : F32))) * u : F32)

# The hero u of the way between two ticks; snapped when a life was
# lost or he moved 2 or more (a respawn).
def Fighter.lerp(+a: Fighter, +b: Fighter, +u: F32) -> Fighter:
  Fighter{p0, v0, f0, _, _, _, _, _, _, s0, _, _, _} = a
  Fighter{p, v, face, damage, guard, jumps, action, age, inv, stocks, grace, queued, charge} = b
  +k = R.pick((U32.is_eq(s0, stocks) && (Vec.dist(p0, p) < 2.0 : F32)), u, 1.0)
  Fighter{R.Vec.mix(p0, p, k), R.Vec.mix(v0, v, k), Math.turn(f0, face, k), damage, guard, jumps,
    action, age, inv, stocks, grace, queued, charge}

def Boss.lerp(+a: Boss, +b: Boss, +u: F32) -> Boss:
  Boss{p0, _, f0, _, _, _, _, _, _, _, _} = a
  Boss{p, v, face, hp, stun, strain, state, age, hold, mark, gait} = b
  Boss{R.Vec.mix(p0, p, u), v, Math.turn(f0, face, u), hp, stun, strain, state, age, hold, mark, gait}

def Lens.lerp(+a: Lens, +b: Lens, +u: F32) -> Lens:
  Lens{x0, y0, w0, _, _, _} = a
  Lens{x, y, w, vx, vy, vw} = b
  Lens{R.mix(x0, x, u), R.mix(y0, y, u), R.mix(w0, w, u), vx, vy, vw}

def Fighter.at(+f: Fighter) -> R.Vec:
  Fighter{p, _, _, _, _, _, _, _, _, _, _, _, _} = f
  p

# The game u of the way from tick a to b for the view; the cape snaps
# when the hero moved 2 or more.
def Game.lerp(+a: Game, +b: Game, +u: F32) -> Game:
  Game{_, _, _, _, p0, b0, _, c0, r0, l0, _} = a
  Game{time, held, taps, mode, hero, boss, flash, cloth, garb, lens, blast} = b
  +snap = (Vec.dist(Fighter.at(p0), Fighter.at(hero)) >= 2.0 : F32)
  Game{time, held, taps, mode, Fighter.lerp(p0, hero, u), Boss.lerp(b0, boss, u), flash,
    R.Cloth.lerp(c0, cloth, R.pick(snap, 1.0, u)), Garb.lerp(r0, garb, u), Lens.lerp(l0, lens, u),
    blast}

# The view's clock: the tick and the way to the next, held in a pause.
def Game.clock(+g: Game, +u: F32) -> F32:
  Game{time, _, _, mode, _, _, _, _, _, _, _} = g
  R.pick(U32.is_eq(mode, 4), U32.to_f32(time),
    R.max(0.0, (U32.to_f32(time) - 1.0 + u : F32)))

# A point on a sphere of radius r at c toward s, and the nearer of two
# points to s.
def Vec.onto(+c: R.Vec, +r: F32, +s: R.Vec) -> R.Vec:
  R.Vec.mix(c, s, R.min(1.0, (r / R.max(0.001, Vec.dist(c, s)) : F32)))

def Vec.nearer(+a: R.Vec, +b: R.Vec, +s: R.Vec) -> R.Vec:
  R.Vec.mix(a, b, R.pick((Vec.dist(b, s) < Vec.dist(a, s) : F32), 1.0, 0.0))

# The contact point (the flash's light): the boss's chest or head
# nearest the hero's chest while he attacks, else the chest.
def Game.contact(+f: Fighter, +b: Boss) -> R.Vec:
  Fighter{p, _, _, _, guard, _, action, _, _, _, _, _, charge} = f
  Boss{q, _, yaw, _, stun, _, state, bage, _, _, _} = b
  +k = Boss.pose(state, bage, stun)
  +s = R.Vec.add(p, R.Vec{0.0, 0.9, 0.16})
  +on = Vec.nearer(Vec.onto(Boss.at(q, yaw, Pose.spine(k, 0.57)), 0.8, s),
    Vec.onto(Boss.at(q, yaw, Pose.spine(k, 1.0)), 0.5, s), s)
  R.Vec.mix(s, on, R.pick(Act.attack(action), 1.0, 0.0))

# Effects
# -------

# The effects, records drawn after: the swing's
# arcs, a special's ribbons, the charge's glow, the dodge's ring, the
# guard's field, a flash's sparks, a detonation, the boss's blade
# trail, its slam's shockwave, its block's flash, its aura.
type Fx is Data:
  Swing{p: R.Vec, face: F32, angle: F32, charge: U32}
  Special{p: R.Vec, face: F32, act: U32, u: F32}
  Charge{p: R.Vec, face: F32, u: F32, t: F32}
  Dodge{p: R.Vec, face: F32, age: U32}
  Guard{p: R.Vec, guard: F32, age: U32, flash: U32}
  Spark{p: R.Vec, age: U32}
  Boom{x: F32, y: F32, age: F32, who: U32}
  Slash{p: R.Vec, face: F32, state: U32, age: U32, stun: U32}
  Shock{x: F32, y: F32, age: U32}
  Parry{p: R.Vec, age: U32}
  Aura{p: R.Vec, t: F32}

# A quad of projected corners, one colour blended (m 1 alpha, 2
# additive) at al; behind the eye, nothing.
def Fx.put(
  +a: R.Vec, +b: R.Vec, +c: R.Vec, +d: R.Vec, +col: U32, +m: U32, +al: F32, cells: R.Cells
) -> R.Cells:
  R.Vec{ax, ay, aw} = a
  R.Vec{bx, by, _} = b
  R.Vec{cx, cy, cw} = c
  R.Vec{dx, dy, _} = d
  R.Quad.put(ax, ay, bx, by, cx, cy, dx, dy, R.min(aw, cw), col, m, al, 1919.0, 1199.0, cells)

def Fx.quad(
  +a: R.Vec, +b: R.Vec, +c: R.Vec, +d: R.Vec, +col: U32, +m: U32, +al: F32, +view: View,
  cells: R.Cells
) -> R.Cells:
  +cam = Stage.cam(view)
  Fx.put(R.Cam.proj(cam, a), R.Cam.proj(cam, b), R.Cam.proj(cam, c), R.Cam.proj(cam, d), col, m,
    al, cells)

# An additive beam from a to b, w0 wide at a and w1 at b, across z.
def Fx.beam(
  +a: R.Vec, +b: R.Vec, +w0: F32, +w1: F32, +col: U32, +al: F32, +view: View, cells: R.Cells
) -> R.Cells:
  +n = R.Vec.unit(R.Vec.cross(R.Vec.sub(b, a), R.Vec{0.0, 0.0, 1.0}))
  Fx.quad(R.Vec.add(a, R.Vec.scale(n, w0)), R.Vec.add(b, R.Vec.scale(n, w1)),
    R.Vec.sub(b, R.Vec.scale(n, w1)), R.Vec.sub(a, R.Vec.scale(n, w0)), col, 2, al, view, cells)

# A point of an arc at an angle on a circle of radius r about the
# chest (0.90 up, 0.34 before) of a figure at p facing face.
def Fx.arcpt(+ang: F32, +r: F32, +p: R.Vec, +face: F32) -> R.Vec:
  Boss.at(p, face, R.Vec{(F32.cos(ang) * r : F32), (0.90 + F32.sin(ang) * r : F32), 0.34})

# n segments of an additive arc from segment i: from theta over sweep
# at a radius, its width swelling as sin(pi u).
def Fx.arc(
  n: Nat, +i: F32, +k: F32, +theta: F32, +sweep: F32, +r: F32, +width: F32, +p: R.Vec,
  +face: F32, +col: U32, +al: F32, +view: View, acc: R.Cells
) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +u = (i * k : F32)
      +a = (theta + u * sweep : F32)
      +b = (theta + (u + k) * sweep : F32)
      +w = (r - width * F32.sin((u * 3.1415927 : F32)) : F32)
      Fx.arc(m, (i + 1.0 : F32), k, theta, sweep, r, width, p, face, col, al, view,
        Fx.quad(Fx.arcpt(a, r, p, face), Fx.arcpt(b, r, p, face), Fx.arcpt(b, w, p, face),
          Fx.arcpt(a, w, p, face), col, 2, al, view, acc))

# n triangles from i of an additive disc about c facing the eye.
def Fx.disc(
  n: Nat, +i: F32, +k: F32, +c: R.Vec, +r: F32, +col: U32, +al: F32, +view: View, acc: R.Cells
) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +a = (i * k * 6.2831853 : F32)
      +b = ((i + 1.0) * k * 6.2831853 : F32)
      Fx.disc(m, (i + 1.0 : F32), k, c, r, col, al, view,
        Fx.quad(c, R.Vec.add(c, R.Vec{(F32.cos(a) * r : F32), (F32.sin(a) * r : F32), 0.0}),
          R.Vec.add(c, R.Vec{(F32.cos(b) * r : F32), (F32.sin(b) * r : F32), 0.0}), c, col, 2,
          al, view, acc))

# A point of a special's ribbon, local to the figure: kind 0 a loop
# about the chest wobbling in z, 2 a wake behind (the dash), 3 a helix
# rising from the feet.
def Fx.ribpt(+kind: U32, +u: F32, +phase: F32, +r: F32) -> R.Vec:
  +a = (u * 6.2831853 + phase : F32)
  +pulse = (F32.sin((u * 3.1415927 : F32)) * 0.52 : F32)
  +k2 = U32.is_eq(kind, 2)
  +k3 = U32.is_eq(kind, 3)
  R.Vec{R.pick(k2, (0.0 - u * r : F32), R.pick(k3, (F32.cos(a) * pulse : F32),
      (F32.cos(a) * r : F32))),
    R.pick(k2, (0.9 + F32.sin((u * 9.4 + phase : F32)) * 0.09 : F32),
      R.pick(k3, (0.1 + u * r : F32), (0.9 + F32.sin(a) * r * 0.66 : F32))),
    R.pick(k2, (F32.sin(phase) * 0.22 : F32), R.pick(k3, (F32.sin(a) * pulse : F32),
      (F32.sin((a * 2.0 + phase : F32)) * r * 0.24 : F32)))}

# n segments of a ribbon of a kind from segment i: a quad across the
# curve, its width swelling from 0.15 to 1 by sin(pi u).
def Fx.rib(
  n: Nat, +i: F32, +k: F32, +kind: U32, +phase: F32, +r: F32, +width: F32, +p: R.Vec,
  +face: F32, +col: U32, +al: F32, +view: View, acc: R.Cells
) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +u = (i * k : F32)
      +a = Fx.ribpt(kind, u, phase, r)
      +b = Fx.ribpt(kind, (u + k : F32), phase, r)
      +nn = R.Vec.scale(R.Vec.unit(R.Vec.cross(R.Vec.sub(b, a), R.Vec{0.0, 0.0, 1.0})),
        (width * (0.15 + 0.85 * F32.sin((u * 3.1415927 : F32))) : F32))
      Fx.rib(m, (i + 1.0 : F32), k, kind, phase, r, width, p, face, col, al, view,
        Fx.quad(Boss.at(p, face, R.Vec.add(a, nn)), Boss.at(p, face, R.Vec.add(b, nn)),
          Boss.at(p, face, R.Vec.sub(b, nn)), Boss.at(p, face, R.Vec.sub(a, nn)), col, 2, al,
          view, acc))

# At most n segments of an arc of a sweep at a radius about p: fewer
# when small on the screen.
def Fx.segs(+n: F32, +sweep: F32, +r: F32, +p: R.Vec, +view: View) -> F32:
  +cam = Stage.cam(view)
  R.min(n, F32.ceil((R.Grid.arc((r * R.Cam.px(cam, p) : F32)) * sweep * 0.159155 : F32)))

def Fx.nat(+n: F32) -> Nat:
  U32.to_nat(F32.to_u32(n))

# A thread: a thin ribbon of up to 20 segments and its soft halo.
def Fx.thread(
  +kind: U32, +phase: F32, +r: F32, +p: R.Vec, +face: F32, +col: U32, +al: F32, +view: View,
  acc: R.Cells
) -> R.Cells:
  +n = Fx.segs(20.0, 6.2831853, r, p, view)
  Fx.rib(Fx.nat(n), 0.0, (1.0 / n : F32), kind, phase, r, 0.018, p, face, col, al, view,
    Fx.rib(Fx.nat(n), 0.0, (1.0 / n : F32), kind, phase, r, 0.055, p, face, col, (al * 0.12 : F32),
      view, acc))

# The swing's arcs at the blade's angle: the cut (radius 2.9 heavy,
# 1.78 else), its halo, a thin inner line.
def Fx.cut(+heavy: Bool, +angle: F32, +col: U32, +p: R.Vec, +face: F32, +view: View) -> R.Cells:
  +r = R.pick(heavy, 2.9, 1.78)
  +n = Fx.segs(24.0, 1.9, r, p, view)
  +m = Fx.segs(16.0, 1.75, r, p, view)
  Fx.arc(Fx.nat(n), 0.0, (1.0 / n : F32), (angle - 0.90 : F32), 1.90, r,
    R.pick(heavy, 0.30, 0.14), p, face, col, 0.75, view,
    Fx.arc(Fx.nat(n), 0.0, (1.0 / n : F32), (angle - 1.06 : F32), 1.92, (r + 0.04 : F32),
      R.pick(heavy, 0.60, 0.28), p, face, col, 0.12, view,
      Fx.arc(Fx.nat(m), 0.0, (1.0 / m : F32), (angle - 1.18 : F32), 1.75, (r - 0.17 : F32),
        0.025, p, face, 16055017, 0.4, view, R.CNil{})))

# The thorns from i of the down special's bloom: a horn from the feet
# to a tip, a beam of light along it.
def Fx.thorn(
  n: Nat, +i: F32, +scale: F32, +p: R.Vec, +face: F32, +view: View, acc: R.Cells
) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +a = (i * 0.785398 : F32)
      +root = {R.Vec{(F32.cos(a) * 0.34 : F32), 0.04, (F32.sin(a) * 0.30 : F32)} : R.Vec}
      +tip = {R.Vec{(F32.cos(a) * scale * 2.5 : F32), (scale * (0.9 + F32.abs(F32.sin(a))) : F32),
        (F32.sin(a) * scale * 1.5 : F32)} : R.Vec}
      Fx.thorn(m, (i + 1.0 : F32), scale, p, face, view,
        Fx.beam(Boss.at(p, face, root), Boss.at(p, face, tip), 0.012, 0.004, 16568248, 0.7,
          view, R.Cells.merge(acc, Hero.part(R.Inst.span(R.Own{2, 0.0}, root, tip, (scale * 0.65 : F32),
            (scale * 0.6 : F32)), Mat.paint(13590649, 0.30, 0.15, 0.12), 6, 2, p, face, view))))

# The special's light at u of its progress, scaled by sin(pi u): down,
# eight thorns and a ring; else three threads (a wake for the dash, a
# helix for the upward ones, a loop else).
def Fx.special(down: Bool, +act: U32, +u: F32, +p: R.Vec, +face: F32, +view: View) -> R.Cells:
  match down:
    case True{}:
      +scale = R.max(0.02, F32.sin((u * 3.1415927 : F32)))
      Fx.thorn(8n, 0.0, scale, p, face, view,
        Fx.thread(0, 0.0, (scale * 2.2 : F32), p, face, 15043735, 0.45, view, R.CNil{}))
    case False{}:
      +scale = R.max(0.02, F32.sin((u * 3.1415927 : F32)))
      +phase = (u * 15.0 : F32)
      +kind = R.word(Act.up(act), 3, R.word((U32.is_eq(act, 20) || U32.is_eq(act, 24)),
        2, 0))
      +r = R.pick(U32.is_eq(kind, 2), 4.0, R.pick(U32.is_eq(kind, 3), 3.7,
        (scale * 2.65 : F32)))
      Fx.thread(kind, phase, r, p, face, 15841738, (scale * 0.6 : F32), view,
        Fx.thread(kind, (phase + 2.1 : F32), (r * 0.82 : F32), p, face, 15251616,
          (scale * 0.5 : F32), view,
          Fx.thread(kind, (phase + 4.2 : F32), (r * 0.90 : F32), p, face, 9886675,
            (scale * 0.35 : F32), view, R.CNil{})))

# The charge's glow (u of the full charge): a thread about the chest
# turning with time, an additive field and a ring, growing.
def Fx.charge(+u: F32, +t: F32, +p: R.Vec, +face: F32, +view: View) -> R.Cells:
  +size = (0.25 + u * 0.20 : F32)
  +n = Fx.segs(24.0, 6.2831853, (0.24 + u * 0.22 : F32), p, view)
  Fx.thread(0, (t * 0.10 : F32), (0.45 + u * 0.35 : F32), p, face, 16767096,
    (0.15 + u * 0.35 : F32), view,
    Fx.arc(Fx.nat(n), 0.0, (1.0 / n : F32), 0.0, 6.2831853, (0.24 + u * 0.22 : F32), 0.022, p,
      face, 16768957, 0.65, view,
      Mesh.of(R.Inst.ball(R.Globe{}, Boss.at(p, face, R.Vec{0.20, 1.08, 0.0}), size, size, size),
        R.Mat{16767404, 1.0, 0.0, 0.0, 0, 2, (0.06 + u * 0.14 : F32)}, 8, 4, view)))

# The guard's field: a translucent shell grown by the guard, pale in
# the parry window (its first 6 ticks), lit by a flash.
def Fx.guard(+guard: F32, +age: U32, +flash: U32, +p: R.Vec, +view: View) -> R.Cells:
  +early = (age < 6 : U32)
  Mesh.of(R.Inst.ball(R.Globe{}, R.Vec.add(p, R.Vec{0.0, 0.86, 0.0}), (0.72 + guard * 0.003 : F32),
      (0.98 + guard * 0.003 : F32), 0.85),
    R.Mat{R.word(early, 14482943, 5423871), 1.0, 0.0, 0.0, 0, 1,
      (R.pick(early, 0.14, 0.07) + R.pick((flash > 0 : U32), 0.2, 0.0) : F32)}, 12, 6, view)

# The sparks from i of a hit: beams flying from the contact point.
def Fx.sparks(n: Nat, +i: F32, +p: R.Vec, +age: F32, +view: View, acc: R.Cells) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +d = R.Vec.unit(R.Vec{F32.cos((i * 2.4 : F32)), F32.sin((i * 5.7 : F32)),
        F32.sin((i * 2.4 : F32))})
      Fx.sparks(m, (i + 1.0 : F32), p, age, view,
        Fx.beam(R.Vec.add(p, R.Vec.scale(d, (age * 0.23 : F32))),
          R.Vec.add(p, R.Vec.scale(d, (age * 0.23 + 0.65 : F32))), 0.05, 0.02, 16769470, 1.0,
          view, acc))

# The rays from i of a detonation at p: every 22.5 degrees, flying out
# and thinning.
def Fx.rays(n: Nat, +i: F32, +p: R.Vec, +age: F32, +col: U32, +view: View, acc: R.Cells) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +a = (i * 0.392699 : F32)
      +d = {R.Vec{F32.cos(a), F32.sin(a), 0.0} : R.Vec}
      +r = (0.2 + age * 0.12 : F32)
      Fx.rays(m, (i + 1.0 : F32), p, age, col, view,
        Fx.beam(R.Vec.add(p, R.Vec.scale(d, r)),
          R.Vec.add(p, R.Vec.scale(d, (r + 1.5 - age * 0.02 : F32))),
          R.max(0.0, (0.12 - age * 0.0025 : F32)), 0.02, col, 0.8, view, acc))

# A detonation at p of an age: sixteen rays, a ring, a vertical beam,
# thinning over 42 ticks.
def Fx.boom(+p: R.Vec, +age: F32, +col: U32, +view: View) -> R.Cells:
  Fx.rays(16n, 0.0, p, age, col, view,
    Fx.arc(16n, 0.0, 0.0625, 0.0, 6.2831853, (0.4 + age * 0.13 : F32), 0.12,
      R.Vec.sub(p, R.Vec{0.0, 0.90, 0.34}), 0.0, col, 0.6, view,
      Fx.beam(R.Vec.sub(p, R.Vec{0.0, 5.0, 0.0}), R.Vec.add(p, R.Vec{0.0, 5.0, 0.0}),
        R.max(0.0, (0.20 - age * 0.012 : F32)), R.max(0.0, (0.20 - age * 0.012 : F32)),
        16776677, 0.8, view, R.CNil{})))

# The blade's trail: n quads back from the tip and the blade's middle
# to the ones a tick earlier, fading.
def Fx.trail(
  n: Nat, +k: U32, +p: R.Vec, +face: F32, +state: U32, +age: U32, +stun: U32, +tip: R.Vec,
  +mid: R.Vec, +view: View, acc: R.Cells
) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +pose = Boss.pose(state, R.word((age > k : U32), (age - k : U32), 0), stun)
      +t2 = Boss.tip(p, face, pose)
      +m2 = Boss.at(p, face, R.Vec.add(Pose.grip(pose), R.Vec.scale(Pose.dir(pose), 1.5)))
      Fx.trail(m, (k + 1 : U32), p, face, state, age, stun, t2, m2, view,
        Fx.quad(tip, t2, m2, mid, 10352639, 2, (0.5 - U32.to_f32(k) * 0.08 : F32), view, acc))

# The slam's shockwave: a band of quads from i about (x, y) on the
# floor (an ellipse, as the arena), of a radius and a height.
def Fx.shock(
  n: Nat, +i: F32, +x: F32, +y: F32, +r: F32, +h: F32, +al: F32, +view: View, acc: R.Cells
) -> R.Cells:
  match n:
    case 0n:
      acc
    case 1n+m:
      +a = (i * 0.2617994 : F32)
      +b = (a + 0.2617994 : F32)
      +ax = (x + F32.cos(a) * r : F32)
      +az = (F32.sin(a) * r * 0.48 : F32)
      +bx = (x + F32.cos(b) * r : F32)
      +bz = (F32.sin(b) * r * 0.48 : F32)
      Fx.shock(m, (i + 1.0 : F32), x, y, r, h, al, view,
        Fx.quad(R.Vec{ax, y, az}, R.Vec{bx, y, bz}, R.Vec{bx, (y + h : F32), bz},
          R.Vec{ax, (y + h : F32), az}, 11197695, 2, al, view, acc))

def Fx.one(+f: Fx, +view: View) -> R.Cells:
  match f:
    case Swing{p, face, angle, charge}:
      +heavy = (charge > 2 : U32)
      Fx.cut(heavy, angle, R.word(heavy, 16768423, 14154209), p, face, view)
    case Special{p, face, act, u}:
      Fx.special(Act.down(act), act, u, p, face, view)
    case Charge{p, face, u, t}:
      Fx.charge(u, t, p, face, view)
    case Dodge{p, face, age}:
      Fx.thread(0, (U32.to_f32(age) * 0.15 : F32), 0.75, p, face, 8381419,
        (U32.to_f32(age) / 70.0 : F32), view, R.CNil{})
    case Guard{p, guard, age, flash}:
      Fx.guard(guard, age, flash, p, view)
    case Spark{p, age}:
      Fx.sparks(16n, 0.0, p, U32.to_f32(age), view, R.CNil{})
    case Boom{x, y, age, who}:
      Fx.boom(R.Vec{x, y, 1.0}, age, R.word(U32.is_eq(who, 1), 16285568, 16249550), view)
    case Slash{p, face, state, age, stun}:
      +k = Boss.pose(state, age, stun)
      Fx.trail(6n, 1, p, face, state, age, stun, Boss.tip(p, face, k),
        Boss.at(p, face, R.Vec.add(Pose.grip(k), R.Vec.scale(Pose.dir(k), 1.5))), view, R.CNil{})
    case Shock{x, y, age}:
      +fade = (1.0 - U32.to_f32(age) / 20.0 : F32)
      Fx.shock(24n, 0.0, x, y, (0.6 + U32.to_f32(age) * 0.30 : F32), (0.4 * fade : F32),
        (0.55 * fade : F32), view, R.CNil{})
    case Parry{p, age}:
      Fx.disc(12n, 0.0, 0.0833333, p, (0.9 - U32.to_f32(age) * 0.07 : F32), 14482943,
        (0.7 - U32.to_f32(age) * 0.08 : F32), view, R.CNil{})
    case Aura{p, t}:
      +al = (0.06 + 0.02 * F32.sin((t * 0.25 : F32)) : F32)
      +c = R.Vec.add(p, R.Vec{0.0, 0.0, 0.3})
      Fx.disc(12n, 0.0, 0.0833333, c, 1.0, 16726560, al, view,
        Fx.disc(12n, 0.0, 0.0833333, c, 0.55, 16726560, (al * 1.5 : F32), view, R.CNil{}))

def Fx.add(on: Bool, fx: Fx, rest: List<&2, Fx>) -> List<&2, Fx>:
  match on:
    case False{}:
      rest
    case True{}:
      fx <> rest

# The boss's effects: its blade's trail while live and 4 ticks after,
# the slam's wave, the block's flash at the hilt, the aura enraged.
def Fx.boss(+b: Boss, +t: F32, rest: List<&2, Fx>) -> List<&2, Fx>:
  Boss{p, _, face, hp, stun, _, state, age, _, _, _} = b
  R.Vec{x, y, _} = p
  +k = Boss.pose(state, age, stun)
  +wind = Boss.wind(state)
  Fx.add(((state > 0 : U32) && U32.is_eq(stun, 0) && (age >= wind : U32)
      && (age < (wind + Boss.act(state) + 4 : U32) : U32)), Slash{p, face, state, age, stun},
    Fx.add((U32.is_eq(state, 7) && (age < 20 : U32)), Shock{x, y, age},
      Fx.add((U32.is_eq(state, 6) && (age < 8 : U32)), Parry{Boss.hilt(p, face, k), age},
        Fx.add(((hp < 160.0 : F32) && (hp > 0.0 : F32)),
          Aura{Boss.at(p, face, Pose.spine(k, 1.0)), t}, rest))))

# The detonation while it lasts, held inside the lens.
def Fx.blast(m: Maybe<&2, Blast>, +l: Lens, +t: F32, rest: List<&2, Fx>) -> List<&2, Fx>:
  match m:
    case None{}:
      rest
    case Some{b}:
      Blast{x, y, born, who} = b
      Lens{cx, cy, w, _, _, _} = l
      +age = (t - U32.to_f32(born) : F32)
      Fx.add((age < 42.0 : F32),
        Boom{R.clamp(x, (cx - w * 0.44 : F32), (cx + w * 0.44 : F32)),
          R.clamp(y, (cy - w * 0.22 : F32), (cy + w * 0.22 : F32)), R.max(0.0, age), who},
        rest)

def Fx.list(+g: Game, +t: F32) -> List<&2, Fx>:
  Game{_, _, _, _, hero, boss, flash, _, _, lens, blast} = g
  Fighter{p, _, face, _, guard, _, action, age, _, _, _, _, charge} = hero
  +hit = Act.hit(action)
  +len = U32.to_f32(Act.length(action))
  +attack = Act.attack(action)
  +special = Act.special(action)
  Fx.add((attack && Bool.not(special) && (age <= (hit + 3 : U32) : U32)
      && ((age + 4 : U32) >= hit : U32)), Swing{p, face, Hero.angle(action, age), charge},
    Fx.add((attack && special),
      Special{p, face, action, R.sat(((len - U32.to_f32(age)) / len : F32))},
      Fx.add(Act.charging(action), Charge{p, face, R.sat((U32.to_f32(charge) / 45.0 : F32)), t},
        Fx.add(U32.is_eq(action, 6), Dodge{p, face, age},
          Fx.add(U32.is_eq(action, 3), Guard{p, guard, age, flash},
            Fx.add((flash > 0 : U32), Spark{Game.contact(hero, boss), (7 - flash : U32)},
              Fx.blast(blast, lens, t, Fx.boss(boss, t, []))))))))

def Fx.draw(fx: List<&2, Fx>, +view: View) -> R.Cells:
  match fx:
    case Nil{}:
      R.CNil{}
    case f <> rest:
      R.Cells.merge(Fx.one(f, view), Fx.draw(rest, view))


# HUD
# ---

# The original's HUD on its 1024 x 640 canvas: a rectangle, alpha over
# the scene (m 1) or opaque (m 0) at the inverse depth d.
def Hud.rect(
  +x: F32, +y: F32, +w: F32, +h: F32, +col: U32, +m: U32, +al: F32, +d: F32, cells: R.Cells
) -> R.Cells:
  +x0 = (x * 1.875 : F32)
  +y0 = (y * 1.875 : F32)
  +x1 = ((x + w) * 1.875 : F32)
  +y1 = ((y + h) * 1.875 : F32)
  R.Quad.put(x0, y0, x0, y1, x1, y1, x1, y0, d, col, m, al, 1919.0, 1199.0, cells)

# Text of a size and style at (x, y) on the canvas.
def Hud.text(
  x: F32, y: F32, size: F32, +style: U32, +col: U32, s: String, cells: R.Cells
) -> R.Cells:
  R.Text.put((x * 1.875 : F32), (y * 1.875 : F32), (size * 1.875 : F32), style, col, s, 1919.0,
    1199.0, cells)

def Move.name(act: U32) -> String:
  match act:
    case 2:
      "Moon snare"
    case 3:
      "Guard"
    case 6:
      "Air dodge"
    case 7:
      "Crouch"
    case 20:
      "Blade dash"
    case 21:
      "Moon ascent"
    case 22:
      "Crescent bloom"
    case 23:
      "Moon cyclone"
    case 24:
      "Blade dive"
    case 25:
      "Moon ascent"
    case 26:
      "Comet fall"
    case 30:
      "Charging side smash"
    case 31:
      "Charging sky smash"
    case 32:
      "Charging low smash"
    case _:
      "J  Blade      K  Moon"

def Hud.parry(on: Bool, cells: R.Cells) -> R.Cells:
  match on:
    case False{}:
      cells
    case True{}:
      Hud.text(472.0, 91.0, 20.0, 1, 14938614, "PARRY", cells)

# The fight's panel: the hero's damage, lives and guard, the move's
# name and the smash charge, the boss's strain and vitality, the keys,
# PARRY on one.
def Hud.fight(+g: Game, cells: R.Cells) -> R.Cells:
  Game{_, _, _, _, hero, boss, flash, _, _, _, _} = g
  Fighter{_, _, _, damage, guard, _, action, _, _, stocks, _, _, charge} = hero
  Boss{_, _, _, hp, stun, strain, _, _, _, _, _} = boss
  Hud.rect(0.0, 549.0, 1024.0, 91.0, 592914, 1, 0.82, 1000.0,
    Hud.rect(36.0, 549.0, 952.0, 0.6, 3753540, 0, 1.0, 2000.0,
      Hud.text(37.0, 557.0, 11.0, 2, 15120588, "THE BLADE",
        Hud.text(34.0, 571.0, 42.0, 1, R.word((damage > 80.0 : F32), 15572866, 15920620),
          U32.show(F32.to_u32(damage)) ++ "%",
          Hud.text(155.0, 578.0, 16.0, 1, 12434368, U32.show(stocks) ++ " lives",
            Hud.rect(155.0, 610.0, 110.0, 2.0, 2832972, 0, 1.0, 2000.0,
              Hud.rect(155.0, 610.0, (110.0 * guard / 100.0 : F32), 2.0, 7977935, 0, 1.0, 2500.0,
                Hud.text(669.0, 557.0, 11.0, 2, 14405571, Boss.name(),
                  Hud.text(898.0, 571.0, 42.0, 1, 14788253, U32.show(F32.to_u32(strain)) ++ "%",
                    Hud.rect(670.0, 610.0, 192.0, 3.0, 2832972, 0, 1.0, 2000.0,
                      Hud.rect(670.0, 610.0, (192.0 * hp / 360.0 : F32), 3.0,
                        R.word((hp < 160.0 : F32), 14524034, 13482665), 0, 1.0, 2500.0,
                        Hud.text(670.0, 584.0, 10.0, 0, 9084575, "VITALITY",
                          Hud.text(375.0, 580.0, 14.0, 1, 13030592, Move.name(action),
                            Hud.rect(377.0, 606.0, R.pick(Act.charging(action),
                              (140.0 * R.sat((U32.to_f32(charge) / 45.0 : F32)) : F32), 0.0),
                              2.0, 15644068, 0, 1.0, 2500.0,
                              Hud.text(360.0, 623.0, 9.0, 0, 9084575,
                                "I  Jump    L  Guard / dodge    P  Pause",
                                Hud.parry(((flash > 0 : U32) && U32.is_eq(action, 3)
                                  && (stun > 0 : U32)), cells))))))))))))))))

# The title: the name, a rule and the tagline, the button, the help.
def Hud.title(cells: R.Cells) -> R.Cells:
  Hud.text(41.0, 115.0, 75.0, 1, 15920360, "Slash",
    Hud.text(41.0, 181.0, 75.0, 1, 15920360, "Boss",
      Hud.rect(48.0, 270.0, 43.0, 1.0, 12694169, 1, 0.8, 1000.0,
        Hud.text(47.0, 286.0, 16.0, 1, 12107707, "One blade. One severing cut.",
          Hud.rect(375.0, 503.0, 274.0, 39.0, 987680, 1, 0.83, 1000.0,
            Hud.rect(375.0, 503.0, 274.0, 1.0, 8155507, 0, 1.0, 2000.0,
              Hud.text(395.0, 511.0, 18.0, 2, 15064013, "L",
                Hud.text(449.0, 510.0, 19.0, 1, 15330267, "Begin the duel",
                  Hud.text(295.0, 558.0, 11.5, 0, 11647924,
                    "Move + J / K changes your attack. Hold a direction + J to charge a smash.",
                    Hud.text(390.0, 585.0, 11.5, 0, 9544869,
                      "I  Jump     L  Guard / air dodge     P  Pause", cells))))))))))

# The end of a duel: its title at x, its line at x2, the choices.
def Hud.end(+x: F32, +col: U32, title: String, +x2: F32, line: String, cells: R.Cells) -> R.Cells:
  Hud.text(x, 113.0, 43.0, 1, col, title, Hud.text(x2, 169.0, 17.0, 1, 11715764, line,
    Hud.text(414.0, 495.0, 15.0, 0, 14540496, "L  Duel again     K  Back", cells)))

def Hud.pause(cells: R.Cells) -> R.Cells:
  Hud.rect(343.0, 171.0, 340.0, 142.0, 724246, 1, 0.94, 1000.0,
    Hud.text(447.0, 191.0, 40.0, 1, 15263695, "Paused",
      Hud.text(410.0, 265.0, 15.0, 0, 11715764, "L  Continue     K  Back", cells)))

# The screen of a mode: the title alone; the fight's panel under the
# win, the loss or the pause.
def Hud.screen(title: Bool, won: Bool, lost: Bool, paused: Bool, +g: Game, cells: R.Cells) -> R.Cells:
  match title won lost paused:
    case True{} _ _ _:
      Hud.title(cells)
    case False{} True{} _ _:
      Hud.end(327.0, 15135440, "Moon unbroken", 369.0, "The blade falls silent. One final cut.",
        Hud.fight(g, cells))
    case False{} False{} True{} _:
      Hud.end(373.0, 15049618, "Blade undone", 391.0, "Rise again. Learn its rhythm.",
        Hud.fight(g, cells))
    case False{} False{} False{} True{}:
      Hud.pause(Hud.fight(g, cells))
    case False{} False{} False{} False{}:
      Hud.fight(g, cells)

# The HUD of a game: the name and the boss's, then its mode's screen.
def Hud.build(+g: Game, cells: R.Cells) -> R.Cells:
  Game{_, _, _, mode, hero, boss, _, _, _, _, _} = g
  Hud.text(34.0, 22.0, 20.0, 1, 14801615, "SLASH BOSS",
    Hud.text(35.0, 46.0, 8.5, 2, 9019827, Boss.name(),
      Hud.screen(U32.is_eq(mode, 0), U32.is_eq(mode, 2), U32.is_eq(mode, 3), U32.is_eq(mode, 4), g,
        cells)))

# The scene at the view's clock: the hero and his cape (56 patches in
# two reds), the boss, the stage in five branches, the effects, the
# HUD; the last scene dropped beside them.
def Scene.build(+g: Game, +t: F32, used: R.Cells) -> R.Cells:
  Game{_, _, _, _, hero, boss, flash, cloth, garb, lens, _} = g
  +view = View.at(lens, t, flash, Game.contact(hero, boss))
  a b c d1 d2 d3 d4 d5 h e u = Hero.build(hero, t, view)
    R.Cloth.mesh(~View, ~Stage.cam, ~Mesh.of, 3n, cloth, 0, Fit.cape(), False{}, 12199235, 10423856,
      0.84, 0.0, view)
    Boss.alive(Boss.dead(boss), boss, garb, t, view) Stage.top(view) Stage.deep(view)
    Stage.arch((0.0 - 9.5 : F32), view) Stage.pair(view) Stage.rest(view) Hud.build(g, R.CNil{})
    Fx.draw(Fx.list(g, t), view) R.Cells.drop(4n, used)
  R.Cells.merge(R.Cells.m4(a, b, c, R.Cells.merge(R.Cells.merge(R.Cells.merge(d1, d2), d3), R.Cells.merge(d4,
    d5))), R.Cells.merge(e, R.Cells.merge(h, u)))


# Sky
# ---

# The sky at a place: the ridge heights (the lower, 2, in front of 1)
# of a column, the star (centre, size, 0 for none, colour) of its
# square, its band.
type Sky is Data:
  Sky{r2: F32, r1: F32, sx: F32, sy: F32, ss: F32, sc: U32, band: U32}

# A mountain ridge (layer 1 or 2) as a screen height over the column
# xf: the original's over 1024 x 640, scaled by 1.875.
def Sky.ridge(+l: F32, +xf: F32) -> F32:
  +f = (xf / 120.0 : F32)
  (497.0 + 165.0 * l - 79.0 * F32.sin((0.7 * f + 2.0 * l : F32))
    - 52.0 * F32.sin((1.9 * f + 4.0 * l : F32)) - 30.0 * F32.cos((3.7 * f : F32)) : F32)

# The gradient in bands of 16 rows: (16, 26, 36) to (49, 61, 72).
def Sky.band(+y: U32) -> U32:
  +u = (U32.to_f32((y >> 4n : U32)) / 75.0 : F32)
  R.pack((0.063 + 0.129 * u : F32), (0.102 + 0.137 * u : F32),
    (0.141 + 0.141 * u : F32))

# The star of the 16 (a diamond of half width 1.3 or 0.65, two greys)
# whose diamond meets the h-square at (x, y), walked from i.
def Sky.star(n: Nat, +i: F32, +x: F32, +y: F32, +h: F32, +sky: Sky) -> Sky:
  match n:
    case 0n:
      sky
    case 1n+k:
      Sky{r2, r1, sx, sy, ss, sc, band} = sky
      +px = (((i * 137.508 + 31.0) % 1024.0 : F32) * 1.875 : F32)
      +py = ((12.0 + F32.abs(F32.sin((i * 4.73 : F32))) * 228.0) * 1.875 : F32)
      +ii = F32.to_u32(i)
      +s = (R.pick(U32.is_eq((ii .&. 3 : U32), 0), 1.3, 0.65) * 1.875 : F32)
      +hit = ((px + s > x) && (px - s < x + h) && (py + s * 2.0 > y)
        && (py - s * 2.0 < y + h) : F32)
      Sky.star(k, (i + 1.0 : F32), x, y, h, Sky{r2, r1, R.pick(hit, px, sx),
        R.pick(hit, py, sy), R.pick(hit, s, ss),
        R.word(hit, R.word(U32.is_eq((ii .&. 1 : U32), 0), 10989229, 6253955), sc),
        band})

def Sky.stars(low: Bool, +x: F32, +y: F32, +h: F32, +sky: Sky) -> Sky:
  match low:
    case True{}:
      sky
    case False{}:
      Sky.star(16n, 0.0, x, y, h, sky)

# The sky of the h-square at (x, y): its ridges at its centre column,
# its star (none below the stars' reach), its band.
def Sky.of(+x: U32, +y: U32, +h: U32) -> Sky:
  +xc = (U32.to_f32(x) + 0.5 * U32.to_f32(h) : F32)
  Sky.stars((y > 460 : U32), U32.to_f32(x), U32.to_f32(y), U32.to_f32(h),
    Sky{Sky.ridge(2.0, xc), Sky.ridge(1.0, xc), 0.0, 0.0, 0.0, 0, Sky.band(y)})

# Does a ridge or the star cross the h-square at (x, y)? A ridge's
# slope is under 1.6, so it moves under h across the square.
def Sky.mixed(+sky: Sky, +x: U32, +y: U32, +h: U32) -> Bool:
  Sky{r2, r1, sx, sy, ss, _, band} = sky
  +xf = U32.to_f32(x)
  +yf = U32.to_f32(y)
  +hf = U32.to_f32(h)
  (((yf < r2 + hf + 1.0) && (yf + hf > r2 - hf - 1.0))
    || ((yf < r1 + hf + 1.0) && (yf + hf > r1 - hf - 1.0))
    || ((ss > 0.0) && (sx + ss > xf) && (sx - ss < xf + hf) && (sy + ss * 2.0 > yf)
      && (sy - ss * 2.0 < yf + hf)) : F32)

# The colour under the ridges (layer 2 in front), a star or the band.
def Sky.layer(m2: Bool, m1: Bool, star: Bool, +sc: U32, +band: U32) -> U32:
  match m2 m1 star:
    case True{} _ _:
      2042676
    case False{} True{} _:
      2437689
    case False{} False{} True{}:
      sc
    case False{} False{} False{}:
      band

def Sky.at(+x: U32, +y: U32, +sky: Sky) -> U32:
  Sky{r2, r1, sx, sy, ss, sc, band} = sky
  +xf = (U32.to_f32(x) + 0.5 : F32)
  +yf = (U32.to_f32(y) + 0.5 : F32)
  Sky.layer((yf > r2 : F32), (yf > r1 : F32),
    ((ss > 0.0) && ((F32.abs((xf - sx : F32)) * 2.0 + F32.abs((yf - sy : F32)) : F32)
      <= (ss * 2.0 : F32)) : F32), sc, band)

# The sky of the columns x, x + 1 when the tile needs pixels, else the
# tile's.
def Sky.col(per: Bool, +x: U32, +sky: Sky) -> Sky:
  match per:
    case False{}:
      sky
    case True{}:
      Sky{_, _, sx, sy, ss, sc, band} = sky
      +xc = (U32.to_f32(x) + 1.0 : F32)
      Sky{Sky.ridge(2.0, xc), Sky.ridge(1.0, xc), sx, sy, ss, sc, band}


# The frame of a scene over the last one: the library's bang under the
# game's sky.
def Play.frame(cells: R.Cells, old: Image) -> Image & R.Cells:
  R.Frame.show(~Sky, ~Sky.of, ~Sky.mixed, ~Sky.col, ~Sky.at, ~Screen.w, ~Screen.h, cells, old)

# Sound
# -----

# The sound: 14 clips synthesized at launch and 7 read from WAV files
# (media/slash_boss_3d) into one store of samples; a mixer of up to 24
# voices renders 512-frame stereo blocks at 48 kHz. A clip: its first
# sample in the store, its frames, its rate, its channels.
type Clip is Data:
  Clip{start: U32, frames: U32, rate: U32, ch: U32}

# A voice: its clip, its place in frames, its step a frame, its gains
# on the left and the right, does it loop.
type Voice is Data:
  Voice{clip: Clip, pos: F32, step: F32, gl: F32, gr: F32, loop: Bool}

# A cue: the clip (0-13 synthesized, 14 bell, 15 whoosh, 16 blade, 17
# dash, 18 parry), its gain, pan, rate, looping.
type Cue is Data:
  Cue{kind: U32, gain: F32, pan: F32, rate: F32, loop: Bool}

# The sound: the device (none when it failed to open), the store, the
# clips by kind, the voices (oldest first), the voices before the last
# block (kept while its write may be dropped), the last block, the
# frames the device held at the clock stamp.
type Sound is Type:
  Sound{dev: Maybe<Audio>, pcm: Array<F32>, +bank: List<&2, Clip>, +voices: List<&2, Voice>,
    +prev: List<&2, Voice>, +block: List<&2, F32>, +queued: U32, +stamp: Nat}

# The chunk tags of a WAV walk.
type Tag is Data:
  Head{}
  Fmt{}
  Body{}
  Skip{}

# A WAV's format: its kind (1 PCM16, 3 float32), channels, rate, bits.
type Wave is Data:
  Wave{kind: U32, ch: U32, rate: U32, bits: U32}

def Synth.noise(+i: U32) -> F32:
  +a = (U32.xor(i, (i >> 16n)) * 2146121005 : U32)
  +b = (U32.xor(a, (a >> 15n)) * 2221713035 : U32)
  (U32.to_f32((U32.xor(b, (b >> 16n)) .&. 65535 : U32)) / 32767.5 - 1.0 : F32)

# Sample i of clip kind (65536 at 48 kHz): hiss, swish, thud, bell,
# chirp, hop, boom, FM voice by kind (0-12) under an attack and a
# squared tail; 13 the drone.
def Synth.sample(+kind: U32, +i: U32) -> F32:
  +u = (U32.to_f32(i) / 65536.0 : F32)
  +t = (U32.to_f32(i) / 48000.0 : F32)
  +attack = R.min(1.0, (t * 240.0 : F32))
  +tail = ((1.0 - u) * (1.0 - u) : F32)
  +hiss = (Synth.noise(i) * 0.65 + Synth.noise((i / 3 : U32)) * 0.35 : F32)
  +swish = ((hiss * F32.exp((0.0 - t * 18.0 : F32)) * 0.32)
    + (F32.sin((t * (11000.0 - t * 6500.0) : F32)) * F32.exp((0.0 - t * 27.0 : F32)) * 0.08) : F32)
  +thud = ((F32.sin((t * (680.0 - t * 230.0) : F32)) * F32.exp((0.0 - t * 13.0 : F32)) * 0.38)
    + (hiss * F32.exp((0.0 - t * 48.0 : F32)) * 0.28) : F32)
  +bell = ((F32.sin((t * 6911.5 : F32)) + (F32.sin((t * 10361.3 : F32)) * 0.45)
    + (F32.sin((t * 15742.1 : F32)) * 0.22)) * F32.exp((0.0 - t * 4.0 : F32)) * 0.17 : F32)
  +chirp = (F32.sin((t * (1900.0 + t * 14000.0) : F32)) * F32.exp((0.0 - t * 10.0 : F32)) * 0.18 : F32)
  +hop = (F32.sin((t * (2100.0 + t * 6200.0) : F32)) * F32.exp((0.0 - t * 26.0 : F32)) * 0.14 : F32)
  +boom = (((F32.sin((t * (540.0 - t * 190.0) : F32)) * 0.32) + (hiss * 0.25))
    * F32.exp((0.0 - t * 2.8 : F32)) + (bell * 0.6) : F32)
  +voice = (((F32.sin((t * 410.0 + F32.sin((t * 720.0 : F32)) * 3.0 : F32)) * 0.20) + (hiss * 0.1))
    * F32.sin((u * 3.1415927 : F32)) : F32)
  +drone = ((F32.sin((u * 1884.9556 : F32)) + (F32.sin((u * 2827.4334 : F32)) * 0.4)
    + (F32.sin((u * 3769.9111 : F32)) * 0.18)) * 0.075 : F32)
  +value = R.pick(U32.is_eq(kind, 0), swish,
    R.pick(U32.is_eq(kind, 1), (swish * 0.7 + bell * 0.35 : F32),
    R.pick(U32.is_eq(kind, 2), (swish * 1.2 + thud * 0.4 : F32),
    R.pick(U32.is_eq(kind, 3), (chirp + swish * 0.5 : F32),
    R.pick(U32.is_eq(kind, 4), thud,
    R.pick(U32.is_eq(kind, 5), bell,
    R.pick(U32.is_eq(kind, 6), (thud * 1.4 + bell * 0.8 : F32),
    R.pick(U32.is_eq(kind, 7), (swish * 0.65 : F32),
    R.pick(U32.is_eq(kind, 8), hop,
    R.pick(U32.is_eq(kind, 9), (thud * 0.38 : F32),
    R.pick(U32.is_eq(kind, 10), boom,
    R.pick(U32.is_eq(kind, 11), voice, (bell * 0.60 : F32)))))))))))))
  R.pick(U32.is_eq(kind, 13), drone, (value * attack * tail : F32))

# k samples of a kind from i into the store at `at`.
def Synth.fill(k: Nat, +kind: U32, +i: U32, +at: U32, pcm: Array<F32>) -> Array<F32>:
  match k:
    case 0n:
      pcm
    case 1n+j:
      Synth.fill(j, kind, (i + 1 : U32), at, Array.set(F32, pcm, (at + i : U32), Synth.sample(kind, i)))

# The clips under n synthesized, each 65536 samples at kind x 65536.
def Synth.all(+n: Nat, pcm: Array<F32>) -> Array<F32>:
  match n:
    case 0n:
      pcm
    case 1n+k:
      Synth.all(k, Synth.fill(U32.to_nat(65536), U32.from_nat(k), 0, (U32.from_nat(k) * 65536 : U32), pcm))

# The little-endian words at the head of the bytes (0 past the end).
def Wav.u16(+b: List<&2, U32>) -> U32:
  match b:
    case x <> y <> _:
      (x .|. (y << 8n) : U32)
    case _:
      0

def Wav.u32(+b: List<&2, U32>) -> U32:
  match b:
    case x <> y <> z <> w <> _:
      (x .|. (y << 8n) .|. (z << 16n) .|. (w << 24n) : U32)
    case _:
      0

def Wav.skip(n: Nat, b: List<&2, U32>) -> List<&2, U32>:
  match n b:
    case 0n _:
      b
    case 1n+k Nil{}:
      Nil{}
    case 1n+k _ <> rest:
      Wav.skip(k, rest)

# A float from its bits (a denormal keeps its scale).
def Wav.float(+w: U32) -> F32:
  +e = ((w >> 23n) .&. 255 : U32)
  +m = ((w .&. 8388607 : U32) .|. R.word(U32.is_eq(e, 0), 0, 8388608) : U32)
  +v = (U32.to_f32(m) * F32.pow(2.0, R.pick(U32.is_eq(e, 0), (0.0 - 149.0 : F32),
    (U32.to_f32(e) - 150.0 : F32))) : F32)
  R.pick((w >= 2147483648 : U32), (0.0 - v : F32), v)

# n samples (PCM16, or float32) from the bytes into the store from `at`.
def Wav.samples(short: Bool, n: Nat, b: List<&2, U32>, +at: U32, pcm: Array<F32>) -> Array<F32>:
  match short n b:
    case _ 0n _:
      pcm
    case True{} 1n+k lo <> hi <> rest:
      +v = (lo .|. (hi << 8n) : U32)
      Wav.samples(True{}, k, rest, (at + 1 : U32), Array.set(F32, pcm, at,
        ((U32.to_f32(v) - R.pick((v >= 32768 : U32), 65536.0, 0.0)) / 32768.0 : F32)))
    case False{} 1n+k x <> y <> z <> w <> rest:
      Wav.samples(False{}, k, rest, (at + 1 : U32), Array.set(F32, pcm, at,
        Wav.float((x .|. (y << 8n) .|. (z << 16n) .|. (w << 24n) : U32))))
    case _ _ _:
      pcm

# The data chunk of `size` bytes decoded into the store at `at` (PCM16
# or float32); the clip.
def Wav.data(+f: Wave, +size: U32, b: List<&2, U32>, +at: U32, pcm: Array<F32>) -> Array<F32> & Clip:
  Wave{kind, ch, rate, bits} = f
  +short = U32.is_eq(kind, 1)
  +ok = ((short && U32.is_eq(bits, 16)) || (U32.is_eq(kind, 3) && U32.is_eq(bits, 32)))
  +n = R.word(ok, (size / (bits / 8) : U32), 0)
  (Wav.samples(short, U32.to_nat(n), b, at, pcm),
    Clip{at, (n / R.word((ch > 0 : U32), ch, 1) : U32), rate, R.word((ch > 0 : U32), ch, 1)})

# The format chunk (an extensible one's kind sits at 24).
def Wav.fmt(+b: List<&2, U32>) -> Wave:
  +kind = Wav.u16(b)
  Wave{R.word(U32.is_eq(kind, 65534), Wav.u16(Wav.skip(24n, b)), kind), Wav.u16(Wav.skip(2n, b)),
    Wav.u32(Wav.skip(4n, b)), Wav.u16(Wav.skip(14n, b))}

def Wav.tag.of(fmt: Bool, data: Bool) -> Tag:
  match fmt data:
    case True{} _:
      Fmt{}
    case _ True{}:
      Body{}
    case _ _:
      Skip{}

def Wav.tag(+w: U32) -> Tag:
  Wav.tag.of(U32.is_eq(w, 544501094), U32.is_eq(w, 1635017060))

# The chunks walked on a fuel: fmt gives the format, data is decoded
# and ends the walk, any other is skipped (padded to even).
def Wav.walk(
  fuel: Nat, tag: Tag, +size: U32, +b: List<&2, U32>, +f: Wave, +at: U32, pcm: Array<F32>
) -> Array<F32> & Clip:
  match fuel tag b:
    case 0n _ _:
      (pcm, Clip{at, 0, 48000, 1})
    case 1n+k _ Nil{}:
      (pcm, Clip{at, 0, 48000, 1})
    case 1n+k Head{} _:
      Wav.walk(k, Wav.tag(Wav.u32(b)), Wav.u32(Wav.skip(4n, b)), Wav.skip(8n, b), f, at, pcm)
    case 1n+k Fmt{} _:
      Wav.walk(k, Head{}, 0, Wav.skip(U32.to_nat((size + (size .&. 1) : U32)), b), Wav.fmt(b), at, pcm)
    case 1n+k Skip{} _:
      Wav.walk(k, Head{}, 0, Wav.skip(U32.to_nat((size + (size .&. 1) : U32)), b), f, at, pcm)
    case 1n+k Body{} _:
      Wav.data(f, size, b, at, pcm)

def Asset.got(r: Result<&1, &1, U32 & String, List<&2, U32>>) -> List<&2, U32>:
  match r:
    case Done{b}:
      b
    case Fail{_}:
      Nil{}

# The bytes read (up to 1 MB), the file closed; none on a failure.
def Asset.read(m: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(List<&2, U32>):
  (f, r) = m
  do IO<List<&2, U32>>:
    Unit <- File.close(f)
    IO.pure(List<&2, U32>, Asset.got(r))

# An asset opened from the cwd, else from the demo's dir; missing, a
# warning and no bytes.
def Asset.opened(
  tries: Nat, +name: String, r: Result<&1, &1, U32 & String, File>
) -> IO(List<&2, U32>):
  match tries r:
    case _ Done{f}:
      do IO<List<&2, U32>>:
        m : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 1048576)
        Asset.read(m)
    case 0n Fail{_}:
      do IO<List<&2, U32>>:
        Unit <- IO.print_err("sound: " ++ name ++ " is missing (silent)")
        IO.pure(List<&2, U32>, Nil{})
    case 1n+k Fail{_}:
      do IO<List<&2, U32>>:
        r2 : Result<&1, &1, U32 & String, File> <- File.open("../../media/slash_boss_3d/" ++ name, "r")
        Asset.opened(k, name, r2)

def Asset.bytes(+name: String) -> IO(List<&2, U32>):
  do IO<List<&2, U32>>:
    r : Result<&1, &1, U32 & String, File> <- File.open("media/slash_boss_3d/" ++ name, "r")
    Asset.opened(1n, name, r)

def Clip.size(+c: Clip) -> U32:
  Clip{_, frames, _, ch} = c
  (frames * ch : U32)

def Clip.frames(+c: Clip) -> U32:
  Clip{_, frames, _, _} = c
  frames

# The named WAV files decoded one after another into the store, each
# after the last clip (the chunks walked on a fuel); the clips, last
# first.
def Asset.each(
  names: List<String>, +at: U32, clips: List<&2, Clip>, r: Array<F32> & Clip
) -> IO(Array<F32> & List<&2, Clip>):
  match names:
    case Nil{}:
      (pcm, clip) = r
      IO.pure(Array<F32> & List<&2, Clip>, (pcm, clip <> clips))
    case name <> rest:
      (pcm, +clip) = r
      +at2 = (at + Clip.size(clip) : U32)
      do IO<Array<F32> & List<&2, Clip>>:
        b : List<&2, U32> <- Asset.bytes(name)
        Asset.each(rest, at2, clip <> clips, Wav.walk(64n, Head{}, 0, Wav.skip(12n, b),
          Wave{1, 1, 48000, 16}, at2, pcm))

# The synthesized clips 0 to n - 1 before the rest.
def Bank.synth(+n: Nat, rest: List<&2, Clip>) -> List<&2, Clip>:
  match n:
    case 0n:
      rest
    case 1n+k:
      Bank.synth(k, Clip{(U32.from_nat(k) * 65536 : U32), 65536, 48000, 1} <> rest)

# The bank by kind from the files loaded (last first, after the
# synthesized region's stand-in): the three bell parts are one
# gapless clip.
def Bank.build(files: List<&2, Clip>) -> List<&2, Clip>:
  match files:
    case parry <> dash <> blade <> whoosh <> c <> b <> a <> _:
      Clip{start, fa, rate, ch} = a
      Bank.synth(14n, [Clip{start, (fa + Clip.frames(b) + Clip.frames(c) : U32), rate, ch}, whoosh,
        blade, dash, parry])
    case _:
      Bank.synth(14n, Nil{})

def Bank.at(n: Nat, +bank: List<&2, Clip>) -> Clip:
  match n bank:
    case _ Nil{}:
      Clip{0, 0, 48000, 1}
    case 0n c <> _:
      c
    case 1n+k _ <> rest:
      Bank.at(k, rest)

# A voice of a clip: its step a frame is the clip's rate over the
# device's times the rate asked; the pan keeps the centre's level.
def Voice.of(+clip: Clip, +gain: F32, +pan: F32, +rate: F32, loop: Bool) -> Voice:
  Clip{_, _, crate, _} = clip
  Voice{clip, 0.0, (U32.to_f32(crate) / 48000.0 * rate : F32), (gain * R.min(1.0, (1.0 - pan : F32)) : F32),
    (gain * R.min(1.0, (1.0 + pan : F32)) : F32), loop}

def Voices.count(+vs: List<&2, Voice>) -> U32:
  match vs:
    case Nil{}:
      0
    case _ <> rest:
      (1 + Voices.count(rest) : U32)

def Voices.snoc(vs: List<&2, Voice>, v: Voice) -> List<&2, Voice>:
  match vs:
    case Nil{}:
      [v]
    case x <> rest:
      x <> Voices.snoc(rest, v)

# The oldest voice that does not loop, stolen.
def Voices.steal(vs: List<&2, Voice>) -> List<&2, Voice>:
  match vs:
    case Nil{}:
      Nil{}
    case Voice{clip, pos, step, gl, gr, True{}} <> rest:
      Voice{clip, pos, step, gl, gr, True{}} <> Voices.steal(rest)
    case Voice{clip, pos, step, gl, gr, False{}} <> rest:
      rest

# A voice added (none for an empty clip), the oldest stolen at 24.
def Voices.put(ok: Bool, full: Bool, v: Voice, vs: List<&2, Voice>) -> List<&2, Voice>:
  match ok full:
    case False{} _:
      vs
    case True{} True{}:
      Voices.snoc(Voices.steal(vs), v)
    case True{} False{}:
      Voices.snoc(vs, v)

def Voices.keep(gone: Bool, v: Voice, rest: List<&2, Voice>) -> List<&2, Voice>:
  match gone:
    case True{}:
      rest
    case False{}:
      v <> rest

# The voices a block later: a looping one wraps, one past its clip's
# end is gone.
def Voices.step(+vs: List<&2, Voice>) -> List<&2, Voice>:
  match vs:
    case Nil{}:
      Nil{}
    case Voice{clip, pos, step, gl, gr, loop} <> rest:
      Clip{start, frames, rate, ch} = clip
      +fr = U32.to_f32(frames)
      +next = (pos + step * 512.0 : F32)
      +over = (next >= fr : F32)
      Voices.keep((over && Bool.not(loop)),
        Voice{Clip{start, frames, rate, ch}, R.pick((over && loop), F32.mod(next, fr), next), step, gl, gr, loop},
        Voices.step(rest))

# The sample after i1 - 1: wrapped to 0 for a loop, else held at the
# last.
def Mix.next(loop: Bool, +i1: U32, +frames: U32) -> U32:
  match loop:
    case True{}:
      R.word((i1 >= frames : U32), 0, i1)
    case False{}:
      R.word((i1 >= frames : U32), (frames - 1 : U32), i1)

# A sample v added to the block at k.
def Mix.ch3(+k: U32, +v: F32, pcm: Array<F32>, r: Array<F32> & F32) -> Array<F32> & Array<F32>:
  (out, o) = r
  (pcm, Array.set(F32, out, k, (o + v : F32)))

# A channel's sample at the cursor (s0 at the frame, s1 at the next,
# interpolated by f; silent past the end) into the block at k.
def Mix.ch2(
  +k: U32, +f: F32, +live: F32, +g: F32, +s0: F32, out: Array<F32>, r: Array<F32> & F32
) -> Array<F32> & Array<F32>:
  (pcm, s1) = r
  Mix.ch3(k, ((s0 + (s1 - s0) * f) * live * g : F32), pcm, Array.get(F32, out, k))

def Mix.ch(
  +k: U32, +f: F32, +live: F32, +g: F32, +a1: U32, out: Array<F32>, r: Array<F32> & F32
) -> Array<F32> & Array<F32>:
  (pcm, s0) = r
  Mix.ch2(k, f, live, g, s0, out, Array.get(F32, pcm, a1))

# The right channel after the left: its samples at a0 and a1.
def Mix.t1(
  +k: U32, +f: F32, +live: F32, +g: F32, +a0: U32, +a1: U32, ro: Array<F32> & Array<F32>
) -> Array<F32> & Array<F32>:
  (pcm, out) = ro
  Mix.ch(k, f, live, g, a1, out, Array.get(F32, pcm, a0))

# A clip's frame at the cursor (floor i0, fraction f) into frame i of
# the block, the left channel then the right (a mono clip reads its
# channel twice).
def Mix.t0(
  +i: U32, +c: F32, +start: U32, +frames: U32, loop: Bool, +gl: F32, +gr: F32, +ch: U32,
  ro: Array<F32> & Array<F32>
) -> Array<F32> & Array<F32>:
  (pcm, out) = ro
  +i0 = F32.to_u32(c)
  +f = (c - U32.to_f32(i0) : F32)
  +hit = (i0 < frames : U32)
  +live = R.pick(hit, 1.0, 0.0)
  +a0 = (start + ch * R.word(hit, i0, (frames - 1 : U32)) : U32)
  +a1 = (start + ch * Mix.next(loop, (i0 + 1 : U32), frames) : U32)
  +off = R.word(U32.is_eq(ch, 1), 0, 1)
  Mix.t1((2 * i + 1 : U32), f, live, gr, (a0 + off : U32), (a1 + off : U32),
    Mix.ch((2 * i : U32), f, live, gl, a1, out, Array.get(F32, pcm, a0)))

# k frames of a voice from frame i at the cursor c into the block; a
# looping cursor wraps.
def Mix.run(
  k: Nat, +i: U32, +c: F32, +step: F32, +start: U32, +frames: U32, +loop: Bool, +gl: F32, +gr: F32,
  +ch: U32, ro: Array<F32> & Array<F32>
) -> Array<F32> & Array<F32>:
  match k:
    case 0n:
      ro
    case 1n+j:
      +c2 = (c + step : F32)
      Mix.run(j, (i + 1 : U32), R.pick((loop && (c2 >= U32.to_f32(frames) : F32)),
          (c2 - U32.to_f32(frames) : F32), c2), step, start, frames, loop, gl, gr, ch,
        Mix.t0(i, c, start, frames, loop, gl, gr, ch, ro))

def Mix.voices(+vs: List<&2, Voice>, ro: Array<F32> & Array<F32>) -> Array<F32> & Array<F32>:
  match vs:
    case Nil{}:
      ro
    case Voice{clip, pos, step, gl, gr, loop} <> rest:
      Clip{start, frames, _, ch} = clip
      Mix.voices(rest, Mix.run(U32.to_nat(512), 0, pos, step, start, frames, loop, gl, gr, ch, ro))

# The block's samples from i down as a list, each clamped.
def Mix.list(k: Nat, +i: U32, acc: List<&2, F32>, r: Array<F32> & F32) -> List<&2, F32>:
  match k:
    case 0n:
      (out, x) = r
      R.clamp(x, (0.0 - 1.0 : F32), 1.0) <> acc
    case 1n+j:
      (out, x) = r
      Mix.list(j, (i - 1 : U32), R.clamp(x, (0.0 - 1.0 : F32), 1.0) <> acc,
        Array.get(F32, out, (i - 1 : U32)))

def Mix.fin(
  dev: Maybe<Audio>, +bank: List<&2, Clip>, +voices: List<&2, Voice>, +queued: U32, +stamp: Nat,
  ro: Array<F32> & Array<F32>
) -> Sound:
  (pcm, out) = ro
  Sound{dev, pcm, bank, Voices.step(voices), voices,
    Mix.list(U32.to_nat(1023), 1023, Nil{}, Array.get(F32, out, 1023)), queued, stamp}

# A block rendered: every voice into a fresh block of 1024 samples,
# listed; the voices stepped, the old ones kept.
def Mix.render(s: Sound) -> Sound:
  Sound{dev, pcm, bank, voices, _, _, queued, stamp} = s
  Mix.fin(dev, bank, voices, queued, stamp, Mix.voices(voices, (pcm, [0.0 : F32*1024n])))

# A cue started: its voice joins the voices (the oldest that does not
# loop stolen at 24; an empty clip is nothing).
def Sound.play(s: Sound, +c: Cue) -> Sound:
  Sound{dev, pcm, bank, voices, prev, block, queued, stamp} = s
  Cue{kind, gain, pan, rate, loop} = c
  +clip = Bank.at(U32.to_nat(kind), bank)
  Sound{dev, pcm, bank, Voices.put((Clip.frames(clip) > 0 : U32), (Voices.count(voices) >= 24 : U32),
      Voice.of(clip, gain, pan, rate, loop), voices), prev, block, queued, stamp}

def Sound.cues(cues: List<&2, Cue>, s: Sound) -> Sound:
  match cues:
    case Nil{}:
      s
    case c <> rest:
      Sound.cues(rest, Sound.play(s, c))

# The write's answer: the frames queued now, at this clock; a dropped
# block (the queue was full) leaves the voices where they were.
def Sound.after(
  old: Maybe<Audio>, pcm: Array<F32>, +bank: List<&2, Clip>, +voices: List<&2, Voice>,
  +prev: List<&2, Voice>, +now: Nat, r: Audio & U32
) -> Sound & Audio:
  (dev, +q) = r
  (Sound{old, pcm, bank, Bool.pick(List<&2, Voice>, (q > 3584 : U32), prev, voices), prev, Nil{},
    q, now}, dev)

def Sound.write(dev: Audio, s: Sound, +now: Nat) -> IO(Sound & Audio):
  Sound{old, pcm, bank, voices, prev, block, _, _} = s
  do IO<Sound & Audio>:
    r : Audio & U32 <- Audio.write(dev, block)
    IO.pure(Sound & Audio, Sound.after(old, pcm, bank, voices, prev, now, r))

def Sound.feed(n: Nat, +now: Nat, sr: Sound & Audio) -> IO(Sound):
  match n:
    case 0n:
      (s, dev) = sr
      Sound{_, pcm, bank, voices, prev, block, queued, stamp} = s
      IO.pure(Sound, Sound{Some{dev}, pcm, bank, voices, prev, block, queued, stamp})
    case 1n+k:
      (s, dev) = sr
      do IO<Sound>:
        sr2 : Sound & Audio <- Sound.write(dev, Mix.render(s), now)
        Sound.feed(k, now, sr2)

# The device fed: the queue as of now (the last count less 48 frames a
# ms since) under 1024 frames asks blocks of 512, at most 8 a frame;
# paused, none.
def Sound.serve(s: Sound, +now: Nat, paused: Bool) -> IO(Sound):
  Sound{dev, pcm, bank, voices, prev, block, queued, stamp} = s
  match dev:
    case None{}:
      IO.pure(Sound, Sound{None{}, pcm, bank, voices, prev, block, queued, stamp})
    case Some{a}:
      +drained = (U32.from_nat(Nat.sub(now, stamp)) * 48 : U32)
      +est = R.word((drained < queued : U32), (queued - drained : U32), 0)
      +want = ((1024 - est + 511) / 512 : U32)
      +n = R.word((paused || (est >= 1024 : U32)), 0, R.word((want < 8 : U32), want, 8))
      Sound.feed(U32.to_nat(n), now, (Sound{None{}, pcm, bank, voices, prev, block, queued, stamp}, a))

def Sound.close(s: Sound) -> IO(Unit):
  Sound{dev, _, _, _, _, _, _, _} = s
  match dev:
    case None{}:
      IO.pure(Unit, Unit{})
    case Some{a}:
      Audio.close(a)

def Sound.device(r: Result<&1, &1, U32 & String, Audio>) -> IO(Maybe<Audio>):
  match r:
    case Done{a}:
      IO.pure(Maybe<Audio>, Some{a})
    case Fail{(code, text)}:
      do IO<Maybe<Audio>>:
        Unit <- IO.print_err("sound: " ++ text ++ " (silent)")
        IO.pure(Maybe<Audio>, None{})

# The sound made: the ambient drone loops from the start.
def Sound.made(dev: Maybe<Audio>, loaded: Array<F32> & List<&2, Clip>) -> Sound:
  (pcm, files) = loaded
  Sound.play(Sound{dev, pcm, Bank.build(files), Nil{}, Nil{}, Nil{}, 0, 0n},
    Cue{13, 0.28, 0.0, 1.0, True{}})

# The device (or none, with a warning), the 14 clips synthesized, the
# 7 files decoded after them.
def Sound.open() -> IO(Sound):
  do IO<Sound>:
    r : Result<&1, &1, U32 & String, Audio> <- Audio.open(48000)
    dev : Maybe<Audio> <- Sound.device(r)
    loaded : Array<F32> & List<&2, Clip> <- Asset.each(["bell_a.wav", "bell_b.wav",
        "bell_c.wav", "whoosh.wav", "blade.wav", "dash.wav", "parry.wav"], 0, Nil{},
      (Synth.all(14n, [0.0 : F32^21n]), Clip{0, 917504, 48000, 1}))
    IO.pure(Sound, Sound.made(dev, loaded))

def Cue.add(
  on: Bool, +kind: U32, +gain: F32, +pan: F32, +rate: F32, acc: List<&2, Cue>
) -> List<&2, Cue>:
  match on:
    case True{}:
      Cue{kind, gain, pan, rate, False{}} <> acc
    case False{}:
      acc

# The cues of a tick from a to b, panned by x / 15: swings and the
# blade, the parry, hits, jumps, landings, dodges, deaths, the boss's
# voice, the bell, the whoosh, the slam, the draw.
def Cue.list(+a: Game, +b: Game, acc: List<&2, Cue>) -> List<&2, Cue>:
  Game{t0, _, _, m0, hero0, boss0, f0, _, _, _, _} = a
  Fighter{p1, v1, face1, damage1, guard1, jumps1, action1, age1, inv1, stocks1, grace1, queued1,
    charge1} = hero0
  Boss{_, _, _, _, _, _, state1, _, _, _, _} = boss0
  Game{time, _, _, mode, hero, boss, flash, _, _, _, _} = b
  Fighter{p, v, _, _, _, _, action, age, _, stocks, _, _, charge} = hero
  Boss{q, _, _, _, stun, _, state, bage, _, _, _} = boss
  +changed = U32.is_ne(t0, time)
  +attack = (changed && Act.attack(action) && (U32.is_ne(action1, action) || (age > age1 : U32)))
  +special = Act.special(action)
  +side = (U32.is_eq(action, 20) || U32.is_eq(action, 24))
  +new_hit = (changed && (flash > f0 : U32))
  +death = (stocks < stocks1 : U32)
  +land = ((Vec.y(v1) < (0.0 - 0.03 : F32) : F32) && Bool.not(Fighter.air(p, v)))
  +jump = ((Vec.y(v) > 0.3 : F32) && (Vec.y(v1) <= 0.0 : F32))
  +pan = R.clamp((Vec.x(p) / 15.0 : F32), (0.0 - 0.7 : F32), 0.7)
  +bpan = R.clamp((Vec.x(q) / 15.0 : F32), (0.0 - 0.7 : F32), 0.7)
  +kind = R.word((charge > 2 : U32), 6, R.word(special, 0, R.word(Act.up(action), 3,
    R.word(side, 2, 1))))
  +parried = (new_hit && U32.is_eq(action, 3) && (stun > 0 : U32))
  +bfresh = (changed && U32.is_eq(bage, 0) && U32.is_ne(state, state1))
  Cue.add(attack, kind, 0.63, pan, (0.96 + U32.to_f32((time % 7 : U32)) * 0.013 : F32),
    Cue.add(attack, R.word(side, 17, 16), 0.44, pan, 1.0,
    Cue.add(parried, 18, 0.60, pan, 1.0,
    Cue.add((new_hit && Bool.not(death)), R.word(parried, 5, 4), 0.70, pan, 1.0,
    Cue.add((changed && jump), 8, 0.56, pan, 1.0,
    Cue.add((changed && land), 9, 0.65, pan, 1.0,
    Cue.add((changed && U32.is_eq(action, 6) && U32.is_ne(action1, 6)), 7, 0.65, pan, 1.0,
    Cue.add((death || (U32.is_eq(mode, 2) && U32.is_ne(m0, 2))), 10, 0.85, 0.0, 1.0,
    Cue.add((changed && U32.is_ne((time / 240 : U32), (t0 / 240 : U32))), 11, 0.35, bpan, 1.0,
    Cue.add((U32.is_eq(m0, 0) && U32.is_eq(mode, 1)), 14, 0.65, 0.0, 1.0,
    Cue.add((attack && special && U32.is_eq((time % 3 : U32), 0)), 15, 0.40, pan, 1.0,
    Cue.add((bfresh && U32.is_eq(state, 7)), 4, 0.98, bpan, 0.8,
    Cue.add((bfresh && U32.is_eq(state, 5)), 5, 0.55, bpan, 1.0,
    Cue.add((bfresh && Act.in(state, 1, 5)), 11, 0.30, bpan, 1.0, acc))))))))))))))

# Loop
# ----

# The live state: the game, the tick before it (the view lies between
# them), the clock at the last frame, the debt of a tick in
# thousandths, the clock the count began at, the count, the cues.
type Live is Data:
  Live{game: Game, prev: Game, stamp: Nat, debt: U32, begin: Nat, frames: U32, cues: List<&2, Cue>}

def Game.paused(+g: Game) -> Bool:
  Game{_, _, _, mode, _, _, _, _, _, _, _} = g
  U32.is_eq(mode, 4)

def Game.quit(esc: Bool, g: Game) -> Maybe<Game>:
  match esc:
    case True{}:
      None{}
    case False{}:
      Some{g}

# A key sets its bit; Esc or Close ends.
def Game.event(+e: Event, g: Game) -> Maybe<Game>:
  match e:
    case Key{code, down}:
      Game.quit(U32.is_eq(code, 27), Game.key(g, code, down))
    case Close{}:
      None{}
    case _:
      Some{g}

def Game.events(events: List<Event>, g: Game) -> Maybe<Game>:
  match events:
    case Nil{}:
      Some{g}
    case e <> rest:
      Maybe.bind(&1, Game, Game, Game.event(e, g), g2 => Game.events(rest, g2))

# n ticks, the last two kept, their cues gathered.
def Live.steps(
  n: Nat, prev: Game, +g: Game, now: Nat, +debt: U32, begin: Nat, +frames: U32, cues: List<&2, Cue>
) -> Live:
  match n:
    case 0n:
      Live{g, prev, now, debt, begin, frames, cues}
    case 1n+k:
      +g2 = Game.step(g)
      Live.steps(k, g, g2, now, debt, begin, frames, Cue.list(g, g2, cues))

# The ticks a frame owes: 60 a second of the elapsed time (at most 100
# ms of it), the rest kept as debt.
def Live.after(
  m: Maybe<Game>, prev: Game, +stamp: Nat, +debt: U32, +now: Nat, begin: Nat, frames: U32,
  cues: List<&2, Cue>
) -> Maybe<Live>:
  match m:
    case None{}:
      None{}
    case Some{g}:
      +ms = U32.from_nat(Nat.sub(now, stamp))
      +total = (debt + R.word((ms < 100 : U32), ms, 100) * 60 : U32)
      Some{Live.steps(U32.to_nat((total / 1000 : U32)), prev, g, now, (total % 1000 : U32), begin,
        frames, cues)}

# The view of the live state: the game between its last two ticks; a
# def of its own, so the state is taken here and the lerp moves the
# cloths instead of borrowing them.
def Live.view(+s: Live, used: R.Cells) -> R.Cells:
  Live{game, prev, _, debt, _, _, _} = s
  +u = (U32.to_f32(debt) / 1000.0 : F32)
  Scene.build(Game.lerp(prev, game, u), Game.clock(game, u), used)

# The frames counted: past half a second the title shows their rate
# and a new count begins at now.
def Play.pace(
  ready: Bool, window: Window, +ms: U32, +count: U32, now: Nat, begin: Nat,
  k: Window -> Nat -> U32 -> IO(Unit)
) -> IO(Unit):
  match ready:
    case False{}:
      k(window, begin, count)
    case True{}:
      IO.bind(Window, Unit, Window.set_title(window, "Slash Boss 3D | "
        ++ U32.show(((count * 1000 + ms / 2) / ms : U32)) ++ " FPS"), w => k(w, now, 0))

# The frame's cues into the sound and the device fed (silent in a
# pause), then the next turn.
def Play.serve(
  window: Window, +live: Live, snd: Sound, +now: Nat, rest: Window -> Live -> Sound -> IO(Unit)
) -> IO(Unit):
  Live{game, prev, stamp, debt, begin, frames, cues} = live
  Game{_, _, _, mode, _, _, _, _, _, _, _} = game
  do IO<Unit>:
    snd2 : Sound <- Sound.serve(Sound.cues(cues, snd), now, U32.is_eq(mode, 4))
    rest(window, Live{game, prev, stamp, debt, begin, frames, Nil{}}, snd2)

# The end closes the sound and the window.
def Play.go(
  window: Window, snd: Sound, +now: Nat, rest: Window -> Live -> Sound -> IO(Unit), next: Maybe<Live>
) -> IO(Unit):
  match next:
    case None{}:
      do IO<Unit>:
        Unit <- Sound.close(snd)
        Window.close(window)
    case Some{live}:
      Play.serve(window, live, snd, now, rest)

# The title paced, the events into the game, then the ticks owed.
def Play.next(
  window: Window, events: List<Event>, game: Game, prev: Game, stamp: Nat, debt: U32,
  +begin: Nat, +frames: U32, +now: Nat, cues: List<&2, Cue>, snd: Sound,
  rest: Window -> Live -> Sound -> IO(Unit)
) -> IO(Unit):
  +ms = U32.from_nat(Nat.sub(now, begin))
  Play.pace((ms >= 500 : U32), window, ms, (frames + 1 : U32), now, begin,
    w => b => fr => Play.go(w, snd, now, rest, Live.after(Game.events(events, game), prev, stamp,
      debt, now, b, fr, cues)))

# The image shown and its scene are kept for the next frame's bang
# and build to drop.
def Play.turn(
  shown: Window & Image & List<Event>, cells: R.Cells, +s: Live, snd: Sound,
  rest: Window -> Live -> Sound -> (Image & R.Cells) -> IO(Unit)
) -> IO(Unit):
  (window, image, events) = shown
  Live{game, prev, stamp, debt, begin, frames, cues} = s
  do IO<Unit>:
    now : Nat <- IO.now()
    Play.next(window, events, game, prev, stamp, debt, begin, frames, now, cues, snd,
      w => l => sn => rest(w, l, sn, (image, cells)))

# The frame to the window, the next turn.
def Play.blit(
  drawn: Image & R.Cells, window: Window, s: Live, snd: Sound,
  rest: Window -> Live -> Sound -> (Image & R.Cells) -> IO(Unit)
) -> IO(Unit):
  (image, cells) = drawn
  do IO<Unit>:
    shown : Window & Image & List<Event> <- Window.frame(window, image)
    Play.turn(shown, cells, s, snd, rest)

# A turn: the scene (the last one dropped in its build), an IO seam
# (the bang must not follow the host's forks in one evaluation), the
# frame (the last one dropped in its bang).
@unsafe
def Play.loop(window: Window, +s: Live, snd: Sound, last: Image & R.Cells) -> IO(Unit):
  (old, used) = last
  do IO<Unit>:
    cells : R.Cells = Live.view(s, used)
    now : Nat <- IO.now()
    drawn : Image & R.Cells <- IO.pure(Image & R.Cells, Play.frame(cells, old))
    Play.blit(drawn, window, s, snd, w => s2 => snd2 => l => Play.loop(w, s2, snd2, l))

def Play.run() -> IO(Unit):
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open("Slash Boss 3D", 1920, 1200))
    snd : Sound <- Sound.open()
    +stamp : Nat <- IO.now()
    Play.loop(window, Live{Game.init(), Game.init(), stamp, 0, stamp, 0, Nil{}}, snd,
      (Pix{0}, R.CNil{}))

# Probe
# -----

def Script.at(+t: U32, +a: U32, +b: U32, +m: U32) -> U32:
  R.word(((t >= a) && (t < b) : U32), m, 0)

# The keys held at a tick of the script: a run, hops, every attack, a
# charged smash, a guard, an air dodge, a dash, a fall off the edge and
# the respawn, the specials.
def Script.held(+t: U32) -> U32:
  (Script.at(t, 1, 3, 128) .|. Script.at(t, 60, 84, 8) .|. Script.at(t, 90, 92, 16)
    .|. Script.at(t, 120, 122, 64) .|. Script.at(t, 126, 128, 16)
    .|. Script.at(t, 180, 182, 8) .|. Script.at(t, 180, 230, 16)
    .|. Script.at(t, 260, 262, 17) .|. Script.at(t, 290, 292, 20)
    .|. Script.at(t, 330, 332, 32) .|. Script.at(t, 370, 372, 33)
    .|. Script.at(t, 340, 356, 8) .|. Script.at(t, 420, 422, 36)
    .|. Script.at(t, 480, 540, 128)
    .|. Script.at(t, 560, 562, 64) .|. Script.at(t, 566, 580, 2) .|. Script.at(t, 568, 570, 128)
    .|. Script.at(t, 620, 622, 64) .|. Script.at(t, 626, 628, 17)
    .|. Script.at(t, 660, 662, 64) .|. Script.at(t, 666, 668, 20)
    .|. Script.at(t, 700, 702, 64) .|. Script.at(t, 706, 708, 24)
    .|. Script.at(t, 740, 742, 64) .|. Script.at(t, 746, 748, 18)
    .|. Script.at(t, 800, 802, 40) .|. Script.at(t, 830, 880, 8)
    .|. Script.at(t, 900, 902, 16) .|. Script.at(t, 950, 952, 18) .|. Script.at(t, 1000, 1002, 18)
    .|. Script.at(t, 1050, 1052, 17) .|. Script.at(t, 1100, 1102, 20)
    .|. Script.at(t, 1150, 1152, 34) : U32)

# The script's rig: the hero has 9 lives from tick 10; the boss's
# vitality is 150 at tick 420 (enraged) and 3 at 900.
def Script.hp(+g: Game, +t: U32) -> Game:
  Game{time, held, taps, mode, hero, boss, flash, cloth, garb, lens, blast} = g
  Fighter{q, hv, yaw, damage, guard, jumps, action, hage, inv, stocks, grace, queued, charge} = hero
  Boss{p, v, face, hp, stun, strain, state, age, hold, mark, gait} = boss
  Game{time, held, taps, mode, Fighter{q, hv, yaw, damage, guard, jumps, action, hage, inv,
      R.word(U32.is_eq(t, 10), 9, stocks), grace, queued, charge},
    Boss{p, v, face, R.pick(U32.is_eq(t, 420), 150.0, R.pick(U32.is_eq(t, 900), 3.0, hp)),
      stun, strain, state, age, hold, mark, gait}, flash, cloth, garb, lens, blast}

def Script.tick(+g: Game, +t: U32) -> Game:
  Game{time, _, taps, mode, hero, boss, flash, cloth, garb, lens, blast} = g
  +h = Script.held(t)
  Game.step(Script.hp(Game{time, h, (taps .|. (h .&. U32.not(Script.held(Sim.dec(t)))) : U32), mode,
    hero, boss, flash, cloth, garb, lens, blast}, t))

def Game.walk(n: Nat, +g: Game, +t: U32) -> Game:
  match n:
    case 0n:
      g
    case 1n+k:
      Game.walk(k, Script.tick(g, t), (t + 1 : U32))

# SLASH_MODE puts the game in a mode (9: the fight with the parry cue
# up).
def Probe.rig(+g: Game, +m: U32) -> Game:
  Game{time, held, taps, mode, hero, boss, flash, cloth, garb, lens, blast} = g
  Fighter{p, v, face, damage, guard, jumps, action, age, inv, stocks, grace, queued, charge} = hero
  Boss{q, bv, yaw, hp, stun, strain, state, bage, hold, mark, gait} = boss
  +cue = U32.is_eq(m, 9)
  Game{time, held, taps, R.word((m > 4 : U32), mode, m),
    Fighter{p, v, face, damage, guard, jumps, R.word(cue, 3, action), age, inv, stocks, grace,
      queued, charge},
    Boss{q, bv, yaw, hp, R.word(cue, 5, stun), strain, state, bage, hold, mark, gait},
    R.word(cue, 3, flash), cloth, garb, lens, blast}

# The measured frames: their count and the ms of the scene's build,
# the frame's bang, the sim's tick, the sound's mix and the whole turn.
type Sums is Data:
  Sums{n: U32, build: U32, draw: U32, tick: U32, mix: U32, whole: U32}


def Probe.ms(+a: Nat, +b: Nat) -> U32:
  U32.from_nat(Nat.sub(b, a))

def Sums.add(warm: Bool, +s: Sums, +b: U32, +d: U32, +k: U32, +m: U32, +w: U32) -> Sums:
  match warm:
    case True{}:
      s
    case False{}:
      Sums{n, sb, sd, sk, sm, sw} = s
      Sums{(n + 1 : U32), (sb + b : U32), (sd + d : U32), (sk + k : U32), (sm + m : U32),
        (sw + w : U32)}

# The sums after a frame (the clocks after its scene and its bang),
# beside its image and its scene (the next bang and build drop them).
def Sums.next(
  ti: Nat & Nat & Image & R.Cells, warm: Bool, +s: Sums, +t0: Nat, +t5: Nat, +t6: Nat, +t7: Nat
) -> Sums & Image & R.Cells:
  (+t1, t2, img, used) = ti
  (Sums.add(warm, s, Probe.ms(t0, t1), Probe.ms(t1, t2), Probe.ms(t5, t6), Probe.ms(t6, t7),
    Probe.ms(t0, t7)), img, used)

# Microseconds a frame.
def Probe.us(+sum: U32, +n: U32) -> String:
  U32.show((sum * 1000 / n : U32))

def Probe.report(+s: Sums) -> IO(Unit):
  Sums{n, build, draw, tick, mix, whole} = s
  IO.print("frames " ++ U32.show(n) ++ " build " ++ Probe.us(build, n) ++ " draw "
    ++ Probe.us(draw, n) ++ " tick " ++ Probe.us(tick, n) ++ " mix " ++ Probe.us(mix, n)
    ++ " whole " ++ Probe.us(whole, n))

# The frame of a built scene, the bang timed; the image and the scene
# come back for the next frame to drop.
def Probe.frame(cells: R.Cells, old: Image) -> IO(Nat & Nat & Image & R.Cells):
  do IO<Nat & Nat & Image & R.Cells>:
    t1 : Nat <- IO.now()
    drawn : Image & R.Cells <- IO.pure(Image & R.Cells, Play.frame(cells, old))
    t2 : Nat <- IO.now()
    IO.pure(Nat & Nat & Image & R.Cells, (t1, t2, drawn))

# The state in a line: the tick, the mode, the hero (place, speed,
# action, damage, guard, lives, invulnerable ticks), the boss (place,
# vitality, stun).
def Probe.line(+g: Game) -> String:
  Game{time, _, _, mode, hero, boss, _, _, _, _, _} = g
  Fighter{p, v, _, damage, guard, _, action, age, inv, stocks, _, _, _} = hero
  R.Vec{x, y, _} = p
  R.Vec{vx, vy, _} = v
  Boss{q, _, _, hp, stun, _, state, bage, _, _, _} = boss
  R.Vec{bx, by, _} = q
  "t " ++ U32.show(time) ++ " mode " ++ U32.show(mode) ++ " hero " ++ F32.show(x) ++ " "
    ++ F32.show(y) ++ " v " ++ F32.show(vx) ++ " " ++ F32.show(vy) ++ " act " ++ U32.show(action)
    ++ " dmg " ++ F32.show(damage) ++ " guard " ++ F32.show(guard) ++ " lives "
    ++ U32.show(stocks) ++ " inv " ++ U32.show(inv) ++ " boss " ++ F32.show(bx) ++ " "
    ++ F32.show(by) ++ " hp " ++ F32.show(hp) ++ " stun " ++ U32.show(stun) ++ " st "
    ++ U32.show(state) ++ " age " ++ U32.show(bage)

def Probe.say(on: Bool, text: String) -> IO(Unit):
  match on:
    case False{}:
      IO.pure(Unit, Unit{})
    case True{}:
      IO.print(text)

# n blocks rendered, each taken out of the sound onto the list (newest
# first); the game and the cues ride along.
def Probe.push(block: List<&2, F32>, acc: List<&2, List<&2, F32>>) -> List<&2, List<&2, F32>>:
  match block:
    case Nil{}:
      acc
    case x <> rest:
      (x <> rest) <> acc

def Probe.render(
  n: Nat, s: Sound, acc: List<&2, List<&2, F32>>, g: Game, cues: List<&2, Cue>
) -> Game & Sound & List<&2, Cue> & List<&2, List<&2, F32>>:
  match n:
    case 0n:
      Sound{dev, pcm, bank, voices, prev, block, queued, stamp} = s
      (g, Sound{dev, pcm, bank, voices, prev, Nil{}, queued, stamp}, cues, Probe.push(block, acc))
    case 1n+k:
      Sound{dev, pcm, bank, voices, prev, block, queued, stamp} = s
      Probe.render(k, Mix.render(Sound{dev, pcm, bank, voices, prev, Nil{}, queued, stamp}),
        Probe.push(block, acc), g, cues)

def Probe.text(b: List<&2, F32>) -> String:
  match b:
    case Nil{}:
      "\n"
    case x <> rest:
      U32.show(F32.bits(x)) ++ " " ++ Probe.text(rest)

def Probe.wrote(w: File & Result<&1, &1, U32 & String, Unit>) -> IO(Maybe<File>):
  (f, r) = w
  IO.pure(Maybe<File>, Some{f})

def Probe.put(b: List<&2, F32>, f: Maybe<File>) -> IO(Maybe<File>):
  match f:
    case None{}:
      IO.pure(Maybe<File>, None{})
    case Some{file}:
      do IO<Maybe<File>>:
        w : File & Result<&1, &1, U32 & String, Unit> <- File.write(file, Probe.text(b))
        Probe.wrote(w)

# The blocks (newest first) written oldest first.
def Probe.wav(blocks: List<&2, List<&2, F32>>, f: Maybe<File>) -> IO(Maybe<File>):
  match blocks:
    case Nil{}:
      IO.pure(Maybe<File>, f)
    case b <> rest:
      do IO<Maybe<File>>:
        f2 : Maybe<File> <- Probe.wav(rest, f)
        Probe.put(b, f2)

def Probe.close(f: Maybe<File>) -> IO(Unit):
  match f:
    case None{}:
      IO.pure(Unit, Unit{})
    case Some{file}:
      File.close(file)

# A tick's cues into the sound and n blocks rendered: the game after,
# the sound, the cues, the blocks.
def Probe.mix(
  +a: Game, +g2: Game, snd: Sound, n: Nat
) -> Game & Sound & List<&2, Cue> & List<&2, List<&2, F32>>:
  +cues = Cue.list(a, g2, Nil{})
  Probe.render(n, Sound.cues(cues, snd), Nil{}, g2, cues)

def Probe.cues(cues: List<&2, Cue>, +t: U32) -> IO(Unit):
  match cues:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Cue{kind, gain, pan, rate, _} <> rest:
      do IO<Unit>:
        Unit <- IO.print("cue t " ++ U32.show(t) ++ " kind " ++ U32.show(kind) ++ " gain "
          ++ F32.show(gain) ++ " pan " ++ F32.show(pan) ++ " rate " ++ F32.show(rate))
        Probe.cues(rest, t)

def Sound.told(s: Sound, on: Bool) -> IO(Sound):
  Sound{dev, pcm, bank, voices, prev, block, queued, stamp} = s
  do IO<Sound>:
    Unit <- Probe.say(on, "queue " ++ U32.show(queued) ++ " voices " ++ U32.show(Voices.count(voices)))
    IO.pure(Sound, Sound{dev, pcm, bank, voices, prev, block, queued, stamp})

# The device fed as in the game (no dump asked), its queue told every
# 60 ticks.
def Probe.serve(feed: Bool, s: Sound, +now: Nat, +t: U32) -> IO(Sound):
  match feed:
    case False{}:
      IO.pure(Sound, s)
    case True{}:
      do IO<Sound>:
        s2 : Sound <- Sound.serve(s, now, False{})
        Sound.told(s2, U32.is_eq((t % 60 : U32), 0))

# The summary every 60 ticks; the state on a dodge's first tick, on
# the boss's first tick of a state or a stun, on the hero's first hurt
# tick.
def Probe.watch(+g: Game, +t: U32) -> IO(Game):
  Game{_, _, _, mode, hero, boss, _, _, _, _, _} = g
  Fighter{_, _, _, _, _, _, action, age, _, _, _, _, _} = hero
  Boss{_, _, _, _, stun, _, state, bage, _, _, _} = boss
  do IO<Game>:
    Unit <- Probe.say(U32.is_eq((t % 60 : U32), 0), Probe.line(g))
    Unit <- Probe.say((U32.is_eq(action, 6) && U32.is_eq(age, 28)), "dodge " ++ Probe.line(g))
    Unit <- Probe.say((U32.is_eq(mode, 1) && U32.is_eq(bage, 0) && ((state > 0 : U32)
      || (stun > 0 : U32))), "boss " ++ Probe.line(g))
    Unit <- Probe.say((U32.is_eq(action, 4) && U32.is_eq(age, 23)), "hurt " ++ Probe.line(g))
    IO.pure(Game, g)

# N frames of the scripted game: the view, the frame, the tick and the
# mix (800 frames a tick in blocks of 512), each timed; the first 8
# warm up.
def Probe.loop(
  left: Nat, gs: Game & Sound & List<&2, Cue> & List<&2, List<&2, F32>>, +prev: Game, +t: U32,
  si: Sums & Image & R.Cells, +seen: Nat, +rig: U32, +due: U32, file: Maybe<File>, +feed: Bool
) -> IO(Unit):
  match left:
    case 0n:
      (g, snd, cues, blocks) = gs
      (s, img, used) = si
      do IO<Unit>:
        f2 : Maybe<File> <- Probe.wav(blocks, file)
        Unit <- Probe.cues(cues, Sim.dec(t))
        g1 : Game <- Probe.watch(g, Sim.dec(t))
        Unit <- Probe.close(f2)
        Unit <- Sound.close(snd)
        Probe.report(s)
    case 1n+k:
      (+g, snd, cues, blocks) = gs
      (s, img, used) = si
      do IO<Unit>:
        f2 : Maybe<File> <- Probe.wav(blocks, file)
        Unit <- Probe.cues(cues, Sim.dec(t))
        g1 : Game <- Probe.watch(g, Sim.dec(t))
        t8 : Nat <- IO.now()
        snd2 : Sound <- Probe.serve(feed, snd, t8, Sim.dec(t))
        t0 : Nat <- IO.now()
        cells : R.Cells = Scene.build(Probe.rig(Game.lerp(prev, g, 0.5), rig), Game.clock(g, 0.5),
          used)
        ti : Nat & Nat & Image & R.Cells <- Probe.frame(cells, img)
        t5 : Nat <- IO.now()
        g2 : Game = Script.tick(g, t)
        t6 : Nat <- IO.now()
        gs2 : Game & Sound & List<&2, Cue> & List<&2, List<&2, F32>> <-
          IO.pure(Game & Sound & List<&2, Cue> & List<&2, List<&2, F32>>,
            Probe.mix(g, g2, snd2, U32.to_nat(R.word(feed, 0, ((due + 800) / 512 : U32)))))
        t7 : Nat <- IO.now()
        Probe.loop(k, gs2, g, (t + 1 : U32), Sums.next(ti, Nat.is_lt(seen, 8n), s, t0, t5, t6, t7),
          1n+seen, rig, ((due + 800) % 512 : U32), f2, feed)

# A frame as lines: Q opens a node, a number is a Pix.
def Dump.tree(img: Image) -> IO(Unit):
  match img:
    case Pix{c}:
      IO.print(U32.show(c))
    case Qua{tl, tr, bl, br}:
      do IO<Unit>:
        Unit <- IO.print("Q")
        Unit <- Dump.tree(tl)
        Unit <- Dump.tree(tr)
        Unit <- Dump.tree(bl)
        Dump.tree(br)

def Frame.only(drawn: Image & R.Cells) -> Image:
  (img, _) = drawn
  img

def Env.u32(m: Maybe<&2, U32>, default: U32) -> U32:
  match m:
    case None{}:
      default
    case Some{v}:
      v

def Env.num(r: Result<&1, &1, U32 & String, String>, +default: U32) -> U32:
  match r:
    case Fail{_}:
      default
    case Done{text}:
      Env.u32(U32.read(text), default)

def Probe.dump(dump: Result<&1, &1, U32 & String, String>, +rig: U32) -> IO(Unit):
  match dump:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{text}:
      +g = Probe.rig(Game.walk(U32.to_nat(Env.u32(U32.read(text), 1)), Game.init(), 0), rig)
      Dump.tree(Frame.only(Play.frame(Scene.build(g, Game.clock(g, 1.0), R.CNil{}), Pix{0})))

def Probe.rest(n: Nat, +rig: U32, snd: Sound, ff: Maybe<File> & Bool) -> IO(Unit):
  (file, feed) = ff
  do IO<Unit>:
    Unit <- Probe.loop(n, (Game.init(), snd, Nil{}, Nil{}), Game.init(), 0,
      (Sums{0, 0, 0, 0, 0, 0}, Pix{0}, R.CNil{}), 0n, rig, 0, file, feed)
    dump : Result<&1, &1, U32 & String, String> <- IO.get_env("SLASH_DUMP")
    Probe.dump(dump, rig)

# n looping voices over the synthesized clips (SLASH_VOICES).
def Sound.fill(+n: Nat, s: Sound) -> Sound:
  match n:
    case 0n:
      s
    case 1n+k:
      Sound.fill(k, Sound.play(s, Cue{(U32.from_nat(k) % 13 : U32), 0.1, 0.0, 1.0, True{}}))

def Probe.file.got(r: Result<&1, &1, U32 & String, File>) -> Maybe<File>:
  match r:
    case Fail{_}:
      None{}
    case Done{f}:
      Some{f}

# The SLASH_WAV file opened to write, and is the device to be fed.
def Probe.file(r: Result<&1, &1, U32 & String, String>) -> IO(Maybe<File> & Bool):
  match r:
    case Fail{_}:
      IO.pure(Maybe<File> & Bool, (None{}, True{}))
    case Done{path}:
      do IO<Maybe<File> & Bool>:
        f : Result<&1, &1, U32 & String, File> <- File.open(path, "w")
        IO.pure(Maybe<File> & Bool, (Probe.file.got(f), False{}))

def Probe.run(text: String) -> IO(Unit):
  do IO<Unit>:
    mode : Result<&1, &1, U32 & String, String> <- IO.get_env("SLASH_MODE")
    voices : Result<&1, &1, U32 & String, String> <- IO.get_env("SLASH_VOICES")
    wav : Result<&1, &1, U32 & String, String> <- IO.get_env("SLASH_WAV")
    snd : Sound <- Sound.open()
    ff : Maybe<File> & Bool <- Probe.file(wav)
    Probe.rest(U32.to_nat(Env.u32(U32.read(text), 600)), Env.num(mode, 99),
      Sound.fill(U32.to_nat(Env.num(voices, 0)), snd), ff)

def Main.mode(probe: Result<&1, &1, U32 & String, String>) -> IO(Unit):
  match probe:
    case Fail{_}:
      Play.run()
    case Done{text}:
      Probe.run(text)

def main() -> IO(Unit):
  do IO<Unit>:
    probe : Result<&1, &1, U32 & String, String> <- IO.get_env("SLASH_PROBE")
    Main.mode(probe)
