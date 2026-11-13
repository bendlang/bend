io_eff(CID(empty_chunks), () =>
  Array.isArray(io_held) ? io_held.filter((chunk) => chunk.length === 0).length : 0);
