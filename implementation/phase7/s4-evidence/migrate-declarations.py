#!/usr/bin/env python3
"""One-off S4 source edit. Never imported by the compiler or its build tools."""
import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PROJECT = ROOT / "selfhost"
AREA = PROJECT / "build/phase7/s4"
INVENTORY = Path(__file__).with_name("declarations-counts.json")
INVENTORY_SHA = "bc31164c1b71d0c6a4707d18f5a2a9ec411e21350c6da994bb3e2039299ee8b7"
MANIFEST_SHA = "08c4c055006c8564139a88b793aadfe1dc0b6d100b4c3f2b26ccf8005f8d65c7"
DECL = re.compile(r"^(type|law|def)\s+([^\s(<:]+)")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def counts(data):
    lines = data.splitlines()
    return dict(physical=len(lines), nonblank=sum(bool(x.strip()) for x in lines), bytes=len(data))


def inventory_tree(directory):
    result = {}
    for file in sorted(directory.rglob("*")):
        require(not file.is_symlink(), f"Refuse symlink: {file}")
        if file.is_file():
            result[str(file.relative_to(directory))] = digest(file.read_bytes())
    return result


def snapshot(target, original):
    target = target.resolve()
    require(target.is_relative_to(AREA.resolve()), "Output must remain in isolated S4 build area")
    require(not target.exists(), f"Refuse to replace existing source snapshot: {target}")
    shutil.copytree(PROJECT / "src", target)
    require(inventory_tree(target) == original, "Copied source differs from frozen input")


def transform(data, selected):
    lines = data.decode("utf8").splitlines(keepends=True)
    declarations = [(i, m.group(1), m.group(2)) for i, line in enumerate(lines)
                    if (m := DECL.match(line))]
    positions = {(kind, name): i for i, kind, name in declarations}
    require(len(positions) == len(declarations), "Duplicate declaration in source")
    edits, records = [], []
    for name in sorted(selected):
        start = positions[("law", name)]
        definition = positions[("def", name)]
        require(lines[start] == f"law {name}:\n", f"Unexpected law header: {name}")
        cursor, binders, names = start + 1, [], []
        while lines[cursor].startswith("  for "):
            binder = lines[cursor][6:].removesuffix("\n")
            match = re.fullmatch(r"[-+]?([A-Za-z_][A-Za-z_0-9]*): (.+)", binder)
            require(match is not None and "#" not in binder, f"Unsupported binder: {name}")
            binders.append(binder)
            names.append(match.group(1))
            cursor += 1
        result_line = lines[cursor]
        require(result_line.startswith("  ") and not result_line.startswith("   "),
                f"Unexpected return indentation: {name}")
        result = result_line[2:].removesuffix("\n")
        require(result and "#" not in result and not result.startswith(("for ", "exs ")),
                f"Unsupported return expression: {name}")
        cursor += 1
        separator = int(cursor < len(lines) and lines[cursor] == "\n")
        require(lines[definition] == f"def {name}({', '.join(names)}):\n",
                f"Fill parameter names/order changed: {name}")
        require(definition > 0 and lines[definition - 1] == "@unsafe\n",
                f"Unsafe annotation missing: {name}")
        header = (f"def {name}(\n" + "".join(f"  {b},\n" for b in binders)
                  + f") -> {result}:\n") if binders else f"def {name}() -> {result}:\n"
        edits.extend([(start, cursor + separator, ""), (definition, definition + 1, header)])
        records.append(dict(name=name, lawLine=start + 1, definitionLine=definition + 1,
                            binders=binders, result=result, separatorLinesRemoved=separator))
    edits.sort()
    pieces, cursor = [], 0
    for start, end, replacement in edits:
        require(start >= cursor, "Overlapping edits")
        pieces.extend(["".join(lines[cursor:start]), replacement])
        cursor = end
    pieces.append("".join(lines[cursor:]))
    result = "".join(pieces).encode("utf8")
    before_events = [(kind, name) for _, kind, name in declarations]
    after_events = [(m.group(1), m.group(2)) for line in result.decode().splitlines()
                    if (m := DECL.match(line))]
    require(after_events == [x for x in before_events if x != ("law", x[1]) or x[1] not in selected],
            "Nonselected declaration or definition order changed")
    require(result.count(b"\n@unsafe\n") == data.count(b"\n@unsafe\n"), "Unsafe markers changed")
    return result, records


def migrate(args, report):
    require(digest(INVENTORY.read_bytes()) == INVENTORY_SHA, "Frozen candidate inventory changed")
    audit = json.loads(INVENTORY.read_text())
    manifest_data = (PROJECT / "src/compiler.json").read_bytes()
    require(digest(manifest_data) == MANIFEST_SHA, "Manifest changed")
    modules = json.loads(manifest_data)["modules"]
    require(modules == [row["file"] for row in audit["source_identities"]], "Module order changed")
    inputs = {rel: (PROJECT / rel).read_bytes() for rel in modules}
    for row in audit["source_identities"]:
        require(digest(inputs[row["file"]]) == row["sha256"], f"Source changed: {row['file']}")
    selected = set(audit["fixed_order_converted_names"])
    require(len(selected) == 425, "Unexpected full candidate count")
    expected = audit["policies"]["fixed_definition_order"]
    if args.mode == "pilot":
        selected = set(audit["minimal_module_pilot"][0]["converted_names"])
        expected = audit["minimal_module_pilot"][0]
    if args.retain_capability_laws:
        require(args.mode == "all", "Capability correction applies to the full migration")
        retained = {"j_layout_error", "annotate_selected"}
        require(retained <= selected, "Expected capability laws absent from original inventory")
        selected -= retained
        # Attempt a01 demonstrated the host's literal-law export probes. Preserve
        # both declarations; do not change bootstrap capability selection.
        expected = dict(expected, physical_lines_saved=830,
                        declaration_nonblank_lines_saved=425, bytes_saved=12112,
                        separator_lines_saved=405)
        report["retainedCapabilityLaws"] = sorted(retained)
    original_tree = inventory_tree(PROJECT / "src")
    report.update(baseline="8cc51c1", mode=args.mode, inventorySha256=INVENTORY_SHA,
                  manifestSha256=MANIFEST_SHA, inputTree=original_tree, modules=[], transformed=[])
    if args.baseline_project:
        snapshot(Path(args.baseline_project) / "src", original_tree)
    output = Path(args.output_project).resolve() / "src"
    snapshot(output, original_tree)
    found = set()
    for rel, data in inputs.items():
        names = set(re.findall(r"^def ([^ (]+)", data.decode(), re.M)) & selected
        changed, records = transform(data, names)
        for record in records:
            record["file"] = rel
        report["transformed"].extend(records)
        found.update(names)
        if names:
            (output / Path(rel).relative_to("src")).write_bytes(changed)
        report["modules"].append(dict(file=rel, before=counts(data), after=counts(changed),
                                      beforeSha256=digest(data), afterSha256=digest(changed)))
    require(found == selected, "Candidate names were missing or duplicated")
    report["before"] = {key: sum(m["before"][key] for m in report["modules"]) for key in counts(b"")}
    report["after"] = {key: sum(m["after"][key] for m in report["modules"]) for key in counts(b"")}
    report["saved"] = {key: report["before"][key] - report["after"][key] for key in report["before"]}
    separators = sum(r["separatorLinesRemoved"] for r in report["transformed"])
    require(report["saved"] == dict(physical=expected["physical_lines_saved"],
                                    nonblank=expected["declaration_nonblank_lines_saved"],
                                    bytes=expected["bytes_saved"]), "Migration differs from frozen budget")
    require(separators == expected["separator_lines_saved"], "Separator accounting changed")
    report.update(separatorLinesRemoved=separators, bytesSavedExcludingSeparatorNewlines=report["saved"]["bytes"] - separators,
                  outputProject=str(output.parent), outputTree=inventory_tree(output),
                  eventsBefore=audit["top_level_events"], eventsAfter=audit["top_level_events"] - len(found),
                  lawCountAfter=audit["laws"] - len(found), bodiesPreservedByDisjointEdits=True,
                  definitionOrderPreserved=True, assemblerUnchanged=True)
    require(inventory_tree(PROJECT / "src") == original_tree, "Main source changed during migration")
    report["complete"] = True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=["pilot", "all"], required=True)
    parser.add_argument("--output-project", required=True)
    parser.add_argument("--baseline-project")
    parser.add_argument("--retain-capability-laws", action="store_true")
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    report_path = Path(args.report).resolve()
    require(not report_path.exists(), "Refuse to overwrite a migration report")
    report = dict(kind="phase7-s4-declaration-migration", complete=False,
                  toolSha256=digest(Path(__file__).read_bytes()))
    try:
        migrate(args, report)
    except Exception as error:
        report["error"] = str(error)
        raise
    finally:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({key: report[key] for key in ["complete", "mode", "saved", "eventsAfter", "outputProject"]}))


if __name__ == "__main__":
    main()
