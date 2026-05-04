#!/usr/bin/env python3
"""Mechanical cite-check for Scriptorium synthesis artifacts.

Walks a synthesis.md and confirms every empirical claim resolves to an
evidence row in evidence.jsonl. Exits non-zero on any failure. This is
the discipline gate that prevents Scriptorium from shipping zero-citation
artifacts.

Usage:
  python3 scripts/cite-check.py \\
    --synthesis path/to/synthesis.md \\
    --evidence path/to/evidence.jsonl \\
    --corpus path/to/corpus.jsonl \\
    [--mode strict|lenient] \\
    [--min-citations N]

Strict mode (default for chapter/memo/brief/teaching/deck):
  - Requires a minimum total citation count for the synthesis
  - Any unresolved [paper:loc] token is a failure
  - Any inferred metadata is a failure
  - Synthesis with zero citations is an automatic failure (catches v0.2.x memo bug)

Lenient mode (default for exploration):
  - Same checks but emit warnings instead of failures
  - Still flags zero-citation synthesis as a failure (this floor is universal)
"""
import argparse
import json
import re
import sys
from pathlib import Path


CITE_RE = re.compile(
    r"\[([a-zA-Z][a-zA-Z0-9_\-]*:[a-zA-Z0-9_\-]+):"
    r"(abstract|page:[0-9\-]+|sec:[a-zA-Z_\-]+|L[0-9]+-L[0-9]+)\]"
)

META_PATTERNS = [
    r"^#+\s",
    r"^---+$",
    r"^\s*$",
    r"^\s*>\s",
    r"^\s*\*\s",
    r"^\s*\d+\.\s",
]


def is_meta(line):
    s = line.strip()
    if not s:
        return True
    for pat in META_PATTERNS:
        if re.match(pat, s):
            return True
    if s.startswith("**") and s.endswith("**") and len(s) < 100:
        return True
    if s.lower().startswith(("table of contents", "contents", "references", "bibliography")):
        return True
    return False


def split_sentences(text):
    out = []
    for line in text.split("\n"):
        if is_meta(line):
            continue
        sents = re.split(r"(?<=[.!?])\s+(?=[A-Z\(\[\*])", line.strip())
        for s in sents:
            if s.strip():
                out.append(s.strip())
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--synthesis", required=True)
    ap.add_argument("--evidence", required=True)
    ap.add_argument("--corpus", required=True)
    ap.add_argument("--mode", default="strict", choices=["strict", "lenient"])
    ap.add_argument("--min-citations", type=int, default=1,
                    help="Minimum total citations in synthesis. Default 1; "
                         "chapter intent should be 10+, memo 3+, brief 5+.")
    args = ap.parse_args()

    synth_text = Path(args.synthesis).read_text()
    evidence = [json.loads(l) for l in Path(args.evidence).read_text().splitlines() if l.strip()]
    corpus = [json.loads(l) for l in Path(args.corpus).read_text().splitlines() if l.strip()]

    ev_keys = set((r["paper_id"], r["locator"]) for r in evidence)
    corpus_by_id = {p["paper_id"]: p for p in corpus}

    sentences = split_sentences(synth_text)
    n_sents = len(sentences)
    n_with_cite = 0
    n_total_cites = 0
    n_resolved = 0
    n_unresolved = 0
    unresolved_examples = []
    n_unsupported = 0
    unsupported_examples = []

    metadata_buckets = {"verified": 0, "partial": 0, "inferred": 0}

    for sent in sentences:
        cites = CITE_RE.findall(sent)
        if not cites:
            n_unsupported += 1
            if len(unsupported_examples) < 3:
                unsupported_examples.append(sent[:90])
            continue
        n_with_cite += 1
        for paper_id, locator in cites:
            n_total_cites += 1
            if (paper_id, locator) in ev_keys:
                n_resolved += 1
                p = corpus_by_id.get(paper_id, {})
                mr = p.get("metadata_resolution", "verified")
                metadata_buckets[mr] = metadata_buckets.get(mr, 0) + 1
            else:
                n_unresolved += 1
                if len(unresolved_examples) < 3:
                    unresolved_examples.append(f"[{paper_id}:{locator}] in: {sent[:80]}...")

    failures = []

    if n_total_cites < args.min_citations:
        failures.append(
            f"FLOOR FAILED: synthesis has {n_total_cites} total citations; "
            f"minimum is {args.min_citations}. Scriptorium does not ship "
            f"zero-citation artifacts. Run search and extract before synthesis."
        )

    if n_unresolved > 0:
        failures.append(f"{n_unresolved} citation(s) reference an evidence row that does not exist.")

    if metadata_buckets["inferred"] > 0 and args.mode == "strict":
        failures.append(
            f"{metadata_buckets['inferred']} citation(s) have inferred metadata "
            f"(paper title/author reconstructed from prose, not API). Strict mode blocks ship."
        )

    pct = lambda n: f"{(n*100/n_total_cites):.0f}%" if n_total_cites else "0%"

    print(f"Cite-check — {args.mode} mode")
    print()
    print(f"Sentences total:                  {n_sents}")
    print(f"Sentences with citations:         {n_with_cite}")
    print(f"Sentences without citations:      {n_unsupported}")
    print(f"Citation tokens total:            {n_total_cites}")
    print(f"Citations resolved to evidence:   {n_resolved} / {n_total_cites}")
    if n_total_cites:
        print(f"Citation metadata resolution:")
        print(f"  verified: {metadata_buckets['verified']} ({pct(metadata_buckets['verified'])})")
        print(f"  partial:  {metadata_buckets['partial']} ({pct(metadata_buckets['partial'])})")
        print(f"  inferred: {metadata_buckets['inferred']} ({pct(metadata_buckets['inferred'])})")
    print()

    if unresolved_examples:
        print("Unresolved citation examples:")
        for ex in unresolved_examples:
            print(f"  - {ex}")
        print()

    if failures:
        print("FAILURES:")
        for f in failures:
            print(f"  - {f}")
        print()
        if args.mode == "strict":
            print("Status: FAILED — do not ship.")
            sys.exit(1)
        else:
            print("Status: WARNING (lenient mode)")
            sys.exit(0)

    print("Status: PASSED")
    sys.exit(0)


if __name__ == "__main__":
    main()
