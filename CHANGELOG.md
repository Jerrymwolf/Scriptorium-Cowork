# Changelog

All notable changes to scriptorium-cowork are documented here.

## 0.5.1 — 2026-05-04

The README-readability patch. v0.5.0 shipped a README that read like internal release notes — four blockquotes of changelog jargon at the top, raw `[paper_id:locator]` syntax shown to users, internal terms like "PRISMA", "claim search", "evidence row" without translation, and skill names (`grill-me`, `grill-question`) in user-facing trigger phrases. v0.5.1 is purely a documentation fix.

### Changed
- **README.md rewritten for a researcher who's never used the plugin.** 247 → 183 lines. Jargon stripped:
  - Four blockquotes of release notes condensed to a single one-line plain-English note linking to CHANGELOG
  - `[paper_id:locator]` syntax replaced with example APA citations users will actually see
  - "PRISMA audit trail" → "paper trail your committee can audit"
  - "evidence-first claims" → "every empirical claim cites a real source"
  - "contradiction surfacing" → "disagreement is named, not averaged"
  - Skill names removed from trigger-phrase table; replaced with what the user actually says
  - The raw evidence-row JSON dump removed; replaced with three plain-English paragraphs about the draft, paper trail, and contradictions section
- **`scripts/smoke-test.sh` README check is now version-agnostic** (was hardcoded to `"New in v0.2.0"`; now matches any `v0.x.y` callout). Prevents this whole class of drift on future README rewrites.

### Migrating from v0.5.0
- No behavior changes. Pure docs + test-harness improvement. Re-install the v0.5.1 `.plugin` if you want the friendlier README in your installed copy; otherwise keep using v0.5.0 without functional difference.

## 0.5.0 — 2026-05-04

The voice-reconciliation release. Closes the v0.4.x incoherence where the disconfirmer gate (intent-keyed) and the synthesize voice authorship policy (output_intent-keyed) could disagree — e.g., `intent: defending + output_intent: memo` would fire the gate but write in building voice. v0.5.0 puts both halves of the defending-position discipline under the same control.

### A1 — Voice keys on intent (the discipline-coherence fix)

- **Voice authorship policy now keys on `intent`, not `output_intent`.** Three rules instead of seven:
  - `intent: defending` → defending voice (system surfaces synthesis only)
  - `intent: building` → building voice (system suggests argument as drafts)
  - `intent: curious` → curious voice (system may author argument with interpretation tag)
- **Default-intent table per `output_intent`** preserves v0.4.x behavior for users who never see the intent question. chapter/brief default to defending; memo/teaching/deck default to building; podcast/exploration default to curious. The default fires when `grill-question` doesn't run.
- **Disconfirmer gate (R8) and voice now both key on `intent`** — the two halves of defending-position discipline are internally coherent. No more memo-with-defended-position-but-building-voice contradictions.
- **`intent_source` field** added to handoff state: `"user"` (user picked explicitly via `grill-question` Step 0 cold-start) vs. `"derived"` (set by default table because grill-question didn't fire). Used by scope to decide whether to surface unusual-combination warnings.
- **Soft warnings for unusual `intent` × `output_intent` combinations** added to scope's Step 4 scan. Non-blocking; surfaced in the recap so the user can confirm or revise:
  - chapter + curious → "Chapters usually defend a position. Confirm?"
  - memo + curious → "Memos usually carry a recommendation. Want exploration mode?"
  - exploration + defending → "Exploration is for thinking out loud, not staking positions. Want chapter?"
  - exploration + building → "Want memo or brief instead?"
  - podcast + defending → "Defended-position podcasts are rare — confirm?"
  - deck + curious / deck + defending → "Decks usually carry a recommendation. Confirm?"
  Warnings only fire when `intent_source: "user"` — derived defaults don't trigger warnings the user never asked for.

### Why this matters in user terms

In v0.4.x, picking `intent: building` for a dissertation chapter had no visible effect on the rendered output — voice still resolved to defending per output_intent. The form widget was theater. v0.5.0 makes the user's intent pick actually drive how the system writes. Defended memo gets defending voice. Building chapter gets building voice. The form means what it says.

### Migrating from v0.4.1

- **No state changes.** Existing scopes and configs work unchanged.
- **No v0.4.x re-renders required** — for users who never hit `grill-question`'s cold-start path, voice resolves identically (per the default-intent table). Behavior change only affects users who explicitly picked an intent that disagreed with their output_intent.
- **Audit log additivity:** `details.intent_source` is now recorded on direction-phase entries. Existing readers continue to work; the new key is additive.

### Files touched

- `skills/synthesize/SKILL.md` — voice table replaced (output_intent-keyed → intent-keyed); default-intent table added
- `skills/scope/SKILL.md` — Step 4 soft-warning scan extended with 7 unusual-combination warnings
- `skills/grill-question/SKILL.md` — Step 0 prose updated; sets `intent_source: "user"` on cold-start, `"derived"` on handoff
- `skills/grill-me/SKILL.md` — exit table sets explicit `intent` and `intent_source: "derived"` on every direct-to-review path
- `scripts/smoke-test.sh` — 12 new A1 contract checks
- `CHANGELOG.md`, `README.md`, `TODO.md` — version notes
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — version bump

## 0.4.1 — 2026-05-04

The render-correctness patch. v0.4.0's memo trace shipped with raw audit-grammar tokens (`[consensus:9b8a4808...:abstract]`) visible in the rendered output — exactly the failure mode `NARRATION.md` line 31 prohibits. This release fixes that and locks in APA 7th edition as the canonical citation style.

### Render layer
- **R20**: render skill mandates explicit translation of `[paper_id:locator]` synthesis-grammar tokens to user-facing citations before any rendered artifact ships. Spec'd algorithm, named the failure mode (audit-grammar leaking into render), added smoke-test enforcement. The synthesis grammar is preserved only in the audit log and the click-to-source viewer's data attributes — never in body text.
- **R21**: APA 7th edition is the canonical citation style. Inline format: `(Author, Year)` for single, `(Smith & Jones, 2023)` for two, `(Li et al., 2023)` for 3+ from first cite. Multiple-paper inline: semicolon-separated, alphabetized. Narrative form: `Author (Year) finds…`. References-list format: alphabetized, italicized journal names, sentence-case article titles. Alternative styles (Chicago, MLA, IEEE, Vancouver) are tracked as v0.5.0+ candidates behind a config flag.
- **R22**: `scripts/smoke-test.sh` now greps every rendered Markdown artifact in outputs for unexpanded `[paper_id:locator]` tokens. Their presence is a release blocker. Catches the v0.4.0 failure structurally.

### Probe robustness
- **Probe gap fix**: the `~~breadth search` keyword set now includes `"semantic scholar"` (with a space) alongside the no-space, underscore, and hyphen variants. The v0.4.0 memo trace surfaced two real Cowork tools whose descriptions used the human-readable spacing that the v0.4.0 keyword set didn't catch. Lesson encoded in skill prose: keyword sets must include human-readable forms alongside API/identifier forms.

### Discipline clarity
- **`<arg>` enforcement scope**: synthesize prose now states explicitly that the mechanical script (`runtime/cite-check.py`) does NOT enforce per-tier rules (factual / synthesis / argument). Per-tier discipline requires Haiku-judged classification and runs in inline mode only. The script's job is the floor: every cited token resolves, total citations meet the floor, no inferred metadata in strict mode. v0.4.0 prose was ambiguous on this; v0.4.1 names the boundary clearly.

### Migrating from v0.4.0
- **No state changes.** All v0.4.0 artifacts and configs work unchanged.
- **Render output format change**: any user-facing rendered Markdown that previously contained literal `[paper_id:locator]` tokens (a v0.4.0 bug, not a feature) now contains APA-formatted parenthetical citations. Re-render any v0.4.0 memos with `/render` for the corrected output.
- **Citation style is APA 7th edition by default** — the citation-style config key lands in v0.5.0+; for now, v0.4.1 ships APA, full stop.

## 0.4.0 — 2026-05-04

The comprehensive UX & discipline patch. Closes the v0.3.0 gaps surfaced by cold-walk audit: the cite-check script silently dropped every PMID-style citation; `output_intent` was set in grill-me but only partly consumed downstream; the connector probe leaked the skill's own name on first turn; review re-asked direction even when grill-me had handed off; the Cowork-only cite-check fallback was under-specified; long pipelines went silent without a glanceable progress indicator; the end-of-pipeline closing was hardcoded for chapter shape; the disconfirmer gate had no real trigger; vocabulary files were duplicated across grill skills.

### P0 fix: cite-check on biomed corpora
- **R0**: `runtime/cite-check.py` regex now accepts numeric-prefix `paper_id`s (was `[a-zA-Z]…`, rejected every `pmid:38920760` token). Test fixture covers pmid / openalex / consensus shapes; smoke test invokes it.

### Packaging fix: cite-check.py actually ships
- **Revision A**: runtime helper scripts moved from `scripts/` to a new top-level `runtime/` directory. Previously, `scripts/*` was excluded from the `.plugin` build but skills referenced `scripts/cite-check.py` — meaning the cite-check script the v0.3.0 release-note promised was never in the shipped artifact. Skill prose now references `runtime/cite-check.py` and `runtime/build-viewer.py`. Dev-only scripts (release.sh, validate-plugin.js, smoke-test.sh) stay in `scripts/`.

### `output_intent` end-to-end (R2, R10, R12, R19)
- `scope` reads `output_intent` from grill handoff and auto-calibrates `corpus_target`, `year_range`, `publication_types`, `depth` from a per-intent table. Explicit user overrides win.
- `synthesize` voice authorship policy now keys directly on `output_intent` (chapter/brief → defending; memo/teaching/deck → building; podcast/exploration → curious). Closes the v0.3.0 misalignment where memo could land in either building or defending depending on grill-me wording.
- `review`'s closing question adapts: chapter → "podcast version, slides?", memo → "Slack-ready, one-pager?", podcast → "ship to NotebookLM?", etc. Seven intent-keyed variants.
- `render` mode adapts: chapter/brief/teaching → click-to-source HTML viewer; memo/exploration → 1-page Markdown + viewer; podcast/deck → NotebookLM bundle + viewer.
- `scope` recap shape adapts: chapter/brief/teaching/deck → full dissertation-style table; memo/podcast/exploration → 4-line condensed recap (drops year_range, methodology, publication_types since they're auto-calibrated).

### Pipeline orchestration
- **R4**: `review` Step 0 (direction check) now skips when grill-me/grill-question handoff state is in context. Closes the v0.3.0 redundancy where direction was asked twice.
- **R5**: `scriptorium-progress-<slug>` Cowork artifact updates at every phase boundary. 7-step progress card with `pending` / `active` / `done` / `errored` states, glanceable status independent of narration cadence. Wires up existing infra (Cowork artifacts), not a new feature.
- **R15**: dropped hard wall-clock estimates ("12–20 minutes", "about 2 minutes") from skill narration. Replaced with relative phrases per `NARRATION.md` §Timing language. Real Cowork latency varies; estimates were aspirational.
- **R16** (hypothesis, opt-in): `search` Step 2.5 shows constructed queries for review before firing, behind `[scriptorium] preview_queries = false` flag. Default off pending Annie-test feedback. Flagged for v0.5.0 reassessment.

### Discipline (script + prose)
- **R1**: `is_meta()` substring rules in `runtime/cite-check.py` now honestly documented in synthesize prose as "mechanical script mode" alongside Haiku-judged inline mode. Closes prose/code contradiction (smoke test verified both claims passed; in v0.3.0, the script reintroduced the very rules the prose said were replaced).
- **R6**: synthesize Cowork-only fallback gets explicit per-sentence walk algorithm with same outputs as the Python script. Substring vs. Haiku difference matters only for borderline list-item-shaped empirical sentences.

### Grill flow
- **R8**: `grill-question` gets Intent check Step 0 (read intent from grill-me handoff or elicit cold-start as form widget with curious / building / defending pills + data-other). Disconfirmer gate (Q5) now reliably triggers — fires only when `intent: defending`. Closes v0.3.0 gap where the gate's trigger condition was never resolved.
- **R9**: disconfirmer Q5 form gets four example-shape pills modeling the specificity bar; clicking a pill reveals a pre-framed textarea. Users no longer face a bare textarea with no anchor for what specificity looks like.

### Single source of truth + state
- **R7**: `shared-vocabulary.md` consolidated. `skills/grill-me/references/shared-vocabulary.md` is now a one-line pointer to `skills/grill-question/references/shared-vocabulary.md`. Validator addition catches drift.
- **R14**: connector overrides now persist across sessions in `scriptorium-config`'s `[scriptorium.connector_overrides]` block. Stale overrides (saved tool no longer connected) emit `connector.override.stale` audit entry and fall back to probe.
- **R17**: `grill-me` and `grill-question` now append audit entries on completion (`direction.grill-me.complete` / `direction.grill-question.complete`). Every phase entry's `details` block now includes `output_intent` — additive wire-format change; existing audit-trail readers keep working.

### Narration & escape hatches
- **R3**: dropped "Using `using-scriptorium` to route this session" line from first-turn checklist — it directly violated `NARRATION.md`'s prohibition on raw skill names in chat. Probe now runs silently.
- **R11**: `NARRATION.md` gets §Failure-state narration with canonical template (plain-language phase name + one-sentence diagnosis + one-sentence consequence + retry/override/stop options) plus three filled examples.
- **R18**: `using-scriptorium` documents Skip-ahead routes for power users — "I have a corpus, just extract", "Re-run the cite-check", "Just publish what I have", "Re-render the viewer", etc. Each route checks preconditions and surfaces gaps in plain language rather than silently falling through.

### Cleanup
- **R13**: removed stale smoke-test placeholder (`scripts/smoke-test.sh` line 36–37 placeholder regex that was annotated "the real check is below"). The real check is the only check.
- Smoke-test version regex generalized from `0\.[23]\.[0-9]+` to `0\.[0-9]+\.[0-9]+` — permanent strategy that doesn't drift on every minor bump.

### Migrating from v0.3.0
- **No breaking state changes.** `scriptorium-config` TOML gains optional `[scriptorium.connector_overrides]` and `preview_queries` keys; existing configs work unchanged.
- **Audit log wire format**: every phase entry's `details` now includes `output_intent`. Additive — existing keys unchanged. If you have downstream tooling that asserts `details` keys, allowlist the new key.
- **Script paths**: skills now reference `runtime/cite-check.py` and `runtime/build-viewer.py`. If you have downstream tooling that invoked `scripts/cite-check.py`, update the path.
- **Default `output_intent`** for legacy v0.3.0 sessions where intent isn't set: chapter (the safest, most rigorous calibration).

## 0.3.0 — 2026-05-04

The discipline-enforcement release. Closes the v0.2.2 failure mode where a "strategy memo" intent silently fell through to vibe-mode prose with zero citations and fabricated heuristics.

### Architectural change: every Scriptorium exit now produces a literature-backed artifact
- **`grill-me` exits rewritten.** Every user intent now routes through `review` with calibrated `{output_intent, depth}` parameters. No exit silently falls through to a non-existent skill or to "no skill — journal it." Casual consumption → review with `podcast` intent. Strategic decision → review with `memo` intent. Just-thinking → review with `exploration` intent and a small lit scan. Even 5-minute curiosity sessions now run a 5–10 paper search.
- **`review` accepts `output_intent` dispatch.** New table maps `chapter / memo / brief / podcast / teaching / exploration / deck` to corpus_target, synthesis length, voice, and final artifact format. The pipeline is the same; the calibration changes.

### Added: mechanical cite-check enforcement
- **`scripts/cite-check.py`** — Python script that walks a synthesis, classifies sentences, and exits non-zero on:
  - Total citation count below the floor for the output_intent (10 for chapter, 3 for memo, etc.)
  - Any `[paper:loc]` token that doesn't resolve to an evidence row
  - Any cited paper with `metadata_resolution: inferred` in strict mode
- **`synthesize` SKILL.md mandates the script as the final hard gate.** The cite-check is no longer purely operator-trust. The script catches the v0.2.2 failure mode (synthesis with zero citations) automatically — exit 1 means do not ship.

### Fixed
- **No more silent fall-through to vibe-mode.** The strategy-memo intent that produced a zero-citation, fabricated-heuristics memo in v0.2.2 now routes through the full review pipeline with `memo` calibration: 10–15 paper scan, ~800-word synthesis with strategic-recommendation framing, every claim cited.

### What changes for users
You can ask Scriptorium for a quick podcast on a topic you're curious about, or a strategy memo, or a teaching artifact, or a dissertation chapter — and every one of those will produce an artifact backed by real literature, with click-to-source citations. The depth scales (5 papers for curious, 200+ for exhaustive); the discipline doesn't.

### Migration from v0.2.x
- Existing v0.2.x reviews don't need to change.
- New runs with intents that didn't previously route cleanly (memo, podcast, teaching, exploration) now get full pipeline treatment instead of bare prose.

## 0.2.2 — 2026-05-03

UX patch — interactive choice forms. Closes follow-on feedback from a v0.2.1 grill-me test: multi-choice questions were rendered as bulleted prose that the user had to type a reply to, when they should have been clickable forms with a "type something different" escape.

### Fixed
- **Every multi-choice question in the grill, scope, review, publish, render, and setup skills now fires a clickable form widget**, never a bulleted text question. Click is the right interaction; type is the escape hatch.
- **Every form includes a "type something different" option** (`data-other` escape hatch). Users are never locked into the system's option set.

### Added
- **`NARRATION.md` §Interactive choice contract** — the mandate. Pattern reference, when-to-fire/when-not-to-fire rules, list of skills with choice points.
- **Smoke-test contract checks** — release-blocker if any choice-point skill is missing the Interactive choices section, or if `NARRATION.md` lacks the contract or the `data-other` requirement.

### What changes for users
The grill no longer feels like an interview where you have to type "purpose: strategy memo" back at the AI. Click the option that fits, or click "something different" and type your own. Same for every other choice in the pipeline — depth, audience, render target, retry-vs-override.

## 0.2.1 — 2026-05-03

UX patch — narration. Closes feedback (from the only user who has tried it: Annie) that the messages between queries were confusing and that the entire process should be narrated so anyone could understand. Pure prose work; no architectural changes.

### Fixed
- **Plain-language narration during long operations.** Every skill now follows a `User narration` contract: before any operation, write what's happening in plain language; during, emit periodic updates; after, summarize in one human sentence. Internal vocabulary (corpus, evidence row, disconfirmer, locator, cite-check, etc.) is translated on first use per `NARRATION.md`.
- **Search and synthesize phases — the worst silent periods — now narrate continuously.** Users can tell what the system is doing without re-reading or guessing. No more raw tool-call output bleeding into chat.
- **Connector probe results are translated.** `~~claim search` becomes "a peer-reviewed paper search"; users no longer see internal `~~category` placeholders.
- **Front-door grilling translates the question into the user's language.** The disconfirmer, tradition, boundaries, and tier-3 fields no longer appear as raw field-name jargon; the grill asks conversationally and recaps in the user's own words.

### Added
- **`NARRATION.md`** — the style guide every skill follows. Vocabulary translation table, narration rhythm, cost budget, the Annie test (operationalized as a 5-question reader-comprehension check).
- **Smoke-test contract checks for narration.** All 14 skills must reference a `User narration` section; `NARRATION.md` must contain the Annie test, vocabulary table, and cost budget. Release-blocker.

### What changes for users
The same pipeline runs the same way; what's different is what you see while it's happening. You'll always know what's going on, what's coming next, and roughly how long it'll take. Internal Scriptorium vocabulary stays internal — chat reads like a person walking you through the work, not a build log.

## 0.2.0 — 2026-05-02

The discipline-gates release. Tightens the front-door grilling, the synthesis cite-check, and the connector probe. Demos a click-to-source viewer as a Cowork artifact.

### Three discipline gates (new)
- **Disconfirmer gate in `grill-question`.** For users defending a position (dissertation, peer-reviewed paper, thesis), the grill now requires a named falsification target — *"if I'm doing my job, I should be looking for things that could push back on your view; what's the most credible challenge?"* Generic answers ("any counter-evidence") get one reflective re-ask; specific answers (a finding pattern, a published critic, a methodological objection) pass and drive downstream search/synthesize/contradiction phases. Curious and building intents skip the gate.
- **Three-tier sentence typing in `synthesize`.** Sentences are now classified as factual (cites one paper at a locator with a verbatim quote), synthesis (chains ≥2 quote-anchored evidence rows), argument (the author's interpretive position; tagged visibly), or meta (heading/transition). Cite-check applies different rules per tier. The argument layer is user-authored by default for `defending` intent; system-authored only for `curious` (with an "interpretation" marker).
- **LLM-judged meta-detection.** Replaces the v0.1.7 substring `is_meta()` rules. Cite-check now uses Cowork's Haiku shortcut to classify uncited sentences semantically — no more hand-tuning string patterns to recognize legitimate author-voice transitions.

### Connector probe upgrade
- **Description-keyword fallback (Pass 1.5).** When a tool's name doesn't match any keyword set (typically UUID-registered tools), the probe now reads its MCP description for the same keywords. Real impact: `mcp__abc123__search_articles` with a description containing "PubMed" auto-resolves to `~~biomed search` without forcing manual override.

### UX — click-to-source viewer (now a real skill)
- **New `render` skill.** `skills/render/SKILL.md` produces a click-to-source HTML viewer for any synthesis from its corpus + evidence + synthesis.md triple. Hard precondition: synthesis cite-check must have passed. Output is a Cowork artifact (`scriptorium-viewer-<review-slug>`) that opens in the sidebar — every citation is clickable; the side panel shows the paper title, venue, DOI, evidence-row metadata (tier, direction, concept), the verbatim supporting quote, and a one-click link to the source.
- **New `scripts/build-viewer.py`.** Reference builder that the `render` skill invokes (or re-implements inline if the user is in a Cowork-only environment). Takes `--synthesis`, `--corpus`, `--evidence`, `--out` and emits a self-contained HTML file.

### Folded in from v0.1.8
- Workflow fix: `synthesize` and `contradictions` no longer race; `review` owns the contradictions phase, `synthesize` asks before firing inline when invoked directly.
- Validator: `scripts/validate-plugin.js` runs at release time. Wired into `release.sh`. Removed the redundant description-length-only check.
- CLAUDE.md: corrected skill count, replaced manual zip command with release-script reference, added Post-release verification + Rollback sections.
- CHANGELOG: v0.1.5 and v0.1.6 annotated as internal milestones (never released to GitHub).

### Migrating from v0.1.x
- **Cite-check is stricter for synthesis sentences.** Before v0.2.0, any cited sentence passed if it had at least one resolving `[paper:loc]` token. v0.2.0 distinguishes factual sentences (one cite) from synthesis sentences (≥2 cites required). If a v0.1.x synthesis fails the v0.2.0 cite-check, the most likely cause is synthesis sentences with only one citation — re-run `synthesize` to re-classify and re-cite, or add the second supporting citation manually.
- **Argument sentences now require visible tagging.** Inline interpretive claims must be wrapped in `<arg>...</arg>` in source markdown or rendered with an "*interpretation*" marker in HTML. Untagged argument sentences will be flagged.
- **`/synthesize` direct invocation now asks before firing `/contradictions`.** Pipeline behavior under `/review` is unchanged.

### What changes for users
- **`/grill-question` users:** when defending a position, you'll be asked to name what would change your mind. This is the Pocock-style discipline — uncomfortable on first encounter, indispensable by the third dissertation chapter.
- **`/synthesize` users:** factual / synthesis / argument distinction is now visible in the cite-check report. Author-voice synthesis no longer gets stripped as "unsupported."
- **All users:** the click-to-source viewer is available as a Cowork artifact for any synthesis you produce. Open any citation; see the source.

### Out of scope, deferred to v0.3.0 / v1.0.0
- Loop-mode `open` orchestrator and `refine` skill (with verbs: drop, expand, regenerate, pin, fork, diff) — the loop-mode UX (v1.0.0)
- Forkable domain grills (`grill-question-medical`, `grill-question-policy`) (v1.0.0)
- Multi-target render expansion (direct-to-Word, direct-to-Notion without NotebookLM detour) (v0.3.0)
- README rewrite for the dual-mode positioning (v1.0.0)

## 0.1.8 — 2026-05-02

Bug fix and release-pipeline hardening.

### Fixed
- **synthesize/contradictions workflow conflict.** `synthesize`'s Step 4 told the model to fire `contradictions` before the cite-check; `review`'s Phase 6 told the model `contradictions` runs as a separate pass after synthesis. Two skills disagreeing on workflow produced inconsistent behavior depending on which entry point the user used. Fix: `synthesize` is now responsible only for drafting and the cite-check; `review` owns the contradictions phase. When invoked directly, `synthesize` asks the user whether to run `contradictions` next rather than firing it inline.

### Added
- **`scripts/validate-plugin.js`** — Node-based release-time validator. Checks manifest validity, version consistency across `plugin.json` and `marketplace.json`, plugin.json description length (≤256, Cowork's cap), skill count (13), frontmatter integrity, stale renamed-skill references, the synthesize/contradictions workflow contract, and packaged-plugin shape (no developer-only files leak into the `.plugin`). `scripts/release.sh` now runs it automatically before tagging; the redundant description-length check inside the release script was removed.

### Cleaned
- CLAUDE.md updated: skill count corrected from "eleven" to "thirteen"; stale hand-rolled zip command replaced with `./scripts/release.sh <version>` plus `node scripts/validate-plugin.js`.
- CHANGELOG: v0.1.5 and v0.1.6 entries annotated as internal milestones (never released to GitHub; bundled into v0.1.7) so users browsing the CHANGELOG don't try to install non-existent versions.

## 0.1.7 — 2026-04-30

Comprehensive skill rename — drops verbose prefixes (`lit-*`, `research-*`, `running-*`, `setting-up-*`) so the slash menu shows clean short verbs instead of long-named auto-surfaced skills.

### Changed
- **Twelve skills renamed.** Cowork surfaces every skill's `name:` field as a slash command in the menu, alongside any explicit command files. The v0.1.6 plugin had eleven long-named skills (`/lit-scoping`, `/lit-searching`, `/running-lit-review`, `/setting-up-scriptorium`, `/research-grill-me`, etc.) cluttering the menu next to the three short commands. Renames:

  | Old | New |
  |---|---|
  | `setting-up-scriptorium` | `setup` |
  | `running-lit-review` | `review` |
  | `lit-scoping` | `scope` |
  | `lit-searching` | `search` |
  | `lit-screening` | `screen` |
  | `lit-extracting` | `extract` |
  | `lit-synthesizing` | `synthesize` |
  | `lit-contradiction-check` | `contradictions` |
  | `lit-audit-trail` | `audit` |
  | `lit-publishing` | `publish` |
  | `research-grill-me` | `grill-me` |
  | `research-questions-grill-me` | `grill-question` |

  `using-scriptorium` (the router) was kept as-is — it fires automatically on session start and isn't a user-facing slash invocation.

- **Removed `commands/` directory.** v0.1.6's `/grill`, `/review`, `/publish` command wrappers are now redundant — the underlying skills have those exact names. Three fewer files; one fewer surface area; no duplicate slash menu entries.

- **Cross-references updated everywhere.** Every skill's prose, the README, and CHANGELOG entries that named skills now use the new names. Verified by grep — zero orphan references to old names remain. Skill graph reachability test passes: all 13 skills resolve from the five entry points.

- **`using-scriptorium` frontmatter description** updated to enumerate the new skill names rather than reference the dropped `lit-*` glob.

### Migration
Existing reviews continue to work — skill names appear in user-memory notes only as informational labels, not as references the runtime resolves. New reviews use the new names everywhere. If you upgrade from v0.1.6 to v0.1.7 mid-review, expect the next skill to fire under its short name (e.g., `synthesize` instead of `lit-synthesizing`); behavior is identical.

## 0.1.6 — 2026-04-30

> **Note:** This version was an internal milestone, never released to GitHub. All v0.1.5 and v0.1.6 changes shipped publicly as part of v0.1.7. The git tag (if any) is preserved for development history.

Slash commands plus second-pass fix on `grill-me`.

### Added — slash commands (three-command MVP)
- **`/grill [topic]`** — fires `grill-me`. Direction interview about what you want from a topic.
- **`/review [research question]`** — fires `review`. Full pipeline; the orchestrator's Step 0 routes to grill-me first if you don't have a question yet.
- **`/publish [artifact type]`** — fires `publish`. Pushes the finished review to NotebookLM for podcast / deck / mindmap / video.

Three commands, not all twelve possible — daily-use commands only. Mid-pipeline operations (`/scope`, `/extract`, `/synthesis`, etc.) stay natural-language-only for now; can add in v0.1.7+ if power users ask. Slash commands and natural-language triggers coexist; whichever fires first wins, and the underlying skills are identical either way.

### Fixed — `grill-me` second pass
- **Frontmatter description** rewritten to surface the direction-vs-content distinction explicitly, including the negative-case clause: *"Do NOT fire when the user wants to learn the topic itself; fire when they want to figure out what to do with it."* This puts the anti-pattern in the skill matcher's decision context rather than only in the skill body. v0.1.5 fixed the body; v0.1.6 fixes the routing.
- **README example transcript** updated to model the right entry phrasing — *"I'm thinking about caffeine and working memory but I'm not sure what I want from it yet"* — replacing the v0.1.4 phrasing *"I want to read up on caffeine and working memory"* (which leaned consume-shaped and biased the bot's response).
- **README trigger-phrase table** drops *"grill me on this topic"* from the recommended phrasing — that's the linguistic trap that caused the v0.1.4 content-grilling bug. Better triggers now lead: *"I have a topic but don't know what I want from it"* and *"help me figure out what to do with this idea"*.
- **Acknowledgment-permitted clause** added to the failure-modes section so the model doesn't over-correct: a warm one-line acknowledgment of the topic name (*"I see you're interested in [topic]. Let me help you figure out what you want to do with it."*) is allowed; what's not allowed is asking the user *about* the topic's content.

## 0.1.5 — 2026-04-30

> **Note:** This version was an internal milestone, never released to GitHub. All v0.1.5 and v0.1.6 changes shipped publicly as part of v0.1.7. The git tag (if any) is preserved for development history.

Real-world bug fix from the first install test.

### Fixed
- **`grill-me` was content-grilling instead of direction-grilling.** The skill was asking users questions about the topic itself (*"what aspects interest you?"*, *"what have you read?"*, *"what's your current understanding?"*) rather than questions about what they want from engaging with the topic (purpose, audience, artifact, depth). Two design issues in the v0.1.4 skill prose set this trap: the role was "Oxford tutor" (a metaphor that connotes content-grilling — Oxford tutors test students on subject knowledge), and the skill listed what to resolve but never said what NOT to ask.
- **Fix:** rewrote the skill with (a) the role reframed as "research-direction coach" rather than tutor, (b) an explicit anti-pattern block at the top with three concrete *don't-ask-this* examples and three *do-ask-this* examples, (c) a new failure mode named *"Topic-grilling"* with a self-check rule: *"if you catch yourself asking the user about the topic's content rather than their relationship to it, restart with a purpose question."*

## 0.1.4 — 2026-04-30

Re-ship of v0.1.3 with an install-blocking fix. v0.1.3 shipped a `plugin.json` whose `description` field was 517 characters, which Cowork's marketplace validator rejects (cap is ~256). The artifact attached to the v0.1.3 GitHub release is non-installable; use v0.1.4 instead.

### Fixed (install-blocking)
- `plugin.json` description trimmed from 517 → 229 characters so the manifest passes Cowork validation.
- `scripts/release.sh` now validates the built `.plugin`'s `plugin.json` description length at build time (refuses to release if > 256). Same check added to `.github/workflows/release.yml`.
- Release tooling now defensively excludes `marketplace.json`, `scripts/`, and `.github/` from the `.plugin` distribution. (These belong in the repo, not in the artifact dragged into Cowork chat.)

### Content
- All v0.1.3 features ship unchanged (evidence tiers, metadata resolution, two-stage contradictions, doctoral-workflow README, grill-me skills). See the v0.1.3 section below for the full list.

## 0.1.3 — 2026-04-30 — ⚠️ SUPERSEDED BY v0.1.4

> The v0.1.3 GitHub Release was deleted because its `.plugin` artifact is non-installable (517-char `description` exceeds Cowork's ~256 cap). The git tag is preserved for history. Use **v0.1.4**, which ships identical features with the manifest fix.

Three audit fixes that strengthen synthesis defensibility — evidence tiers in the schema, metadata-resolution-aware cite-check, and a same-question filter on contradictions.

### Added — evidence tier (Concern 1)
- New optional field on `EvidenceEntry`: `evidence_tier ∈ {meta_analysis, systematic_review, experimental, observational, cross_sectional, qualitative, theoretical_or_review}`. Set during extraction.
- `extract` now includes a "Tagging the design tier" step that walks the model through which tier applies to a given claim, allowing different tiers per row from the same paper when methods sections mix designs.
- `synthesize` Step 1 now modulates prose register by tier — meta-analyses produce declarative prose, RCTs produce qualified prose, cross-sectional studies produce correlational prose, etc. The tier name is named *explicitly in prose* (e.g., "a meta-analysis of fourteen trials shows…") so it survives the markdown→audio handoff to NotebookLM. The host model has no metadata channel; the prose is the channel.
- Custom seven-tier scheme rather than GRADE / OCEBM / Cochrane, justified by the social-science / management / EdD/DBA target audience.

### Added — metadata resolution (Concern 2)
- New required field on `Paper`: `metadata_resolution ∈ {verified, partial, inferred}`. Set during search; propagates to `EvidenceEntry` at extraction.
- `search` now includes assignment rules: `verified` requires DOI/PMID resolution or exact title+authors+year match; `partial` allows gap-filling from a related record; `inferred` covers any field constructed from prose context rather than a verified API response.
- `synthesize` cite-check (Step 5) is now a **two-part check**: claim-to-evidence linkage AND citation metadata resolution. Strict mode blocks commit (`status: failure`) on **any** inferred citation — the threshold is binary, not probabilistic, because the README's "synthesis you can defend" promise can't tolerate guessed bibliographic data in a dissertation chapter.
- New cite-check report format surfaces verified/partial/inferred counts with explicit warning glyphs.
- Audit row gains `n_metadata_verified / n_metadata_partial / n_metadata_inferred`.

### Changed — contradiction check (Concern 3)
- `contradictions` now runs a **two-stage check**. Stage 1 gathers direction-mismatch candidates as before. Stage 2 asks the model whether each candidate pair is answering the same question (same construct, population, timeframe, operationalization) — three-way output: `same_question` / `different_questions` / `uncertain`.
- Three rendering templates replace the single named-camps template: same-question disagreements get the original camps framing; different-questions findings get a new "Findings vary across…" section that explicitly says they could both be true simultaneously; `uncertain` cases get flagged for human review rather than confidently mis-framed.
- The `uncertain` bucket is the load-bearing piece — it makes the skill honest about the slug-fragility problem (informally-assigned `concept` slugs don't guarantee same-construct measurement). Better to flag five items for the user than to confidently mis-frame two.
- Synthesis now renders contradictions under three separate headings instead of one: *"Where authors disagree on the same question"*, *"Where findings vary across populations / timeframes / operationalizations"*, *"Disagreements I couldn't classify."*
- Audit row bifurcates: `n_candidates / n_same_question / n_different_questions / n_uncertain`.

### Repositioned (README, plugin metadata)
- **README lead and hero rewritten** to position Scriptorium as a research-direction-and-literature-review tool for graduate students and doctoral researchers — *"from a half-formed research idea to a defensible direction, with the literature to back it up"* — rather than as "lit review with podcast." The canonical doctoral workflow (idea → grill → research question → lit review → defensible synthesis) is the lead use case. The NotebookLM podcast / Studio artifacts are now framed as a downstream "neat function" — a real value-add and worth highlighting, but the convenience output of the workflow, not the workflow itself.
- **"Three patterns that work"** expanded to four and reordered: doctoral workflow first, get-unstuck-on-vague-interest second, hand-draft-and-tape-to-committee third, get-smart-fast-for-meeting fourth.
- **`plugin.json` and `marketplace.json` descriptions** updated to lead with the grad-student / doctoral-researcher audience and the idea-to-question-to-review pipeline. The directory submission text now matches what the tool actually does best.

### Fixed (install-blocking)
- **`plugin.json` description length cap.** Cowork's validator silently rejects `.plugin` files when `plugin.json`'s `description` field exceeds ~256 characters. The v0.1.3 description (517 chars) tripped this and caused install to fail with an opaque "Plugin validation failed" message. Trimmed to 245 chars; the longer marketing prose lives in the README and the GitHub repo About field where there is no such cap. Both `scripts/release.sh` and `.github/workflows/release.yml` now check description length at build time and refuse to build a non-installable artifact.
- **`marketplace.json` excluded from the `.plugin` distribution.** The marketplace manifest belongs in the GitHub repo for the `/plugin marketplace add` install path; including it inside the `.plugin` file is redundant. The release tooling now excludes it by default.

### Migration
None required — `evidence_tier` and `metadata_resolution` are optional on existing rows. Reviews built with v0.1.2 continue to work; rows lacking the new fields render with the previous register (un-modulated). New reviews built with v0.1.3 get the full benefits. Re-extracting an existing review with v0.1.3 to populate the new fields is supported but not necessary.

### Files touched
- `skills/using-scriptorium/SKILL.md` — schema updates for `Paper`, `EvidenceEntry`, `AuditEntry`.
- `skills/search/SKILL.md` — `metadata_resolution` assignment rules.
- `skills/extract/SKILL.md` — `evidence_tier` tagging step + propagation of `metadata_resolution`.
- `skills/synthesize/SKILL.md` — register-modulation rule + two-part cite-check + new report format.
- `skills/contradictions/SKILL.md` — two-stage check + three rendering templates.

## 0.1.2 — 2026-04-30

Two new Pocock-style direction-elicitation skills, plus a direction-check at the top of `review`.

### Added
- **`grill-me`** — Oxford-tutor-style skill for users who have a topic but haven't decided what they want from it. Five exit profiles routing to NotebookLM, syllabus skill, strategy-memo skill, `grill-question`, Scriptorium directly, or "just thinking — journal it." Wrong-skill detection redirects to `grill-question` when the user opens with both a topic and an artifact.
- **`grill-question`** — Doctoral-methods-supervisor-style skill for users with a topic and a clear research-paper-shaped artifact intent who don't yet have a defensible RQ. Five stopping criteria (six for mixed-methods); tradition routing via "kind of answer" instead of "qual or quant"; practitioner-doctorate detection (EdD/DBA/CLO) with positionality surfacing and Herr & Anderson validity stack. Works both downstream of `grill-me` and as cold-start.
- **Direction check at the top of `review`** — after the connector probe and before scoping, asks the user *"do you already have a clear research question, or would you like to grill out your direction first?"* Three-way route: skip grill / question grill / full grill. Skipped automatically if the user's initial prompt already contains a research question.
- **`shared-vocabulary.md`** in each grill-me skill's `references/` folder — defines `purpose`, `artifact`, `depth`, `tradition`, `boundaries`, `stopping state`, `handoff state`, `discovery escape hatch` consistently across the two skills.
- **`/research/` directory** at the parent repo root with three design memos that produced these skills (`shared-vocabulary.md`, `grill-me-memo.md`, `grill-question-memo.md`) — kept as the design rationale; the SKILL.md files are the executable prose.

### Changed
- **`scope`** now has a Step 0 that detects grill-me handoff state in conversation context and treats inherited fields as resolved, skipping Tier 1+2 questions that already have answers. Grill-me users go straight to the recap.
- **`using-scriptorium` dispatch table** adds two rows for the new direction-elicitation phases.
- **README restructured** so grilling is the recommended starting point. New "Where to start" section right under the lead presents three openings ranked by user confidence — *"grill me on this topic"* (recommended default), *"grill me on the question"* (you have a topic + paper-shaped intent), *"run a lit review on X"* (you have a clear research question already). The example transcript moved up alongside the openings. Trigger-phrase table reordered so grill-me sits above the full-pipeline command.

### Migration
None required — the new skills are additive and the direction check is opt-in (skipped when the user's first message already contains a research question).

## 0.1.1 — 2026-04-30

Connector-detection fixes, restored full-text cascade, Scite support, library-proxy handoff, README revision.

### Added
- **Scite as a `~~citation context` connector category.** Used by `contradictions` to enrich named camps with cross-corpus supporting / contrasting citation counts, and as optional enrichment on each evidence row in `extract`. Scite's classification is enrichment — it never replaces in-corpus citations.
- **Unpaywall full-text retrieval via `WebFetch`.** Restored to the cascade — was previously documented as Cowork-unavailable, but Unpaywall's free public API (`api.unpaywall.org`) is reachable from `WebFetch` whenever the Cowork org allowlists the host.
- **arXiv full-text retrieval via `WebFetch`.** Same pattern — `export.arxiv.org` is a free public endpoint, no auth required.
- **`library_proxy_base` config knob and library-proxy handoff path.** When the OA cascade misses, Scriptorium generates a proxied URL (`{library_proxy_base}{paper.doi_url}`) and hands it to the user. The user clicks, authenticates in their browser, downloads the PDF, and drags it back into the Cowork chat. The agent never authenticates as the user to the library — that's the browser's job. Examples for UPenn, Harvard, Stanford, Yale, Columbia, Berkeley, MIT shipped in `setup`.
- **Network allowlist guidance.** `setup` now mentions when an enterprise allowlist might block Unpaywall/arXiv and lists the hosts to add.

### Changed
- **`using-scriptorium` connector probe is now a two-pass aggressive matcher.** Previously the probe prefix-matched a small set of `mcp__claude_ai_*__*` patterns, which silently missed connectors registered under other naming conventions (`mcp__plugin_research_*__*`, `mcp__<vendor>-mcp__*`). The new probe enumerates all available `mcp__*` tools, lowercases their names, and matches against keyword sets. After resolving, it always reports what was detected to the user and offers a retry / manual-override path before degrading.
- **Full-text cascade in `extract`** now reads: `user_pdf → unpaywall → arxiv → pmc → library_proxy → abstract_only` (was `user_pdf → pmc → abstract_only`).
- **README rewritten** to lead with the NotebookLM/podcast use case, surface concrete output samples (real `evidence` row + `synthesis` fragment), and add three lived-in patterns (meeting prep, meta-synthesis, defense briefing).

### Fixed
- Connector probe silently failing when Consensus was registered as `mcp__plugin_research_consensus__*` (the new Cowork plugin-style naming) instead of the older `mcp__claude_ai_Consensus__*` form.
- README link rot — `[synthesis.md](http://synthesis.md)` and similar auto-link mistakes replaced with proper relative links or code formatting.

### Migration
None required — `library_proxy_base`, `unpaywall_email`, and the new `~~citation context` category are all opt-in. Existing v0.1.0 users will see the new probe behavior and library-proxy prompt the next time `using-scriptorium` and `setup` fire.

## 0.1.0 — 2026-04-29

Initial Cowork-native release of Scriptorium.

### Added
- Eleven skills covering the full lit-review pipeline (using-scriptorium, setup, scope, search, screen, extract, synthesize, contradictions, audit, publish, review).
- INJECTION.md discipline preamble loaded by `using-scriptorium` to replace the missing Claude Code SessionStart hook.
- CONNECTORS.md documenting six tool categories (`~~claim search`, `~~breadth search`, `~~biomed search`, `~~document store`, `~~knowledge base`, `~~notebook publish`) with a state-home cascade rule.
- State-adapter mapping: NotebookLM > document store (Drive/Box/OneDrive) > knowledge base (Notion/Confluence) > session-only.
- Hard-gate cite-check at the end of `synthesize` (replaces the CC PostToolUse hook).
- Privacy gate in `publish` requiring explicit user consent before any upload to NotebookLM.

### Differs from the Claude Code edition
- No CLI required — pure skills + MCP.
- No PostToolUse hooks (Cowork has no hook system); discipline lives in skill prose.
- No slash commands (Cowork dispatches via natural language); README lists trigger phrases.
- Connector-agnostic — works with whichever scholarly-search MCPs the user has connected, not just OpenAlex/Semantic Scholar.

### Known limitations (v0.1.0; addressed in v0.1.1)
- Connector probe used prefix matching on a narrow set of MCP names; non-standard names silently missed. **Fixed in v0.1.1.**
- Full-text cascade collapsed to `user_pdf → pmc → abstract_only` — Unpaywall and arXiv were documented as unavailable. **Restored via `WebFetch` in v0.1.1.**
- No university library access path. **Library-proxy handoff added in v0.1.1.**
- Reviewer-branch agents (`lit-cite-reviewer`, `lit-contradiction-reviewer`) from the Claude Code edition are not yet ported — synthesis-exit cite-check runs inline.
- On Cowork for Windows, the in-chat `.plugin` rich preview can fail (issue #50041 in claude-code repo); fall back to Settings → Plugins → Upload.
