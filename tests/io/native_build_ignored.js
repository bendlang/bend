function native_build_ignored() {
  const fs = require("node:fs");
  const os = require("node:os");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-native-ignored-"));
  const bun = typeof Bun !== "undefined";
  const prefix = bun && Bun.main.startsWith("/$bunfs/")
    ? [] : [path.resolve("bend2/main.ts")];
  const options = { encoding: "utf8", timeout: 4000,
    env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9",
      BEND_NO_TELEMETRY: "1", CC: path.join(dir, "cc"),
      BEND_TEST_CC_LOG: path.join(dir, "cc.log") },
  };
  try {
    // The wrapper rejects unwanted dependencies, even with every SDK installed.
    fs.writeFileSync(options.env.CC, '#!/bin/sh\n'
      + 'printf "%s\\n" "$@" > "$BEND_TEST_CC_LOG"\nfor arg do\n'
      + '  case "$arg" in objective-c|-lX11|-ldl|-lasound) exit 99;; esac\n'
      + 'done\nexec clang "$@"\n', { mode: 0o755 });
    const input = path.join(dir, "main.bend");
    const output = path.join(dir, "program");
    fs.writeFileSync(input, 'import Base\ndef Probe.value() -> IO(U32):\n'
      + '  import "./probe.c"\ndef main() -> IO(Unit):\n'
      + '  do IO<Unit>:\n    n : U32 <- Probe.value()\n'
      + '    IO.print(U32.show(n))\n');
    const ignored = '/*\n'
      + '# import <Foundation/Foundation.h>\n# include <X11/Xlib.h>\n*/\n'
      + '// #include <alsa/asoundlib.h>\n'
      + 'static const char* example = "#include <X11/Xlib.h>";\n'
      + 'static const char* unicode = "\u2028#import <Foundation/Foundation.h>'
      + '\u2029#include <alsa/asoundlib.h>";\n'
      + '#define USE_OPTIONAL 0\n#if USE_OPTIONAL\n'
      + '#import <Foundation/Foundation.h>\n#include <alsa/asoundlib.h>\n#endif\n'
      + '#ifdef __OBJC__\n#error plain C must stay C\n#endif\n';
    // Clang accepts this extension while -E rejects it. The fallback must
    // retain the original canonical signals, including the space after import.
    const legacy = '#\u00a0define LEGACY 1\n/*\n'
      + ' # import <Foundation/Foundation.h>\n#import<Foundation/Foundation.h>\n'
      + '#import\t<Foundation/Foundation.h>\n # include <X11/Xlib.h>\n*/\n'
      + '#if 0\n # import <Foundation/Foundation.h>\n#endif\n'
      + '#ifdef __OBJC__\n#error plain C must stay C\n#endif\n';
    const body = 'Term probe_value_run(Env e, Term* f, IoWork* w) { return 42; }\n'
      + 'static void __attribute__((constructor)) probe_value_use(void) {\n'
      + '  io_eff(CID(Probe.value), probe_value_run);\n}\n';
    // This is also valid C; an import active only in Objective-C does not
    // justify changing the mode of a successful C build.
    const guarded = '#ifdef __OBJC__\n#import <Foundation/Foundation.h>\n#endif\n';
    for (const text of [ignored, legacy, guarded]) {
      fs.writeFileSync(path.join(dir, "probe.c"), text + body);
      const built = child.spawnSync(bun ? process.execPath : "bun",
        [...prefix, input, "-o", output], options);
      if (built.status !== 0) return 1;
      if (!fs.readFileSync(options.env.BEND_TEST_CC_LOG, "utf8")
        .split("\n").includes("-o")) return 3;
      const ran = child.spawnSync(output, [], options);
      if (ran.status !== 0 || ran.stdout.trim() !== "42") return 2;
    }
    return 0;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Native.ignored), native_build_ignored);
