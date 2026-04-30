# Changelog

All notable changes to scriptorium-cowork are documented here.

## 0.1.2 — 2026-04-30

Two new Pocock-style direction-elicitation skills, plus a direction-check at the top of `running-lit-review`.

### Added
- **`research-grill-me`** — Oxford-tutor-style skill for users who have a topic but haven't decided what they want from it. Five exit profiles routing to NotebookLM, syllabus skill, strategy-memo skill, `research-questions-grill-me`, Scriptorium directly, or "just thinking — journal it." Wrong-skill detection redirects to `research-questions-grill-me` when the user opens with both a topic and an artifact.
- **`research-questions-grill-me`** — Doctoral-methods-supervisor-style skill for users with a topic and a clear research-paper-shaped artifact intent who don't yet have a defensible RQ. Five stopping criteria (six for mixed-methods); tradition routing via "kind of answer" instead of "qual or quant"; practitioner-doctorate detection (EdD/DBA/CLO) with positionality surfacing and Herr & Anderson validity stack. Works both downstream of `research-grill-me` and as cold-start.
- **Direction check at the top of `running-lit-review`** — after the connector probe and before scoping, asks the user *"do you already have a clear research question, or would you like to grill out your direction first?"* Three-way route: skip grill / question grill / full grill. Skipped automatically if the user's initial prompt already contains a research question.
- **`shared-vocabulary.md`** in each grill-me skill's `references/` folder — defines `purpose`, `artifact`, `depth`, `tradition`, `boundaries`, `stopping state`, `handoff state`, `discovery escape hatch` consistently across the two skills.
- **`/research/` directory** at the parent repo root with three design memos that produced these skills (`shared-vocabulary.md`, `research-grill-me-memo.md`, `research-questions-grill-me-memo.md`) — kept as the design rationale; the SKILL.md files are the executable prose.

### Changed
- **`lit-scoping`** now has a Step 0 that detects grill-me handoff state in conversation context and treats inherited fields as resolved, skipping Tier 1+2 questions that already have answers. Grill-me users go straight to the recap.
- **`using-scriptorium` dispatch table** adds two rows for the new direction-elicitation phases.
- **README restructured** so grilling is the recommended starting point. New "Where to start" section right under the lead presents three openings ranked by user confidence — *"grill me on this topic"* (recommended default), *"grill me on the question"* (you have a topic + paper-shaped intent), *"run a lit review on X"* (you have a clear research question already). The example transcript moved up alongside the openings. Trigger-phrase table reordered so grill-me sits above the full-pipeline command.

### Migration
None required — the new skills are additive and the direction check is opt-in (skipped when the user's first message already contains a research question).

## 0.1.1 — 2026-04-30

Connector-detection fixes, restored full-text cascade, Scite support, library-proxy handoff, README revision.

### Added
- **Scite as a `~~citation context` connector category.** Used by `lit-contradiction-check` to enrich named camps with cross-corpus supporting / contrasting citation counts, and as optional enrichment on each evidence row in `lit-extracting`. Scite's classification is enrichment — it never replaces in-corpus citations.
- **Unpaywall full-text retrieval via `WebFetch`.** Restored to the cascade — was previously documented as Cowork-unavailable, but Unpaywall's free public API (`api.unpaywall.org`) is reachable from `WebFetch` whenever the Cowork org allowlists the host.
- **arXiv full-text retrieval via `WebFetch`.** Same pattern — `export.arxiv.org` is a free public endpoint, no auth required.
- **`library_proxy_base` config knob and library-proxy handoff path.** When the OA cascade misses, Scriptorium generates a proxied URL (`{library_proxy_base}{paper.doi_url}`) and hands it to the user. The user clicks, authenticates in their browser, downloads the PDF, and drags it back into the Cowork chat. The agent never authenticates as the user to the library — that's the browser's job. Examples for UPenn, Harvard, Stanford, Yale, Columbia, Berkeley, MIT shipped in `setting-up-scriptorium`.
- **Network allowlist guidance.** `setting-up-scriptorium` now mentions when an enterprise allowlist might block Unpaywall/arXiv and lists the hosts to add.

### Changed
- **`using-scriptorium` connector probe is now a two-pass aggressive matcher.** Previously the probe prefix-matched a small set of `mcp__claude_ai_*__*` patterns, which silently missed connectors registered under other naming conventions (`mcp__plugin_research_*__*`, `mcp__<vendor>-mcp__*`). The new probe enumerates all available `mcp__*` tools, lowercases their names, and matches against keyword sets. After resolving, it always reports what was detected to the user and offers a retry / manual-override path before degrading.
- **Full-text cascade in `lit-extracting`** now reads: `user_pdf → unpaywall → arxiv → pmc → library_proxy → abstract_only` (was `user_pdf → pmc → abstract_only`).
- **README rewritten** to lead with the NotebookLM/podcast use case, surface concrete output samples (real `evidence` row + `synthesis` fragment), and add three lived-in patterns (meeting prep, meta-synthesis, defense briefing).

### Fixed
- Connector probe silently failing when Consensus was registered as `mcp__plugin_research_consensus__*` (the new Cowork plugin-style naming) instead of the older `mcp__claude_ai_Consensus__*` form.
- README link rot — `[synthesis.md](http://synthesis.md)` and similar auto-link mistakes replaced with proper relative links or code formatting.

### Migration
None required — `library_proxy_base`, `unpaywall_email`, and the new `~~citation context` category are all opt-in. Existing v0.1.0 users will see the new probe behavior and library-proxy prompt the next time `using-scriptorium` and `setting-up-scriptorium` fire.

## 0.1.0 — 2026-04-29

Initial Cowork-native release of Scriptorium.

### Added
- Eleven skills covering the full lit-review pipeline (using-scriptorium, setting-up-scriptorium, lit-scoping, lit-searching, lit-screening, lit-extracting, lit-synthesizing, lit-contradiction-check, lit-audit-trail, lit-publishing, running-lit-review).
- INJECTION.md discipline preamble loaded by `using-scriptorium` to replace the missing Claude Code SessionStart hook.
- CONNECTORS.md documenting six tool categories (`~~claim search`, `~~breadth search`, `~~biomed search`, `~~document store`, `~~knowledge base`, `~~notebook publish`) with a state-home cascade rule.
- State-adapter mapping: NotebookLM > document store (Drive/Box/OneDrive) > knowledge base (Notion/Confluence) > session-only.
- Hard-gate cite-check at the end of `lit-synthesizing` (replaces the CC PostToolUse hook).
- Privacy gate in `lit-publishing` requiring explicit user consent before any upload to NotebookLM.

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
