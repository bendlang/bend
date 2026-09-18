function io_random_u32() {
  try {
    const bytes = new Uint8Array(4);
    require("node:crypto").randomFillSync(bytes);
    const word = (bytes[0]
      | (bytes[1] << 8)
      | (bytes[2] << 16)
      | (bytes[3] << 24)) >>> 0;
    return io_done(word);
  } catch (error) {
    return { $: "Fail", error: io_tup(1, "CSPRNG: " + String(error)) };
  }
}
