// Renders the film. Usage:
//   node video.js            media/intro.mp4 (1920x1080, 60fps) and media/intro.gif (640px wide, 20fps)
//   node video.js 3 9 26     stills at those seconds into shots/
// Frames stream straight into ffmpeg; nothing lands on disk but the outputs.
const { createCanvas } = require("canvas");
const fs = require("fs"), path = require("path"), { spawn, spawnSync } = require("child_process");
const { draw, setCtx, DUR } = require("./render.js");

// the film is drawn in 1280x720 units; the canvas is that, scaled to 1080p
const K = 1.5, W = 1280*K, H = 720*K, FPS = 60, OUT = path.join(__dirname, "..", "..", "..", "media");
const cv = createCanvas(W, H), ctx = cv.getContext("2d");
ctx.scale(K, K); setCtx(ctx);

const args = process.argv.slice(2);
if (args.length) {
  fs.mkdirSync("shots", { recursive: true });
  for (const a of args) {
    draw(parseFloat(a));
    fs.writeFileSync(`shots/t${a}.png`, cv.toBuffer("image/png"));
    console.log(`shots/t${a}.png`);
  }
} else (async () => {
  const mp4 = path.join(OUT, "intro.mp4"), gif = path.join(OUT, "intro.gif"), N = Math.round(DUR*FPS);
  const ff = spawn("ffmpeg", ["-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "bgra", "-s", `${W}x${H}`,
    "-r", String(FPS), "-i", "-", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-movflags", "+faststart", mp4],
    { stdio: ["pipe", "ignore", "inherit"] });
  for (let f = 0; f < N; f++) {
    draw(f/FPS);
    if (!ff.stdin.write(cv.toBuffer("raw"))) await new Promise(r => ff.stdin.once("drain", r));
    if (f % 1800 === 0) console.log(`${f}/${N}`);
  }
  ff.stdin.end();
  await new Promise(r => ff.on("close", r));
  // the gif: one 48-colour palette for the whole film, ordered dither, frames
  // diffed by ffmpeg, 640px (the README column) at 20fps (one frame in
  // three) throughout. The cube's camera moves change every pixel every
  // frame; this is what keeps the whole under GitHub's 10 MB (30fps would
  // be 16 MB, 64 colours 11 MB)
  spawnSync("ffmpeg", ["-y", "-loglevel", "error", "-i", mp4, "-vf",
    "select='not(mod(n,3))',scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=48[p];[b][p]paletteuse=dither=bayer:bayer_scale=5",
    "-fps_mode", "vfr", gif], { stdio: "inherit" });
  console.log("done: " + mp4 + " " + gif);
})();
