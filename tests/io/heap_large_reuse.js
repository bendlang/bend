// bend-ids 1
// CID #Unit BEND_CID_Unit
// CID :Heap.check BEND_CID_Heap_check
// bend-ids end
// These checks apply only to the native allocator.
function heap_large_reuse() {
  return { $: BEND_CID_Unit };
}

io_eff(BEND_CID_Heap_check, heap_large_reuse);
