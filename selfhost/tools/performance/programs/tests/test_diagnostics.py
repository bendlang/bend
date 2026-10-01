#!/usr/bin/env python3
"""Independent diagnostic orchestration controls; only tiny synthetic modules.

Root executes these serially. No Bend compilation or corpus workload is used.
The deadline/signal controls inject supervisor outcomes instead of waiting for a
real wall deadline; the supervisor itself has separate real-process controls.
"""
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
import diagnose
import run
from support import identity

NODE = os.environ.get("PROGRAMS_TEST_NODE", shutil.which("node") or "node")


def save(file, value):
    Path(file).write_text(json.dumps(value, indent=2) + "\n")


def sha(file):
    return hashlib.sha256(Path(file).read_bytes()).hexdigest()


class DiagnosticControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bend-program-diagnostics-")
        self.root = Path(self.temp.name)
        self.source = self.root / "fixture.bend"
        self.source.write_text("def bench(n: U32) -> U32: n * n\n")
        self.point = {"exportName": "bench", "args": [7], "expected": 49}
        self.catalog = {
            "schemaVersion": 1, "upstreamCommit": "0" * 40,
            "sets": {name: ["fixture"] for name in ["fast", "core", "broad", "full"]},
            "cases": [{"id": "fixture", "point": self.point,
                       "source": {"path": self.source.name, "sha256": sha(self.source),
                                  "bytes": self.source.stat().st_size}}],
        }
        self.catalog_file = self.root / "catalog.json"
        save(self.catalog_file, self.catalog)
        self.modules = {}
        for role in ["typescript", "baseline"]:
            file = self.root / (role + ".mjs")
            file.write_text("export default {bench:n=>n*n};\n")
            self.modules[role] = file
        self.bundle = self.root / "manifest.json"
        self.refresh_bundle()

    def tearDown(self):
        self.temp.cleanup()

    def refresh_bundle(self):
        save(self.bundle, {
            "kind": "bend-program-bundle", "schemaVersion": 1, "complete": True,
            "upstreamCommit": self.catalog["upstreamCommit"],
            "catalogSha256": sha(self.catalog_file),
            "roles": {role: {"label": "synthetic " + role} for role in self.modules},
            "cases": [{"id": "fixture", "sourceSha256": sha(self.source), "point": self.point,
                       "modules": {role: {"path": file.name, "sha256": sha(file),
                                          "bytes": file.stat().st_size}
                                   for role, file in self.modules.items()}}],
        })

    def arguments(self, out="diagnostics", mode="static"):
        return ["--catalog", str(self.catalog_file), "--baseline", str(self.bundle),
                "--budget", "20", "--mode", mode, "--node", NODE,
                "--out", str(self.root / out)]

    def timing_receipt(self):
        receipt = {
            "kind": "bend-program-execution-report", "complete": True, "pass": True,
            "inputs": [identity(self.catalog_file)],
            "plan": {"roles": list(self.modules), "selectedIds": ["fixture"],
                     "variants": {role: {"label": "synthetic " + role} for role in self.modules}},
            "cases": [{"id": "fixture", "point": self.point,
                       "summary": {"complete": True},
                       "samples": [{"role": role, "complete": True,
                                    "result": {"module": {"file": str(file), "sha256": sha(file)}}}
                                   for role, file in self.modules.items()]}],
        }
        file = self.root / "timing.json"
        save(file, receipt)
        return file, receipt

    def test_static_analysis_never_imports_generated_modules(self):
        marker = self.root / "must-not-execute"
        self.modules["baseline"].write_text(
            "import fs from 'node:fs'; fs.writeFileSync(" + json.dumps(str(marker)) +
            ",'executed'); throw Error('AST analysis imported its input'); "
            "export default {bench:n=>n*n};\n")
        self.refresh_bundle()
        result = subprocess.run([sys.executable, str(HERE / "diagnose.py"), *self.arguments()],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        report = json.loads((self.root / "diagnostics/report.json").read_text())
        self.assertTrue(report["pass"])
        self.assertTrue(report["analysis"]["complete"])
        self.assertEqual(report["profiles"], [])
        self.assertFalse(marker.exists())
        analysis = json.loads((self.root / "diagnostics/analysis/report.json").read_text())
        self.assertEqual(len(analysis["entries"]), 2)
        self.assertEqual(len(analysis["comparisons"]), 1)

    def test_from_run_rejects_changed_measured_module(self):
        file, _ = self.timing_receipt()
        self.modules["baseline"].write_text("export default {bench:()=>48};\n")
        with self.assertRaisesRegex(ValueError, "Measured module changed"):
            diagnose.from_run(file, self.catalog_file, self.catalog["cases"], [])

    def test_from_run_rejects_changed_point(self):
        file, receipt = self.timing_receipt()
        receipt["cases"][0]["point"] = {**self.point, "expected": 48}
        save(file, receipt)
        with self.assertRaisesRegex(ValueError, "changed timing point"):
            diagnose.from_run(file, self.catalog_file, self.catalog["cases"], [])

    def test_from_run_rejects_failed_timing(self):
        file, receipt = self.timing_receipt()
        receipt["pass"] = False
        save(file, receipt)
        with self.assertRaisesRegex(ValueError, "successful execution report"):
            diagnose.from_run(file, self.catalog_file, self.catalog["cases"], [])

    def test_from_run_preserves_exact_module_identities(self):
        file, _ = self.timing_receipt()
        inputs = []
        bundle = diagnose.from_run(file, self.catalog_file, self.catalog["cases"], inputs)
        self.assertEqual(set(bundle["roles"]), set(self.modules))
        for role, module in self.modules.items():
            self.assertEqual(bundle["points"]["fixture"][role]["sha256"], sha(module))
            self.assertEqual(bundle["points"]["fixture"][role]["resolved"], str(module))
        self.assertEqual({i["path"] for i in inputs}, {str(file), *map(str, self.modules.values())})

    def assert_static_stop(self, reason, status):
        class StoppedGuard:
            interrupted = False

            def __init__(self, *_):
                pass

            def __enter__(self):
                return self

            def __exit__(self, *_):
                return False

            def run(self, command, directory, deadline):
                return {"complete": False, "stoppedFor": reason, "returncode": -15}

        with patch.object(diagnose, "ExecutionGuard", StoppedGuard), contextlib.redirect_stdout(io.StringIO()):
            code = diagnose.main(self.arguments(mode="all"))
        self.assertEqual(code, 1)
        report = json.loads((self.root / "diagnostics/report.json").read_text())
        self.assertFalse(report["pass"])
        self.assertEqual(report["status"], status)
        self.assertFalse(report["analysis"]["complete"])
        self.assertEqual(report["completedProfiles"], 0)
        self.assertEqual(len(report["profiles"]), 4)
        self.assertTrue(all(row["status"] == "not-started" for row in report["profiles"]))

    def test_static_deadline_preserves_missing_profile_coverage(self):
        self.assert_static_stop("deadline", "budget-exhausted")

    def test_static_signal_is_interruption(self):
        self.assert_static_stop("signal", "interrupted")

    def test_combined_failure_keeps_successful_timing_distinct(self):
        arguments = ["--catalog", str(self.catalog_file), "--baseline", str(self.bundle),
                     "--budget", "20", "--node", NODE, "--out", str(self.root / "combined"),
                     "--diagnostics", "static", "--diagnostic-budget", "20"]
        # Only the diagnostic stage is replaced; real tiny timing runs first.
        def diagnostic_failure(_):
            snapshot = json.loads((self.root / "combined/timing-snapshot.json").read_text())
            self.assertTrue(snapshot["pass"])
            self.assertTrue(snapshot["cases"][0]["summary"]["complete"])
            return 1

        with patch.object(diagnose, "main", diagnostic_failure), contextlib.redirect_stdout(io.StringIO()):
            code = run.main(arguments)
        self.assertEqual(code, 1)
        report = json.loads((self.root / "combined/report.json").read_text())
        snapshot = json.loads((self.root / "combined/timing-snapshot.json").read_text())
        self.assertTrue(report["pass"])
        self.assertEqual(report["status"], "measured")
        self.assertFalse(report["commandPass"])
        self.assertFalse(report["diagnostics"]["pass"])
        self.assertEqual(report["cases"], snapshot["cases"])
        self.assertTrue(report["cases"][0]["summary"]["ratios"])


if __name__ == "__main__":
    unittest.main()
