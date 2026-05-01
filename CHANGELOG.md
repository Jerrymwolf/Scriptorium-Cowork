# Changelog

All notable changes to scriptorium-cowork are documented here.

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
