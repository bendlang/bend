// IO
// ==

function io_spawn(act) {
  io_push(act, (x) => ({ $: "Emit", value: x }), true);
  return { $: "Unit" };
}
