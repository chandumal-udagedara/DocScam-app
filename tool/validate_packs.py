#!/usr/bin/env python3
"""
Validate DocScam content packs. Run in CI and before packaging.
Exits non-zero on any error, so a bad pack cannot ship.

Usage: python3 validate_packs.py <packs_dir> [--assets <flutter_project_root>]
                                             [--rules <scam-patterns.json>]
"""
import json, sys, argparse
from pathlib import Path

SUPPORTED_MAJOR = 1

# Files that live alongside the content packs but are not content packs.
# index.json is the registry; scam-patterns.json is the checker's rule pack
# and is validated by the checker's own tests, not here.
NON_PACK_FILES = {"index.json", "scam-patterns.json"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("packs_dir")
    ap.add_argument("--assets", help="Flutter project root, to check asset_image files exist")
    ap.add_argument("--rules", help="scam-patterns.json, to check red_flag_rules ids resolve")
    a = ap.parse_args()

    packs_dir = Path(a.packs_dir)
    errors, warnings = [], []

    # Structural validation is a bonus; the hand-written checks below are the
    # ones that actually matter, so an old or missing jsonschema must not stop
    # the run.
    validator = None
    try:
        import jsonschema
        schema = json.loads((Path(__file__).parent / "pack.schema.json").read_text())
        for cls in ("Draft202012Validator", "Draft7Validator", "Draft4Validator"):
            if hasattr(jsonschema, cls):
                validator = getattr(jsonschema, cls)(schema)
                break
        if validator is None:
            warnings.append("jsonschema too old for any known draft - schema check skipped")
    except ImportError:
        warnings.append("jsonschema not installed - schema check skipped (pip install jsonschema)")
    except Exception as e:
        warnings.append(f"schema check skipped ({type(e).__name__}: {e})")

    known_rules = set()
    if a.rules:
        known_rules = {r["id"] for r in json.loads(Path(a.rules).read_text())["rules"]}

    index_path = packs_dir / "index.json"
    if not index_path.exists():
        errors.append("index.json missing")
        index = {"packs": []}
    else:
        index = json.loads(index_path.read_text())

    seen_ids, seen_prompts = set(), {}
    listed = {p["file"] for p in index.get("packs", [])}
    on_disk = {f.name for f in packs_dir.glob("*.json")} - NON_PACK_FILES
    for missing in listed - on_disk:
        errors.append(f"index.json lists {missing} but it is not on disk")
    for orphan in on_disk - listed:
        errors.append(f"{orphan} is on disk but not listed in index.json")

    for entry in index.get("packs", []):
        f = packs_dir / entry["file"]
        if not f.exists():
            continue
        pack = json.loads(f.read_text())

        major = int(pack["schema_version"].split(".")[0])
        if major != SUPPORTED_MAJOR:
            errors.append(f"{f.name}: schema_version {pack['schema_version']} unsupported (expect {SUPPORTED_MAJOR}.x.x)")

        if validator:
            for e in validator.iter_errors(pack):
                errors.append(f"{f.name}: {'/'.join(str(p) for p in e.path)}: {e.message}")

        if entry["question_count"] != len(pack["questions"]):
            errors.append(f"{f.name}: index says {entry['question_count']} questions, file has {len(pack['questions'])}")

        for q in pack["questions"]:
            qid = q["id"]
            if qid in seen_ids:
                errors.append(f"duplicate question id: {qid}")
            seen_ids.add(qid)

            n = len(q["options"])
            for ci in q["correct_indices"]:
                if ci >= n:
                    errors.append(f"{qid}: correct_indices {ci} out of range (only {n} options)")
            if len(set(q["correct_indices"])) != len(q["correct_indices"]):
                errors.append(f"{qid}: repeated index in correct_indices")
            if len(q["correct_indices"]) == n:
                warnings.append(f"{qid}: every option marked correct")
            if len(set(q["options"])) != n:
                warnings.append(f"{qid}: duplicate option text")
            if not q.get("explanation"):
                warnings.append(f"{qid}: no explanation - result screen will show a blank review card")

            key = q["prompt"].strip().lower()[:80]
            if key in seen_prompts:
                warnings.append(f"{qid}: prompt looks duplicated from {seen_prompts[key]}")
            else:
                seen_prompts[key] = qid

            if a.assets and q.get("asset_image"):
                if not (Path(a.assets) / q["asset_image"]).exists():
                    errors.append(f"{qid}: asset not found: {q['asset_image']}")

            for rid in q.get("red_flag_rules", []):
                if known_rules and rid not in known_rules:
                    errors.append(f"{qid}: unknown red_flag_rule '{rid}'")

    print(f"checked {len(index.get('packs', []))} packs, {len(seen_ids)} questions")
    for w in warnings:
        print("  WARN ", w)
    for e in errors:
        print("  ERROR", e)
    print(f"\n{len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
