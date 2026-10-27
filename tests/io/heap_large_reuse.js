// These checks apply only to the native allocator.
function heap_large_reuse() {
  return { $: CID(Unit) };
}

io_eff(CID(Heap.check), heap_large_reuse);
