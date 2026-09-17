// Chan
// ====

function chan_recv(handle, k) {
  const row = handle;
  if (row.ring.length > 0) {
    return { $: "Some", value: chan_take(row) };
  }
  if (row.wait.length > 0 && row.wait[0].item !== null) {
    return { $: "Some", value: chan_wake(row, true) };
  }
  if (row.shut) {
    return { $: "None" };
  }
  row.wait.push({ cont: k, item: null });
  return;
}
