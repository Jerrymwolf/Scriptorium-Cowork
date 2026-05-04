#!/usr/bin/env bash
# Stage v0.2.0 changes as six semantic commits before running release.sh.
#
# Run from the repo root with a clean tracked-but-staged working tree:
#   ./scripts/stage-v0.2.0-commits.sh
#
# Then verify with `git log --oneline -7` and run `./scripts/release.sh 0.2.0`.

set -euo pipefail
cd "$(dirname "$0")/.."

if [ -n "$(git diff --cached --name-only)" ]; then
  echo "ERROR: there are already staged changes. Unstage with 'git reset' before running this script." >&2
  exit 1
fi

echo "=== Commit 1: workflow fix ==="
git add skills/synthesize/SKILL.md skills/review/SKILL.md
git commit -m "fix(workflow): separate synthesize and contradictions phases

synthesize was instructing the model to fire contradictions before its
final cite-check, while review treated contradictions as a separate next
phase. Two skills disagreeing produced inconsistent behavior depending
on entry point.

synthesize now owns drafting + cite-check only. review owns the
contradictions phase. When invoked directly, synthesize asks the user
instead of firing contradictions inline."

echo "=== Commit 2: discipline gates ==="
git add skills/grill-question/SKILL.md skills/synthesize/SKILL.md skills/using-scriptorium/SKILL.md
git commit -m "feat(discipline): three gates for v0.2.0

- grill-question: disconfirmer gate for users defending a position.
  Q5 requires a specific finding pattern, author critique, or
  methodological challenge. Generic answers get one reflective re-ask.
  Drives downstream search/synthesize/contradiction phases.

- synthesize: three-tier sentence typing (factual / synthesis /
  argument / meta). Cite-check applies different rules per tier.
  Voice authorship policy derived from purpose: defending intent =
  user-authored argument; curious = system-authored with
  interpretation marker.

- synthesize: LLM-judged meta-detection replaces v0.1.7 substring
  is_meta() rules.

- using-scriptorium: Pass 1.5 description-keyword fallback for
  UUID-named tools. Closes the manual-override-required gap surfaced
  in the 2026-05-01 SDT lit-review session."

echo "=== Commit 3: render skill ==="
git add skills/render/SKILL.md scripts/build-viewer.py
git commit -m "feat(render): click-to-source viewer skill

New skills/render/SKILL.md produces a Cowork artifact that renders
synthesis.md as readable author-year prose. Click any citation to see
the source paper, evidence-row metadata (tier, direction, concept),
verbatim supporting quote, and one-click DOI link.

scripts/build-viewer.py is the reference builder. Takes synthesis,
corpus, evidence; emits a self-contained HTML file.

This is the trust mechanism that distinguishes Scriptorium from a
paraphrase engine — every factual claim traces to a verifiable source."

echo "=== Commit 4: validator + release tooling ==="
git add scripts/validate-plugin.js scripts/release.sh scripts/smoke-test.sh scripts/stage-v0.2.0-commits.sh
git commit -m "ci: release-time validator and smoke test

scripts/validate-plugin.js — Node validator. Checks manifest validity,
version consistency, description length, skill count (now 14),
frontmatter integrity, stale-reference patterns, the
synthesize/contradictions workflow contract, and packaged-plugin
shape. Wired into scripts/release.sh before tagging; the redundant
description-length-only check was removed.

scripts/smoke-test.sh — static contract smoke test. Greps the SKILL.md
files for the expected behavior contracts. Release-blocker check.
22/22 pass on v0.2.0.

scripts/stage-v0.2.0-commits.sh — this file. Stages six semantic
commits before release.sh runs."

echo "=== Commit 5: documentation ==="
git add CLAUDE.md README.md TODO.md PROCESS.md
git commit -m "docs: v0.2.0 contributor and user docs

- CLAUDE.md: skill count corrected to fourteen; manual-zip command
  replaced with release-script reference; Post-release verification
  and Rollback sections added.
- README.md: v0.2.0 callout near the top with link to migration notes.
- TODO.md: roadmap with v0.3.0, v1.0.0, v1.1.0+ candidates and
  documentation backlog.
- PROCESS.md: contribution contract — plan-mode is the default,
  execute-mode requires explicit approval, deviation surfacing,
  version-number discipline (1.0.0 reserved for loop-mode release),
  smoke-test discipline, commit hygiene."

echo "=== Commit 6: changelog + version bump ==="
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "docs(v0.2.0): changelog, migration notes, version bump

- CHANGELOG: v0.2.0 entry — three discipline gates, connector probe
  upgrade, render skill, folded v0.1.8 work, migration notes from
  v0.1.x. v0.1.5 and v0.1.6 annotated as internal milestones.
- plugin.json + marketplace.json: 0.1.7 -> 0.2.0 across all three
  version fields."

echo
echo "=== Stage complete ==="
echo "Run 'git log --oneline -6' to confirm the six commits."
echo "Then run './scripts/release.sh 0.2.0' to ship."
