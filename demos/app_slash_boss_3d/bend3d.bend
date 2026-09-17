# Bend3D: a 3D renderer. The host meshes surfaces of materials into
# screen triangles (projected, lit at the vertices) sorted by 64-px
# cell into a quadtree; one bang walks it on the device into an Image.
import Base

# Vec
# ---

type Vec is Data:
  Vec{x: F32, y: F32, z: F32}

# pick and word beside Bool.pick: a generic def over a word type boxes
# its words (a Term and a sink per use), the typed ones keep them.
def pick(c: Bool, a: F32, b: F32) -> F32:
  match c:
    case True{}:
      a
    case False{}:
      b

def word(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

def min(+a: F32, +b: F32) -> F32:
  pick((a < b : F32), a, b)

def max(+a: F32, +b: F32) -> F32:
  pick((a < b : F32), b, a)

def clamp(+x: F32, +lo: F32, +hi: F32) -> F32:
  min(hi, max(lo, x))

def sat(+x: F32) -> F32:
  clamp(x, 0.0, 1.0)

def mix(+a: F32, +b: F32, +t: F32) -> F32:
  (a + (b - a) * t : F32)

def pack(+r: F32, +g: F32, +b: F32) -> U32:
  (F32.to_u32((255.0 * sat(r) : F32)) << 16n
    .|. F32.to_u32((255.0 * sat(g) : F32)) << 8n
    .|. F32.to_u32((255.0 * sat(b) : F32)) : U32)

def chan(+c: U32) -> F32:
  (U32.to_f32((c .&. 255 : U32)) / 255.0 : F32)

def Vec.add(+a: Vec, +b: Vec) -> Vec:
  Vec{ax, ay, az} = a
  Vec{bx, by, bz} = b
  Vec{(ax + bx : F32), (ay + by : F32), (az + bz : F32)}

def Vec.sub(+a: Vec, +b: Vec) -> Vec:
  Vec{ax, ay, az} = a
  Vec{bx, by, bz} = b
  Vec{(ax - bx : F32), (ay - by : F32), (az - bz : F32)}

def Vec.scale(+a: Vec, +k: F32) -> Vec:
  Vec{x, y, z} = a
  Vec{(x * k : F32), (y * k : F32), (z * k : F32)}

def Vec.dot(+a: Vec, +b: Vec) -> F32:
  Vec{ax, ay, az} = a
  Vec{bx, by, bz} = b
  (ax * bx + ay * by + az * bz : F32)

def Vec.cross(+a: Vec, +b: Vec) -> Vec:
  Vec{ax, ay, az} = a
  Vec{bx, by, bz} = b
  Vec{(ay * bz - az * by : F32), (az * bx - ax * bz : F32),
    (ax * by - ay * bx : F32)}

def Vec.len(+v: Vec) -> F32:
  F32.sqrt(Vec.dot(v, v))

def Vec.unit(+v: Vec) -> Vec:
  Vec.scale(v, (1.0 / max(0.00001, Vec.len(v)) : F32))

def Vec.mix(+a: Vec, +b: Vec, +t: F32) -> Vec:
  Vec{ax, ay, az} = a
  Vec{bx, by, bz} = b
  Vec{mix(ax, bx, t), mix(ay, by, t), mix(az, bz, t)}

# Turned about y (0 faces +x, pi faces -x).
def Vec.turn(+v: Vec, +face: F32) -> Vec:
  Vec{x, y, z} = v
  +c = F32.cos(face)
  +s = F32.sin(face)
  Vec{(x * c + z * s : F32), y, (z * c - x * s : F32)}

def Vec.rgb(+c: U32) -> Vec:
  Vec{chan((c >> 16n : U32)), chan((c >> 8n : U32)), chan(c)}

# Cam
# ---

# The eye, its basis (right, up, forward into the scene; unit), the
# focal length in pixels, the principal point, the near plane, the
# frame size. All scalars: the record rides in registers through every
# call and fork; a boxed record shared by every vertex is an atomic
# count per use.
type Cam is Data:
  Cam{eye: Vec, right: Vec, up: Vec, fwd: Vec, focal: F32, cx: F32, cy: F32, near: F32, w: U32,
    h: U32}

# A world point on the screen as (x, y, 1 / depth); w = 0 behind the
# near plane.
def Cam.proj(+cam: Cam, +p: Vec) -> Vec:
  Cam{eye, right, up, fwd, focal, cx, cy, near, _, _} = cam
  +r = Vec.sub(p, eye)
  +depth = Vec.dot(r, fwd)
  +w = pick((depth > near : F32), (1.0 / depth : F32), 0.0)
  Vec{(cx + focal * Vec.dot(r, right) * w : F32), (cy - focal * Vec.dot(r, up) * w : F32), w}

# The app's camera hook: its camera from its frame data, built where
# used (a camera passed down every call rides in every frame).
def Hook.cam(F: Data) -> Type:
  @+f: F -> Cam

def Cam.eye(+cam: Cam) -> Vec:
  Cam{eye, _, _, _, _, _, _, _, _, _} = cam
  eye

# The pixels a world unit spans at p.
def Cam.px(+cam: Cam, +p: Vec) -> F32:
  Cam{eye, _, _, fwd, focal, _, _, near, _, _} = cam
  +depth = Vec.dot(Vec.sub(p, eye), fwd)
  (focal * pick((depth > near : F32), (1.0 / depth : F32), 0.0) : F32)

# Surf
# ----

# The unit shapes over the unit square, du x dv outward: the sphere;
# the open cylinder y = 0..1; the box's sides and its lid at y = 1; the
# octahedron; the app's own kind with a parameter, through its hook.
type Shape is Data:
  Globe{}
  Tube{}
  Box{}
  Plate{}
  Gem{}
  Own{k: U32, x: F32}

# A surface: a unit shape in a basis; a Catmull-Rom sheet over its top
# row a..d and bottom row e..h; a ring at height cy of radius r0..r1 on
# the ellipse (sx, sz). A flat sum: the widest constructor sets the
# size, every surface rides in registers.
type Surf is Data:
  Inst{k: Shape, o: Vec, x: Vec, y: Vec, z: Vec}
  Sheet{a: Vec, b: Vec, c: Vec, d: Vec, e: Vec, f: Vec, g: Vec, h: Vec}
  Ring{cx: F32, cy: F32, cz: F32, sx: F32, sz: F32, r0: F32, r1: F32}

# The app's unit shape hook: kind, parameter, u, v; its size hook: the
# patches around and along from the screen half sizes (fx, fy, fz; r
# the wider of fx and fz).
def Hook.unit() -> Type:
  U32 -> @+x: F32 -> @+u: F32 -> @+v: F32 -> Vec

def Hook.size() -> Type:
  U32 -> @+r: F32 -> @+fx: F32 -> @+fy: F32 -> @+fz: F32 -> Vec

def Unit.go(~unit: Hook.unit(), k: Shape, +u: F32, +v: F32, +a: F32, +b: F32, +w: F32) -> Vec:
  match k:
    case Globe{}:
      +sb = F32.sin(b)
      Vec{(F32.cos(a) * sb : F32), F32.cos(b), (F32.sin(a) * sb : F32)}
    case Tube{}:
      Vec{F32.cos(a), w, F32.sin(a)}
    case Box{}:
      +ca = F32.cos((a + 0.7853982 : F32))
      +sa = F32.sin((a + 0.7853982 : F32))
      +m = (1.0 / max(F32.abs(ca), F32.abs(sa)) : F32)
      Vec{(ca * m : F32), (1.0 - 2.0 * v : F32), (sa * m : F32)}
    case Plate{}:
      Vec{(2.0 * u - 1.0 : F32), 1.0, (1.0 - 2.0 * v : F32)}
    case Gem{}:
      +sb = F32.sin(b)
      +x = (F32.cos(a) * sb : F32)
      +y = F32.cos(b)
      +z = (F32.sin(a) * sb : F32)
      +d = (1.0 / (F32.abs(x) + F32.abs(y) + F32.abs(z) : F32) : F32)
      Vec{(x * d : F32), (y * d : F32), (z * d : F32)}
    case Own{i, x}:
      unit(i, x, u, v)

def Inst.map(+p: Vec, +o: Vec, +x: Vec, +y: Vec, +z: Vec) -> Vec:
  Vec{px, py, pz} = p
  Vec{ox, oy, oz} = o
  Vec{xx, xy, xz} = x
  Vec{yx, yy, yz} = y
  Vec{zx, zy, zz} = z
  Vec{(ox + xx * px + yx * py + zx * pz : F32),
    (oy + xy * px + yy * py + zy * pz : F32),
    (oz + xz * px + yz * py + zz * pz : F32)}

# Catmull-Rom through b and c, steered by a and d.
def Spline.at(+a: F32, +b: F32, +c: F32, +d: F32, +u: F32) -> F32:
  (0.5 * (2.0 * b + (c - a) * u + (2.0 * a - 5.0 * b + 4.0 * c - d) * u * u
    + (3.0 * b - a + d - 3.0 * c) * u * u * u) : F32)

def Spline.vec(+a: Vec, +b: Vec, +c: Vec, +d: Vec, +u: F32) -> Vec:
  Vec{ax, ay, az} = a
  Vec{bx, by, bz} = b
  Vec{cx, cy, cz} = c
  Vec{dx, dy, dz} = d
  Vec{Spline.at(ax, bx, cx, dx, u), Spline.at(ay, by, cy, dy, u), Spline.at(az, bz, cz, dz, u)}

def Surf.at(~unit: Hook.unit(), +s: Surf, +u: F32, +v: F32) -> Vec:
  match s:
    case Inst{k, o, x, y, z}:
      Inst.map(Unit.go(~unit, k, u, v, (6.2831853 * u : F32), (3.1415927 * v : F32), (1.0 - v : F32)),
        o, x, y, z)
    case Sheet{a, b, c, d, e, f, g, h}:
      Vec.mix(Spline.vec(a, b, c, d, u), Spline.vec(e, f, g, h, u), v)
    case Ring{cx, cy, cz, sx, sz, r0, r1}:
      +a = (6.2831853 * u : F32)
      +r = (r0 + (r1 - r0) * v : F32)
      Vec{(cx + sx * r * F32.cos(a) : F32), cy, (cz + sz * r * F32.sin(a) : F32)}

# A unit shape scaled at a centre; from a to b (its y), w wide and d
# deep.
def Inst.ball(k: Shape, +c: Vec, +sx: F32, +sy: F32, +sz: F32) -> Surf:
  Inst{k, c, Vec{sx, 0.0, 0.0}, Vec{0.0, sy, 0.0}, Vec{0.0, 0.0, sz}}

def Inst.span(k: Shape, +a: Vec, +b: Vec, +w: F32, +d: F32) -> Surf:
  +axis = Vec.sub(b, a)
  +up = Vec.unit(axis)
  +right = Vec.unit(Vec.cross(up, Vec{0.002, 0.0, 1.0}))
  Inst{k, a, Vec.scale(right, w), axis, Vec.scale(Vec.unit(Vec.cross(right, up)), d)}

# An instance turned about y and moved to p; other surfaces stay.
def Surf.turn(+s: Surf, +p: Vec, +face: F32) -> Surf:
  match s:
    case Inst{k, o, x, y, z}:
      Vec{ox, oy, oz} = o
      Vec{xx, xy, xz} = x
      Vec{yx, yy, yz} = y
      Vec{zx, zy, zz} = z
      Vec{px, py, pz} = p
      +c = F32.cos(face)
      +sn = F32.sin(face)
      Inst{k, Vec{(px + ox * c + oz * sn : F32), (py + oy : F32), (pz + oz * c - ox * sn : F32)},
        Vec{(xx * c + xz * sn : F32), xy, (xz * c - xx * sn : F32)},
        Vec{(yx * c + yz * sn : F32), yy, (yz * c - yx * sn : F32)},
        Vec{(zx * c + zz * sn : F32), zy, (zz * c - zx * sn : F32)}}
    case other:
      other

# Light
# -----

# A material: colour, roughness, metalness, glow, the app's tag (for
# its shade hook), blend mode (0 opaque, 1 alpha, 2 additive, 3 soft),
# alpha.
type Mat is Data:
  Mat{c: U32, rough: F32, metal: F32, glow: F32, tag: U32, m: U32, al: F32}

# A lit point: the base (the tint in linear light), the tint, the glow,
# f0, the normal facing the viewer, the view direction, the GGX terms.
type Lit is Data:
  Lit{base: Vec, tint: Vec, glow: F32, f0: Vec, n: Vec, v: Vec, nv: F32, a2: F32, k: F32, kd: F32}

# ACES on a linear channel, then gamma.
def Light.tone(+x: F32) -> F32:
  F32.pow(sat(((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14) : F32)), 0.4545)

def Light.tone3(+c: Vec) -> Vec:
  Vec{r, g, b} = c
  Vec{Light.tone(r), Light.tone(g), Light.tone(b)}

# A channel of one light: Schlick's Fresnel f over f0, Lambert of the
# rest, the specular sp.
def Light.ch(+base: F32, +f0: F32, +fr: F32, +sp: F32, +kd: F32, +lc: F32, +nl: F32) -> F32:
  +f = (f0 + (1.0 - f0) * fr : F32)
  (((1.0 - f) * kd * base + sp * f) * lc * nl : F32)

# One light of colour lc from the direction dir: GGX (a2), Smith (k).
def Light.one(+l: Lit, +dir: Vec, +lc: Vec) -> Vec:
  Lit{base, _, _, f0, n, v, nv, a2, k, kd} = l
  Vec{br, bg, bb} = base
  Vec{fr0, fg0, fb0} = f0
  Vec{lr, lg, lb} = lc
  +nl = max(0.0, Vec.dot(n, dir))
  +h = Vec.unit(Vec.add(v, dir))
  +nh = max(0.0, Vec.dot(n, h))
  +vh = max(0.0, Vec.dot(v, h))
  +den = (nh * nh * (a2 - 1.0) + 1.0 : F32)
  +d = (a2 / max(0.00001, (3.1415927 * den * den : F32)) : F32)
  +g = ((nv / (nv * (1.0 - k) + k)) * (nl / (nl * (1.0 - k) + k)) : F32)
  +t = (1.0 - vh : F32)
  +fr = (t * t * t * t * t : F32)
  +sp = (d * g / max(0.0001, (4.0 * nv * nl : F32)) : F32)
  Vec{Light.ch(br, fr0, fr, sp, kd, lr, nl), Light.ch(bg, fg0, fr, sp, kd, lg, nl),
    Light.ch(bb, fb0, fr, sp, kd, lb, nl)}

# A point light at q on the point p: a smooth window over its range,
# over 1 + fall d^2.
def Light.pt(+l: Lit, +p: Vec, +q: Vec, +lc: Vec, +range: F32, +fall: F32) -> Vec:
  +delta = Vec.sub(q, p)
  +d = F32.sqrt(Vec.dot(delta, delta))
  +near = sat((1.0 - d / range : F32))
  Light.one(l, Vec.scale(delta, (1.0 / max(0.001, d) : F32)),
    Vec.scale(lc, (near * near / (1.0 + fall * d * d : F32) : F32)))

# The point p of normal n under a material of a tint, seen from the eye.
def Light.at(+mat: Mat, +tint: Vec, +p: Vec, +n: Vec, +cam: Cam) -> Lit:
  Mat{_, rough, metal, glow, _, _, _} = mat
  Vec{tr, tg, tb} = tint
  Cam{eye, _, _, _, _, _, _, _, _, _} = cam
  +base = {Vec{F32.pow(tr, 2.2), F32.pow(tg, 2.2), F32.pow(tb, 2.2)} : Vec}
  +view = Vec.unit(Vec.sub(eye, p))
  +un = Vec.unit(n)
  +nn = Vec.scale(un, pick((Vec.dot(un, view) < 0.0 : F32), (0.0 - 1.0 : F32), 1.0))
  +r = clamp(rough, 0.06, 1.0)
  Lit{base, tint, glow, Vec.mix(Vec{0.04, 0.04, 0.04}, base, metal), nn, view,
    max(0.0001, Vec.dot(nn, view)), (r * r * r * r : F32),
    ((r + 1.0) * (r + 1.0) * 0.125 : F32), ((1.0 - metal) * 0.3183099 : F32)}

def Light.sum(+l: Lit, +amb: Vec, +sum: Vec) -> Vec:
  Lit{base, tint, glow, _, _, _, _, _, _, _} = l
  Vec{br, bg, bb} = base
  Vec{ar, ag, ab} = amb
  Light.tone3(Vec.add(Vec.add(Vec{(br * ar : F32), (bg * ag : F32), (bb * ab : F32)},
    Vec.scale(tint, glow)), sum))

# The app's shade hook: material, point, normal, (u, v), app data; the
# vertex colour.
def Hook.shade(F: Data) -> Type:
  @+m: Mat -> @+p: Vec -> Vec -> F32 -> F32 -> F -> Vec

# Tri
# ---

# A screen vertex (x, y, 1 / depth) with its colour.
type Vert is Data:
  Vert{x: F32, y: F32, w: F32, r: F32, g: F32, b: F32}

type Rect is Data:
  Rect{x0: U32, y0: U32, x1: U32, y1: U32}

# A screen triangle: two barycentric planes (l = a x + b y + c; l2 = 1
# - l0 - l1: inside when none is negative), the inverse-depth plane
# (c, du, dv; the nearest has the largest w), three colour planes, the
# mode (0 opaque, 1 alpha, 2 additive, 3 soft: r and g hold the disc's
# coordinates times w, b the tint packed), alpha, the pixel box.
type Tri is Data:
  Tri{l0: Vec, l1: Vec, w: Vec, r: Vec, g: Vec, b: Vec, m: U32, al: F32, box: Rect}

# A cons list: the one shape a flat loop walks with no stack.
type Tris is Data:
  TNil{}
  TCons{+tri: Tri, next: Tris}

# The triangles by 64-cell: a quadtree over the 2048 root, its leaves
# the cells' lists. One list per cell, not per pixel: a list shared by
# pixels is contended atomics.
type Cells is Data:
  CNil{}
  CLeaf{+n: U32, +ts: Tris}
  CQua{tl: Cells, tr: Cells, bl: Cells, br: Cells}

# a reversed onto b (the order does not matter).
def Tris.app(a: Tris, b: Tris) -> Tris:
  match a:
    case TNil{}:
      b
    case TCons{t, n}:
      Tris.app(n, TCons{t, b})

def Tri.wmax(
  +wc: F32, +wx: F32, +wy: F32, +fx0: F32, +fy0: F32, +fx1: F32, +fy1: F32
) -> F32:
  max(max((wc + wx * fx0 + wy * fy0 : F32), (wc + wx * fx1 + wy * fy0 : F32)),
    max((wc + wx * fx0 + wy * fy1 : F32), (wc + wx * fx1 + wy * fy1 : F32)))

# Is no corner pixel of the box separated from the triangle by an edge?
def Tri.cover(+t: Tri, +fx0: F32, +fy0: F32, +fx1: F32, +fy1: F32) -> Bool:
  Tri{l0, l1, _, _, _, _, _, _, _} = t
  Vec{a0, b0, c0} = l0
  Vec{a1, b1, c1} = l1
  ((Tri.wmax(c0, a0, b0, fx0, fy0, fx1, fy1) >= 0.0)
    && (Tri.wmax(c1, a1, b1, fx0, fy0, fx1, fy1) >= 0.0)
    && (Tri.wmax((1.0 - c0 - c1 : F32), (0.0 - (a0 + a1) : F32), (0.0 - (b0 + b1) : F32),
      fx0, fy0, fx1, fy1) >= 0.0) : F32)

# Cells
# -----

# Bit 4: the quadrant of a coordinate shifted so its level's bit sits
# there.
def Cells.bit(+c: U32) -> Bool:
  ((c .&. 16) > 0 : U32)

# The triangle into the cell (cx, cy) of a region of 64 << k: right and
# low pick the quadrant, the bits shift for the next level. Eight arms:
# one arm picking the child would share all four.
def Cells.put(
  k: Nat, right: Bool, low: Bool, c: Cells, +cx: U32, +cy: U32, +t: Tri
) -> Cells:
  match k:
    case 0n:
      match c:
        case CLeaf{n, ts}:
          CLeaf{(n + 1 : U32), TCons{t, ts}}
        case _:
          CLeaf{1, TCons{t, TNil{}}}
    case 1n+e:
      match right low c:
        case False{} False{} CQua{tl, tr, bl, br}:
          CQua{Cells.put(e, Cells.bit(cx), Cells.bit(cy), tl, (cx << 1n : U32),
            (cy << 1n : U32), t), tr, bl, br}
        case True{} False{} CQua{tl, tr, bl, br}:
          CQua{tl, Cells.put(e, Cells.bit(cx), Cells.bit(cy), tr, (cx << 1n : U32),
            (cy << 1n : U32), t), bl, br}
        case False{} True{} CQua{tl, tr, bl, br}:
          CQua{tl, tr, Cells.put(e, Cells.bit(cx), Cells.bit(cy), bl, (cx << 1n : U32),
            (cy << 1n : U32), t), br}
        case True{} True{} CQua{tl, tr, bl, br}:
          CQua{tl, tr, bl, Cells.put(e, Cells.bit(cx), Cells.bit(cy), br,
            (cx << 1n : U32), (cy << 1n : U32), t)}
        case False{} False{} _:
          CQua{Cells.put(e, Cells.bit(cx), Cells.bit(cy), CNil{}, (cx << 1n : U32),
            (cy << 1n : U32), t), CNil{}, CNil{}, CNil{}}
        case True{} False{} _:
          CQua{CNil{}, Cells.put(e, Cells.bit(cx), Cells.bit(cy), CNil{},
            (cx << 1n : U32), (cy << 1n : U32), t), CNil{}, CNil{}}
        case False{} True{} _:
          CQua{CNil{}, CNil{}, Cells.put(e, Cells.bit(cx), Cells.bit(cy), CNil{},
            (cx << 1n : U32), (cy << 1n : U32), t), CNil{}}
        case True{} True{} _:
          CQua{CNil{}, CNil{}, CNil{}, Cells.put(e, Cells.bit(cx), Cells.bit(cy),
            CNil{}, (cx << 1n : U32), (cy << 1n : U32), t)}

def Cells.merge(a: Cells, b: Cells) -> Cells:
  match a b:
    case CNil{} _:
      b
    case other CNil{}:
      other
    case CLeaf{n, ts} CLeaf{m, us}:
      CLeaf{(n + m : U32), Tris.app(ts, us)}
    case CQua{a1, a2, a3, a4} CQua{b1, b2, b3, b4}:
      CQua{Cells.merge(a1, b1), Cells.merge(a2, b2), Cells.merge(a3, b3),
        Cells.merge(a4, b4)}
    case _ _:
      CNil{}

def Cells.m4(a: Cells, b: Cells, c: Cells, d: Cells) -> Cells:
  Cells.merge(Cells.merge(a, b), Cells.merge(c, d))

def Tri.into(hit: Bool, +cx: U32, +cy: U32, +t: Tri, c: Cells) -> Cells:
  match hit:
    case False{}:
      c
    case True{}:
      Cells.put(5n, Cells.bit(cx), Cells.bit(cy), c, (cx << 1n : U32),
        (cy << 1n : U32), t)

# The triangle into the cells of its box whose pixel centres it meets:
# m cells left of w columns from (cx0, cy0).
def Tri.spread(+m: Nat, +w: U32, +cx0: U32, +cy0: U32, +t: Tri, c: Cells) -> Cells:
  match m:
    case 0n:
      c
    case 1n+p:
      +i = U32.from_nat(p)
      +cx = (cx0 + i % w : U32)
      +cy = (cy0 + i / w : U32)
      +fx0 = (U32.to_f32((cx << 6n : U32)) + 0.5 : F32)
      +fy0 = (U32.to_f32((cy << 6n : U32)) + 0.5 : F32)
      Tri.spread(p, w, cx0, cy0, t, Tri.into(Tri.cover(t, fx0, fy0, (fx0 + 63.0 : F32),
        (fy0 + 63.0 : F32)), cx, cy, t, c))

# A cell's list freed, one flat loop; CNil comes back, a merge's identity.
def Tris.free(ts: Tris) -> Cells:
  match ts:
    case TNil{}:
      CNil{}
    case TCons{_, n}:
      Tris.free(n)

# The last frame's tree freed on the host: k levels in parallel, then
# sequential; on one thread it costs milliseconds, so it rides the
# next build's forks.
def Cells.drop(+k: Nat, c: Cells) -> Cells:
  match k c:
    case 1n+e CQua{tl, tr, bl, br}:
      a b cc d = Cells.drop(e, tl) Cells.drop(e, tr) Cells.drop(e, bl) Cells.drop(e, br)
      Cells.m4(a, b, cc, d)
    case 0n CQua{tl, tr, bl, br}:
      Cells.m4(Cells.drop(0n, tl), Cells.drop(0n, tr), Cells.drop(0n, bl), Cells.drop(0n, br))
    case _ CLeaf{_, ts}:
      Tris.free(ts)
    case _ CNil{}:
      CNil{}

# Mesh
# ----

def Mesh.norm(+a: Vec, +b: Vec, +c: Vec, +d: Vec) -> Vec:
  Vec{ax, ay, az} = a
  Vec{bx, by, bz} = b
  Vec{cx, cy, cz} = c
  Vec{dx, dy, dz} = d
  +ux = (ax - bx : F32)
  +uy = (ay - by : F32)
  +uz = (az - bz : F32)
  +vx = (cx - dx : F32)
  +vy = (cy - dy : F32)
  +vz = (cz - dz : F32)
  Vec{(uy * vz - uz * vy : F32), (uz * vx - ux * vz : F32),
    (ux * vy - uy * vx : F32)}

def Mesh.vert.go(+p: Vec, +l: Vec) -> Vert:
  Vec{x, y, w} = p
  Vec{r, g, b} = l
  Vert{x, y, w, r, g, b}

# The vertex at (u, v): projected, shaded under the normal by forward
# differences (one stencil for every patch sharing the vertex, so the
# shading is seamless; v kept off the poles).
def Mesh.vert(
  ~F: Data, ~cam: Hook.cam(F), ~unit: Hook.unit(), ~shade: Hook.shade(F), +s: Surf, +mat: Mat,
  +u: F32, +v: F32, +f: F
) -> Vert:
  +p = Surf.at(~unit, s, u, v)
  +vn = clamp(v, 0.0025, 0.9975)
  +q = Surf.at(~unit, s, u, vn)
  Mesh.vert.go(Cam.proj(cam(f), p), shade(mat, p, Mesh.norm(Surf.at(~unit, s, (u + 0.005 : F32),
    vn), q, Surf.at(~unit, s, u, (vn + 0.005 : F32)), q), u, v, f))

# A plane (c, du, dv) through three values at the vertices.
def Tri.plane(
  +a0: F32, +b0: F32, +c0: F32, +a1: F32, +b1: F32, +c1: F32, +v0: F32,
  +v1: F32, +v2: F32
) -> Vec:
  +d0 = (v0 - v2 : F32)
  +d1 = (v1 - v2 : F32)
  Vec{(v2 + c0 * d0 + c1 * d1 : F32), (a0 * d0 + a1 * d1 : F32),
    (b0 * d0 + b1 * d1 : F32)}

# The triangle of its planes and pixel box into the cells its box spans.
def Mesh.tri(
  +a0: F32, +b0: F32, +c0: F32, +a1: F32, +b1: F32, +c1: F32, +w: Vec, +r: Vec,
  +g: Vec, +b: Vec, +m: U32, +al: F32, +x0: U32, +y0: U32, +x1: U32, +y1: U32,
  c: Cells
) -> Cells:
  +cx0 = (x0 >> 6n : U32)
  +cy0 = (y0 >> 6n : U32)
  +cw = ((x1 >> 6n) - cx0 + 1 : U32)
  Tri.spread(U32.to_nat((cw * ((y1 >> 6n) - cy0 + 1) : U32)), cw, cx0, cy0,
    Tri{Vec{a0, b0, c0}, Vec{a1, b1, c1}, w, r, g, b, m, al, Rect{x0, y0, x1, y1}}, c)

def Mesh.keep(
  ok: Bool, +p: Vert, +q: Vert, +r: Vert, +area: F32, +m: U32, +al: F32,
  +bx0: F32, +by0: F32, +bx1: F32, +by1: F32, c: Cells
) -> Cells:
  match ok:
    case False{}:
      c
    case True{}:
      Vert{x0, y0, w0, cr0, cg0, cb0} = p
      Vert{x1, y1, w1, cr1, cg1, cb1} = q
      Vert{x2, y2, w2, cr2, cg2, cb2} = r
      +ia = (1.0 / area : F32)
      +a0 = ((y1 - y2) * ia : F32)
      +b0 = ((x2 - x1) * ia : F32)
      +c0 = (0.0 - (a0 * x2 + b0 * y2) : F32)
      +a1 = ((y2 - y0) * ia : F32)
      +b1 = ((x0 - x2) * ia : F32)
      +c1 = (0.0 - (a1 * x2 + b1 * y2) : F32)
      Mesh.tri(a0, b0, c0, a1, b1, c1,
        Tri.plane(a0, b0, c0, a1, b1, c1, w0, w1, w2),
        Tri.plane(a0, b0, c0, a1, b1, c1, cr0, cr1, cr2),
        Tri.plane(a0, b0, c0, a1, b1, c1, cg0, cg1, cg2),
        Tri.plane(a0, b0, c0, a1, b1, c1, cb0, cb1, cb2), m, al, F32.to_u32(bx0),
        F32.to_u32(by0), F32.to_u32(bx1), F32.to_u32(by1), c)

# Three vertices into the cells of the frame whose last pixel is (x1,
# y1); nothing when one is behind the eye, the box misses, or an
# opaque one faces away (surfaces wind outward).
def Mesh.raster(
  +p: Vert, +q: Vert, +r: Vert, +m: U32, +al: F32, +x1: F32, +y1: F32, c: Cells
) -> Cells:
  Vert{ax, ay, w0, _, _, _} = p
  Vert{bx, by, w1, _, _, _} = q
  Vert{cx, cy, w2, _, _, _} = r
  +area = ((by - cy) * (ax - cx) + (cx - bx) * (ay - cy) : F32)
  +bx0 = max(0.0, F32.floor(min(ax, min(bx, cx))))
  +by0 = max(0.0, F32.floor(min(ay, min(by, cy))))
  +bx1 = min(x1, F32.ceil(max(ax, max(bx, cx))))
  +by1 = min(y1, F32.ceil(max(ay, max(by, cy))))
  Mesh.keep(Bool.and(((w0 > 0.0) && (w1 > 0.0) && (w2 > 0.0) && (bx0 <= bx1)
      && (by0 <= by1) && (F32.abs(area) > 0.001) : F32),
      Bool.or((area < 0.0 : F32), (m > 0 : U32))), p, q, r, area, m, al, bx0,
    by0, bx1, by1, c)

# j patches of the strip [u0, u1] below v, from the top corners p and q,
# each two triangles.
def Grid.strip(
  ~F: Data, ~cam: Hook.cam(F), ~unit: Hook.unit(), ~shade: Hook.shade(F), j: Nat, +s: Surf,
  +mat: Mat, +f: F, +u0: F32, +u1: F32, +v: F32, +dv: F32, +x1: F32, +y1: F32, +p: Vert, +q: Vert,
  acc: Cells
) -> Cells:
  match j:
    case 0n:
      acc
    case 1n+k:
      Mat{_, _, _, _, _, m, al} = mat
      +v1 = (v + dv : F32)
      +r = Mesh.vert(~F, ~cam, ~unit, ~shade, s, mat, u0, v1, f)
      +t = Mesh.vert(~F, ~cam, ~unit, ~shade, s, mat, u1, v1, f)
      Grid.strip(~F, ~cam, ~unit, ~shade, k, s, mat, f, u0, u1, v1, dv, x1, y1, r, t,
        Mesh.raster(p, t, r, m, al, x1, y1, Mesh.raster(p, q, t, m, al, x1, y1, acc)))

# The strip i of a grid of nu by nv patches, in the frame of the camera
# (its last pixel clamps the boxes).
def Grid.leaf(
  ~F: Data, ~cam: Hook.cam(F), ~unit: Hook.unit(), ~shade: Hook.shade(F), +i: U32, +nu: U32,
  +nv: U32, +s: Surf, +mat: Mat, +c: Cam, +f: F
) -> Cells:
  Cam{_, _, _, _, _, _, _, _, w, h} = c
  +u0 = (U32.to_f32(i) / U32.to_f32(nu) : F32)
  +u1 = (U32.to_f32((i + 1 : U32)) / U32.to_f32(nu) : F32)
  Grid.strip(~F, ~cam, ~unit, ~shade, U32.to_nat(nv), s, mat, f, u0, u1, 0.0,
    (1.0 / U32.to_f32(nv) : F32), (U32.to_f32(w) - 1.0 : F32), (U32.to_f32(h) - 1.0 : F32),
    Mesh.vert(~F, ~cam, ~unit, ~shade, s, mat, u0, 0.0, f),
    Mesh.vert(~F, ~cam, ~unit, ~shade, s, mat, u1, 0.0, f), CNil{})

# The strips [i, i + 2^d) of a grid, a fork tree: one fork per strip
# is unbalanced, one per patch drowns in tasks.
def Grid.go(
  ~F: Data, ~cam: Hook.cam(F), ~unit: Hook.unit(), ~shade: Hook.shade(F), +d: Nat, on: Bool,
  +i: U32, +nu: U32, +nv: U32, +s: Surf, +mat: Mat, +f: F
) -> Cells:
  match d on:
    case 0n True{}:
      Grid.leaf(~F, ~cam, ~unit, ~shade, i, nu, nv, s, mat, cam(f), f)
    case 1n+e True{}:
      +j = (i + U32.shln(1, e) : U32)
      a b = Grid.go(~F, ~cam, ~unit, ~shade, e, True{}, i, nu, nv, s, mat, f)
        Grid.go(~F, ~cam, ~unit, ~shade, e, (j < nu : U32), j, nu, nv, s, mat, f)
      Cells.merge(a, b)
    case _ False{}:
      CNil{}

def Grid.deep(more: Bool, d: Nat) -> Nat:
  match more:
    case True{}:
      1n+d
    case False{}:
      d

# The least d with 2^d >= n, on a fuel.
def Grid.depth(f: Nat, +n: U32, +d: Nat) -> Nat:
  match f:
    case 0n:
      d
    case 1n+p:
      Grid.depth(p, n, Grid.deep((U32.shln(1, d) < n : U32), d))

# Segments for a circle of a screen radius within a pixel of round
# (its sagitta), at least 4; 20-px steps over a length, at least 1.
def Grid.arc(+r: F32) -> F32:
  max(4.0, F32.ceil((3.1415927 * F32.sqrt((r * 0.5 : F32)) : F32)))

def Grid.len(+l: F32) -> F32:
  max(1.0, F32.ceil((l * 0.05 : F32)))

# The patches a unit shape of screen half sizes (fx, fy, fz; r the
# wider of fx, fz) needs around and along: a box four a side (its
# corners on vertices), the rest by their sagitta both ways.
def Unit.fit(~size: Hook.size(), k: Shape, +r: F32, +fx: F32, +fy: F32, +fz: F32) -> Vec:
  match k:
    case Box{}:
      Vec{(4.0 * Grid.len((r * 2.0 : F32)) : F32), Grid.len((fy * 2.0 : F32)), 0.0}
    case Own{i, _}:
      size(i, r, fx, fy, fz)
    case _:
      Vec{Grid.arc(r), F32.ceil((Grid.arc(max(r, fy)) * 0.5 : F32)), 0.0}

# The patches a surface needs on the screen: fewer when small; only an
# instance is sized.
def Surf.fit(~size: Hook.size(), +s: Surf, +cam: Cam) -> Vec:
  match s:
    case Inst{k, o, x, y, z}:
      +f = Cam.px(cam, o)
      +fx = (f * Vec.len(x) : F32)
      +fy = (f * Vec.len(y) : F32)
      +fz = (f * Vec.len(z) : F32)
      Unit.fit(~size, k, max(fx, fz), fx, fy, fz)
    case _:
      Vec{9999.0, 9999.0, 0.0}

def Mesh.fit(
  ~F: Data, ~cam: Hook.cam(F), ~unit: Hook.unit(), ~shade: Hook.shade(F), +fit: Vec, +s: Surf,
  +mat: Mat, +nu: U32, +nv: U32, +f: F
) -> Cells:
  Vec{fu, fv, _} = fit
  +mu = F32.to_u32(min(U32.to_f32(nu), fu))
  +mv = F32.to_u32(min(U32.to_f32(nv), fv))
  Grid.go(~F, ~cam, ~unit, ~shade, Grid.depth(9n, mu, 0n), True{}, 0, mu, mv, s, mat, f)

# A surface of a material as a grid of at most nu by nv patches.
def Mesh.of(
  ~F: Data, ~cam: Hook.cam(F), ~unit: Hook.unit(), ~size: Hook.size(), ~shade: Hook.shade(F),
  +s: Surf, +mat: Mat, +nu: U32, +nv: U32, +f: F
) -> Cells:
  Mesh.fit(~F, ~cam, ~unit, ~shade, Surf.fit(~size, s, cam(f)), s, mat, nu, nv, f)

# A screen quad (counter-clockwise when opaque) at the inverse depth d,
# of one colour, in the cells of the frame whose last pixel is (x1, y1).
def Quad.put(
  +qx0: F32, +qy0: F32, +qx1: F32, +qy1: F32, +qx2: F32, +qy2: F32, +qx3: F32, +qy3: F32,
  +d: F32, +c: U32, +m: U32, +al: F32, +x1: F32, +y1: F32, cells: Cells
) -> Cells:
  +r = chan((c >> 16n : U32))
  +g = chan((c >> 8n : U32))
  +b = chan(c)
  Mesh.raster(Vert{qx0, qy0, d, r, g, b}, Vert{qx2, qy2, d, r, g, b},
    Vert{qx3, qy3, d, r, g, b}, m, al, x1, y1, Mesh.raster(Vert{qx0, qy0, d, r, g, b},
      Vert{qx1, qy1, d, r, g, b}, Vert{qx2, qy2, d, r, g, b}, m, al, x1, y1, cells))

# Cloth
# -----

# 64 Verlet particles (column i % cols around, row i / cols down) in a
# four-way tree of three levels; a thread is its point and its last.
type Cloth is Data:
  Thread{p: Vec, old: Vec}
  Weave{a: Cloth, b: Cloth, c: Cloth, d: Cloth}

# A cloth's cut: the columns around (a ring, or open over the back
# half), the rows down, the radius at the top and its growth down, the
# drift back, the top's height, the length, the hem's scallop and its
# points around, the flattening in z, the tie across (0 for loose
# strands), the body's radius between lo and hi, the floor, the stripe
# (the period of its two colours).
type Fit is Data:
  Fit{cols: U32, rows: U32, open: U32, r0: F32, r1: F32, back: F32, top: F32, len: F32,
    hem: F32, pts: F32, flat: F32, tie: F32, body: F32, lo: F32, hi: F32, floor: F32, stripe: U32}

# The app's wind hook: the time and the particle; a push a tick.
def Hook.wind() -> Type:
  @+t: F32 -> U32 -> Vec

# Particle i at rest about the anchor o, turned to the facing.
def Cloth.rest(+i: U32, +fit: Fit, +o: Vec, +face: F32) -> Vec:
  Fit{cols, rows, open, r0, r1, back, top, len, hem, pts, flat, _, _, _, _, _, _} = fit
  +col = U32.to_f32((i % cols : U32))
  +u = pick(U32.is_eq(open, 0), (col * 6.2831853 / U32.to_f32(cols) : F32),
    (1.5707963 + (col + 0.5) * 3.1415927 / U32.to_f32(cols) : F32))
  +v = (U32.to_f32((i / cols : U32)) / U32.to_f32((rows - 1 : U32)) : F32)
  +r = (r0 + v * r1 : F32)
  Vec.add(o, Vec.turn(Vec{(F32.cos(u) * r - v * back : F32),
    (top - v * len * (1.0 + hem * F32.cos((u * pts : F32))) : F32),
    (F32.sin(u) * r * flat : F32)}, face))

# The particles from i at rest, n levels deep (stride 4^n).
def Cloth.seed(+n: Nat, +i: U32, +fit: Fit, +o: Vec, +face: F32) -> Cloth:
  match n:
    case 0n:
      +p = Cloth.rest(i, fit, o, face)
      Thread{p, p}
    case 1n+k:
      +s = U32.shln(1, (k + k : Nat))
      Weave{Cloth.seed(k, i, fit, o, face), Cloth.seed(k, (i + s : U32), fit, o, face),
        Cloth.seed(k, (i + s * 2 : U32), fit, o, face),
        Cloth.seed(k, (i + s * 3 : U32), fit, o, face)}

# The point of particle i, n levels down (stride 16 at the root).
def Cloth.at(n: Nat, c: Cloth, +i: U32, +stride: U32) -> Vec:
  match n c:
    case _ Thread{p, _}:
      p
    case 0n _:
      Vec{0.0, 0.0, 0.0}
    case 1n+k Weave{a, b, cc, d}:
      +part = (i / stride : U32)
      +right = U32.is_ne((part .&. 1 : U32), 0)
      Cloth.at(k, Bool.pick(Cloth, (part >= 2 : U32), Bool.pick(Cloth, right, d, cc),
        Bool.pick(Cloth, right, b, a)), (i % stride : U32), (stride / 4 : U32))

def Cloth.limit(+v: Vec, +m: F32) -> Vec:
  Vec.scale(v, min(1.0, (m / max(0.00001, Vec.len(v)) : F32)))

# Verlet: 0.94 of the motion, the wind, a pull to the rest and a cap on
# the stray (the wind and the caps scale with the length); the top row
# sits at rest, lowered by drop.
def Cloth.move(
  ~wind: Hook.wind(), +c: Cloth, +i: U32, +stride: U32, +fit: Fit, +o: Vec, +face: F32, +t: F32,
  +drop: F32
) -> Cloth:
  match c:
    case Thread{p, old}:
      Fit{cols, _, _, _, _, _, _, len, _, _, _, _, _, _, _, _, _} = fit
      +k = (len * 1.282 : F32)
      +target = Cloth.rest(i, fit, Vec.sub(o, Vec{0.0, drop, 0.0}), face)
      +free = pick((i >= cols : U32), 1.0, 0.0)
      +motion = Cloth.limit(Vec.scale(Vec.sub(p, old), 0.94), (0.38 * k : F32))
      +next = Vec.add(Vec.add(p, motion), Vec.add(Vec.scale(wind(t, i), k),
        Vec.scale(Vec.sub(target, p), 0.025)))
      Thread{Vec.mix(target, Vec.add(target, Cloth.limit(Vec.sub(next, target), (0.85 * k : F32))),
          free), Vec.mix(target, p, free)}
    case Weave{a, b, cc, d}:
      +s = (stride / 4 : U32)
      Weave{Cloth.move(~wind, a, i, s, fit, o, face, t, drop),
        Cloth.move(~wind, b, (i + stride : U32), s, fit, o, face, t, drop),
        Cloth.move(~wind, cc, (i + stride * 2 : U32), s, fit, o, face, t, drop),
        Cloth.move(~wind, d, (i + stride * 3 : U32), s, fit, o, face, t, drop)}

# The pull of particle j on p (particle i) toward their rest distance.
def Cloth.pull(+all: Cloth, +i: U32, +j: U32, +fit: Fit, +p: Vec) -> Vec:
  +delta = Vec.sub(Cloth.at(3n, all, j, 16), p)
  +dist = Vec.len(delta)
  +len = Vec.len(Vec.sub(Cloth.rest(i, fit, Vec{0.0, 0.0, 0.0}, 0.0),
    Cloth.rest(j, fit, Vec{0.0, 0.0, 0.0}, 0.0)))
  Vec.scale(delta, ((dist - len) / max(0.00001, dist) : F32))

# A local point pushed out of the body and off the floor.
def Cloth.hold(+local: Vec, +fit: Fit, +o: Vec) -> Vec:
  Vec{x, y, z} = local
  Fit{_, _, _, _, _, _, _, _, _, _, _, _, body, lo, hi, floor, _} = fit
  +rad = F32.sqrt((x * x + z * z : F32))
  +push = pick(((y > lo) && (y < hi) : F32), max(1.0, (body / max(0.001, rad) : F32)), 1.0)
  Vec.add(o, Vec{(x * push : F32), max(floor, y), (z * push : F32)})

# A Jacobi pass: 0.24 of the neighbours' pull (the ring wraps unless
# open; the tie scales it across) in the snapshot all, then held.
def Cloth.solve(
  +c: Cloth, +all: Cloth, +i: U32, +stride: U32, +fit: Fit, +o: Vec, +face: F32, +drop: F32
) -> Cloth:
  match c:
    case Thread{p, old}:
      Fit{cols, rows, open, _, _, _, _, _, _, _, _, tie, _, _, _, _, _} = fit
      +col = (i % cols : U32)
      +row = (i / cols : U32)
      +ring = U32.is_eq(open, 0)
      +l = word((col > 0 : U32), (i - 1 : U32), word(ring, (i + cols - 1 : U32), i))
      +r = word(((col + 1 : U32) < cols : U32), (i + 1 : U32), word(ring, (i + 1 - cols : U32), i))
      +force = Vec.add(Vec.scale(Vec.add(Cloth.pull(all, i, l, fit, p),
            Cloth.pull(all, i, r, fit, p)), tie),
        Vec.add(Cloth.pull(all, i, word((row > 0 : U32), (i - cols : U32), i), fit, p),
          Cloth.pull(all, i, word(((row + 1 : U32) < rows : U32), (i + cols : U32), i), fit, p)))
      +safe = Cloth.hold(Vec.sub(Vec.add(p, Vec.scale(force, 0.24)), o), fit, o)
      Thread{Vec.mix(Cloth.rest(i, fit, Vec.sub(o, Vec{0.0, drop, 0.0}), face), safe,
        pick((i >= cols : U32), 1.0, 0.0)), old}
    case Weave{a, b, cc, d}:
      +s = (stride / 4 : U32)
      Weave{Cloth.solve(a, all, i, s, fit, o, face, drop),
        Cloth.solve(b, all, (i + stride : U32), s, fit, o, face, drop),
        Cloth.solve(cc, all, (i + stride * 2 : U32), s, fit, o, face, drop),
        Cloth.solve(d, all, (i + stride * 3 : U32), s, fit, o, face, drop)}

def Cloth.relax(n: Nat, +c: Cloth, +fit: Fit, +o: Vec, +face: F32, +drop: F32) -> Cloth:
  match n:
    case 0n:
      c
    case 1n+k:
      Cloth.relax(k, Cloth.solve(c, c, 0, 16, fit, o, face, drop), fit, o, face, drop)

def Cloth.step(
  ~wind: Hook.wind(), +c: Cloth, +fit: Fit, +o: Vec, +face: F32, +t: F32, +drop: F32
) -> Cloth:
  Cloth.relax(3n, Cloth.move(~wind, c, 0, 16, fit, o, face, t, drop), fit, o, face, drop)

def Cloth.lerp(+a: Cloth, +b: Cloth, +u: F32) -> Cloth:
  match a b:
    case Thread{p0, o0} Thread{p, o}:
      Thread{Vec.mix(p0, p, u), Vec.mix(o0, o, u)}
    case Weave{a0, b0, c0, d0} Weave{a1, b1, c1, d1}:
      Weave{Cloth.lerp(a0, a1, u), Cloth.lerp(b0, b1, u), Cloth.lerp(c0, c1, u),
        Cloth.lerp(d0, d1, u)}
    case _ _:
      b

# The app's mesher hook (Mesh.of under its hooks): a surface of a
# material as at most nu by nv patches under the app's frame data.
def Hook.mesh(F: Data) -> Type:
  @+s: Surf -> @+mat: Mat -> @+nu: U32 -> @+nv: U32 -> @+f: F -> Cells

# The patch under particle i: Catmull-Rom over its row (the ring
# wraps, an open cloth clamps) and the row below, 2 x 2; the columns
# alternate two colours by the stripe.
def Cloth.patch(
  ~F: Data, ~mesh: Hook.mesh(F), +c: Cloth, +i: U32, +fit: Fit, +c0: U32, +c1: U32, +rough: F32,
  +f: F
) -> Cells:
  Fit{cols, _, open, _, _, _, _, _, _, _, _, _, _, _, _, _, stripe} = fit
  +row = ((i / cols) * cols : U32)
  +col = (i % cols : U32)
  +ring = U32.is_eq(open, 0)
  +l = (row + word(ring, ((col + cols - 1) % cols : U32),
    word((col > 0 : U32), (col - 1 : U32), col)) : U32)
  +r = (row + word(ring, ((col + 1) % cols : U32), (col + 1 : U32)) : U32)
  +rr = (row + word(ring, ((col + 2) % cols : U32),
    word(((col + 2 : U32) < cols : U32), (col + 2 : U32), (col + 1 : U32))) : U32)
  mesh(Sheet{Cloth.at(3n, c, l, 16), Cloth.at(3n, c, i, 16),
      Cloth.at(3n, c, r, 16), Cloth.at(3n, c, rr, 16), Cloth.at(3n, c, (l + cols : U32), 16),
      Cloth.at(3n, c, (i + cols : U32), 16), Cloth.at(3n, c, (r + cols : U32), 16),
      Cloth.at(3n, c, (rr + cols : U32), 16)},
    Mat{word(U32.is_eq((i % stripe : U32), 0), c0, c1), rough, 0.0, 0.0, 0, 0, 1.0},
    word(ring, 2, 1), word(ring, 2, 1), f)

# The strand from particle i to the one below: a ribbon facing the
# eye, w wide each side.
def Cloth.rope(
  ~F: Data, ~cam: Hook.cam(F), ~mesh: Hook.mesh(F), +c: Cloth, +i: U32, +fit: Fit, +c0: U32,
  +rough: F32, +w: F32, +f: F
) -> Cells:
  Fit{cols, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _} = fit
  +a = Cloth.at(3n, c, i, 16)
  +b = Cloth.at(3n, c, (i + cols : U32), 16)
  +axis = Vec.sub(b, a)
  +right = Vec.unit(Vec.cross(axis, Vec.sub(Cam.eye(cam(f)), a)))
  mesh(Inst{Plate{}, Vec.mix(a, b, 0.5), Vec.scale(right, w),
    Vec{0.0, 0.0, 0.0}, Vec.scale(axis, (0.0 - 0.5 : F32))}, Mat{c0, rough, 0.0, 0.0, 0, 0, 1.0},
    1, 1, f)

def Cloth.piece(
  ~F: Data, ~cam: Hook.cam(F), ~mesh: Hook.mesh(F), skip: Bool, rope: Bool, +c: Cloth, +i: U32,
  +fit: Fit, +c0: U32, +c1: U32, +rough: F32, +w: F32, +f: F
) -> Cells:
  match skip rope:
    case True{} _:
      CNil{}
    case False{} False{}:
      Cloth.patch(~F, ~mesh, c, i, fit, c0, c1, rough, f)
    case False{} True{}:
      Cloth.rope(~F, ~cam, ~mesh, c, i, fit, c0, rough, w, f)

# The pieces of a cloth (patches of two colours, or ropes of a width),
# a fork tree over 64: none under the last row, nor past an open
# cloth's last column.
def Cloth.mesh(
  ~F: Data, ~cam: Hook.cam(F), ~mesh: Hook.mesh(F), +n: Nat, +c: Cloth, +i: U32, +fit: Fit,
  +rope: Bool, +c0: U32, +c1: U32, +rough: F32, +w: F32, +f: F
) -> Cells:
  match n:
    case 0n:
      Fit{cols, rows, open, _, _, _, _, _, _, _, _, _, _, _, _, _, _} = fit
      Cloth.piece(~F, ~cam, ~mesh, (((i / cols) + 1 : U32) >= rows : U32)
          || (Bool.not(rope) && U32.is_eq(open, 1) && U32.is_eq((i % cols : U32), (cols - 1 : U32))),
        rope, c, i, fit, c0, c1, rough, w, f)
    case 1n+k:
      +s = U32.shln(1, (k + k : Nat))
      a b cc d = Cloth.mesh(~F, ~cam, ~mesh, k, c, i, fit, rope, c0, c1, rough, w, f)
        Cloth.mesh(~F, ~cam, ~mesh, k, c, (i + s : U32), fit, rope, c0, c1, rough, w, f)
        Cloth.mesh(~F, ~cam, ~mesh, k, c, (i + s * 2 : U32), fit, rope, c0, c1, rough, w, f)
        Cloth.mesh(~F, ~cam, ~mesh, k, c, (i + s * 3 : U32), fit, rope, c0, c1, rough, w, f)
      Cells.m4(a, b, cc, d)

# Text
# ----

# A stroke font: a glyph's first character is its advance in half
# units (code - 48), the rest its stroke points (code - 48 = x + 5 y
# over a 5 x 8 grid, y down from the cap line, 6 the baseline), a
# space lifting the pen.
def Font.glyph(c: U32) -> String:
  match c:
    case 65:
      ";N2R EG"
    case 66:
      ";N039>B? BHMQN"
    case 67:
      ";9315IOQM"
    case 68:
      ";N039MQN"
    case 69:
      ":40NR ?B"
    case 70:
      ":40N ?B"
    case 71:
      ";9315IOQMCA"
    case 72:
      ";0N ?C 4R"
    case 73:
      "50N"
    case 74:
      ":4MQOI"
    case 75:
      ";0N 4D @R"
    case 76:
      ":0NR"
    case 77:
      ";N0A4R"
    case 78:
      ";N0R4"
    case 79:
      ";139MQOI51"
    case 80:
      ";N039>B?"
    case 81:
      ";139MQOI51 FW"
    case 82:
      ";N039>B? AR"
    case 83:
      ";9315:@BHMQOI"
    case 84:
      ":04 2P"
    case 85:
      ";0IOQM4"
    case 86:
      ";0P4"
    case 87:
      "<0O<Q4"
    case 88:
      ";0R 4N"
    case 89:
      ";0A4 AP"
    case 90:
      ";04NR"
    case 48:
      ";139MQOI51"
    case 49:
      "8:2P"
    case 50:
      ";5139>NR"
    case 51:
      ";5139>B@ BHMQOI"
    case 52:
      ";Q3DH"
    case 53:
      ";40?BHMQOI"
    case 54:
      ";9315IOQMHB?"
    case 55:
      ":04O"
    case 56:
      ";@:5139>B@DIOQMHB"
    case 57:
      ";IOQM9315:@C"
    case 37:
      "<02<:0 4N FHRPF"
    case 47:
      "94N"
    case 43:
      ";7K ?C"
    case 46:
      "4IN"
    case 44:
      "4JOS"
    case 39:
      "40:"
    case 45:
      "8?B"
    case _:
      "6"

# A stroke as a quad: half wv wide across an upright, wh across a bar,
# its ends past the points so joints close; opaque, nearer than any
# world point (inverse depth 3000).
def Text.seg(
  +ax: F32, +ay: F32, +bx: F32, +by: F32, +wv: F32, +wh: F32, +col: U32, +x1: F32, +y1: F32,
  cells: Cells
) -> Cells:
  +dx = (bx - ax : F32)
  +dy = (by - ay : F32)
  +l = F32.sqrt((dx * dx + dy * dy : F32))
  +hw = (wh + (wv - wh) * F32.abs(dy) / l : F32)
  +ex = (dx / l * hw : F32)
  +ey = (dy / l * hw : F32)
  Quad.put((ax - ex - ey : F32), (ay - ey + ex : F32), (bx + ex - ey : F32),
    (by + ey + ex : F32), (bx + ex + ey : F32), (by + ey - ex : F32), (ax - ex + ey : F32),
    (ay - ey - ex : F32), 3000.0, col, 0, 1.0, x1, y1, cells)

def Text.stroke(
  on: Bool, +ax: F32, +ay: F32, +bx: F32, +by: F32, +wv: F32, +wh: F32, +col: U32,
  +x1: F32, +y1: F32, cells: Cells
) -> Cells:
  match on:
    case False{}:
      cells
    case True{}:
      Text.seg(ax, ay, bx, by, wv, wh, col, x1, y1, cells)

# The strokes of a glyph's points from x on the baseline, u a grid
# step: a point after another (the pen down) is a stroke; a space
# lifts the pen.
def Text.strokes(
  g: String, down: Bool, +px: F32, +py: F32, +x: F32, +base: F32, +u: F32, +wv: F32,
  +wh: F32, +col: U32, +x1: F32, +y1: F32, cells: Cells
) -> Cells:
  match g:
    case SNil{}:
      cells
    case SCon{Chr{+c}, rest}:
      +k = (c - 48 : U32)
      +on = (c > 32 : U32)
      +qx = (x + U32.to_f32((k % 5 : U32)) * u : F32)
      +qy = (base - (6.0 - U32.to_f32((k / 5 : U32))) * u : F32)
      Text.strokes(rest, on, qx, qy, x, base, u, wv, wh, col, x1, y1,
        Text.stroke(Bool.and(down, on), px, py, qx, qy, wv, wh, col, x1, y1, cells))

def Text.adv(g: String) -> F32:
  match g:
    case SNil{}:
      0.0
    case SCon{Chr{a}, pts}:
      U32.to_f32((a - 48 : U32))

def Text.pts(g: String) -> String:
  match g:
    case SNil{}:
      SNil{}
    case SCon{_, pts}:
      pts

# Text from x on the baseline; a lowercase letter is its capital at 0.72.
def Text.go(
  s: String, +x: F32, +base: F32, +u: F32, +wv: F32, +wh: F32, +col: U32, +x1: F32, +y1: F32,
  cells: Cells
) -> Cells:
  match s:
    case SNil{}:
      cells
    case SCon{Chr{+c}, rest}:
      +low = ((c >= 97) && (c <= 122) : U32)
      +k = (u * pick(low, 0.72, 1.0) : F32)
      +code = word(low, (c - 32 : U32), c)
      Text.go(rest, (x + Text.adv(Font.glyph(code)) * k * 0.5 : F32), base, u, wv, wh, col, x1, y1,
        Text.strokes(Text.pts(Font.glyph(code)), False{}, 0.0, 0.0, x, base, k, wv, wh, col, x1, y1,
          cells))

# Text of a size (pixels) and style (0 sans, 1 serif, 2 bold) at (x,
# y), the top left of its box, in the frame whose last pixel is (x1,
# y1); the baseline 0.88 of the size down.
def Text.put(
  +x: F32, +y: F32, +sz: F32, +style: U32, +col: U32, s: String, +x1: F32, +y1: F32, cells: Cells
) -> Cells:
  +k = max(0.8, (sz * pick(U32.is_eq(style, 2), 0.06, pick(U32.is_eq(style, 1), 0.05, 0.035)) : F32))
  Text.go(s, x, (y + sz * 0.88 : F32), (sz * 0.116667 : F32), k,
    pick(U32.is_eq(style, 1), max(0.8, (k * 0.5 : F32)), k), col, x1, y1, cells)

# Frame
# -----

# The app's backdrop, four hooks over its summary S: the summary of
# the h-square at (x, y); does it cross the square (else the tile is
# one Pix); the summary narrowed to the columns at x when per (the
# tile has pixels); the pixel.
def Sky.of(S: Data) -> Type:
  @+x: U32 -> @+y: U32 -> @+h: U32 -> S

def Sky.flat(S: Data) -> Type:
  @+s: S -> @+x: U32 -> @+y: U32 -> @+h: U32 -> Bool

def Sky.col(S: Data) -> Type:
  Bool -> @+x: U32 -> @+s: S -> S

def Sky.at(S: Data) -> Type:
  @+x: U32 -> @+y: U32 -> @+s: S -> U32

# The app's frame size hooks: constants where used, so no fork task
# carries them.
def Hook.dim() -> Type:
  U32

# The nearest opaque hit at a pixel: inverse depth, colour, the index
# of its triangle in the tile's list (0: none).
type Hit is Data:
  Hit{w: F32, c: U32, i: U32}

# The hits of a 2 x 2 block, and did a pixel take a blend.
type Blk is Data:
  Blk{+h0: Hit, +h1: Hit, +h2: Hit, +h3: Hit, mixed: Bool}

# The last frame's image of a region as its quadrants.
type Four is Data:
  Four{a: Image, b: Image, c: Image, d: Image}

# The filter's answer: the count of hits, the opaque list, the
# transparent list.
type Filt is Data:
  Filt{+n: U32, ts: Tris, bs: Tris}

def Tris.put(on: Bool, +t: Tri, acc: Tris) -> Tris:
  match on:
    case True{}:
      TCons{t, acc}
    case False{}:
      acc

# A triangle whose box meets the tile's: kept when no edge separates
# the tile's corner pixels from it.
def Tris.test(
  over: Bool, +t: Tri, +fx0: F32, +fy0: F32, +fx1: F32, +fy1: F32, f: Filt
) -> Filt:
  match over:
    case False{}:
      f
    case True{}:
      Tri{_, _, _, _, _, _, m, _, _} = t
      Filt{n, acc, bcc} = f
      +hit = Tri.cover(t, fx0, fy0, fx1, fy1)
      +opaque = U32.is_eq(m, 0)
      Filt{(n + word(hit, 1, 0) : U32), Tris.put(Bool.and(hit, opaque), t, acc),
        Tris.put(Bool.and(hit, Bool.not(opaque)), t, bcc)}

# The triangles of the borrowed list that meet [x0, x1] x [y0, y1].
def Tris.filter(cs: Tris, +x0: U32, +y0: U32, +x1: U32, +y1: U32, f: Filt) -> Filt:
  match cs:
    case TNil{}:
      f
    case TCons{t, m}:
      Tri{_, _, _, _, _, _, _, _, box} = t
      Rect{bx0, by0, bx1, by1} = box
      Tris.filter(m, x0, y0, x1, y1, Tris.test(
        ((bx0 <= x1) && (bx1 >= x0) && (by0 <= y1) && (by1 >= y0) : U32), t,
        (U32.to_f32(x0) + 0.5 : F32), (U32.to_f32(y0) + 0.5 : F32),
        (U32.to_f32(x1) + 0.5 : F32), (U32.to_f32(y1) + 0.5 : F32), f))

# Is the point in the triangle? A hair of slack closes the cracks
# where a patch meets two finer ones.
def Tri.in(+l0: F32, +l1: F32) -> Bool:
  ((l0 >= 0.0) && (l1 >= 0.0) && (l0 + l1 <= 1.004) : F32)

def Blk.hit(
  hit: Bool, +t: Tri, +w: F32, +i: U32, +px: F32, +py: F32, +old: Hit
) -> Hit:
  match hit:
    case False{}:
      old
    case True{}:
      Tri{_, _, _, r, g, b, _, _, _} = t
      Vec{rc, ru, rv} = r
      Vec{gc, gu, gv} = g
      Vec{bc, bu, bv} = b
      Hit{w, pack((rc + ru * px + rv * py : F32), (gc + gu * px + gv * py : F32),
        (bc + bu * px + bv * py : F32)), i}

def Blk.at(~S: Data, ~at: Sky.at(S), none: Bool, +c: U32, +x: U32, +y: U32, +sky: S) -> U32:
  match none:
    case False{}:
      c
    case True{}:
      at(x, y, sky)

def Blend.mix(
  lerp: Bool, +al: F32, +r: F32, +g: F32, +b: F32, +oldr: F32, +oldg: F32,
  +oldb: F32
) -> U32:
  match lerp:
    case True{}:
      pack((oldr + (r - oldr) * al : F32), (oldg + (g - oldg) * al : F32),
        (oldb + (b - oldb) * al : F32))
    case False{}:
      pack((oldr + r * al : F32), (oldg + g * al : F32), (oldb + b * al : F32))

# A colour over the old one by the mode: a soft one lerps its tint by
# alpha under cos^2 of the distance from its centre (r, g over w).
def Blend.mode(
  soft: Bool, +m: U32, +al: F32, +r: F32, +g: F32, +b: F32, +w: F32, +old: U32
) -> U32:
  match soft:
    case False{}:
      Blend.mix(U32.is_eq(m, 1), al, r, g, b, chan((old >> 16n : U32)), chan((old >> 8n : U32)), chan(old))
    case True{}:
      +c = F32.cos((1.5707963 * min(1.0, (F32.sqrt((r * r + g * g : F32)) / w : F32)) : F32))
      +t = F32.to_u32(b)
      Blend.mix(True{}, (al * c * c : F32), chan((t >> 16n : U32)), chan((t >> 8n : U32)), chan(t),
        chan((old >> 16n : U32)), chan((old >> 8n : U32)), chan(old))

def Blend.px(hit: Bool, +t: Tri, +px: F32, +py: F32, +old: U32) -> U32:
  match hit:
    case False{}:
      old
    case True{}:
      Tri{_, _, w, r, g, b, m, al, _} = t
      Vec{wc, wu, wv} = w
      Vec{rc, ru, rv} = r
      Vec{gc, gu, gv} = g
      Vec{bc, bu, bv} = b
      Blend.mode(U32.is_eq(m, 3), m, al, (rc + ru * px + rv * py : F32),
        (gc + gu * px + gv * py : F32), (bc + bu * px + bv * py : F32),
        (wc + wu * px + wv * py : F32), old)

def Blk.one(same: Bool, +k0: U32, +k1: U32, +k2: U32, +k3: U32) -> Image:
  match same:
    case True{}:
      Pix{k0}
    case False{}:
      Qua{Pix{k0}, Pix{k1}, Pix{k2}, Pix{k3}}

# The block's image: one Pix under one opaque triangle nothing blended
# over, or of one colour; else four.
def Blk.four(+b: Blk) -> Image:
  Blk{h0, h1, h2, h3, mixed} = b
  Hit{_, k0, i0} = h0
  Hit{_, k1, i1} = h1
  Hit{_, k2, i2} = h2
  Hit{_, k3, i3} = h3
  Blk.one((U32.is_eq(i0, i1) && U32.is_eq(i1, i2) && U32.is_eq(i2, i3)
    && (((i0 > 0) && Bool.not(mixed))
      || (U32.is_eq(k0, k1) && U32.is_eq(k1, k2) && U32.is_eq(k2, k3))) : U32),
    k0, k1, k2, k3)

# A transparent triangle nearer than the block's hits blended over
# its colours; mixed when a pixel took it.
def Blend.step(+t: Tri, +px: F32, +py: F32, +b: Blk) -> Blk:
  Tri{l0, l1, w, _, _, _, _, _, _} = t
  Vec{a0, b0, c0} = l0
  Vec{a1, b1, c1} = l1
  Vec{wc, wu, wv} = w
  Blk{h0, h1, h2, h3, mixed} = b
  Hit{w0, k0, i0} = h0
  Hit{w1, k1, i1} = h1
  Hit{w2, k2, i2} = h2
  Hit{w3, k3, i3} = h3
  +l0 = (a0 * px + b0 * py + c0 + 0.002 : F32)
  +l1 = (a1 * px + b1 * py + c1 + 0.002 : F32)
  +w = (wc + wu * px + wv * py : F32)
  +px1 = (px + 1.0 : F32)
  +py1 = (py + 1.0 : F32)
  +q0 = Bool.and(Tri.in(l0, l1), (w > w0 : F32))
  +q1 = Bool.and(Tri.in((l0 + a0 : F32), (l1 + a1 : F32)), (w + wu > w1 : F32))
  +q2 = Bool.and(Tri.in((l0 + b0 : F32), (l1 + b1 : F32)), (w + wv > w2 : F32))
  +q3 = Bool.and(Tri.in((l0 + a0 + b0 : F32), (l1 + a1 + b1 : F32)),
    (w + wu + wv > w3 : F32))
  Blk{Hit{w0, Blend.px(q0, t, px, py, k0), i0}, Hit{w1, Blend.px(q1, t, px1, py, k1), i1},
    Hit{w2, Blend.px(q2, t, px, py1, k2), i2}, Hit{w3, Blend.px(q3, t, px1, py1, k3), i3},
    Bool.or(mixed, Bool.or(Bool.or(q0, q1), Bool.or(q2, q3)))}

# The transparent triangles over the four blocks in the list's order,
# one flat loop; then their images.
def Blend.go(
  bs: Tris, +px: F32, +py: F32, +b0: Blk, +b1: Blk, +b2: Blk, +b3: Blk
) -> Image:
  match bs:
    case TNil{}:
      Qua{Blk.four(b0), Blk.four(b1), Blk.four(b2), Blk.four(b3)}
    case TCons{t, n}:
      +px1 = (px + 2.0 : F32)
      +py1 = (py + 2.0 : F32)
      Blend.go(n, px, py, Blend.step(t, px, py, b0), Blend.step(t, px1, py, b1),
        Blend.step(t, px, py1, b2), Blend.step(t, px1, py1, b3))

def Blk.fill(~S: Data, ~at: Sky.at(S), +b: Blk, +x: U32, +y: U32, +sky: S) -> Blk:
  Blk{h0, h1, h2, h3, mixed} = b
  Hit{w0, c0, i0} = h0
  Hit{w1, c1, i1} = h1
  Hit{w2, c2, i2} = h2
  Hit{w3, c3, i3} = h3
  +x1 = (x + 1 : U32)
  +y1 = (y + 1 : U32)
  Blk{Hit{w0, Blk.at(~S, ~at, U32.is_eq(i0, 0), c0, x, y, sky), i0},
    Hit{w1, Blk.at(~S, ~at, U32.is_eq(i1, 0), c1, x1, y, sky), i1},
    Hit{w2, Blk.at(~S, ~at, U32.is_eq(i2, 0), c2, x, y1, sky), i2},
    Hit{w3, Blk.at(~S, ~at, U32.is_eq(i3, 0), c3, x1, y1, sky), i3}, mixed}

# The triangle i over the block's four pixel centres from (px, py):
# the planes step by a column and a row.
def Blk.step(+t: Tri, +i: U32, +px: F32, +py: F32, +b: Blk) -> Blk:
  Tri{l0, l1, w, _, _, _, _, _, _} = t
  Vec{a0, b0, c0} = l0
  Vec{a1, b1, c1} = l1
  Vec{wc, wu, wv} = w
  Blk{h0, h1, h2, h3, mixed} = b
  Hit{w0, _, _} = h0
  Hit{w1, _, _} = h1
  Hit{w2, _, _} = h2
  Hit{w3, _, _} = h3
  +l0 = (a0 * px + b0 * py + c0 + 0.002 : F32)
  +l1 = (a1 * px + b1 * py + c1 + 0.002 : F32)
  +w = (wc + wu * px + wv * py : F32)
  +px1 = (px + 1.0 : F32)
  +py1 = (py + 1.0 : F32)
  Blk{Blk.hit(Bool.and(Tri.in(l0, l1), (w > w0 : F32)), t, w, i, px, py, h0),
    Blk.hit(Bool.and(Tri.in((l0 + a0 : F32), (l1 + a1 : F32)),
        (w + wu > w1 : F32)), t, (w + wu : F32), i, px1, py, h1),
    Blk.hit(Bool.and(Tri.in((l0 + b0 : F32), (l1 + b1 : F32)),
        (w + wv > w2 : F32)), t, (w + wv : F32), i, px, py1, h2),
    Blk.hit(Bool.and(Tri.in((l0 + a0 + b0 : F32), (l1 + a1 + b1 : F32)),
        (w + wu + wv > w3 : F32)), t, (w + wu + wv : F32), i, px1, py1, h3), mixed}

# The nearest opaque triangle over the four blocks from (px, py), the
# entries counted from i, one flat loop: an entry is read once for
# sixteen pixels; then the backdrop, the blends.
def Blk.go(
  ~S: Data, ~at: Sky.at(S), cs: Tris, bs: Tris, +i: U32, +px: F32, +py: F32, +x: U32, +y: U32,
  +sa: S, +sb: S, +b0: Blk, +b1: Blk, +b2: Blk, +b3: Blk
) -> Image:
  match cs:
    case TNil{}:
      +x1 = (x + 2 : U32)
      +y1 = (y + 2 : U32)
      Blend.go(bs, px, py, Blk.fill(~S, ~at, b0, x, y, sa), Blk.fill(~S, ~at, b1, x1, y, sb),
        Blk.fill(~S, ~at, b2, x, y1, sa), Blk.fill(~S, ~at, b3, x1, y1, sb))
    case TCons{t, n}:
      +px1 = (px + 2.0 : F32)
      +py1 = (py + 2.0 : F32)
      Blk.go(~S, ~at, n, bs, (i + 1 : U32), px, py, x, y, sa, sb, Blk.step(t, i, px, py, b0),
        Blk.step(t, i, px1, py, b1), Blk.step(t, i, px, py1, b2),
        Blk.step(t, i, px1, py1, b3))

# Four blocks under the backdrops of their two column pairs.
def Tile.b4(
  ~S: Data, ~col: Sky.col(S), ~at: Sky.at(S), +cs: Tris, +bs: Tris, +per: Bool, +x: U32, +y: U32,
  +sky: S
) -> Image:
  +b = {Blk{Hit{0.0, 0, 0}, Hit{0.0, 0, 0}, Hit{0.0, 0, 0}, Hit{0.0, 0, 0}, False{}} : Blk}
  Blk.go(~S, ~at, cs, bs, 1, (U32.to_f32(x) + 0.5 : F32), (U32.to_f32(y) + 0.5 : F32), x, y,
    col(per, x, sky), col(per, (x + 2 : U32), sky), b, b, b, b)

def Tile.b8(
  ~S: Data, ~col: Sky.col(S), ~at: Sky.at(S), +cs: Tris, +bs: Tris, +per: Bool, +x: U32, +y: U32,
  +sky: S
) -> Image:
  +x1 = (x + 4 : U32)
  +y1 = (y + 4 : U32)
  Qua{Tile.b4(~S, ~col, ~at, cs, bs, per, x, y, sky), Tile.b4(~S, ~col, ~at, cs, bs, per, x1, y, sky),
    Tile.b4(~S, ~col, ~at, cs, bs, per, x, y1, sky), Tile.b4(~S, ~col, ~at, cs, bs, per, x1, y1, sky)}

# The tile's lists freed after its pixels read them, one flat loop (as
# dead parameters the runtime's sink is 0.55 ms a frame slower).
def Tile.fin(img: Image, cs: Tris, bs: Tris) -> Image:
  match cs bs:
    case TCons{_, n} _:
      Tile.fin(img, n, bs)
    case TNil{} TCons{_, n}:
      Tile.fin(img, TNil{}, n)
    case TNil{} TNil{}:
      img

# A tile as four 8-squares of four 4-squares, straight-line: a
# recursion costs a frame per square on the device.
def Tile.b16(
  ~S: Data, ~col: Sky.col(S), ~at: Sky.at(S), +cs: Tris, +bs: Tris, +per: Bool, +x: U32, +y: U32,
  +sky: S
) -> Image:
  +x1 = (x + 8 : U32)
  +y1 = (y + 8 : U32)
  Qua{Tile.b8(~S, ~col, ~at, cs, bs, per, x, y, sky), Tile.b8(~S, ~col, ~at, cs, bs, per, x1, y, sky),
    Tile.b8(~S, ~col, ~at, cs, bs, per, x, y1, sky), Tile.b8(~S, ~col, ~at, cs, bs, per, x1, y1, sky)}

# A plain tile (no hit, nothing of the backdrop crossing) is one Pix;
# else its pixels over its lists.
def Tile.pick(
  ~S: Data, ~col: Sky.col(S), ~at: Sky.at(S), plain: Bool, +cs: Tris, +bs: Tris, +per: Bool, +x: U32,
  +y: U32, +sky: S
) -> Image:
  match plain:
    case True{}:
      Pix{at(x, y, sky)}
    case False{}:
      Tile.fin(Tile.b16(~S, ~col, ~at, cs, bs, per, x, y, sky), cs, bs)

def Tile.fate(
  ~S: Data, ~col: Sky.col(S), ~at: Sky.at(S), f: Filt, +per: Bool, +x: U32, +y: U32, +sky: S
) -> Image:
  Filt{n, cs, bs} = f
  Tile.pick(~S, ~col, ~at, Bool.and(U32.is_eq(n, 0), Bool.not(per)), cs, bs, per, x, y, sky)

# A tile of the cell's borrowed list: its backdrop, its own lists, its
# pixels; the last frame's tile (old) is sunk.
def Tile.go(
  ~S: Data, ~of: Sky.of(S), ~flat: Sky.flat(S), ~col: Sky.col(S), ~at: Sky.at(S), cs: Tris,
  +x: U32, +y: U32, old: Four
) -> Image:
  +sky = of(x, y, 16)
  Tile.fate(~S, ~col, ~at, Tris.filter(cs, x, y, (x + 15 : U32), (y + 15 : U32),
    Filt{0, TNil{}, TNil{}}), flat(sky, x, y, 16), x, y, sky)

def Image.open(old: Image) -> Four:
  match old:
    case Pix{+c}:
      Four{Pix{c}, Pix{c}, Pix{c}, Pix{c}}
    case Qua{a, b, c, d}:
      Four{a, b, c, d}

# k levels of four-way forks over the cell's borrowed list down to its
# tiles: a fork per pixel drowns in scheduling, a fork per cell leaves
# lanes idle. The last frame's image goes down quadrant by quadrant,
# each tile sinking its own: a host drop of a frame costs milliseconds.
def Cell.fork(
  ~S: Data, ~of: Sky.of(S), ~flat: Sky.flat(S), ~col: Sky.col(S), ~at: Sky.at(S), +k: Nat,
  +cs: Tris, +x: U32, +y: U32, old: Four
) -> Image:
  match k:
    case 0n:
      Tile.go(~S, ~of, ~flat, ~col, ~at, cs, x, y, old)
    case 1n+e:
      Four{oa, ob, oc, od} = old
      +h = U32.shln(16, e)
      +x1 = (x + h : U32)
      +y1 = (y + h : U32)
      a b c d = Cell.fork(~S, ~of, ~flat, ~col, ~at, e, cs, x, y, Image.open(oa))
        Cell.fork(~S, ~of, ~flat, ~col, ~at, e, cs, x1, y, Image.open(ob))
        Cell.fork(~S, ~of, ~flat, ~col, ~at, e, cs, x, y1, Image.open(oc))
        Cell.fork(~S, ~of, ~flat, ~col, ~at, e, cs, x1, y1, Image.open(od))
      Qua{a, b, c, d}

# An empty region of 64 << k: black off the frame, else split down to
# its tiles.
def Frame.sky(
  ~S: Data, ~of: Sky.of(S), ~flat: Sky.flat(S), ~col: Sky.col(S), ~at: Sky.at(S), ~w: Hook.dim(),
  ~h: Hook.dim(), +k: Nat, on: Bool, +x: U32, +y: U32, old: Four
) -> Image:
  match k on:
    case 0n True{}:
      Cell.fork(~S, ~of, ~flat, ~col, ~at, 2n, TNil{}, x, y, old)
    case 1n+e True{}:
      Four{oa, ob, oc, od} = old
      +s = U32.shln(64, e)
      +x1 = (x + s : U32)
      +y1 = (y + s : U32)
      a b c d = Frame.sky(~S, ~of, ~flat, ~col, ~at, ~w, ~h, e, True{}, x, y, Image.open(oa))
        Frame.sky(~S, ~of, ~flat, ~col, ~at, ~w, ~h, e, (x1 < w : U32), x1, y, Image.open(ob))
        Frame.sky(~S, ~of, ~flat, ~col, ~at, ~w, ~h, e, (y1 < h : U32), x, y1, Image.open(oc))
        Frame.sky(~S, ~of, ~flat, ~col, ~at, ~w, ~h, e, ((x1 < w) && (y1 < h) : U32), x1, y1,
          Image.open(od))
      Qua{a, b, c, d}
    case _ False{}:
      Pix{0}

# A region of the borrowed tree: empty, its backdrop; a cell, its
# tiles; a node forks.
def Frame.node(
  ~S: Data, ~of: Sky.of(S), ~flat: Sky.flat(S), ~col: Sky.col(S), ~at: Sky.at(S), ~w: Hook.dim(),
  ~h: Hook.dim(), c: Cells, +k: Nat, +x: U32, +y: U32, old: Four
) -> Image:
  match c:
    case CNil{}:
      Frame.sky(~S, ~of, ~flat, ~col, ~at, ~w, ~h, k, ((x < w) && (y < h) : U32), x, y, old)
    case CLeaf{_, ts}:
      Cell.fork(~S, ~of, ~flat, ~col, ~at, 2n, ts, x, y, old)
    case CQua{tl, tr, bl, br}:
      match k:
        case 0n:
          Pix{0}
        case 1n+e:
          Four{oa, ob, oc, od} = old
          +s = U32.shln(64, e)
          +x1 = (x + s : U32)
          +y1 = (y + s : U32)
          a b c d = Frame.node(~S, ~of, ~flat, ~col, ~at, ~w, ~h, tl, e, x, y, Image.open(oa))
            Frame.node(~S, ~of, ~flat, ~col, ~at, ~w, ~h, tr, e, x1, y, Image.open(ob))
            Frame.node(~S, ~of, ~flat, ~col, ~at, ~w, ~h, bl, e, x, y1, Image.open(oc))
            Frame.node(~S, ~of, ~flat, ~col, ~at, ~w, ~h, br, e, x1, y1, Image.open(od))
          Qua{a, b, c, d}

# The w x h frame over the last one (dropped tile by tile inside it):
# one bang, since a launch costs a fixed fee; the tree is borrowed,
# never copied, and comes back for the host to drop.
def Frame.show(
  ~S: Data, ~of: Sky.of(S), ~flat: Sky.flat(S), ~col: Sky.col(S), ~at: Sky.at(S), ~w: Hook.dim(),
  ~h: Hook.dim(), +cells: Cells, old: Image
) -> Image & Cells:
  (Frame.node!(~S, ~of, ~flat, ~col, ~at, ~w, ~h, cells, 5n, 0, 0, Image.open(old)), cells)
