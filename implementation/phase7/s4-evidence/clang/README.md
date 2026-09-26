# Isolated Clang 19 for S4 native gates

Ready: Debian Clang 19.1.7 (package version `1:19.1.7-3~deb11u1`, amd64).

No system package installation or repository changes were performed. The four official Debian packages were downloaded and extracted only below `/tmp/bend-s4-clang19`. Download, extraction and smoke work used CPU 1 and nice 10. CPU 0 was left to the checked self-hosting proof.

Use this environment only for the desired child process:

```sh
env PATH="/tmp/bend-s4-clang19/root/usr/lib/llvm-19/bin:$PATH" \
  LD_LIBRARY_PATH=/tmp/bend-s4-clang19/root/usr/lib/x86_64-linux-gnu \
  CC=/tmp/bend-s4-clang19/root/usr/lib/llvm-19/bin/clang \
  <native-gate-command>
```

The existing environment may instead append its LD_LIBRARY_PATH if required by unrelated tools. No shell startup file or global environment was changed.

`package-manifest.json` records all package versions, sizes, SHA256 values and official snapshot download URLs. The security archive's signed InRelease was verified using the installed Debian archive keyring (good Debian 11 and Debian 12 security archive signatures), its Packages.xz SHA256 was checked, and every downloaded `.deb` matched the indexed size and SHA256 as well as the snapshot SHA1. Actual .deb Package/Version/Architecture fields were also checked. Direct security archive HTTP and HTTPS package URLs returned 404; those failed attempts are retained. Official `snapshot.debian.org` supplied the same package bytes.

`verification.json` records argv, process-local environment, CPU affinity, nice level, return codes and artifact hashes. Clang reports version 19.1.7; ldd reports no missing library. Its Clang and LLVM shared libraries come from the isolated root; other libraries, C headers and linker come from the existing system. A tiny C11 program including stdint/stdio and exercising unsigned `_BitInt(128)` compiled with `-O2 -Wall -Wextra -Werror` and ran with exact output `clang-c-smoke:42`. No Bend compilation, benchmark, GPU operation or full native conformance gate was run by this setup task.

This is a minimal extracted C CLI toolchain, not an installed package dependency closure. Optional Objective-C, Clang C API, sanitizer and LLVM LTO packages were not downloaded. Native gate validation remains the parent task.

Reproduction: `download.py` verifies and downloads the four exact packages from the retained signed metadata; extracted files are under `root`; `verify.py` runs the recorded tiny smoke. Keep failed evidence and package hashes with any published validation report.

## Archived setup inputs

This directory preserves the original small evidence files, setup scripts and C source; no compiler binaries or Debian package payloads are committed. Original `/tmp` paths inside reports identify the executed files. `archive-manifest.json` hashes these archived evidence bytes. The compressed Packages index is retained to let the signed-index-to-package-hash chain be independently checked.

To reproduce in a fresh temporary directory using the exact archived metadata:

```sh
mkdir -p /tmp/bend-s4-clang19/{evidence,packages,root}
cp implementation/phase7/s4-evidence/clang/* /tmp/bend-s4-clang19/evidence/
cp implementation/phase7/s4-evidence/clang/{download.py,verify.py} /tmp/bend-s4-clang19/
taskset -c 1 nice -n 10 python3 /tmp/bend-s4-clang19/download.py
```

After successful verification, run `dpkg-deb -x PACKAGE /tmp/bend-s4-clang19/root` for each of the four manifest packages under CPU 1/nice 10, then `taskset -c 1 nice -n 10 python3 /tmp/bend-s4-clang19/verify.py`. These extraction commands perform no installation or package maintainer scripts. Existing system C headers, linker and runtime dependencies are listed in `system-runtime-packages.stdout`.

Failed direct URLs were `http(s)://security.debian.org/debian-security/` plus each `Filename` in `selected-packages-05.txt` (404); the initial sandbox attempt failed DNS. The directory-index probes at security/archive Debian also returned 404. An initial snapshot query omitted the epoch and returned 404; the retained successful snapshot API queries used `1%3A19.1.7-3~deb11u1`. Each package's successful `snapshot.debian.org/file/<SHA1>` URL, indexed SHA256 and size are in `package-manifest.json`. No automatic approval review rejected these operations.
