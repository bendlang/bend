// Audio
// =====

function audio_write(audio, samples) {
  const s = audio;
  let n = 0;
  for (let xs = samples; xs.$ === CID(Con); xs = xs.tail) {
    n += 1;
  }
  const now = Date.now();
  s.queued = Math.max(0, s.queued - (now - s.at) * s.rate / 1000);
  s.at = now;
  if (s.queued + n / 2 <= 4096) {
    s.queued += n / 2;
  }
  return io_tup(audio, Math.floor(s.queued));
}

io_eff(CID(Audio.write), audio_write);
