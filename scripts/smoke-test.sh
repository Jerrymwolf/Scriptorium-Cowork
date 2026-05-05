#!/usr/bin/env bash
# Static contract smoke test for Scriptorium-Cowork v0.2.0+.
#
# Confirms the SKILL.md prose contains the expected behavior contracts.
# This is a release-blocker check — runtime testing in a live Cowork session is still required
# before publishing to the marketplace.

set -euo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0

check() {
  local description="$1"
  local file="$2"
  local pattern="$3"
  if grep -qE "$pattern" "$file"; then
    echo "  ✓ $description"
    PASS=$((PASS+1))
  else
    echo "  ✗ $description"
    echo "      file: $file"
    echo "      pattern: $pattern"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Workflow contract: synthesize/contradictions separated ==="
check "synthesize asks before firing /contradictions when invoked directly" \
  skills/synthesize/SKILL.md \
  "If the user invoked .synthesize. directly, ask whether they want to run .contradictions. next"
check "review owns the contradictions phase as a separate pass" \
  skills/review/SKILL.md \
  "Contradictions.*fire .contradictions. as a separate pass"
# Negative check (R13, v0.4.0: removed placeholder; this is the real check)
if grep -qE "Run the contradiction check" skills/synthesize/SKILL.md; then
  echo "  ✗ synthesize still instructs Run the contradiction check"
  FAIL=$((FAIL+1))
else
  echo "  ✓ synthesize no longer instructs Run the contradiction check"
  PASS=$((PASS+1))
fi

echo
echo "=== Discipline gates (v0.2.0 new) ==="
check "grill-question has disconfirmer gate" \
  skills/grill-question/SKILL.md \
  "[Dd]isconfirmer gate"
check "grill-question disconfirmer requires specific finding pattern" \
  skills/grill-question/SKILL.md \
  "specific finding pattern"
check "grill-question disconfirmer requires specific author/critic" \
  skills/grill-question/SKILL.md \
  "specific author or critique"
check "grill-question disconfirmer requires specific methodological challenge" \
  skills/grill-question/SKILL.md \
  "specific methodological challenge"
check "synthesize has three-tier sentence typing" \
  skills/synthesize/SKILL.md \
  "factual.*synthesis.*argument.*meta"
check "synthesize has voice authorship policy" \
  skills/synthesize/SKILL.md \
  "[Vv]oice authorship policy"
check "synthesize uses LLM-judged meta-detection (Haiku call)" \
  skills/synthesize/SKILL.md \
  "Haiku"
check "synthesize replaces substring is_meta() rules" \
  skills/synthesize/SKILL.md \
  "replaces.*v0\.1\.7 substring"

echo
echo "=== Connector probe upgrade ==="
check "using-scriptorium has Pass 1.5 description-keyword fallback" \
  skills/using-scriptorium/SKILL.md \
  "Pass 1\.5.*description"

echo
echo "=== Render skill (v0.2.0 new) ==="
if [ -f skills/render/SKILL.md ]; then
  check "render skill exists with frontmatter" \
    skills/render/SKILL.md \
    "^name: render"
  check "render skill produces click-to-source viewer" \
    skills/render/SKILL.md \
    "click-to-source"
else
  echo "  - render skill not yet created (deferred to v0.3.0)"
fi

echo
echo "=== Documentation ==="
check "CHANGELOG has v0.2.x entry" \
  CHANGELOG.md \
  "^## 0\.[23]\.[0-9]+"
check "CHANGELOG has migration notes from v0.1.x" \
  CHANGELOG.md \
  "Migrating from v0\.1"
check "TODO.md exists" \
  TODO.md \
  "Roadmap"
check "PROCESS.md exists" \
  PROCESS.md \
  "Plan-mode is the default"
check "README has at least one version callout" \
  README.md \
  "[Ww]hat's new in v0\.[0-9]+\.[0-9]+|[Nn]ew in v0\.[0-9]+\.[0-9]+"

echo
echo "=== Narration contract (v0.2.1) ==="
check "NARRATION.md exists with Annie test reference" \
  NARRATION.md \
  "Annie test"
check "NARRATION.md has vocabulary translation table" \
  NARRATION.md \
  "Vocabulary translation table"
check "NARRATION.md has cost budget" \
  NARRATION.md \
  "Cost budget"
for skill in audit contradictions extract grill-me grill-question publish render review scope screen search setup synthesize using-scriptorium; do
  check "$skill has User narration section" \
    "skills/$skill/SKILL.md" \
    "^## User narration"
done

echo
echo "=== Interactive choice contract (v0.2.2) ==="
check "NARRATION.md has Interactive choice contract" \
  NARRATION.md \
  "Interactive choice contract"
check "NARRATION.md mandates data-other escape hatch" \
  NARRATION.md \
  "data-other"
for skill in grill-me grill-question review scope publish render setup; do
  check "$skill has Interactive choices section" \
    "skills/$skill/SKILL.md" \
    "^## Interactive choices"
done

echo
echo "=== Always-research + mechanical cite-check (v0.3.0) ==="
check "grill-me exits all route through review" \
  skills/grill-me/SKILL.md \
  "every Scriptorium exit produces a literature-backed artifact"
check "review accepts output_intent dispatch" \
  skills/review/SKILL.md \
  "Output-intent dispatch"
check "synthesize invokes mechanical cite-check (v0.4.0: runtime/ path)" \
  skills/synthesize/SKILL.md \
  "runtime/cite-check\.py"
if [ -f runtime/cite-check.py ]; then
  echo "  ✓ runtime/cite-check.py exists"
  PASS=$((PASS+1))
else
  echo "  ✗ runtime/cite-check.py missing"
  FAIL=$((FAIL+1))
fi

echo
echo "=== v0.4.0 — comprehensive UX & discipline patch ==="

# R0 — cite-check regex accepts numeric paper_ids
check "cite-check.py regex accepts numeric paper_ids" \
  runtime/cite-check.py \
  "\[a-zA-Z0-9\]\[a-zA-Z0-9_"
if bash scripts/cite-check-test.sh >/dev/null 2>&1; then
  echo "  ✓ R0 cite-check fixture passes (pmid/openalex/consensus)"
  PASS=$((PASS+1))
else
  echo "  ✗ R0 cite-check fixture FAILS"
  FAIL=$((FAIL+1))
fi

# Revision A — runtime scripts moved out of scripts/
check "runtime/cite-check.py exists" runtime/cite-check.py "import argparse"
check "synthesize references runtime/cite-check.py" \
  skills/synthesize/SKILL.md "runtime/cite-check\.py"

# R1 — script-mode honestly documented
check "synthesize honestly documents script substring fallback" \
  skills/synthesize/SKILL.md \
  "[Mm]echanical .script. mode"
check "synthesize uses Haiku for borderline meta-vs-content" \
  skills/synthesize/SKILL.md \
  "Haiku.*borderline meta-vs-content"

# R3 — name leak removed
if grep -q 'Using `using-scriptorium`' skills/using-scriptorium/SKILL.md; then
  echo "  ✗ R3 — using-scriptorium name still leaks"
  FAIL=$((FAIL+1))
else
  echo "  ✓ R3 — name leak removed"
  PASS=$((PASS+1))
fi

# R4 — review Step 0 skip on grill handoff
check "review Step 0 skips on grill handoff" \
  skills/review/SKILL.md \
  "grill-me. or .grill-question. just handed off"

# R5 — progress artifact
check "review references scriptorium-progress artifact" \
  skills/review/SKILL.md \
  "scriptorium-progress"
check "review references mcp__cowork__update_artifact" \
  skills/review/SKILL.md \
  "mcp__cowork__update_artifact"

# R7 — vocab consolidated
if [ "$(wc -c < skills/grill-me/references/shared-vocabulary.md)" -lt 500 ]; then
  echo "  ✓ R7 — vocab consolidated"
  PASS=$((PASS+1))
else
  echo "  ✗ R7 — grill-me vocab still full size (drift risk)"
  FAIL=$((FAIL+1))
fi

# R8 — intent check in grill-question
check "grill-question has Intent check Step 0" \
  skills/grill-question/SKILL.md \
  "Intent check.*Step 0"

# R9 — disconfirmer example pills
check "disconfirmer Q5 has example-shape pills" \
  skills/grill-question/SKILL.md \
  "example-shape pills"
check "disconfirmer pills include specific published critic shape" \
  skills/grill-question/SKILL.md \
  "specific published critic"

# R10 — scope recap adapts to intent
check "scope has condensed recap shape" \
  skills/scope/SKILL.md \
  "Condensed recap"

# R11 — failure-state narration
check "NARRATION has failure-state section" \
  NARRATION.md \
  "Failure-state narration"

# R12 — review closing question per intent
for intent in chapter memo brief podcast teaching deck exploration; do
  check "review closing question for $intent" \
    skills/review/SKILL.md \
    "\`$intent\`"
done

# R13 — placeholder removed (count occurrences to avoid self-match;
# stale state had 2 lines: a check{} call AND its placeholder regex.
# Removed state has 1 line — only the audit comment in this block).
PLACEHOLDER_HITS=$(grep -cE 'synthesize does NOT instruct handoff' scripts/smoke-test.sh || true)
if [ "$PLACEHOLDER_HITS" -gt 1 ]; then
  echo "  ✗ R13 — stale placeholder check still present ($PLACEHOLDER_HITS hits)"
  FAIL=$((FAIL+1))
else
  echo "  ✓ R13 — stale placeholder check removed"
  PASS=$((PASS+1))
fi

# R14 — connector overrides persist
check "setup TOML has connector_overrides block" \
  skills/setup/SKILL.md \
  "scriptorium\.connector_overrides"

# R15 — no hard minute estimates in skill prose
if grep -qE '[0-9]+ ?(minute|min[^a-z])' skills/*/SKILL.md; then
  echo "  ✗ R15 — hard minute estimates remain in skill prose"
  FAIL=$((FAIL+1))
else
  echo "  ✓ R15 — minute estimates dropped"
  PASS=$((PASS+1))
fi
check "NARRATION has Timing language section" \
  NARRATION.md \
  "Timing language"

# R16 — pre-search query review (opt-in flag)
check "search has Step 2.5 query review" \
  skills/search/SKILL.md \
  "preview_queries"

# R17 — audit entries on grill phases
check "grill-me has Audit append section" \
  skills/grill-me/SKILL.md \
  "grill-me\.complete"
check "grill-question has Audit append section" \
  skills/grill-question/SKILL.md \
  "grill-question\.complete"

# R18 — fast-path routes
check "using-scriptorium has Skip-ahead routes" \
  skills/using-scriptorium/SKILL.md \
  "Skip-ahead routes"

# R19 — render shape per intent
check "render has Render mode by intent" \
  skills/render/SKILL.md \
  "Render mode by intent"

# R20 (v0.4.1) — render must translate [paper_id:locator] to APA inline format
check "render mandates citation translation" \
  skills/render/SKILL.md \
  "Citation translation — MANDATORY"
check "render warns about audit-grammar leaking into render" \
  skills/render/SKILL.md \
  "audit-trail grammar leaking"

# R21 (v0.4.1) — APA 7th edition is the canonical citation style
check "render specifies APA 7th edition" \
  skills/render/SKILL.md \
  "APA 7th edition"
check "render APA inline format uses comma between author and year" \
  skills/render/SKILL.md \
  "Smith, 2023"
check "render APA et al. format for 3+ authors" \
  skills/render/SKILL.md \
  "Li et al\., 2023"
check "render References section format" \
  skills/render/SKILL.md \
  "References-list format"

echo
echo "=== A1 (v0.5.0) — voice reconciliation: intent drives voice ==="

# A1.1 — synthesize voice table is keyed on intent, not output_intent
check "synthesize voice table keyed on intent" \
  skills/synthesize/SKILL.md \
  "voice is now keyed on .intent. directly"
check "synthesize 3-rule voice table present" \
  skills/synthesize/SKILL.md \
  "\`defending\` \| defending"
check "synthesize default-intent table per output_intent" \
  skills/synthesize/SKILL.md \
  "default-intent table"

# A1.2 — scope has unusual-combination soft warnings
check "scope warns chapter+curious" \
  skills/scope/SKILL.md \
  "Chapters usually defend a position"
check "scope warns memo+curious" \
  skills/scope/SKILL.md \
  "Memos usually carry a recommendation"
check "scope warns exploration+defending" \
  skills/scope/SKILL.md \
  "Exploration is for thinking out loud, not staking"
check "scope distinguishes intent_source user vs derived" \
  skills/scope/SKILL.md \
  'intent_source: "user" \| "derived"'

# A1.3 — grill-question carries intent_source field
check "grill-question sets intent_source field" \
  skills/grill-question/SKILL.md \
  "intent_source"
check "grill-question explicitly notes intent drives voice as of v0.5.0" \
  skills/grill-question/SKILL.md \
  "intent drives BOTH the disconfirmer gate AND the synthesize voice"

# A1.4 — grill-me derives intent on direct-to-review paths
check "grill-me sets intent in podcast handoff" \
  skills/grill-me/SKILL.md \
  "intent: curious, intent_source: derived"
check "grill-me sets intent in memo handoff" \
  skills/grill-me/SKILL.md \
  "intent: building, intent_source: derived"
check "grill-me sets intent in chapter handoff" \
  skills/grill-me/SKILL.md \
  "intent: defending, intent_source: derived"
check "grill-me documents intent derivation table" \
  skills/grill-me/SKILL.md \
  "Intent derivation .A1, v0.5.0"

echo
echo "=== v0.4.1 — render translation + APA + probe gap ==="

# R22 (v0.4.1) — runtime grep on rendered outputs for audit-grammar token leaks.
# If the outputs/ directory has rendered Markdown (memo, exploration, etc.),
# grep them for [paper_id:locator] patterns. Their presence is a release blocker.
echo "  [R22] runtime grep on rendered outputs:"
LEAKED_OUTPUTS=""
if compgen -G "/sessions/cool-vibrant-cori/mnt/outputs/scriptorium-memo-*.md" > /dev/null || \
   compgen -G "/sessions/cool-vibrant-cori/mnt/outputs/scriptorium-exploration-*.md" > /dev/null; then
  for f in /sessions/cool-vibrant-cori/mnt/outputs/scriptorium-memo-*.md \
           /sessions/cool-vibrant-cori/mnt/outputs/scriptorium-exploration-*.md; do
    [ -f "$f" ] || continue
    if grep -qE '\[[a-z][a-z0-9_\-]*:[a-zA-Z0-9_\-]+:[a-zA-Z0-9_\-]+\]' "$f"; then
      LEAKED_OUTPUTS="$LEAKED_OUTPUTS $f"
    fi
  done
  if [ -n "$LEAKED_OUTPUTS" ]; then
    echo "  ✗ R22 — audit-grammar tokens leaked into rendered output(s):$LEAKED_OUTPUTS"
    FAIL=$((FAIL+1))
  else
    echo "  ✓ R22 — no audit-grammar tokens in rendered outputs"
    PASS=$((PASS+1))
  fi
else
  echo "  - R22 skipped (no rendered outputs to scan in this run)"
fi
check "render mandates the runtime grep enforcement" \
  skills/render/SKILL.md \
  "Smoke test enforcement"

# R2 — output_intent end-to-end
for skill in scope synthesize review; do
  check "$skill consumes output_intent" \
    "skills/$skill/SKILL.md" \
    "output_intent"
done

echo
echo "=== Plugin manifest ==="
check "plugin.json version is 0.x.x" \
  .claude-plugin/plugin.json \
  "\"version\": \"0\.[0-9]+\.[0-9]+\""
check "marketplace.json version is 0.x.x" \
  .claude-plugin/marketplace.json \
  "\"version\": \"0\.[0-9]+\.[0-9]+\""

echo
echo "==========================="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "==========================="

if [ $FAIL -gt 0 ]; then
  echo "Static contract smoke test FAILED. Do not ship."
  exit 1
fi

echo "Static contract smoke test PASSED."
echo
echo "RUNTIME TEST (still required before public marketplace submission):"
echo "  1. Install the unpublished v0.2.0 .plugin in a fresh Cowork session"
echo "  2. Fire /scriptorium with a tiny defending-intent prompt:"
echo "       \"I'm testing v0.2.0. Help me grill out a chapter on caffeine and working memory.\""
echo "     Confirm: grill-question asks Q5 (\"what evidence would change your mind?\")"
echo "  3. Run /review on the resulting question with depth=scan, max 5 papers."
echo "     Confirm: audit log shows single synthesis.verify entry (no double-cycle)"
echo "  4. Open the click-to-source viewer artifact and confirm citations resolve to source quotes"
echo
