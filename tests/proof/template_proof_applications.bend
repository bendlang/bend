# --verdict must preserve types when template arguments reduce to lambdas.
import Base

def app(~g: U32 -> U32, x: U32) -> U32:
  g(x)

law via:
  for ~f: U32 -> U32
  for ~ok: (@x: U32 -> {f(x) == f(x) : U32})
  for x: U32
  {f(x) == f(x) : U32}

def via(f, ok, x):
  ok(x)

def app_h(~h: U32 -> U32) -> U32 -> U32:
  y => app(~h, y)

def h_ok(~h: U32 -> U32) -> (@z: U32 -> {app_h(~h)(z) == app_h(~h)(z) : U32}):
  z => {==}

law use:
  for ~h: U32 -> U32
  for x: U32
  {app_h(~h)(x) == app_h(~h)(x) : U32}

def use(h, x):
  via(~app_h(~h), ~h_ok(~h), x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
