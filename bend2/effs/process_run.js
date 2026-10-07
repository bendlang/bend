// Process
// =======

// The steps of process_run.c, parked on the loop instead of a helper thread:
// the call waits on the child's pipes and on a descriptor that turns readable
// once it exits (a pidfd on Linux, a kqueue on macOS; without one, it looks
// every 50ms), so other computations run meanwhile. Once the direct child is
// reaped it reads at most a pipe's capacity more from each, what it could
// hold at the exit: a descendant holding a pipe open does not extend the
// wait. A macOS pipe holds 64KB; a Linux one says (F_GETPIPE_SZ).

// The libc beyond io_sys. On Linux, as on the C lane, it needs glibc 2.34
// or newer for addclosefrom_np.
function process_sys() {
  if (globalThis.BEND_PROCESS === undefined) {
    const mac = io_sys().mac;
    const fn = (args, returns = "i32") => ({ args, returns });
    globalThis.BEND_PROCESS = require("bun:ffi").dlopen(mac
      ? "libSystem.dylib" : "libc.so.6", {
      pipe: fn(["ptr"]),
      write: fn(["i32", "ptr", "u64"], "i64"),
      waitpid: fn(["i32", "ptr", "i32"]),
      kill: fn(["i32", "i32"]),
      posix_spawnp: fn(Array(6).fill("ptr")),
      posix_spawn_file_actions_init: fn(["ptr"]),
      posix_spawn_file_actions_adddup2: fn(["ptr", "i32", "i32"]),
      posix_spawn_file_actions_destroy: fn(["ptr"]),
      posix_spawnattr_init: fn(["ptr"]),
      posix_spawnattr_setsigdefault: fn(["ptr", "ptr"]),
      posix_spawnattr_setflags: fn(["ptr", "i32"]),
      posix_spawnattr_destroy: fn(["ptr"]),
      ...mac ? { kqueue: fn([]),
        kevent: fn(["i32", "ptr", "i32", "ptr", "i32", "ptr"]) }
        : { syscall: fn(["i64", "i32", "i32"], "i64"),
          posix_spawn_file_actions_addclosefrom_np: fn(["ptr", "i32"]) },
    }).symbols;
  }
  return globalThis.BEND_PROCESS;
}

// Spawns argv on fresh pipes, SIGPIPE at its default, with no descriptor
// open past 2; answers 0 or an errno. The pipes are close-on-exec, and
// moved above 2 so a closed standard descriptor cannot alias one.
function process_spawn(sys, ps, p, argv) {
  for (const fds of p.pipes) {
    const two = new Int32Array(2);
    if (ps.pipe(sys.ptr(two)) !== 0) {
      return sys.errno();
    }
    fds[0] = two[0];
    fds[1] = two[1];
    for (let j = 0; j < 2; j += 1) {
      if (fds[j] < 3) {
        const moved = sys.fcntl(fds[j], 0, 3);
        if (moved < 0) {
          return sys.errno();
        }
        sys.close(fds[j]);
        fds[j] = moved;
      }
      if (sys.fcntl(fds[j], 2, 1) < 0) {
        return sys.errno();
      }
    }
  }
  for (const fd of [p.pipes[0][1], p.pipes[1][0], p.pipes[2][0]]) {
    const flags = sys.fcntl(fd, 3, 0);
    if (flags < 0 || sys.fcntl(fd, 4, flags | (sys.mac ? 4 : 0x800)) < 0) {
      return sys.errno();
    }
  }
  // argv and the environment as C strings in one block, each list behind
  // NULL-ended pointers; p keeps both alive until the call ends.
  const strs = [...argv,
    ...Object.entries(process.env).map(([k, v]) => k + "=" + v)];
  p.strs = io_bytes(strs.join("\0") + "\0");
  p.ptrs = new BigUint64Array(strs.length + 2);
  const base = sys.ptr(p.strs);
  for (let i = 0, s = 0, at = 0; i < p.strs.length; i += 1) {
    if (p.strs[i] === 0) {
      p.ptrs[s < argv.length ? s : s + 1] = BigInt(base + at);
      s += 1;
      at = i + 1;
    }
  }
  const acts = new Uint8Array(512);
  const attr = new Uint8Array(512);
  let code = ps.posix_spawn_file_actions_init(sys.ptr(acts));
  if (code !== 0) {
    return code;
  }
  for (let i = 0; i < 3 && code === 0; i += 1) {
    code = ps.posix_spawn_file_actions_adddup2(sys.ptr(acts),
      p.pipes[i][i === 0 ? 0 : 1], i);
  }
  if (code === 0 && !sys.mac) {
    code = ps.posix_spawn_file_actions_addclosefrom_np(sys.ptr(acts), 3);
  }
  const pid = new Int32Array(1);
  if (code === 0 && (code = ps.posix_spawnattr_init(sys.ptr(attr))) === 0) {
    // SIGPIPE (13) is bit 12 of a sigset_t on both hosts. The flags are
    // POSIX_SPAWN_SETSIGDEF, plus POSIX_SPAWN_CLOEXEC_DEFAULT on macOS.
    const sigs = new Uint8Array(128);
    sigs[1] = 0x10;
    code = ps.posix_spawnattr_setsigdefault(sys.ptr(attr), sys.ptr(sigs));
    if (code === 0) {
      code = ps.posix_spawnattr_setflags(sys.ptr(attr), sys.mac ? 0x4004 : 4);
    }
    if (code === 0) {
      code = ps.posix_spawnp(sys.ptr(pid), base, sys.ptr(acts),
        sys.ptr(attr), sys.ptr(p.ptrs), sys.ptr(p.ptrs, (argv.length + 1) * 8));
    }
    ps.posix_spawnattr_destroy(sys.ptr(attr));
  }
  ps.posix_spawn_file_actions_destroy(sys.ptr(acts));
  p.child = code === 0 ? pid[0] : -1;
  return code;
}

// A descriptor that turns readable once child exits, or -1.
function process_exitfd(sys, ps, child) {
  if (!sys.mac) {
    return Number(ps.syscall(434, child, 0));
  }
  // A struct kevent: child, EVFILT_PROC, EV_ADD | EV_ONESHOT, NOTE_EXIT.
  const ev = new Uint8Array(32);
  const view = new DataView(ev.buffer);
  view.setBigUint64(0, BigInt(child), true);
  view.setInt16(8, -5, true);
  view.setUint16(10, 0x11, true);
  view.setUint32(12, 0x80000000, true);
  const kq = ps.kqueue();
  if (kq >= 0 && ps.kevent(kq, sys.ptr(ev), 1, null, 0, null) !== 0) {
    sys.close(kq);
    return -1;
  }
  return kq;
}

// Reads stdout (i = 1) or stderr (i = 2) until it would block, or for at
// most left bytes, within the shared output limit; EOF closes it.
function process_read(sys, p, i, left) {
  const fd = p.pipes[i][0];
  const buf = p.buf;
  while (fd >= 0 && left > 0 && p.code === 0) {
    const n = Number(sys.read(fd, sys.ptr(buf), Math.min(left, buf.length)));
    if (n > 0) {
      if (n > p.max - p.len) {
        p.code = 27;
        break;
      }
      p.outs[i - 1].push(buf.slice(0, n));
      p.len += n;
      left -= n;
    } else if (n === 0) {
      sys.close(fd);
      p.pipes[i][0] = -1;
      break;
    } else {
      const code = sys.errno();
      if (code !== 4 && code !== (sys.mac ? 35 : 11)) {
        p.code = code;
      }
      if (code !== 4) {
        break;
      }
    }
  }
}

// Feeds stdin until it would block, closing it once all is written or the
// child stops reading (EPIPE).
function process_feed(sys, ps, p) {
  const fd = p.pipes[0][1];
  while (fd >= 0 && p.code === 0) {
    const left = p.input.length - p.written;
    const n = left === 0 ? 0
      : Number(ps.write(fd, sys.ptr(p.input, p.written), left));
    if (n > 0) {
      p.written += n;
      continue;
    }
    const code = left === 0 ? 32 : sys.errno();
    if (code === 4) {
      continue;
    }
    if (code === (sys.mac ? 35 : 11)) {
      break;
    }
    if (code !== 32) {
      p.code = code;
    }
    sys.close(fd);
    p.pipes[0][1] = -1;
    break;
  }
}

// Kills and reaps a child left running (only a failure leaves one), closes
// every descriptor and answers.
function process_end(sys, ps, p) {
  if (p.child >= 0) {
    ps.kill(p.child, 9);
    while (ps.waitpid(p.child, sys.ptr(p.status), 0) < 0
      && sys.errno() === 4) {
    }
  }
  for (const fd of [p.exit, ...p.pipes.flat()]) {
    if (fd >= 0) {
      sys.close(fd);
    }
  }
  if (p.code !== 0) {
    return io_fail(p.code);
  }
  const s = p.status[0];
  const [out, err] = p.outs.map((b) => Buffer.concat(b).toString("utf8"));
  return io_done(io_tup((s & 0x7f) === 0 ? s >> 8 & 0xff : 128 + (s & 0x7f),
    out, err));
}

function process_run(program, args, input, maxOutput, timeoutMs, k) {
  const argv = [program];
  for (let xs = args; xs.$ === CID(Con); xs = xs.tail) {
    argv.push(xs.head);
  }
  if (maxOutput === 0 || timeoutMs === 0
    || argv.some((arg) => arg.includes("\0"))) {
    return io_fail(22);
  }
  const sys = io_sys();
  const ps = process_sys();
  const p = { pipes: [[-1, -1], [-1, -1], [-1, -1]], child: -1, exit: -1,
    status: new Int32Array(1), input: io_bytes(input), written: 0,
    outs: [[], []], len: 0, max: maxOutput, code: 0,
    buf: new Uint8Array(65536) };
  p.code = process_spawn(sys, ps, p, argv);
  if (p.code !== 0) {
    return process_end(sys, ps, p);
  }
  for (const [i, j] of [[0, 0], [1, 1], [2, 1]]) {
    sys.close(p.pipes[i][j]);
    p.pipes[i][j] = -1;
  }
  p.exit = process_exitfd(sys, ps, p.child);
  const deadline = io_until(timeoutMs);
  const go = () => {
    const got = ps.waitpid(p.child, sys.ptr(p.status), 1);
    if (got === p.child) {
      p.child = -1;
      for (let i = 1; i < 3 && p.code === 0; i += 1) {
        const fd = p.pipes[i][0];
        const room = fd < 0 || sys.mac ? 65536 : sys.fcntl(fd, 1032, 0);
        if (room < 0) {
          p.code = sys.errno();
        }
        process_read(sys, p, i, room);
      }
      return process_end(sys, ps, p);
    }
    if (got < 0 && sys.errno() !== 4) {
      // Not ours to wait on (ECHILD): its pid may be reused, so no kill.
      p.code = sys.errno();
      p.child = -1;
      return process_end(sys, ps, p);
    }
    if (io_late(deadline)) {
      p.code = sys.mac ? 60 : 110;
      return process_end(sys, ps, p);
    }
    // A chunk per pipe, then waitpid again: a descendant that keeps writing
    // must not keep this from seeing the child exit, nor from answering.
    process_feed(sys, ps, p);
    process_read(sys, p, 1, p.buf.length);
    process_read(sys, p, 2, p.buf.length);
    if (p.code !== 0) {
      return process_end(sys, ps, p);
    }
    const ends = [[p.pipes[0][1], true], [p.pipes[1][0], false],
      [p.pipes[2][0], false], [p.exit, false]].filter(([fd]) => fd >= 0);
    io_park_on(ends, false, k, go, p.exit >= 0 ? deadline
      : Math.min(deadline, performance.now() + 50));
    return undefined;
  };
  return go();
}

io_eff(CID(Process.run), process_run);
