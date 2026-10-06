// Process
// =======

// Reap the direct child, then drain only bytes already buffered. Descendants
// may retain its pipes; their EOF must not extend this call or its deadline.

function process_run(program, args, input, maxOutput, timeoutMs) {
  const argv = [program];
  for (let xs = args; xs.$ === CID(Con); xs = xs.tail) {
    argv.push(xs.head);
  }
  if (maxOutput === 0 || timeoutMs === 0
    || argv.some((arg) => arg.includes("\0"))) {
    return io_fail(22);
  }

  let sys;
  let child = -1;
  const pipes = [];
  let actions;
  let attr;
  let actionsReady = false;
  let attrReady = false;
  let status = new Int32Array(1);
  let code = 0;
  let out = [];
  let err = [];
  let outLen = 0;
  let errLen = 0;

  try {
    sys = process_run_sys();
    for (let i = 0; i < 3; i += 1) {
      const fds = new Int32Array(2);
      if (sys.pipe(sys.ptr(fds)) !== 0) {
        code = sys.errno();
        break;
      }
      pipes.push(fds);
      for (let j = 0; j < 2; j += 1) {
        if (fds[j] < 3) {
          const moved = sys.fcntl(fds[j], 0, 3);
          if (moved < 0) {
            code = sys.errno();
            break;
          }
          sys.close(fds[j]);
          fds[j] = moved;
        }
        if (sys.fcntl(fds[j], 2, 1) < 0) {
          code = sys.errno();
          break;
        }
      }
      if (code !== 0) break;
    }

    if (code === 0) {
      for (const fd of [pipes[0][1], pipes[1][0], pipes[2][0]]) {
        const flags = sys.fcntl(fd, 3, 0);
        if (flags < 0 || sys.fcntl(fd, 4, flags | sys.nonblock) < 0) {
          code = sys.errno();
          break;
        }
      }
    }

    if (code === 0) {
      actions = new Uint8Array(1024);
      attr = new Uint8Array(1024);
      code = sys.fileActionsInit(sys.ptr(actions));
      actionsReady = code === 0;
      if (code === 0) {
        code = sys.attrInit(sys.ptr(attr));
        attrReady = code === 0;
      }
      for (let i = 0; i < 3 && code === 0; i += 1) {
        code = sys.addDup2(sys.ptr(actions), pipes[i][i === 0 ? 0 : 1], i);
      }
      for (const [r, w] of pipes) {
        if (code !== 0) break;
        code = sys.addClose(sys.ptr(actions), r);
        if (code === 0) code = sys.addClose(sys.ptr(actions), w);
      }
      const sigset = new Uint8Array(128);
      if (code === 0) code = sys.sigEmptySet(sys.ptr(sigset));
      if (code === 0) code = sys.sigAddSet(sys.ptr(sigset), 13);
      if (code === 0) {
        code = sys.attrSetSigDefault(sys.ptr(attr), sys.ptr(sigset));
      }
      if (code === 0) {
        code = sys.attrSetFlags(sys.ptr(attr), sys.mac ? 0x4004 : 4);
      }
      if (code === 0 && !sys.mac) {
        code = sys.addCloseFrom(sys.ptr(actions), 3);
      }
      if (code === 0) {
        const strings = [];
        const pointers = [];
        for (const arg of argv) {
          const bytes = Buffer.from(arg + "\0");
          strings.push(bytes);
          pointers.push(BigInt(sys.ptr(bytes)));
        }
        pointers.push(0n);
        const argvBuf = new BigUint64Array(pointers);
        const envStrings = [];
        const envPointers = [];
        for (const [key, value] of Object.entries(process.env)) {
          const bytes = Buffer.from(key + "=" + value + "\0");
          envStrings.push(bytes);
          envPointers.push(BigInt(sys.ptr(bytes)));
        }
        envPointers.push(0n);
        const envBuf = new BigUint64Array(envPointers);
        const pid = new Int32Array(1);
        code = sys.spawnp(sys.ptr(pid), sys.ptr(strings[0]), sys.ptr(actions),
          sys.ptr(attr), sys.ptr(argvBuf), sys.ptr(envBuf));
        if (code === 0) child = pid[0];
      }
    }

    if (actionsReady) {
      sys.fileActionsDestroy(sys.ptr(actions));
      actionsReady = false;
    }
    if (attrReady) {
      sys.attrDestroy(sys.ptr(attr));
      attrReady = false;
    }
    if (code !== 0) return io_fail(code);

    sys.close(pipes[0][0]); pipes[0][0] = -1;
    sys.close(pipes[1][1]); pipes[1][1] = -1;
    sys.close(pipes[2][1]); pipes[2][1] = -1;
    let written = 0;
    const inputBytes = Buffer.from(input);
    if (inputBytes.length === 0) {
      sys.close(pipes[0][1]); pipes[0][1] = -1;
    }

    const deadline = performance.now() + timeoutMs;
    const pollfds = new Uint8Array(24);
    const view = new DataView(pollfds.buffer);
    const available = new Int32Array(1);
    while (code === 0) {
      const got = sys.waitpid(child, sys.ptr(status), 1);
      if (got === child) {
        child = -1;
        for (let i = 1; i < 3 && code === 0; i += 1) {
          if (pipes[i][0] < 0) continue;
          const fd = pipes[i][0];
          if (sys.ioctl(fd, sys.fionread, sys.ptr(available)) !== 0) {
            code = sys.errno();
            break;
          }
          let left = available[0];
          while (left > 0 && code === 0) {
            const size = Math.min(left, 8192);
            const buffer = new Uint8Array(size);
            const n = Number(sys.read(fd, sys.ptr(buffer), size));
            if (n <= 0) {
              code = n < 0 ? sys.errno() : 0;
              break;
            }
            if (outLen + errLen + n > maxOutput) {
              code = 27;
              break;
            }
            if (i === 1) {
              out.push(buffer.subarray(0, n));
              outLen += n;
            } else {
              err.push(buffer.subarray(0, n));
              errLen += n;
            }
            left -= n;
          }
        }
        break;
      }
      if (got < 0 && sys.errno() !== 4) {
        code = sys.errno();
        break;
      }
      const now = performance.now();
      if (now >= deadline) {
        code = sys.mac ? 60 : 110;
        break;
      }
      view.setInt32(0, pipes[0][1], true);
      view.setInt16(4, 4, true);
      view.setInt32(8, pipes[1][0], true);
      view.setInt16(12, 1, true);
      view.setInt32(16, pipes[2][0], true);
      view.setInt16(20, 1, true);
      const left = Math.min(50, deadline - now);
      const ready = sys.poll(sys.ptr(pollfds), 3, left);
      if (ready < 0) {
        if (sys.errno() !== 4) code = sys.errno();
        continue;
      }
      if (ready === 0) continue;
      for (let i = 0; i < 3 && code === 0; i += 1) {
        const fd = pipes[i][i === 0 ? 1 : 0];
        const events = view.getInt16(i * 8 + 6, true);
        if (fd < 0 || events === 0) continue;
        if (i === 0) {
          const remain = inputBytes.length - written;
          const size = Math.min(remain, 8192);
          const n = Number(sys.write(fd, sys.ptr(inputBytes, written), size));
          if (n > 0) written += n;
          else if (n < 0 && sys.errno() !== 11 && sys.errno() !== 35
            && sys.errno() !== 4 && sys.errno() !== 32) {
            code = sys.errno();
          }
          if (written === inputBytes.length
            || (n < 0 && sys.errno() === 32)) {
            sys.close(fd);
            pipes[0][1] = -1;
          }
        } else {
          const buffer = new Uint8Array(8192);
          const n = Number(sys.read(fd, sys.ptr(buffer), buffer.length));
          if (n > 0) {
            if (outLen + errLen + n > maxOutput) {
              code = 27;
            } else if (i === 1) {
              out.push(buffer.subarray(0, n));
              outLen += n;
            } else {
              err.push(buffer.subarray(0, n));
              errLen += n;
            }
          } else if (n === 0) {
            sys.close(fd);
            pipes[i][0] = -1;
          } else if (n < 0 && sys.errno() !== 11 && sys.errno() !== 35
            && sys.errno() !== 4) {
            code = sys.errno();
          }
        }
      }
    }

    if (child >= 0) {
      if (code !== 0) sys.kill(child, 9);
      while (sys.waitpid(child, sys.ptr(status), 0) < 0 && sys.errno() === 4) {
      }
      child = -1;
    }
    if (code !== 0) return io_fail(code);
    const childStatus = status[0];
    const exitCode = (childStatus & 0x7f) === 0
      ? (childStatus >> 8) & 0xff
      : 128 + (childStatus & 0x7f);
    return io_done(io_tup(exitCode,
      Buffer.concat(out, outLen).toString("utf8"),
      Buffer.concat(err, errLen).toString("utf8")));
  } catch (e) {
    if (child >= 0 && sys) {
      sys.kill(child, 9);
      while (sys.waitpid(child, sys.ptr(status), 0) < 0 && sys.errno() === 4) {
      }
    }
    return io_fail(typeof e.errno === "number" ? Math.abs(e.errno) : 5);
  } finally {
    if (actionsReady) sys.fileActionsDestroy(sys.ptr(actions));
    if (attrReady) sys.attrDestroy(sys.ptr(attr));
    if (sys) {
      for (const [r, w] of pipes) {
        if (r >= 0) sys.close(r);
        if (w >= 0) sys.close(w);
      }
    }
  }
}

function process_run_sys() {
  if (globalThis.BEND_PROCESS_SYS === undefined) {
    const ffi = require("bun:ffi");
    const mac = process.platform === "darwin";
    const stackVarargs = mac && process.arch === "arm64";
    // Darwin arm64 passes variadic arguments on the stack, after x0..x7.
    const lib = ffi.dlopen(mac ? "libSystem.dylib" : "libc.so.6", {
      pipe: { args: ["ptr"], returns: "i32" },
      fcntl: { args: stackVarargs ? Array(9).fill("i32")
        : ["i32", "i32", "i32"], returns: "i32" },
      close: { args: ["i32"], returns: "i32" },
      read: { args: ["i32", "ptr", "u64"], returns: "i64" },
      write: { args: ["i32", "ptr", "u64"], returns: "i64" },
      poll: { args: ["ptr", "u64", "i32"], returns: "i32" },
      ioctl: { args: stackVarargs
        ? ["i32", "u64", ...Array(6).fill("i32"), "ptr"]
        : ["i32", "u64", "ptr"], returns: "i32" },
      waitpid: { args: ["i32", "ptr", "i32"], returns: "i32" },
      kill: { args: ["i32", "i32"], returns: "i32" },
      [mac ? "__error" : "__errno_location"]:
        { args: [], returns: "ptr" },
      sigemptyset: { args: ["ptr"], returns: "i32" },
      sigaddset: { args: ["ptr", "i32"], returns: "i32" },
      posix_spawn_file_actions_init: { args: ["ptr"], returns: "i32" },
      posix_spawn_file_actions_adddup2:
        { args: ["ptr", "i32", "i32"], returns: "i32" },
      posix_spawn_file_actions_addclose:
        { args: ["ptr", "i32"], returns: "i32" },
      posix_spawn_file_actions_destroy:
        { args: ["ptr"], returns: "i32" },
      posix_spawnattr_init: { args: ["ptr"], returns: "i32" },
      posix_spawnattr_setsigdefault:
        { args: ["ptr", "ptr"], returns: "i32" },
      posix_spawnattr_setflags: { args: ["ptr", "i32"], returns: "i32" },
      posix_spawnattr_destroy: { args: ["ptr"], returns: "i32" },
      posix_spawnp: { args: ["ptr", "ptr", "ptr", "ptr", "ptr", "ptr"],
        returns: "i32" },
      ...(mac ? {} : { posix_spawn_file_actions_addclosefrom_np:
        { args: ["ptr", "i32"], returns: "i32" } }),
    });
    const symbols = lib.symbols;
    globalThis.BEND_PROCESS_SYS = {
      ...symbols,
      fcntl: stackVarargs
        ? (fd, cmd, arg) => symbols.fcntl(fd, cmd, 0, 0, 0, 0, 0, 0, arg)
        : symbols.fcntl,
      ioctl: stackVarargs
        ? (fd, request, arg) => symbols.ioctl(fd, request, 0, 0, 0, 0, 0, 0, arg)
        : symbols.ioctl,
      ptr: ffi.ptr,
      errno: () => ffi.read.i32(symbols[mac ? "__error" : "__errno_location"](), 0),
      mac,
      nonblock: mac ? 4 : 0x800,
      fionread: mac ? 0x4004667f : 0x541b,
      fileActionsInit: symbols.posix_spawn_file_actions_init,
      fileActionsDestroy: symbols.posix_spawn_file_actions_destroy,
      addDup2: symbols.posix_spawn_file_actions_adddup2,
      addClose: symbols.posix_spawn_file_actions_addclose,
      addCloseFrom: symbols.posix_spawn_file_actions_addclosefrom_np,
      attrInit: symbols.posix_spawnattr_init,
      attrDestroy: symbols.posix_spawnattr_destroy,
      attrSetSigDefault: symbols.posix_spawnattr_setsigdefault,
      attrSetFlags: symbols.posix_spawnattr_setflags,
      sigEmptySet: symbols.sigemptyset,
      sigAddSet: symbols.sigaddset,
      spawnp: symbols.posix_spawnp,
    };
  }
  return globalThis.BEND_PROCESS_SYS;
}

io_eff(CID(Process.run), process_run);
