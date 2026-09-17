// Chan
// ====

function chan_close(handle) {
  const row = handle;
  if (!row.shut) {
    chan_shut(row);
  }
  return { $: "Unit" };
}
