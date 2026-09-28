# the module of respelled_*: respelled_first imports it directly as
# ./respelled/core.bend and again through ../reg/respelled/facts.bend,
# whose path climbs out of tests/import and back in
import Base

def seven() -> Nat:
  7n
