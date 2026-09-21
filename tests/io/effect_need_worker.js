let asked = false;

function a_run(ms) {
  const value = asked ? 11 : 99;
  asked = false;
  return value;
}

function a_run_need() {
  asked = true;
  return { time: true };
}
