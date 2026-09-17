# a partial match is legal when a live context binder holds an emptied
# datatype (check-efq's dead-context rule), and such a def can reach
# emission as a stored closure value even though no call can ever run
# it. Before this pin the C emitter refused the whole program ("a
# partial match") while the JS backend and the interpreter compiled and
# ran it -- a backend acceptance divergence. The missing tail IS an Efq
# tail: both emitters now print their stuck default (ERR_TAGS in C, the
# unreachable throw in JS) and every lane prints the same text.
import Base

law absurd.arm:
  for e: Empty
  for b: Bool
  U32

def absurd.arm(e, b):
  match b:
    case True{}: 1

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    f = absurd.arm
    IO.print("ok")

#|ok
