#!/usr/bin/env python3
"""
Extract DocScam's hardcoded question bank (lib/question_bank.dart) into
versioned JSON content packs.

One-shot migration tool: run it once, commit the JSON, delete the Dart
literals. Kept in the repo as provenance for how the packs were produced.

Usage:  python3 extract_question_bank.py <question_bank.dart> <out_dir>
"""
import json, re, sys, unicodedata
from pathlib import Path

SCHEMA_VERSION = "1.0.0"
CONTENT_VERSION = "2026.08.27"


def strip_dart_string(chunk):
    """Join Dart adjacent string literals ('a' 'b' -> 'ab') and unescape."""
    parts, i, n = [], 0, len(chunk)
    while i < n:
        c = chunk[i]
        if c in "'\"":
            quote, buf, i = c, [], i + 1
            while i < n:
                if chunk[i] == "\\" and i + 1 < n:
                    nxt = chunk[i + 1]
                    buf.append({"n": "\n", "t": "\t", "r": "\r"}.get(nxt, nxt))
                    i += 2
                    continue
                if chunk[i] == quote:
                    i += 1
                    break
                buf.append(chunk[i])
                i += 1
            parts.append("".join(buf))
        else:
            i += 1
    return "".join(parts)


def split_top_level(body):
    """Split a Q(...) argument list on commas at paren/bracket depth 0."""
    out, buf, depth, i, n = [], [], 0, 0, len(body)
    while i < n:
        c = body[i]
        if c in "'\"":
            quote = c
            buf.append(c)
            i += 1
            while i < n:
                buf.append(body[i])
                if body[i] == "\\":
                    i += 2
                    if i - 1 < n:
                        buf.append(body[i - 1])
                    continue
                if body[i] == quote:
                    i += 1
                    break
                i += 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        if c == "," and depth == 0:
            out.append("".join(buf))
            buf = []
        else:
            buf.append(c)
        i += 1
    if "".join(buf).strip():
        out.append("".join(buf))
    return out


def balanced_block(src, start):
    """Given index of '(' return index just past its matching ')'."""
    depth, i, n = 0, start, len(src)
    while i < n:
        c = src[i]
        if c in "'\"":
            quote = c
            i += 1
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == quote:
                    break
                i += 1
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("unbalanced parens")


def slugify(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def normalise_asset(path):
    """'./assets/Seasons/x.png' -> 'assets/Seasons/x.png' (Flutter-correct)."""
    p = path.strip().lstrip("./")
    return p if p.startswith("assets/") else "assets/" + p


def parse(src):
    cats = [(m.group(1), m.start()) for m in re.finditer(r"^\s{2}'([^']+)':\s*\[", src, re.M)]
    packs, warnings = {}, []
    for idx, (name, start) in enumerate(cats):
        end = cats[idx + 1][1] if idx + 1 < len(cats) else len(src)
        seg, questions, qn = src[start:end], [], 0
        for m in re.finditer(r"\bconst\s+Q\s*\(", seg):
            open_paren = seg.index("(", m.start())
            body = seg[open_paren + 1: balanced_block(seg, open_paren) - 1]
            fields = {}
            for arg in split_top_level(body):
                if ":" not in arg:
                    continue
                key, _, val = arg.partition(":")
                fields[key.strip()] = val.strip()
            if "prompt" not in fields:
                continue
            qn += 1
            qid = f"{slugify(name)}-{qn:03d}"

            options = [strip_dart_string(o) for o in
                       split_top_level(fields.get("options", "[]").strip()[1:-1]) if o.strip()]
            correct = [int(x) for x in re.findall(r"\d+", fields.get("correctIndices", ""))]

            q = {
                "id": qid,
                "prompt": strip_dart_string(fields["prompt"]).strip(),
                "options": options,
                "correct_indices": correct,
                "explanation": strip_dart_string(fields["explanation"]).strip()
                if "explanation" in fields else None,
                "asset_image": normalise_asset(strip_dart_string(fields["assetImage"]))
                if "assetImage" in fields else None,
                "red_flag_rules": [],
            }

            if not options:
                warnings.append(f"{qid}: no options")
            if not correct:
                warnings.append(f"{qid}: no correct answer")
            if any(c >= len(options) for c in correct):
                warnings.append(f"{qid}: correct_indices out of range (opts={len(options)}, idx={correct})")
            if q["explanation"] is None:
                warnings.append(f"{qid}: missing explanation")
            if len(set(options)) != len(options):
                warnings.append(f"{qid}: duplicate option text")
            questions.append(q)

        packs[name] = {
            "schema_version": SCHEMA_VERSION,
            "content_version": CONTENT_VERSION,
            "pack_id": slugify(name),
            "title": name,
            "locale": "en-AU",
            "source": "migrated from lib/question_bank.dart",
            "questions": questions,
        }
    return packs, warnings


def main():
    src = Path(sys.argv[1]).read_text(encoding="utf-8")
    out = Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
    packs, warnings = parse(src)
    index = []
    for name, pack in packs.items():
        f = out / f"{pack['pack_id']}.json"
        f.write_text(json.dumps(pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        index.append({"pack_id": pack["pack_id"], "title": name,
                      "file": f.name, "question_count": len(pack["questions"])})
        print(f"  {f.name}: {len(pack['questions'])} questions")
    (out / "index.json").write_text(json.dumps(
        {"schema_version": SCHEMA_VERSION, "content_version": CONTENT_VERSION,
         "packs": index}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    total = sum(i["question_count"] for i in index)
    print(f"\ntotal: {total} questions in {len(index)} packs")
    if warnings:
        print(f"\n{len(warnings)} content warnings:")
        for w in warnings:
            print("  !", w)
    else:
        print("\nno content warnings")


if __name__ == "__main__":
    main()
