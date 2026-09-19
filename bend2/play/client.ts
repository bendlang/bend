export {};

const get = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
declare const ace: any;
const editor = ace.edit("source");
editor.setTheme("ace/theme/chrome");
editor.session.setMode("ace/mode/bend");
editor.setOptions({ tabSize: 2, useSoftTabs: true, useWorker: false, showPrintMargin: false, fontSize: 12, behavioursEnabled: true, scrollPastEnd: 0.2 });
editor.commands.addCommand({ name: "bend-run", bindKey: { win: "Ctrl-Enter", mac: "Command-Enter" }, exec: () => run() });
const source = {
  get value(): string { return editor.getValue(); },
  set value(v: string) { editor.setValue(v); },
  setAttribute(name: string, val: string): void { editor.container.setAttribute(name, val); },
};
const output = get<HTMLTextAreaElement>("output");
const results = get<HTMLTextAreaElement>("results");
const stdinBox = get<HTMLTextAreaElement>("stdin");
const example = get<HTMLSelectElement>("example");
type Action = "interpret" | "compile-run" | "compile-js" | "compile-c";
const actions: Action[] = ["interpret", "compile-run", "compile-js", "compile-c"];
const cancel = get<HTMLButtonElement>("cancel");
const copy = get<HTMLButtonElement>("copy");
const download = get<HTMLButtonElement>("download");
const examples: Record<string, string> = {
  hello: `import Base

# A small program, ready to compile.
def greet(name: String) -> String:
  String.append("Hello, ", name)

def main() -> IO(Unit):
  IO.print(greet("Bend"))
`,
  numbers: `import Base

# A + parameter can be used more than once.
def square(+x: U32) -> U32:
  U32.mul(x, x)

def main() -> U32:
  square(12)
`,
  lists: `import Base

# Types say exactly what goes in and comes out.
def main() -> U32:
  List.foldl(~&2, ~U32, ~U32, ~U32.add, [1, 2, 3, 4, 5], 0)
`,
  error: `import Base

# This function promises a number.
# Change the string to 42 and compile again.
def main() -> U32:
  "not a number"
`,
  calc: `import Base

# A calculator: each IO.read_line takes one line from Stdin.
# Try 40 and 2, then Compile to JS and run.
def calc.usage() -> IO(U32):
  do IO<U32>:
    u : Unit <- IO.print("usage: enter two numbers, one per line")
    return 0

def calc.bad() -> IO(U32):
  do IO<U32>:
    u : Unit <- IO.print("not a number")
    return 0

def calc.done(n: U32, m: Maybe<&2, U32>) -> IO(U32):
  match m:
    case None{}:
      calc.bad()
    case Some{k}:
      do IO<U32>:
        u : Unit <- IO.print(U32.show(U32.add(n, k)))
        return 0

def calc.with_n(n: U32, y: String) -> IO(U32):
  calc.done(n, U32.read(y))

def calc.with_m(m: Maybe<&2, U32>, y: String) -> IO(U32):
  match m:
    case None{}:
      calc.bad()
    case Some{n}:
      calc.with_n(n, y)

def calc.with_xy(x: String, y: String) -> IO(U32):
  calc.with_m(U32.read(x), y)

def calc.with_x(x: String, b: Maybe<&1, String>) -> IO(U32):
  match b:
    case None{}:
      calc.usage()
    case Some{y}:
      calc.with_xy(x, y)

def calc.go(a: Maybe<&1, String>, b: Maybe<&1, String>) -> IO(U32):
  match a:
    case None{}:
      calc.usage()
    case Some{x}:
      calc.with_x(x, b)

def main() -> IO(U32):
  do IO<U32>:
    a : Maybe<&1, String> <- IO.read_line()
    b : Maybe<&1, String> <- IO.read_line()
    n : U32 <- calc.go(a, b)
    return n
`,
  lits: `import Base

# Literals carry their type; operators need spaces and an annotation context.
def main() -> U32:
  (6 * 7 : U32)
`,
  affine: `import Base

# Affine by default (use at most once); +x is reusable (Data only).
def square(+x: U32) -> U32:
  (x * x : U32)

def main() -> U32:
  square(12)
`,
  quant: `import Base

# -A is erased (checker only); n affine; +x reusable.
def replicate(-A: Data, n: Nat, +x: A) -> List<&2, A>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      x <> replicate(A, p, x)

def main() -> Nat:
  List.length(&2, U32, replicate(U32, 3n, 7))
`,
  closure: `import Base

# Closures are values but affine: callable at most once.
def adder(k: U32) -> U32 -> U32:
  x => (x + k : U32)

def main() -> U32:
  add2 = adder(2)
  add5 = adder(5)
  add5(add2(1))
`,
  shape: `import Base

# A custom datatype (is Data: copiable) with trailing-brace matching.
type Shape is Data:
  Circle{r: U32}
  Square{s: U32}

def area(x: Shape) -> U32:
  match x:
    case Circle{+r}:
      (3 * r * r : U32)
    case Square{+s}:
      (s * s : U32)

def main() -> U32:
  area(Square{5})
`,
  natrec: `import Base

# Recursion must shrink a matched part, and every variable stays
# single-use: n is spent by the match, so only p may continue.
def double(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      Nat.add(1n, Nat.add(1n, double(p)))

def main() -> Nat:
  double(21n)
`,
  dowork: `import Base

# Effects sequence in do blocks; every bind is annotated.
def main() -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print("first")
    v : Unit <- IO.print("second")
    return Unit{}
`,
  maybe: `import Base

# do works for any monad with bind/pure; None short-circuits.
def add_strs(a: String, b: String) -> Maybe<&2, U32>:
  do Maybe<&2, U32>:
    x : U32 <- U32.read(a)
    y : U32 <- U32.read(b)
    return (x + y : U32)

def main() -> Maybe<&2, U32>:
  add_strs("40", "2")
`,
  pcall: `import Base

# Parallel calls: a b = f(x) g(y) runs both, joins, and binds.
def dbl(+x: U32) -> U32:
  (x + x : U32)

def main() -> U32:
  x y = dbl(20) dbl(22)
  (x + y : U32)
`,
  gpu: `import Base

# A ! suffix sends the call (and its inner parallel calls) to the GPU.
# Without a GPU it still runs in parallel on the CPU; JS runs it plainly.
def dbl(+x: U32) -> U32:
  (x + x : U32)

def main() -> U32:
  dbl!(21)
`,
  forkjoin: `import Base

# IO.fork runs a computation concurrently; IO.join waits for its value.
def slow(x: U32) -> IO(U32):
  do IO<U32>:
    u : Unit <- IO.sleep(20)
    return x

def main() -> IO(Unit):
  do IO<Unit>:
    a : Chan(U32) <- IO.fork(U32, slow(20))
    b : Chan(U32) <- IO.fork(U32, slow(22))
    x : U32 <- IO.join(U32, a)
    y : U32 <- IO.join(U32, b)
    u : Unit <- IO.print(U32.show((x + y : U32)))
    return Unit{}
`,
  chan: `import Base

# Fibers talk over channels; +ch shares the handle across steps.
def consume(m: Maybe<&1, U32>) -> IO(U32):
  match m:
    case None{}:
      do IO<U32>:
        u : Unit <- IO.print("empty")
        return 0
    case Some{v}:
      do IO<U32>:
        u : Unit <- IO.print(U32.show((v + 2 : U32)))
        return 0

def main.go(c: Chan(U32)) -> IO(U32):
  +ch = c
  do IO<U32>:
    Bool <- Chan.send(U32, ch, 40)
    m : Maybe<&1, U32> <- Chan.recv(U32, ch)
    n : U32 <- consume(m)
    return n

def main() -> IO(U32):
  IO.bind(Chan(U32), U32, Chan.new(U32, 8), main.go)
`,
  pred: `import Base

# A predicate as a type: a def returning Type, computed by matching.
def IsZero(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Empty

def main() -> IsZero(0n):
  Unit{}
`,
  law: `import Base

# A law states a fact; the paired def proves it. Matching refines the
# goal, the recursive call is the induction hypothesis, % rewrites.
law add_zero:
  for x: Nat
  {Nat.add(x, 0n) == x : Nat}

def add_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def main() -> {Nat.add(2n, 0n) == 2n : Nat}:
  add_zero(2n)
`,
  witness: `import Base

# exs asks for a witness, returned beside its evidence as nested pairs.
law pick:
  exs y: Nat
  exs e: {y == 2n : Nat}
  {Nat.add(y, 1n) == 3n : Nat}

def pick():
  (2n, {==}, {==})

law main:
  Sigma<&1, &1, Nat, y => Sigma<&1, &1, {y == 2n : Nat}, e => {Nat.add(y, 1n) == 3n : Nat}>>

def main(): pick()
`,
  rewrite: `import Base

# %x@e is the explicit-motive rewrite: x binds the equation, _ its end.
law cong_succ:
  for a: Nat
  for b: Nat
  for e: {a == b : Nat}
  {Nat.add(a, 1n) == Nat.add(b, 1n) : Nat}

def cong_succ(a, b, e):
  %e : {Nat.add(a, 1n) == Nat.add(_, 1n) : Nat}
  {==}

def main() -> {Nat.add(2n, 1n) == Nat.add(2n, 1n) : Nat}:
  cong_succ(2n, 2n, {==})
`,
  form: `import Base

# First-order syntax, internalized: formulas are Data, Eval is Tarski's
# valuation, and the reflection law holds by computation ({==}).
type Form is Data:
  FTrue{}
  FFalse{}
  FAnd{l: Form, r: Form}
  FOr{l: Form, r: Form}
  FNot{f: Form}

def Eval(f: Form) -> Bool:
  match f:
    case FTrue{}:
      True{}
    case FFalse{}:
      False{}
    case FAnd{l, r}:
      Bool.and(Eval(l), Eval(r))
    case FOr{l, r}:
      Bool.or(Eval(l), Eval(r))
    case FNot{x}:
      Bool.not(Eval(x))

law eval_and:
  for l: Form
  for r: Form
  {Eval(FAnd{l, r}) == Bool.and(Eval(l), Eval(r)) : Bool}

def eval_and(l, r):
  {==}

def main() -> U32:
  Bool.to_u32(Eval(FAnd{FTrue{}, FOr{FFalse{}, FNot{FFalse{}}}}))
`,
  modal: `import Base

# A modal-boundary analogue: Boxed seals a fragment behind a pure API.
# Only IO.bind can sequence effects, so values inside Boxed never touch
# them; unbox(box(x)) == x holds by computation.
type Boxed<a, -A: Kind(a)> is Kind(a):
  Box{v: A}

def box(a, -A: Kind(a), x: A) -> Boxed<a, A>:
  Box{x}

def unbox(a, -A: Kind(a), b: Boxed<a, A>) -> A:
  match b:
    case Box{v}:
      v

law box_roundtrip:
  for +x: U32
  {unbox(&2, U32, box(&2, U32, x)) == x : U32}

def box_roundtrip(x):
  {==}

def main() -> U32:
  unbox(&2, U32, box(&2, U32, 42))
`,
  split: `import Base

# Affine state split across a fork-join: each half is owned by one call.
def sum(xs: List<U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{h, t}:
      (h + sum(t) : U32)

def halves(l: List<U32>, r: List<U32>) -> U32 & U32:
  a b = sum(l) sum(r)
  (a, b)

def main() -> U32 & U32:
  halves([1, 2], [3, 4])
`,
  dual: `import Base

# The tangent-bundle functor on scalars, as dual numbers: D{re, du} keeps
# a value beside its derivative, and each op applies the chain rule, so
# evaluating a polynomial yields its value and slope together. F32 ops are
# host primitives, so main runs on a backend lane (here, the JS one).
type Dual is Data:
  D{re: F32, du: F32}

def Dual.add(+a: Dual, +b: Dual) -> Dual:
  match a b:
    case D{x, dx} D{y, dy}:
      D{F32.add(x, y), F32.add(dx, dy)}

def Dual.mul(+a: Dual, +b: Dual) -> Dual:
  match a b:
    case D{x, dx} D{y, dy}:
      D{F32.mul(x, y), F32.add(F32.mul(x, dy), F32.mul(dx, y))}

def show_dual(d: Dual) -> IO(Unit):
  match d:
    case D{v, s}:
      IO.print(U32.show(F32.to_u32(v)) ++ " " ++ U32.show(F32.to_u32(s)))

def main() -> IO(Unit):
  # f(t) = t^2 + 3t at t = 2: value 10, slope 7.
  +x = {D{2.0, 1.0} : Dual}
  show_dual(Dual.add(Dual.mul(x, x), Dual.mul({D{3.0, 0.0} : Dual}, x)))
`,
};
const exampleStdin: Record<string, string> = {
  calc: "40\n2\n",
};
// Demo dir -> label plus extra files the demo's main imports. Sources ship
// as static files; the picker fetches them into the editor and the aux map,
// and run() posts the whole set to the worker's memory filesystem.
const demos: Record<string, { label: string; aux: Record<string, string>; sim?: { extract: string | null; makeEdits: (w: number, h: number) => string[][] } }> = {
  "demo:pure_par_sum": { label: "Parallel sum", aux: {} },
  "demo:pure_par_sort": { label: "Parallel sort", aux: {} },
  "demo:pure_hvm5_mini": { label: "HVM mini", aux: {} },
  "demo:proof_insertion_sort": { label: "Insertion sort", aux: {} },
  "demo:proof_numerics": { label: "Numerics", aux: {} },
  "demo:proof_typed_eval": { label: "Typed eval", aux: {} },
  "demo:io_hello_world": { label: "Hello IO", aux: {} },
  "demo:app_triangle_2d": { label: "Triangle", aux: {} },
  "demo:app_pong_game_2d": { label: "Pong", aux: {} },
  "demo:app_win_is_bug_2d": { label: "WinIsBug", aux: {} },
  "demo:app_ray_tracer_3d": { label: "Ray tracer", aux: {},
    sim: {
      extract: "\"Fly\", (\\d+), (\\d+),",
      makeEdits: (w: number, h: number) => {
        let depth = 0;
        let cover = 1;
        while (cover < Math.max(w, h) && depth < 12) { cover *= 2; depth++; }
        const hud = Math.max(w, h) < 512 ? "0" : null;
        const edits = [
          ["Fly\\.scene!\\(\\d+n,", `Fly.scene!(${depth}n,`],
          ["\"Fly\", \\d+, \\d+,", `"Fly", ${w}, ${h},`],
        ];
        if (hud !== null) edits.push(["\\(\\(x < 96\\) && \\(y < 40\\) : U32\\)", "False{}"]);
        return edits;
      },
    } },
  "demo:app_slash_boss_3d": { label: "Slash boss", aux: { "bend3d.bend": "demos/app_slash_boss_3d/bend3d.bend" } },
  "demo:io_http_fetch": { label: "HTTP fetch · needs native", aux: {} },
  "demo:io_http_server": { label: "HTTP server · needs native", aux: {} },
  "demo:io_tcp_echos": { label: "TCP echo · needs native", aux: {} },
};
let auxFiles: Record<string, string> = {};
function renderSim(): void {
  get("sim-wrap").hidden = !(example.value in demos && demos[example.value].sim);
}
function simWH(): { w: number; h: number } {
  const num = (id: string): number => {
    const v = parseInt(get<HTMLInputElement>(id).value, 10);
    return v > 0 ? Math.min(2048, v) : 0;
  };
  return { w: num("simw"), h: num("simh") };
}
function renderAux(): void {  const bar = get("auxbar");
  bar.hidden = Object.keys(auxFiles).length === 0;
  bar.replaceChildren(...Object.keys(auxFiles).map(name => {
    const chip = document.createElement("span");
    chip.className = "aux-chip";
    chip.textContent = name + " ";
    const drop = document.createElement("button");
    drop.className = "text-button";
    drop.textContent = "×";
    drop.title = "Drop " + name;
    drop.addEventListener("click", () => { delete auxFiles[name]; renderAux(); });
    chip.appendChild(drop);
    return chip;
  }));
}
const storageKey = "bend.playground.v1";
let DEBUG = new URLSearchParams(location.search).get("debug") === "true";
function syncURL(): void {
  const params = new URLSearchParams(location.search);
  if (DEBUG) params.set("debug", "true");
  else params.delete("debug");
  if (example.value in demos) params.set("demo", example.value.slice("demo:".length));
  else params.delete("demo");
  if (example.value in demos && demos[example.value].sim) {
    const sw = simWH().w;
    const sh = simWH().h;
    if (sw > 0) params.set("sw", String(sw));
    else params.delete("sw");
    if (sh > 0) params.set("sh", String(sh));
    else params.delete("sh");
  } else { params.delete("sw"); params.delete("sh"); }
  const dw = dispNum("dispw");
  const dh = dispNum("disph");
  if (dw > 0) params.set("w", String(dw));
  else params.delete("w");
  if (dh > 0) params.set("h", String(dh));
  else params.delete("h");
  history.replaceState(null, "", location.pathname + (params.toString() ? "?" + params : ""));
}
function dlog(msg: string): void {
  if (!DEBUG) return;
  const log = get("debuglog");
  log.textContent += (log.textContent ? "\n" : "") + msg;
  const lines = log.textContent.split("\n");
  if (lines.length > 200) log.textContent = lines.slice(-200).join("\n");
}
let worker: Worker;
let runner: Worker | undefined;
let ready = false;
let busy = false;
let phase = "Compiling…";
let tab: "results" | "compiled" | "display" = "results";
let generation = 0;
let request = 0;
let timer: ReturnType<typeof setTimeout>;
let compiledSource = "";
let compiledTarget = "";
let activeSource = "";
let activeTarget = "";
let activeAction: Action = "compile-run";

function status(text: string, state = ""): void {
  get("status-text").textContent = text;
  get("status").className = state;
}
function visibleOutput(): HTMLTextAreaElement { return tab === "compiled" ? output : results; }
function controls(): void {
  for (const action of actions) get<HTMLButtonElement>(action).disabled = !ready || busy;
  cancel.hidden = !busy;
  source.setAttribute("aria-busy", String(busy));
  copy.disabled = download.disabled = tab === "display" || !visibleOutput().value;
}
const tabs = ["results", "compiled", "display"] as const;
function selectTab(next: typeof tab, focus = false): void {
  tab = next;
  if (next === "display") editor.blur();
  for (const name of tabs) {
    const button = get("tab-" + name);
    button.setAttribute("aria-selected", String(tab === name));
    button.tabIndex = tab === name ? 0 : -1;
    get("panel-" + name).hidden = tab !== name;
  }
  if (focus) get("tab-" + tab).focus();
  controls();
}
for (const name of tabs) {
  get("tab-" + name).addEventListener("click", () => selectTab(name));
  get("tab-" + name).addEventListener("keydown", event => {
    if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
      event.preventDefault();
      const at = tabs.indexOf(tab);
      selectTab(event.key === "Home" ? "results" : event.key === "End" ? "display"
        : tabs[(at + (event.key === "ArrowRight" ? 1 : tabs.length - 1)) % tabs.length], true);
    }
  });
}
function persist(): void {
  try { localStorage.setItem(storageKey, JSON.stringify({ source: source.value, example: example.value, stdin: stdinBox.value, mode: stdinMode(), dispw: get<HTMLInputElement>("dispw").value, disph: get<HTMLInputElement>("disph").value, simw: get<HTMLInputElement>("simw").value, simh: get<HTMLInputElement>("simh").value })); } catch {}
}
function stdinMode(): string {
  return document.querySelector<HTMLInputElement>('input[name="stdin-mode"]:checked')?.value ?? "prefill";
}
// Display size: the W/H inputs are the source of truth (empty = follow
// the program). Presets only fill them in. Changing either restarts the
// running demo from the same build.
let nativeSize = { w: 0, h: 0 };
function dispNum(id: string): number {
  const v = parseInt(get<HTMLInputElement>(id).value, 10);
  return v > 0 ? Math.min(4096, v) : 0;
}
function dispEff(): { w: number; h: number } {
  return {
    w: dispNum("dispw") || nativeSize.w,
    h: dispNum("disph") || nativeSize.h,
  };
}
function resCaption(): void {
  const el = get("dispinfo");
  const { w, h } = dispEff();
  el.textContent = w > 0 ? `${w}×${h} · native ${nativeSize.w}×${nativeSize.h}` : "No display";
  for (const b of document.querySelectorAll<HTMLButtonElement>("#displaybar [data-res]")) {
    b.classList.toggle("on", b.dataset.res === dispPreset());
  }
}
function dispPreset(): string {
  const { w, h } = dispEff();
  if (w === nativeSize.w && h === nativeSize.h) return "full";
  if (w * 2 === nativeSize.w && h * 2 === nativeSize.h) return "fast";
  if (w * 4 === nativeSize.w && h * 4 === nativeSize.h) return "preview";
  return "";
}
function sendDisplay(): void {
  if (!busy || !runner) return;
  const { w, h } = dispEff();
  runner.postMessage({ display: { w, h } });
}
function applyDisplay(): void {
  resCaption();
  persist();
  syncURL();
  sendDisplay();
}
function position(): void {
  const cursor = editor.getCursorPosition();
  get("cursor").textContent = `Ln ${cursor.row + 1}, Col ${cursor.column + 1}`;
}
function stale(): boolean { return source.value !== compiledSource; }
function elapsed(ms: number): string { return ms < 1000 ? Math.round(ms) + " ms" : (ms / 1000).toFixed(2) + " s"; }
function edit(): void {
  position();
  persist();
  if (!busy && ready) status("Ready");
  if ((output.value || results.value) && stale()) get("output-state").textContent = "Source changed · run or compile to update";
}
function finish(message: string, failed = false): void {
  clearTimeout(timer);
  runner?.terminate();
  runner = undefined;
  get("inputbar").hidden = true;
  cancel.textContent = "Cancel";
  busy = false;
  results.className = failed ? "error" : "";
  get("output-state").textContent = stale() ? "Source changed · run or compile to update" : message;
  status(stale() ? "Source changed · run or compile again for the latest version" : message, failed ? "error" : "success");
  if (failed) selectTab("results");
  controls();
}
function stop(message: string): void {
  results.value += (results.value && !results.value.endsWith("\n") ? "\n" : "") + message + "\n";
  get("output-state").textContent = message;
  selectTab("results");
  restart(message);
}
function execute(javascript: string, compileTime: number): void {
  phase = "Running…";
  results.placeholder = "Running JavaScript…";
  controls();
  status("Compiled in " + elapsed(compileTime) + " · running JavaScript…", "busy");
  get("output-state").textContent = "Running JavaScript…";
  const current = request;
  runner = new Worker("/runner.js", { type: "module" });
  runner.onmessage = ({ data }) => {
    if (current !== request || !busy) return;
    if (data.type === "output") {
      results.value += data.text;
      results.scrollTop = results.scrollHeight;
      controls();
    } else if (data.type === "input-request") {
      const bar = get("inputbar");
      const line = get<HTMLInputElement>("inputline");
      if (bar.hidden) {
        bar.hidden = false;
        get("output-state").textContent = "Waiting for input…";
        status("Waiting for input…", "busy");
      }
      dlog("[runner] input-request");
      line.focus();
    } else if (data.type === "dbg") {
      dlog(`[${data.from ?? "worker"}] ${data.msg}`);
    } else if (data.type === "win-open") {
      clearTimeout(timer);
      cancel.textContent = "Stop";
      nativeSize = { w: data.w, h: data.h };
      // Initialize the inputs with the default resolution on first open.
      if (!get<HTMLInputElement>("dispw").value) {
        get<HTMLInputElement>("dispw").value = String(data.w);
      }
      if (!get<HTMLInputElement>("disph").value) {
        get<HTMLInputElement>("disph").value = String(data.h);
      }
      resCaption();
      const screen = get<HTMLCanvasElement>("screen");
      screen.width = data.w;
      screen.height = data.h;
      screen.title = data.title;
      selectTab("display");
      get("output-state").textContent = `Display ${data.w}×${data.h} · playing — press Stop to quit`;
      status("Running — press Stop to quit", "busy");
      screen.focus();
    } else if (data.type === "win-frame") {
      const screen = get<HTMLCanvasElement>("screen");
      if (screen.width !== data.w || screen.height !== data.h) {
        screen.width = data.w;
        screen.height = data.h;
      }
      const ctx = screen.getContext("2d", { desynchronized: true })!;
      ctx.putImageData(new ImageData(new Uint8ClampedArray(data.pix), data.w, data.h), 0, 0);
    } else if (data.type === "win-title") {
      get<HTMLCanvasElement>("screen").title = data.title;
    } else if (data.type === "win-close") {
      get("output-state").textContent = "Display closed";
    } else if (data.type === "done") {
      if (!results.value) results.value = "Program finished without output.\n";
      finish(`Exit ${data.code} · ran in ${elapsed(data.elapsed)} · compiled in ${elapsed(compileTime)}`, data.code !== 0);
    }
  };
  runner.onerror = event => {
    event.preventDefault();
    results.value += (event.message || "The execution worker stopped.") + "\n";
    finish("Execution failed", true);
  };
  runner.postMessage({ javascript, stdin: stdinMode() === "ask" ? "" : stdinBox.value, debug: DEBUG });
  sendDisplay();
  timer = setTimeout(() => stop("Execution stopped after 30 seconds."), 30_000);
}
function restart(message?: string, runWhenReady?: Action): void {
  worker?.terminate();
  runner?.terminate();
  runner = undefined;
  get("inputbar").hidden = true;
  clearTimeout(timer);
  generation += 1;
  request += 1;
  ready = busy = false;
  controls();
  status(message ?? "Loading the compiler…");
  const current = generation;
  worker = new Worker("/worker.js", { type: "module" });
  worker.onmessage = ({ data }) => {
    if (current !== generation) return;
    if (data.type === "ready") {
      ready = true;
      controls();
      status(message ?? "Ready");
      dlog("[compiler] ready");
      if (runWhenReady) run(runWhenReady);
      return;
    }
    if (data.type === "dbg") {
      dlog(`[${data.from ?? "worker"}] ${data.msg}`);
      return;
    }
    if (data.type !== "result" || data.id !== request || !busy) return;
    clearTimeout(timer);
    compiledSource = activeSource;
    compiledTarget = activeTarget;
    if (!data.ok) {
      results.value = data.output;
      finish(activeAction === "interpret" ? "Couldn’t interpret this program" : "Couldn’t compile this program", true);
      return;
    }
    if (activeAction === "interpret") {
      results.value = data.output;
      finish("Interpreted in " + elapsed(data.elapsed));
      return;
    }
    output.value = data.output;
    output.scrollTop = output.scrollLeft = 0;
    get("output-size").textContent = compiledTarget.toUpperCase() + " · " + (data.bytes / 1024).toFixed(1) + " KB";
    if (activeAction === "compile-run") {
      execute(data.output, data.elapsed);
    } else {
      results.value = "Compiled to " + (compiledTarget === "c" ? "C" : "JavaScript") + " successfully. The program was not executed.\n";
      selectTab("compiled");
      finish("Compiled in " + elapsed(data.elapsed));
    }
  };
  worker.onerror = event => {
    event.preventDefault();
    worker.terminate();
    ready = true;
    worker.onmessage = null;
    results.value = (event.message || "The compiler stopped.") + "\nChoose an action to retry.";
    finish("Compiler stopped", true);
  };
}
function run(action: Action = "compile-run"): void {
  if (busy || !ready) return;
  if (!worker.onmessage) { restart(undefined, action); return; }
  activeSource = source.value;
  activeAction = action;
  activeTarget = action === "compile-c" ? "c" : action === "interpret" ? "" : "js";
  request += 1;
  busy = true;
  phase = action === "interpret" ? "Interpreting…" : "Compiling…";
  output.value = results.value = "";
  results.className = "";
  results.placeholder = phase;
  get("output-size").textContent = "—";
  get("output-state").textContent = phase;
  selectTab("results");
  status(phase, "busy");
  const files: Record<string, string> = { "/main.bend": activeSource };
  for (const [name, content] of Object.entries(auxFiles)) files["/" + name] = content;
  worker.postMessage({ id: request, files, action, debug: DEBUG });
  timer = setTimeout(() => stop(action === "interpret" ? "Interpretation stopped after 30 seconds." : "Compilation is taking a while — large demos like Ray tracer can need ~45 s in the browser. Try again or split the file."), 60_000);
}

source.value = examples.hello;
try {
  const saved = JSON.parse(localStorage.getItem(storageKey) ?? "null");
  if (saved && typeof saved.source === "string") source.value = saved.source;
  if (saved?.example in examples || saved?.example in demos) example.value = saved.example;
  const demoParam = new URLSearchParams(location.search).get("demo");
  if (demoParam && "demo:" + demoParam in demos) example.value = "demo:" + demoParam;
  if (saved && typeof saved.stdin === "string") stdinBox.value = saved.stdin;
  const mode = saved && (saved.mode === "ask" || saved.mode === "prefill") ? saved.mode : null;
  if (mode) {
    const radio = document.querySelector<HTMLInputElement>(`input[name="stdin-mode"][value="${mode}"]`);
    if (radio) radio.checked = true;
  }
  if (stdinMode() === "ask") {
    stdinBox.placeholder = "Ask-me mode: the box is ignored, the worker waits and asks you per line.";
  }
  const params = new URLSearchParams(location.search);
  const num = (v: string | null): string => v && /^\d+$/.test(v) && Number(v) > 0 ? String(Math.min(4096, Number(v))) : "";
  const pw = num(params.get("w"));
  const ph = num(params.get("h"));
  if (pw || ph) {
    get<HTMLInputElement>("dispw").value = pw;
    get<HTMLInputElement>("disph").value = ph;
  } else {
    try {
      const saved2 = JSON.parse(localStorage.getItem(storageKey) ?? "null");
      if (saved2 && typeof saved2.dispw === "string") get<HTMLInputElement>("dispw").value = saved2.dispw;
      if (saved2 && typeof saved2.disph === "string") get<HTMLInputElement>("disph").value = saved2.disph;
    } catch {}
  }
  const sw = num(params.get("sw"));
  const sh = num(params.get("sh"));
  if (sw || sh) {
    get<HTMLInputElement>("simw").value = sw;
    get<HTMLInputElement>("simh").value = sh;
  } else {
    try {
      const saved3 = JSON.parse(localStorage.getItem(storageKey) ?? "null");
      if (saved3 && typeof saved3.simw === "string") get<HTMLInputElement>("simw").value = saved3.simw;
      if (saved3 && typeof saved3.simh === "string") get<HTMLInputElement>("simh").value = saved3.simh;
    } catch {}
  }
  resCaption();
} catch {}
editor.selection.moveCursorTo(0, 0);
const mac = /Mac|iPhone|iPad/.test(navigator.platform);
get("shortcut").textContent = mac ? "⌘ Enter" : "Ctrl Enter";
get("compile-run").title = (mac ? "⌘ Enter" : "Ctrl Enter") + " to compile to JavaScript and run";
editor.session.on("change", edit);
editor.selection.on("changeCursor", position);
stdinBox.addEventListener("input", persist);
for (const radio of document.querySelectorAll<HTMLInputElement>('input[name="stdin-mode"]')) {
  radio.addEventListener("change", () => {
    stdinBox.placeholder = stdinMode() === "ask"
      ? "Ask-me mode: the box is ignored, the worker waits and asks you per line."
      : "Prefilled lines for IO.read_line, one per line. When they run out the program asks you below.";
    persist();
  });
}
document.addEventListener("keydown", (event) => {
  if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
    event.preventDefault();
    run();
  }
});
function sendInput(): void {
  if (!busy || !runner) return;
  runner.postMessage({ text: get<HTMLInputElement>("inputline").value });
  get<HTMLInputElement>("inputline").value = "";
  get("output-state").textContent = "Running JavaScript…";
  status("Running JavaScript…", "busy");
  get<HTMLInputElement>("inputline").focus();
}
function sendEOF(): void {
  if (!busy || !runner) return;
  runner.postMessage({ eof: true });
  get("inputbar").hidden = true;
}
// DOM codes to the native key table: characters lowercased, arrows and
// function keys on 63232+, modifiers on 65590+, the rest on 65536+.
function winKey(e: KeyboardEvent): number {
  switch (e.code) {
    case "Escape": return 27;
    case "Enter": return 13;
    case "Tab": return 9;
    case "Backspace": return 127;
    case "ArrowUp": return 63232;
    case "ArrowDown": return 63233;
    case "ArrowLeft": return 63234;
    case "ArrowRight": return 63235;
    case "Insert": return 63271;
    case "Delete": return 63272;
    case "Home": return 63273;
    case "End": return 63275;
    case "PageUp": return 63276;
    case "PageDown": return 63277;
    case "ShiftLeft": return 65592;
    case "ShiftRight": return 65596;
    case "ControlLeft": return 65595;
    case "ControlRight": return 65597;
    case "AltLeft": return 65594;
    case "AltRight": return 65598;
    case "MetaLeft": return 65591;
    case "MetaRight": return 65590;
    case "CapsLock": return 65593;
  }
  if (e.key.startsWith("F") && /^F([1-9]|1[0-2])$/.test(e.key)) {
    return 63236 + Number(e.key.slice(1)) - 1;
  }
  if (e.key.length === 1 && e.key >= " ") return e.key.toLowerCase().codePointAt(0)!;
  return 65536 + e.keyCode;
}
function winSend(ev: object): void {
  if (!busy || !runner) return;
  runner.postMessage({ win: "event", ev });
}
function winPoint(e: MouseEvent): [number, number] {
  const screen = get<HTMLCanvasElement>("screen");
  const rect = screen.getBoundingClientRect();
  const clip = (v: number, most: number) => Math.min(Math.max(0, Math.floor(v)), most - 1);
  return [clip((e.clientX - rect.left) * screen.width / rect.width, screen.width),
    clip((e.clientY - rect.top) * screen.height / rect.height, screen.height)];
}
for (const action of actions) get(action).addEventListener("click", () => run(action));
for (const b of document.querySelectorAll<HTMLButtonElement>("#displaybar [data-res]")) {
  b.addEventListener("click", () => {
    const frac = b.dataset.res === "preview" ? 0.25 : b.dataset.res === "fast" ? 0.5 : 1;
    if (nativeSize.w > 0) {
      get<HTMLInputElement>("dispw").value = String(Math.max(1, Math.floor(nativeSize.w * frac)));
      get<HTMLInputElement>("disph").value = String(Math.max(1, Math.floor(nativeSize.h * frac)));
    }
    applyDisplay();
  });
}
for (const id of ["dispw", "disph"]) {
  get<HTMLInputElement>(id).addEventListener("input", () => { applyDisplay(); });
  get<HTMLInputElement>(id).addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      applyDisplay();
    }
  });
}
get("send").addEventListener("click", sendInput);
get("eof").addEventListener("click", sendEOF);
get<HTMLInputElement>("inputline").addEventListener("keydown", (event) => {
  if (event.key === "Enter") {
    event.preventDefault();
    sendInput();
  }
});
cancel.addEventListener("click", () => stop(phase === "Running…" ? "Execution cancelled." : phase === "Interpreting…" ? "Interpretation cancelled." : "Compilation cancelled."));
for (const kind of ["keydown", "keyup"] as const) {
  // Document level so play never depends on canvas focus; text entry
  // in any input or textarea still types instead of playing.
  document.addEventListener(kind, (event) => {
    if (!busy || !runner || tab !== "display") return;
    const t = document.activeElement;
    if (t instanceof HTMLInputElement) return;
    if (t instanceof HTMLTextAreaElement && !t.classList.contains("ace_text-input")) return;
    const e = event as KeyboardEvent;
    if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Tab", " "].includes(e.key)) {
      e.preventDefault();
    }
    const code = winKey(e);
    dlog(`[page] key ${e.code} -> ${code} (${e.type})`);
    winSend({ kind: 0, a: code, b: e.type === "keydown" ? 1 : 0, c: 0, d: 0 });
  });
}
get("screen").addEventListener("mousemove", (event) => {
  const [x, y] = winPoint(event as MouseEvent);
  winSend({ kind: 2, a: x, b: y, c: 0, d: 0 });
});
for (const kind of ["mousedown", "mouseup"] as const) {
  get("screen").addEventListener(kind, (event) => {
    const e = event as MouseEvent;
    const [x, y] = winPoint(e);
    const button = e.button === 0 ? 0 : e.button === 1 ? 2 : 1;
    winSend({ kind: 1, a: x, b: y, c: button, d: kind === "mousedown" ? 1 : 0 });
  });
}
async function reset(): Promise<void> {
  if (busy) restart();
  if (example.value in demos) {
    const dir = example.value.slice("demo:".length);
    const load = async (route: string): Promise<string> => {
      const res = await fetch(route);
      if (!res.ok) throw new Error(route);
      return res.text();
    };
    try {
      status("Loading the demo…", "busy");
      source.value = await load("demos/" + dir + "/main.bend");
      const aux: Record<string, string> = {};
      for (const [name, route] of Object.entries(demos[example.value].aux)) {
        aux[name] = await load(route);
      }
      renderSim();
      const cfg = demos[example.value].sim;
      if (cfg) {
        // Initialize the inputs from the source so the UI is the truth.
        if (cfg.extract) {
          const found = source.value.match(new RegExp(cfg.extract));
          if (found && !get<HTMLInputElement>("simw").value) {
            get<HTMLInputElement>("simw").value = found[1];
          }
          if (found && !get<HTMLInputElement>("simh").value) {
            get<HTMLInputElement>("simh").value = found[2];
          }
        }
        const { w: sw, h: sh } = simWH();
        if (sw > 0 && sh > 0) {
          const before = source.value;
          for (const [pattern, replacement] of cfg.makeEdits(sw, sh)) {
            source.value = source.value.replace(new RegExp(pattern), replacement);
          }
          if (source.value !== before) {
            source.value = `# sim ${sw}x${sh} (adapted from the repo demo)\n` + source.value;
          }
        }
      }
      auxFiles = aux;
      renderAux();
      status(ready ? "Ready" : "Loading the compiler…");
    } catch {
      results.value = "Could not load the demo. Serve the playground with its demos/ dir.";
      finish("Demo load failed", true);
      return;
    }
  } else {
    source.value = examples[example.value];
    auxFiles = {};
    renderAux();
    get("sim-wrap").hidden = true;
    if (example.value in exampleStdin) stdinBox.value = exampleStdin[example.value];
  }
  editor.session.setScrollTop(0);
  editor.selection.moveCursorTo(0, 0);
  edit();
  syncURL();
}
example.addEventListener("change", reset);
for (const id of ["simw", "simh"]) {
  get<HTMLInputElement>(id).addEventListener("input", () => { persist(); syncURL(); });
  get<HTMLInputElement>(id).addEventListener("keydown", async (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      persist(); syncURL();
      await reset();
      run();
    }
  });
}
for (const b of document.querySelectorAll<HTMLButtonElement>("#sim-wrap [data-sim]")) {
  b.addEventListener("click", async () => {
    const v = b.dataset.sim!;
    get<HTMLInputElement>("simw").value = v;
    get<HTMLInputElement>("simh").value = v;
    persist(); syncURL();
    await reset();
    run();
  });
}
get("reset").addEventListener("click", reset);
copy.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(visibleOutput().value);
    copy.textContent = "Copied!";
    setTimeout(() => { copy.textContent = "Copy"; }, 1600);
  } catch {
    visibleOutput().focus();
    visibleOutput().select();
    status("Select and copy the output with your keyboard.");
  }
});
download.addEventListener("click", () => {
  const url = URL.createObjectURL(new Blob([visibleOutput().value], { type: "text/plain;charset=utf-8" }));
  const link = document.createElement("a");
  link.href = url;
  link.download = tab === "compiled" ? "main." + compiledTarget : "results.txt";
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
edit();
get("debugtoggle").checked = DEBUG;
if (DEBUG) {
  get("debugbar").hidden = false;
  dlog("[page] debug on (?debug=true)");
}
get<HTMLInputElement>("debugtoggle").addEventListener("change", () => {
  DEBUG = get<HTMLInputElement>("debugtoggle").checked;
  get("debugbar").hidden = !DEBUG;
  if (DEBUG) dlog("[page] debug on (toggle)");
  syncURL();
});
if (example.value in demos) reset();
restart();
