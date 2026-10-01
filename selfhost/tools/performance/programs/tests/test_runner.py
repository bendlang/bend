#!/usr/bin/env python3
"""Independent negative controls for the bounded generated-program runner.

Only synthetic, tiny modules are used. Root runs this suite serially alongside
the execution worker controls; it never compiles Bend or runs the real corpus.
"""
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
import unittest


HERE = Path(__file__).resolve().parents[1]
RUNNER = HERE / "run.py"
NODE = os.environ.get("PROGRAMS_TEST_NODE", shutil.which("node") or "node")
sys.path.insert(0, str(HERE))
from support import ExecutionGuard, process_stat


def sha(file):
    return hashlib.sha256(Path(file).read_bytes()).hexdigest()


def save(file, value):
    Path(file).write_text(json.dumps(value, indent=2) + "\n")


class RunnerControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bend-program-runner-")
        self.directory = Path(self.temp.name)
        self.catalog_file = self.directory / "catalog.json"
        source = self.directory / "fixture.bend"
        source.write_text("def bench(n: U32) -> U32: n * n\n")
        self.point = {"exportName": "bench", "args": [7], "expected": 49}
        self.catalog = {
            "schemaVersion": 1,
            "upstreamCommit": "0" * 40,
            "cases": [{"id": "fixture", "sets": ["fast", "core", "broad", "full"],
                       "source": {"path": source.name, "sha256": sha(source),
                                  "bytes": source.stat().st_size}, "point": self.point}],
        }
        save(self.catalog_file, self.catalog)
        self.baseline = self.bundle("baseline", ["baseline", "typescript"])

    def tearDown(self):
        self.temp.cleanup()

    def bundle(self, name, roles):
        directory = self.directory / name
        directory.mkdir()
        modules = {}
        for role in roles:
            file = directory / (role + ".mjs")
            file.write_text("export default {bench:n=>n*n};\n")
            modules[role] = {"path": file.name, "sha256": sha(file), "bytes": file.stat().st_size}
        manifest = {
            "kind": "bend-program-bundle", "schemaVersion": 1, "complete": True,
            "upstreamCommit": self.catalog["upstreamCommit"],
            "catalogSha256": sha(self.catalog_file),
            "roles": {role: {"label": "synthetic " + role} for role in roles},
            "cases": [{"id": "fixture", "sourceSha256": self.catalog["cases"][0]["source"]["sha256"],
                       "point": self.point, "modules": modules}],
        }
        path = directory / "manifest.json"
        save(path, manifest)
        return path

    def call(self, *extra, output="run"):
        command = [sys.executable, str(RUNNER), "--catalog", str(self.catalog_file),
                   "--baseline", str(self.baseline), "--budget", "20", "--set", "fast",
                   "--out", str(self.directory / output), "--node", NODE, *map(str, extra)]
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
        receipt = self.directory / output / "report.json"
        return result, json.loads(receipt.read_text()) if receipt.exists() else None

    def assert_rejected(self, result, report):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        if report is not None:
            self.assertFalse(report.get("pass", False), report)

    def test_plan_does_not_execute_or_write_output(self):
        marker = self.directory / "must-not-execute"
        manifest = json.loads(self.baseline.read_text())
        entry = manifest["cases"][0]["modules"]["baseline"]
        module = self.baseline.parent / entry["path"]
        module.write_text("import fs from 'node:fs'; fs.writeFileSync(" + json.dumps(str(marker)) +
                          ",'executed'); export default {bench:n=>n*n};\n")
        entry.update(sha256=sha(module), bytes=module.stat().st_size)
        save(self.baseline, manifest)
        result, report = self.call("--plan")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        json.loads(result.stdout)
        self.assertIsNone(report)
        self.assertFalse((self.directory / "run").exists())
        self.assertFalse(marker.exists())

    def test_tampered_module_is_rejected_before_execution(self):
        marker = self.directory / "must-not-execute"
        module = self.baseline.parent / "baseline.mjs"
        module.write_text("import fs from 'node:fs'; fs.writeFileSync(" + json.dumps(str(marker)) +
                          ",'executed'); export default {bench:n=>n*n};\n")
        result, report = self.call()
        self.assert_rejected(result, report)
        self.assertFalse(marker.exists())

    def test_module_path_cannot_escape_bundle(self):
        manifest = json.loads(self.baseline.read_text())
        module = self.directory / "outside.mjs"
        module.write_text("export default {bench:n=>n*n};\n")
        manifest["cases"][0]["modules"]["baseline"] = {
            "path": "../outside.mjs", "sha256": sha(module), "bytes": module.stat().st_size}
        save(self.baseline, manifest)
        self.assert_rejected(*self.call())

    def test_candidate_point_mismatch_is_rejected(self):
        candidate = self.bundle("candidate", ["candidate"])
        manifest = json.loads(candidate.read_text())
        manifest["cases"][0]["point"] = {**self.point, "args": [8], "expected": 64}
        save(candidate, manifest)
        self.assert_rejected(*self.call("--candidate", candidate))

    def test_candidate_upstream_mismatch_is_rejected(self):
        candidate = self.bundle("candidate", ["candidate"])
        manifest = json.loads(candidate.read_text())
        manifest["upstreamCommit"] = "1" * 40
        save(candidate, manifest)
        self.assert_rejected(*self.call("--candidate", candidate))

    def test_changed_catalog_is_rejected(self):
        self.catalog["cases"][0]["point"] = {**self.point, "expected": 48}
        save(self.catalog_file, self.catalog)
        self.assert_rejected(*self.call())

    def test_unknown_case_is_rejected(self):
        self.assert_rejected(*self.call("--cases", "not-a-case"))

    def test_preserves_existing_output(self):
        output = self.directory / "run"
        output.mkdir()
        receipt = output / "report.json"
        original = '{"pass":false,"sentinel":"previous-interrupted-run"}\n'
        receipt.write_text(original)
        self.assert_rejected(*self.call())
        self.assertEqual(receipt.read_text(), original)

    def test_successful_run_has_complete_paired_coverage(self):
        result, report = self.call()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(report["pass"])
        self.assertEqual(report["status"], "measured")
        self.assertEqual(report["selectedCases"], 1)
        self.assertEqual(report["measuredCases"], 1)
        case = report["cases"][0]
        self.assertEqual(len(case["samples"]), 6)
        self.assertEqual(case["summary"]["balancedRounds"], [0, 1, 2])
        self.assertGreater(case["summary"]["ratios"]["baseline/typescript"], 0)
        self.assertEqual([s["role"] for s in case["samples"]],
                         ["typescript", "baseline", "baseline", "typescript", "typescript", "baseline"])
        self.assertTrue(all(s["result"]["firstResult"] == 49 for s in case["samples"]))
        self.assertLess(report["wallSeconds"], 20)

    def test_wrong_result_retains_failure_without_comparison(self):
        manifest = json.loads(self.baseline.read_text())
        entry = manifest["cases"][0]["modules"]["baseline"]
        module = self.baseline.parent / entry["path"]
        module.write_text("export default {bench:()=>48};\n")
        entry.update(sha256=sha(module), bytes=module.stat().st_size)
        save(self.baseline, manifest)
        result, report = self.call()
        self.assert_rejected(result, report)
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["measuredCases"], 0)
        case = report["cases"][0]
        self.assertFalse(case["summary"]["complete"])
        self.assertIsNone(case["summary"]["ratios"])
        failed = [s for s in case["samples"] if not s["complete"]]
        self.assertEqual(len(failed), 1)
        self.assertIn("wrong result", failed[0]["result"]["error"])

    def test_unfinished_cases_remain_in_coverage(self):
        second = {**self.catalog["cases"][0], "id": "second"}
        self.catalog["cases"].append(second)
        save(self.catalog_file, self.catalog)
        manifest = json.loads(self.baseline.read_text())
        manifest["catalogSha256"] = sha(self.catalog_file)
        row = json.loads(json.dumps(manifest["cases"][0]))
        row["id"] = "second"
        wrong = self.baseline.parent / "second-wrong.mjs"
        wrong.write_text("export default {bench:()=>0};\n")
        row["modules"]["typescript"] = {
            "path": wrong.name, "sha256": sha(wrong), "bytes": wrong.stat().st_size}
        manifest["cases"].append(row)
        save(self.baseline, manifest)
        result, report = self.call()
        self.assert_rejected(result, report)
        self.assertEqual(report["selectedCases"], 2)
        self.assertEqual(report["measuredCases"], 0)
        self.assertEqual([c["id"] for c in report["cases"]], ["fixture", "second"])
        self.assertEqual(report["cases"][0]["summary"]["balancedRounds"], [0])
        self.assertTrue(all(c["summary"]["ratios"] is None for c in report["cases"]))

    def test_archive_link_is_rejected_before_extracting(self):
        archive = self.baseline.parent / "modules.tar.gz"
        with tarfile.open(archive, "w:gz") as stream:
            member = tarfile.TarInfo("baseline.mjs")
            member.type = tarfile.SYMTYPE
            member.linkname = "../../../outside.mjs"
            stream.addfile(member)
        manifest = json.loads(self.baseline.read_text())
        manifest["archive"] = {"path": archive.name, "sha256": sha(archive), "bytes": archive.stat().st_size}
        save(self.baseline, manifest)
        result, report = self.call()
        self.assert_rejected(result, report)
        self.assertIn("Unsafe or repeated archive member", report["error"])

    def test_archive_duplicate_member_is_rejected(self):
        archive = self.baseline.parent / "modules.tar.gz"
        content = (self.baseline.parent / "baseline.mjs").read_bytes()
        with tarfile.open(archive, "w:gz") as stream:
            for _ in range(2):
                member = tarfile.TarInfo("baseline.mjs")
                member.size = len(content)
                stream.addfile(member, io.BytesIO(content))
        manifest = json.loads(self.baseline.read_text())
        manifest["archive"] = {"path": archive.name, "sha256": sha(archive), "bytes": archive.stat().st_size}
        save(self.baseline, manifest)
        result, report = self.call()
        self.assert_rejected(result, report)
        self.assertIn("Unsafe or repeated archive member", report["error"])


class GuardControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bend-program-guard-")
        self.directory = Path(self.temp.name)
        self.lock = self.directory / "execution.lock"

    def tearDown(self):
        self.temp.cleanup()

    def guard(self, rss_mib=128):
        # Synthetic children allocate at most 96 MiB; the real CLI separately
        # enforces a >=1 GiB host-headroom floor and >=128 MiB RSS setting.
        return ExecutionGuard(rss_mib=rss_mib, available_mib=0, lock_path=self.lock)

    def run_child(self, guard, source, duration=2):
        return guard.run([sys.executable, "-c", source], self.directory / "process",
                         time.monotonic() + duration)

    def assert_dead(self, pid):
        for _ in range(25):
            stat = Path(f"/proc/{pid}/stat")
            if not stat.exists():
                return
            raw = stat.read_text()
            if raw[raw.rfind(")") + 2:].split()[0] == "Z":
                return  # The parent/init may not have reaped it yet.
            time.sleep(0.02)
        self.fail(f"child {pid} still running after supervisor cleanup")

    def test_nonzero_exit_is_not_success(self):
        with self.guard() as guard:
            report = self.run_child(guard, "raise SystemExit(7)")
        self.assertFalse(report["complete"])
        self.assertEqual(report["returncode"], 7)
        self.assertNotIn("stoppedFor", report)

    def test_deadline_stops_child_and_detached_grandchild(self):
        pids = self.directory / "pids.json"
        source = ("import json,os,subprocess,sys,time\n"
                  "child=subprocess.Popen([sys.executable,'-c','import time;time.sleep(60)'],"
                  "start_new_session=True)\n"
                  f"open({str(pids)!r},'w').write(json.dumps([os.getpid(),child.pid]))\n"
                  "time.sleep(60)\n")
        identities = []
        try:
            with self.guard() as guard:
                report = self.run_child(guard, source, duration=0.35)
                identities = list(guard.seen.items())
            self.assertFalse(report["complete"])
            self.assertEqual(report["stoppedFor"], "deadline")
            self.assertLess(report["wallSeconds"], 2)
            self.assertTrue(pids.exists(), "timeout control did not reach spawn")
            for pid in json.loads(pids.read_text()):
                self.assert_dead(pid)
            saved = json.loads((self.directory / "process/process.json").read_text())
            self.assertEqual(saved, report)
        finally:
            for pid, birth in identities:
                current = process_stat(pid)
                if current is not None and current[0] == birth:
                    try:
                        os.kill(pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass

    def test_memory_cap_stops_allocating_child(self):
        with self.guard(rss_mib=64) as guard:
            report = self.run_child(guard,
                "import os,time;print(os.getpid(),flush=True);"
                "memory=bytearray(96*1024*1024);time.sleep(60)")
        self.assertFalse(report["complete"])
        self.assertEqual(report["stoppedFor"], "tree-rss-limit")
        self.assertGreater(report["peakTreeRssBytes"], 64 * 1024**2)
        self.assert_dead(int((self.directory / "process/stdout.log").read_text().strip()))

    def test_signal_stops_child_preserves_receipt_and_restores_handler(self):
        before = signal.getsignal(signal.SIGTERM)
        with self.guard() as guard:
            report = self.run_child(guard,
                "import os,signal,time;print(os.getpid(),flush=True);"
                "time.sleep(.05);os.kill(os.getppid(),signal.SIGTERM);time.sleep(60)")
            self.assertEqual(guard.interrupted, signal.SIGTERM)
        self.assertEqual(signal.getsignal(signal.SIGTERM), before)
        self.assertFalse(report["complete"])
        self.assertEqual(report["stoppedFor"], "signal")
        self.assert_dead(int((self.directory / "process/stdout.log").read_text().strip()))
        self.assertEqual(json.loads((self.directory / "process/process.json").read_text()), report)

    def test_shared_lock_refuses_overlapping_execution(self):
        with self.guard():
            with self.assertRaisesRegex(RuntimeError, "execution lock"):
                with self.guard():
                    self.fail("second guard entered while first held the lock")


class SummaryControls(unittest.TestCase):
    @staticmethod
    def sample(role, round_number, value, complete=True):
        return {"role": role, "round": round_number, "complete": complete,
                "result": {"msPerCall": value, "firstCallMs": value, "importMs": 1,
                           "halfDriftPercent": 0, "peakRssKiB": 1000}}

    def test_unbalanced_or_failed_round_cannot_publish_ratio(self):
        from run import summarize
        roles = ["baseline", "typescript"]
        # Complete first round plus an artificially fast unmatched observation.
        samples = [self.sample("baseline", 0, 10), self.sample("typescript", 0, 2),
                   self.sample("baseline", 1, 0.01)]
        result = summarize(samples, roles, 2)
        self.assertFalse(result["complete"])
        self.assertIsNone(result.get("ratios"))
        # A failed last role is not repaired by using earlier survivors.
        samples.append(self.sample("typescript", 1, 1, complete=False))
        result = summarize(samples, roles, 2)
        self.assertFalse(result["complete"])
        self.assertIsNone(result.get("ratios"))

    def test_complete_balanced_rounds_allow_comparison(self):
        from run import summarize
        samples = [self.sample(role, round_number, value)
                   for round_number in range(2)
                   for role, value in [("baseline", 10), ("typescript", 2), ("candidate", 5)]]
        result = summarize(samples, ["baseline", "typescript", "candidate"], 2)
        self.assertTrue(result["complete"])
        self.assertTrue(result.get("ratios"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
