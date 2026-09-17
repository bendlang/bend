// Chan
// ====

function chan_new(room) {
  return { room: Number(room), ring: [], wait: [], shut: false };
}
