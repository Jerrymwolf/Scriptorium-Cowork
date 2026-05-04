# Roadmap TODO

Tracking deferred work. Reviewed at the start of each version's planning.

## v0.5.0 — batched findings from v0.4.x runtime traces (2026-05-04)

Findings surfaced during the memo trace (knowledge graphs in quant analysis) and the chapter trace (caffeine + working memory). v0.4.1 closed the urgent ones; the rest are below, grouped by tier.

### Tier A — concrete v0.5.0 ship items

- **A1: `output_intent` × `intent` voice reconciliation.** ✅ **LANDED in v0.5.0** (option (a) refined: voice keys on intent directly; default-intent table per output_intent preserves v0.4.x behavior; soft warnings for unusual combinations). See CHANGELOG.md for details.

- **A2: Form batching guidance.** Surfaced in chapter trace. `grill-question`'s "one question at a time" prose vs. multi-group elicitation forms is unresolved. Spec when batching is appropriate:
  - Tightly correlated dimensions (intent + tradition; year_range + corpus_target) → batch in one form
  - Independent dimensions (research question + audience) → one form per dimension
  - Add a `batchable_with: [...]` annotation in skill prose for each question.

- **A3: `<arg>` tag rendering convention.** Surfaced in memo trace. Argument-tagged synthesis prose (`<arg>...</arg>`) currently renders as italics in the user-facing memo, but italics are also used for emphasis. The render layer should distinguish:
  - HTML viewer: render `<arg>` as `<span class="arg" title="Argument — author's interpretation">...</span>` with a subtle visual marker
  - Markdown render (memo / exploration): a small label like `*[interpretation]*` or a leading `→` symbol before italicized text
  - Spec the convention in `render/SKILL.md` v0.5.0 section.

- **A4: Inline-mode Haiku integration for per-tier cite-check.** v0.4.1 prose says per-tier enforcement (`<arg>` carries cite + tag, synthesis sentence chains ≥2 cites) "runs in inline mode only" with Haiku judgment, but no Haiku integration is built. v0.5.0 ships the actual implementation:
  - Skills that perform cite-check inline call `window.cowork.askClaude(prompt, [sentence])` per uncited sentence
  - Returns one of `{factual, synthesis, argument, meta}`; per-tier rules apply
  - Spec the prompt template and acceptance criteria.

- **A5: Multi-style citations.** Currently APA-only (R21 v0.4.1). Add style config to `scriptorium-config`:
  ```toml
  [scriptorium]
  citation_style = "apa"   # apa | chicago | mla | ieee | vancouver
  ```
  Per-style render rules in `render/SKILL.md`. Inline + reference-list formats for each. Smoke test: render the same corpus in 5 styles, verify formatting per style guide.

- **A6: `refine` skill with editing primitives.** Mentioned in `render/SKILL.md` ("These land in v0.3.0+ and require the `refine` skill") but never built. v0.5.0 candidate:
  - Verbs: `drop <sentence>`, `expand <concept>`, `regenerate <section>`, `pin <claim>`, `more-skeptical <paragraph>`, `more-confident <paragraph>`
  - Operates on existing synthesis without re-running the full pipeline
  - Audit trail entry per refinement
  - Closes the gap between Scriptorium's batch-pipeline (auto mode) and the loop-mode v1.0.0 vision

### Tier B — tracked but lower priority

- **B1: State-home narration polish.** "Session-only" warning is technically correct but undersells what persists. Cowork artifacts (progress card, viewer) DO survive across sessions. Sharper narration: *"Your structured artifacts (corpus, evidence, audit log) live in this conversation; the progress card and final viewer persist in your Cowork sidebar."*
- **B2: Form widget recommended-default styling.** I rendered "memo" pill with subtitle "likely best fit" — no formal spec. Add convention to `NARRATION.md` Interactive choice contract: subtle blue border + "(recommended)" subtitle text, OR a small "★" prefix.
- **B3: Audit-trail visibility in progress artifact.** R5 progress card shows phase status; could optionally surface audit details on hover (each step's captured details — intent, depth, disconfirmer, query count). Builds toward the v1.1.0 "Audit log viewer" item.
- **B4: Probe Pass 1.5 confidence-scored matching.** Currently substring-only. v0.5.0 should add a confidence score per match (exact-substring = 1.0, fuzzy/edit-distance = 0.6, description-only-no-name = 0.4) and show the top-scoring match per category in the user-facing brief. Reduces false-positive overrides.
- **B5: Demo-form workflow contract.** During the v0.4.1 chapter trace I fired a "UI smoke test" disconfirmer demo when the gate had skipped — the user submitted it. Skills shouldn't fire demo forms in-line because users reasonably expect form input to drive workflow. v0.5.0: if a skill needs to show a UI without collecting input, render as a static SVG/HTML preview, NOT as an active form.
- **B6: Paragraph-level citation strength indicators.** Some synthesis paragraphs cite a single high-tier source (meta-analysis); others chain 4 cross-sectional rows. The render could show a small "[strong]" / "[mixed]" / "[limited]" tag per paragraph based on tier composition. Helps the reader calibrate.

### Tier C — runtime tests still owed (blocks marketplace public-directory ship)

- **C1: R11 failure-state narration in real session.** Force a zero-result search or a network block during full-text fetch. Verify template fires per `NARRATION.md` Failure-state narration. Verify R5 progress artifact errored state. Verify retry/override/stop pill flow.
- **C2: R14 connector override persistence across sessions.** End session, restart, verify saved override applied before Pass 1; verify `connector.override.stale` audit entry on broken override.
- **C3: R16 pre-search query review (Annie test).** Set `preview_queries = true`, walk Annie through a fresh trace, decide post-session whether to default the flag on or revert.

## v0.3.x / v0.4.x deferred (still relevant)

- **Library-proxy handoff for paywalled papers.** When `extract` falls through the cascade (Unpaywall → arXiv → PMC → ...), surface the unfetched papers as a list with proxied URLs the user can one-click-open in their browser, drag the PDF back in, and re-extract from full text. Closes the abstract-only-locator gap surfaced in the SDT lit-review session.
- **Direct-to-Word and direct-to-Notion render targets.** Today `publish` ships only via NotebookLM. Add `render-word` and `render-notion` skills that produce native-format outputs without the NotebookLM detour.
- **Connector probe behavior-ping fallback.** For tools whose name AND description fail keyword matching, issue a tiny test query and classify by response shape. Complements the v0.5.0 confidence-scored matching (B4).

## v1.0.0 candidates (the real "vibe-research" release)

- **Loop-mode `open` orchestrator.** New skill that runs the pipeline in interactive mode — paused at every phase boundary, accepts refinement verbs, regenerates affected scope. Default front door for `/scriptorium` once shipped.
- **`refine` skill with verbs.** drop, expand, regenerate, pin, fork, diff, more-skeptical, more-confident. Operates on existing synthesis without re-running the full pipeline.
- **Forkable domain grills.** `grill-question-medical`, `grill-question-policy`, `grill-question-history`, etc. Each adds discipline-specific gates on top of the generic grill.
- **Plugin description rewrite for dual-mode positioning.** Today's description still reads as v0.1.x ("Research-direction and lit-review plugin... PRISMA-audited review... synthesis chapter you'd defend"). After loop-mode ships, rewrite to reflect both auto and loop modes.
- **README rewrite.** Hero section: "Vibe-research with discipline." Add the three discipline gates as headline features, the click-to-source viewer as the UX demo with a screenshot.

## v1.1.0+ candidates

- **Composable handoffs to other Cowork plugins.** synthesis.md → push to Notion, Word, NotebookLM, data-viz plugin, scheduling plugin (auto-create a defense calendar, etc.) without manual copy.
- **Citation graph view.** Connected Papers-style graph showing the corpus papers as nodes with citation relationships. Highlight the user's evidence rows. Built as a Cowork artifact using a small force-directed JS library.
- **Spec templates as the network effect.** Forkable templates per discipline ("PhD chapter — sociology", "Honors thesis — biology", "B2B competitive scan — SaaS", "Curious-podcaster — 30-min single topic"). Pre-fill 80% of the grill answers; users fork and customize 2–3 things.
- **Audit log viewer.** Cowork artifact rendering audit.jsonl as a PRISMA flow diagram with click-through to each phase's details.

## Documentation backlog

- README hero section + screenshot of the click-to-source viewer
- A "Getting started" walkthrough showing a tiny end-to-end run
- A "for advisors / committees" doc explaining the audit trail and how to verify a Scriptorium-produced chapter
- A migration guide from v0.1.x to v0.2.x for users with in-progress reviews

## Tracking notes

- v0.2.0 (this release) shipped 2026-05-02. The cite-check is now stricter (three-tier); existing v0.1.x syntheses may need to be re-run.
- v0.1.5 and v0.1.6 were internal milestones, not GitHub releases.
- Loop-mode is the moat. Ship it before any major marketing or directory submission.
