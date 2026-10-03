import Base
import ./main.bend as Demo

# Runtime contract, checked by reference tests rather than formal proofs:
# export_ref returns the same affine owner on success and failure.
# X11 success copies the display name and publishes this owner's nonzero U32 ID
# before another connection uses it. Export leaves pending events available.
# WindowRef is copyable data, owns no resource, and never prolongs the Window.
# Use an exported ID only on its display while the owner is open. After close,
# the ID is stale and may be reused. Export does not search or adopt any window.
# Unsupported backends return ENOTSUP with the owner outside the failure.
# Native identity, visibility, and lifetime depend on foreign IO. Neither they
# nor properties depending on @unsafe definitions are claimed as proven here.

law no_close:
  {Demo.quit([]) == False{} : Bool}

law close_stops:
  for rest: List<Event>
  {Demo.quit(Close{} <> rest) == True{} : Bool}

law key_keeps_close:
  for rest: List<Event>
  {Demo.quit(Key{65, True{}} <> Close{} <> rest) == True{} : Bool}
