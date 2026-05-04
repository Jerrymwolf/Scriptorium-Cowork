---
name: render
description: Use when the user has a finished synthesis (synthesis.md + corpus.jsonl + evidence.jsonl) and wants a click-to-source viewer they can open in the Cowork sidebar, share with their advisor, or paste into a chapter draft. Produces a self-contained HTML artifact via `mcp__cowork__create_artifact` where every `[paper_id:locator]` token in the synthesis renders as a clickable author-year link; clicking opens a side panel showing the paper title, venue, DOI, the verbatim supporting quote at that locator, and a one-click link to the source.
---

# Synthesis Rendering (Cowork)

This skill is the bridge from a finished synthesis (markdown with `[paper_id:locator]` tokens) to a human-readable, advisor-shareable, clickable artifact. It does NOT modify the synthesis — it produces a lens over it.

## Precondition (HARD GATE)

Do not fire this skill until ALL of the following are true:

- `synthesis` artifact exists and its most recent cite-check entry has `status: "success"` (strict mode) OR `status: "warning"` with explicit user acknowledgment (lenient mode).
- `corpus` artifact exists with at least the papers cited in the synthesis.
- `evidence` artifact exists with at least the rows referenced in the synthesis.

If any precondition fails, refuse to render and say which one. Hand back to the appropriate skill (usually `synthesize` for re-running the cite-check).

## Render mode by intent (R19, v0.4.0)

`render` reads `output_intent` from the latest scope/review state and produces a different primary artifact per intent. The click-to-source viewer is **always** built (it's the audit-trail surface); what changes is the primary user-facing output.

| `output_intent` | Primary render | Secondary |
|---|---|---|
| `chapter` | Click-to-source HTML viewer (full) | n/a |
| `brief` | Click-to-source HTML viewer | n/a |
| `teaching` | Click-to-source HTML viewer | n/a |
| `memo` | One-page Markdown (template below) | Viewer (linked at bottom) |
| `podcast` | NotebookLM source bundle | Viewer (linked) |
| `deck` | NotebookLM deck | Viewer (linked) |
| `exploration` | Plain Markdown exploration note | Viewer (linked) |

### Memo Markdown template

```markdown
# {{topic}} — strategy memo

**Question:** {{research_question}}
**Decision aid for:** {{audience}}
**Date:** {{ts}}

## Recommendation

{{1-paragraph synthesis with [author-year] citations}}

## What the literature says

{{4–6 paragraphs, each tagged by the strongest evidence_tier present
for that concept; [author-year] citations chained where ≥2 papers}}

## Where the evidence pushes back

{{contradictions.md condensed; named camps if present}}

## What this means for {{audience}}

{{1-paragraph operational implication, marked <arg>...</arg>
if voice = building/defending}}

---

[Click-to-source viewer]({{viewer_artifact_id}}) · {{n_papers}} papers ·
{{n_citations}} citations · cite-check passed
```

### Citation translation — MANDATORY (R20, v0.4.1)

**The synthesis grammar is `[paper_id:locator]`. The render grammar is APA 7th edition. They are not interchangeable, and the synthesis grammar MUST NEVER appear in user-facing rendered output.**

`NARRATION.md` line 31 states explicitly: citation tokens (`[paper_id:locator]`) never appear in user-facing chat. The same rule applies to rendered Markdown, HTML, and any artifact a human reads. The rendered output uses APA citations; the underlying `[paper_id:locator]` token is preserved only in:

- The audit log (machine-readable, never user-facing)
- The click-to-source viewer's data layer (used to populate hover panels — never displayed as the visible link text)

**Citation style — APA 7th edition (R21, v0.4.1):**

Inline parenthetical citations use parentheses, comma between author and year, and `et al.` for 3+ authors:

| Author count | Inline format | Narrative format |
|---|---|---|
| 1 author | `(Weikum, 2021)` | `Weikum (2021) finds…` |
| 2 authors | `(Smith & Jones, 2023)` | `Smith and Jones (2023) find…` |
| 3+ authors | `(Li et al., 2023)` (from first citation) | `Li et al. (2023) find…` |
| Multiple papers same parens | `(Smith, 2023; Jones, 2024)` (semicolon-separated, alphabetical) | n/a |

If the corpus row's authors[] field is missing or insufficient to determine count, default to `et al.` notation as the safe choice — most academic search results return only the first author's surname plus "et al."

References-list format (one per cited paper, alphabetized by first author surname):

```
Author, A. A., et al. (Year). Article title in sentence case. *Journal Name in Title Case*.
```

If full authorship and bibliographic data isn't in the corpus row, ship the closest-fit APA-shaped reference using available fields — partial APA is preferable to non-APA. Mark such rows in the audit log with `metadata_resolution: partial` per the unified schema.

**Translation algorithm** (mechanical — must run before any render artifact ships):

1. Walk the `synthesis.md` source.
2. For each `[paper_id:locator]` token, look up the matching corpus row by `paper_id`.
3. Build the inline APA citation per the table above based on `authors[]` count.
4. Replace the original `[paper_id:locator]` token with the new APA citation in the rendered output.
5. If the same author-year pair appears for two different papers, disambiguate as `(Smith, 2023a)` / `(Smith, 2023b)` ordered by first appearance.
6. Append a **References** section at the bottom (alphabetized) using the APA reference format above.
7. The click-to-source viewer's HTML preserves the `paper_id` and `locator` as `data-pid` and `data-loc` attributes on the citation `<span>`, so clicking still resolves to the underlying evidence row.

**Failure mode the render skill must NOT permit:** shipping a memo or chapter with literal `[consensus:abc123:abstract]` or `[pmid:38920760:page:7]` in the visible body. That is the audit-trail grammar leaking into the user surface — the same class of failure as R3's `using-scriptorium` name leak. Verify before shipping: grep the rendered output for `[a-zA-Z0-9]+:[a-zA-Z0-9]+:` patterns; if any appear in body text (not data attributes), refuse to ship and re-translate.

**Why APA?** It's the dominant citation style in the social sciences, education, business, and increasingly in interdisciplinary research where Scriptorium operates. Alternative styles (Chicago, MLA, IEEE, Vancouver) are tracked as v0.5.0+ candidates; the user can specify in `scriptorium-config` once the multi-style branch lands. For v0.4.1 the citation style is APA, full stop.

**Smoke test enforcement** (added v0.4.1): `scripts/smoke-test.sh` greps every rendered Markdown artifact for unexpanded `[paper_id:locator]` tokens AND for non-APA bracket-style citations like `[Author Year]`; both are release blockers.

**Why this isn't optional:** the v0.4.0 memo trace shipped with raw audit-grammar tokens visible to the user. The interim v0.4.1 fix used `[Author Year]` square brackets, which still aren't APA. v0.4.1 final locks in APA 7th edition as the rendered citation style.

### Exploration Markdown template (lighter)

Same structure as memo but `Recommendation` → `Where this is heading`, and `What this means` → `Open questions`.

## Workflow

1. **Resolve the three input artifacts** via the state adapter mapping (see `using-scriptorium`):
   - `synthesis.md` — the markdown source with `[paper_id:locator]` tokens
   - `corpus.jsonl` — paper metadata (title, authors, year, doi, venue)
   - `evidence.jsonl` — claim/quote/locator/tier/direction per (paper_id, locator)

2. **Filter to citations actually used.** Walk the synthesis; extract all unique `paper_id` values that appear in tokens. Filter `corpus.jsonl` and `evidence.jsonl` to just those papers.

3. **Build the viewer HTML.** Use the reference builder script at `runtime/build-viewer.py` (called via Bash on the user's machine, OR re-implemented inline by the skill if no shell is available — see template below). The script produces a single self-contained HTML file with three things inlined as JSON:
   - `papers`: dictionary of paper_id → metadata
   - `evidence`: list of evidence rows
   - `synthesis`: the prose with tokens replaced by clickable spans

4. **Create the Cowork artifact** via `mcp__cowork__create_artifact`:
   - `id`: `scriptorium-viewer-<review-slug>` (kebab-case; one viewer per review)
   - `html_path`: absolute path to the generated HTML file
   - `description`: one-line summary naming the synthesis title and the citation count

5. **Append one audit entry**: `{phase: "rendering", action: "viewer.created", details: {artifact_id, n_papers_cited, n_evidence_rows_referenced, n_unresolved_citations}, status}`. Status is `success` if all citations resolved; `warning` if any citation in the synthesis didn't resolve to an evidence row (the viewer renders these as broken-line strikethrough).

6. **Tell the user the artifact id and a one-line preview** of what they'll see when they open it. Do not paste the HTML into chat.

## Template — viewer HTML structure

Each citation in the synthesis renders as:

```html
<span class="cite" data-pid="..." data-loc="...">Martela &amp; Riekki (2018)</span>
```

Click handler populates a side panel with:

- Title (from corpus)
- Authors · Venue · Year · DOI link
- Tier tag (meta-analysis / cross-sectional / qualitative / etc.)
- Direction tag (positive / negative / neutral / mixed)
- Locator tag (`page:7` / `abstract` / `sec:Methods`)
- Verbatim quote in a styled blockquote (orange left-border indicates "this is what the paper actually says")
- Two action links: "Open paper ↗" (to DOI) · "Other claims from this paper" (lists all evidence rows for the same paper)

## Reference builder script

The full builder lives at `runtime/build-viewer.py`. It reads three files (synthesis path, corpus path, evidence path) and writes the output HTML to a path the user provides. Skill invocation:

```bash
python3 runtime/build-viewer.py \
  --synthesis path/to/synthesis.md \
  --corpus path/to/corpus.jsonl \
  --evidence path/to/evidence.jsonl \
  --out path/to/viewer.html
```

If the user does not have shell access (Cowork-only mode), the skill re-implements the build inline using JavaScript-string-construction (the artifact tool accepts an HTML file the model writes directly).

## What the viewer does NOT include in v0.2.0

- Live data refresh (the artifact is a snapshot; re-render to update)
- Multi-section navigation (TOC sidebar)
- Diff view across two synthesis versions
- Editing — the viewer is read-only

These land in v0.3.0+ and require the `refine` skill for editing primitives.

## Hand-off

After the artifact is created, report to the user:

> "Click-to-source viewer created: `scriptorium-viewer-<review-slug>`. Open the Cowork sidebar to view it. Every citation is clickable; click any author-year link to see the source paper, the verbatim supporting quote, and a one-click DOI link. Share the artifact id with your advisor — it persists across sessions and they can open it from their own Cowork."

If any citations failed to resolve, name them explicitly so the user knows which ones to verify by hand.

## User narration (added v0.2.1)

Follow `NARRATION.md`.

**Before:**

> Now I'll turn your draft into a click-to-source viewer — every
> citation will be hoverable, every quote will be visible, every
> paper one click away. This goes into your Cowork sidebar so you
> can keep coming back to it. About 30 seconds.

**After:**

> Done. The viewer is in your Cowork sidebar under [artifact id].
> Click any blue author-year link to see the source paper, the
> quote, and the locator. You can share this with your advisor —
> they don't need Scriptorium installed to view it.

## Interactive choices (added v0.2.2)

Render is mostly automatic, but if it asks the user to confirm an artifact id or pick a render target, those questions fire form widgets per `NARRATION.md` §Interactive choice contract, with `data-other` always present.
