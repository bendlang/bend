-- Single-threaded Lean twin of main.bend. Same
-- scene of 9 spheres + one point light at (-3,8,1), same 2x2
-- supersampled pixels, nearest-hit + Lambertian shadow shading +
-- mirror bounce on a countdown depth (4). ray_trace is in the bench's
-- accumulator form: per bounce acc' = acc + ((w*lum)*(1-kr)), w' =
-- w*kr, final level adds acc + (w*lum); nearest folds spheres 8 down
-- to 0 with strict <. Float32 operations preserve the source
-- program's one-operation f32 semantics; the Bend row-fork reduction
-- is a plain row loop (UInt32 wrapping sum).
-- Expected at imageRows=12, imageWidth=6000: 1924309504 (imageRows=6,
-- imageWidth=80: 402971).
def imageRows : UInt32 := 12
def imageWidth : UInt32 := 6000

structure Sphere where
  x : Float32
  y : Float32
  z : Float32
  radius : Float32
  reflection : Float32
  deriving Inhabited

structure Hit where
  distance : Float32
  index : UInt32

def sceneSpheres : Array Sphere := #[
  ⟨0,-10001,5,10000,0.3⟩, ⟨0,0,5,1,0.7⟩, ⟨2,0.5,6,1,0.4⟩,
  ⟨-2,0.5,6,1,0.4⟩, ⟨1,-0.6,3.5,0.4,0.9⟩, ⟨-1,-0.6,3.5,0.4,0.9⟩,
  ⟨0,1.6,7,1.2,0.1⟩, ⟨3.5,0.2,8,1,0.6⟩, ⟨-3.5,0.2,8,1,0.6⟩]

-- ray-sphere: t of the near root, or 1e9 for a miss (disc < 0 or t < eps)
def sphere_isect (i : Nat) (ox oy oz dx dy dz : Float32) : Float32 :=
  let sphere := sceneSpheres[i]!
  let px := ox-sphere.x; let py := oy-sphere.y; let pz := oz-sphere.z
  let b := (px*dx + py*dy) + pz*dz
  let c := ((px*px + py*py) + pz*pz) - sphere.radius*sphere.radius
  let disc := b*b-c
  if disc < 0 then 1e9 else
    let distance := (0-b)-disc.sqrt
    if distance < 0.001 then 1e9 else distance

def scene_nearest (ox oy oz dx dy dz : Float32) : Hit := Id.run do
  let mut hit : Hit := ⟨1e9,9⟩
  for i in [0:9] do
    let index := 8-i
    let distance := sphere_isect index ox oy oz dx dy dz
    if distance < hit.distance then hit := ⟨distance,UInt32.ofNat index⟩
  return hit

partial def ray_trace (depth : UInt32) (ox oy oz dx dy dz acc w : Float32) : Float32 :=
  let hit := scene_nearest ox oy oz dx dy dz
  if hit.index == 9 then acc else
    let sphere := sceneSpheres[hit.index.toNat]!
    let hx:=ox+hit.distance*dx; let hy:=oy+hit.distance*dy; let hz:=oz+hit.distance*dz
    let nx:=(hx-sphere.x)/sphere.radius; let ny:=(hy-sphere.y)/sphere.radius; let nz:=(hz-sphere.z)/sphere.radius
    let lvx:=(-3)-hx; let lvy:=8-hy; let lvz:=1-hz
    let lightLength:=((lvx*lvx+lvy*lvy)+lvz*lvz).sqrt
    let lx:=lvx/lightLength; let ly:=lvy/lightLength; let lz:=lvz/lightLength
    let dot:=(nx*lx+ny*ly)+nz*lz
    let diffuse:=if dot<0 then 0 else dot
    let sox:=hx+0.001*nx; let soy:=hy+0.001*ny; let soz:=hz+0.001*nz
    let shadow:=scene_nearest sox soy soz lx ly lz
    let shade:=if shadow.distance<lightLength then 0 else diffuse
    let luminance:=0.1+0.85*shade
    if depth==0 then acc+w*luminance else
      let twiceDot:=2*((dx*nx+dy*ny)+dz*nz)
      ray_trace (depth-1) sox soy soz (dx-twiceDot*nx) (dy-twiceDot*ny) (dz-twiceDot*nz)
        (acc+(w*luminance)*(1-sphere.reflection)) (w*sphere.reflection)

def ray_sub (fx fy : Float32) : Float32 :=
  let dl:=((fx*fx+fy*fy)+1).sqrt
  ray_trace 4 0 0 0 (fx/dl) (fy/dl) (1/dl) 0 1

-- 2x2 supersampled pixel
def pixel_render (x y : UInt32) (halfWidth halfHeight : Float32) : UInt32 :=
  let xf:=x.toFloat32
  let yf:=y.toFloat32
  let l1:=ray_sub (((xf+0.25)-halfWidth)/halfWidth) ((halfHeight-(yf+0.25))/halfWidth)
  let l2:=ray_sub (((xf+0.75)-halfWidth)/halfWidth) ((halfHeight-(yf+0.25))/halfWidth)
  let l3:=ray_sub (((xf+0.25)-halfWidth)/halfWidth) ((halfHeight-(yf+0.75))/halfWidth)
  let l4:=ray_sub (((xf+0.75)-halfWidth)/halfWidth) ((halfHeight-(yf+0.75))/halfWidth)
  let avg:=((l1+l2)+(l3+l4))*0.25
  let clamped:=if avg<0 then 0 else if 1<avg then 1 else avg
  (255*clamped).toUInt32

def benchmark_run : UInt32 := Id.run do
  let width := imageWidth
  let height := (1 : UInt32) <<< imageRows
  let halfWidth:=(width/2).toFloat32
  let halfHeight:=(height/2).toFloat32
  let mut total : UInt32 := 0
  -- the Bend fork tree permutes row/column indices by odd multipliers
  -- (bijections: same pixel set, same u32 sum); mirrored here
  for yj in [0:height.toNat] do
    let y := (UInt32.ofNat yj * 1588635697) &&& (height - 1)
    for xj in [0:16384] do
      let x := (UInt32.ofNat xj * 2654435761) &&& 16383
      if x < width then
        total := total + pixel_render x y halfWidth halfHeight
  return total

def main : IO Unit := IO.println benchmark_run
