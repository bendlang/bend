// Chan
// ====

function chan_send(handle, value, k) {
  const row = handle;
  if (row.shut) {
    return false;
  }
  if (row.wait.length > 0 && row.wait[0].item === null) {
    chan_wake(row, { $: "Some", value: value });
    return true;
  }
  if (row.ring.length < row.room) {
    row.ring.push(value);
    return true;
  }
  row.wait.push({ cont: k, item: value });
  return;
}
