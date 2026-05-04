---
name: using-scriptorium
description: Use when the user mentions a literature review, asks to find/screen/synthesize/draft research, or starts a Scriptorium session. Probes which Cowork connectors are available, picks the state home, teaches the three disciplines, and dispatches to the phase-appropriate skill (scope / search / screen / extract / synthesize / contradictions / audit / publish, or the grill-me skills upstream).
---

# Using Scriptorium (Cowork)

**Fire this first in every Scriptorium session.** It is the router. After the connector probe runs and the state home is selected, hand off to the skill that matches the user's current phase.

## The three disciplines (non-negotiable)

1. **Evidence-first claims.** Every sentence in `synthesis` either cites `[paper_id:locator]` that exists in the evidence store, or it is stripped/flagged. There is no rhetorical-but-uncited writing.
2. **PRISMA audit trail.** Every search, screen, extraction, and reasoning decision appends one entry to the audit trail. Entries never overwrite; the trail is reconstructable.
3. **Contradiction surfacing.** When evidence on the same concept points in different directions, name the disagreement explicitly. Do not average away conflict.

## Connector probe (run at session start)

The probe runs in three passes (v1.0.0). Pass 1 matches tool *names* against keyword sets. Pass 1.5 (added v1.0.0) matches tool *descriptions* when the name is opaque (UUID-registered tools, unhelpfully short names). Pass 2 resolves each Scriptorium category to whatever Pass 1 + 1.5 found. If a category the user expects is missing, ask before falling through to a degraded path.

### Pass 1 — enumerate and match

List every tool whose name starts with `mcp__`. For each, lowercase the name and check substring matches against these keyword sets:

| Keyword set (case-insensitive substring) | Resolves to |
|---|---|
| `consensus` | `~~claim search` |
| `scholar_gateway`, `scholar-gateway`, `scholargateway`, `semantic_scholar`, `semantic-scholar`, `semanticscholar`, `semantic scholar`, `openalex` | `~~breadth search` |
| `pubmed`, `pmc` | `~~biomed search` |
| `scite` | `~~citation context` |
| `notebooklm`, `notebook_lm` | `~~notebook publish` |
| `google_drive`, `google-drive`, `gdrive`, `box`, `onedrive`, `sharepoint` | `~~document store` |
| `notion`, `confluence` | `~~knowledge base` |

Naming variants Cowork uses today: `mcp__claude_ai_<service>__*` (older), `mcp__plugin_<category>_<service>__*` (current plugin-style), `mcp__<service>-mcp__*` (vendor-named), `mcp__<uuid>__*` (Cowork connector store anonymized). Match all of them.

### Pass 1.5 — description-keyword fallback (added v1.0.0)

For any tool whose name did NOT match a keyword set in Pass 1 (typically UUID-registered tools), read its MCP description string and apply the same keyword sets to it. Real example from a real session: `mcp__6de5d9ff-...__search_articles` had a name with no keyword match, but its description contains "PubMed" and "biomedical and life sciences research articles" — Pass 1.5 resolves it to `~~biomed search` cleanly without forcing the user to intervene.

**v0.4.1 keyword extension:** the breadth-search list now includes `"semantic scholar"` (with a space) in addition to the no-space and underscore/hyphen variants. The v0.4.0 memo trace surfaced two real Cowork tool descriptions that wrote the database name with a space ("Semantic Scholar"), which the underscore-only keyword set didn't catch. Lesson: keyword sets must include the human-readable form alongside the API/identifier forms.

If both Pass 1 and Pass 1.5 fail to resolve a category, surface the unresolved tools to the user for manual override:

> The following tools are connected but I couldn't auto-route: `mcp__abc123__semanticSearch`, `mcp__def456__paper_search`. If any of these is your `~~breadth search` or `~~claim search`, say *"use mcp__abc123__semanticSearch as my breadth search"* and I'll record the override.

### Pass 2 — report and confirm

After Pass 1, tell the user exactly what resolved:

> Connector probe results:
> - `~~claim search` — Consensus (`mcp__plugin_research_consensus__search`)
> - `~~biomed search` — PubMed (`mcp__plugin_research_pubmed__search_articles`)
> - `~~citation context` — Scite (`mcp__plugin_research_scite__assistant`)
> - `~~notebook publish` — NotebookLM (`mcp__notebooklm-mcp__notebook_create`)
> - `~~breadth search` — not detected
> - `~~document store` — not detected
> - `~~knowledge base` — not detected
>
> If you have a connector enabled that I missed, say *"retry probe"* or *"I have <connector> connected as <tool name>"* and I'll use it directly.

The retry path is critical — Cowork connectors sometimes register under non-obvious names, and a missed connector silently degrades the entire pipeline. Always show the user what resolved before proceeding.

### Pass 3 — pick search backends and state home

Search backend selection rule:

- If `~~claim search` resolved → prefer it for claim-framed questions.
- If `~~biomed search` resolved AND the topic is biomedical → use it for primary recall.
- If `~~breadth search` resolved → use it as the breadth pass alongside one of the above.
- If `~~citation context` resolved → reserve it for `contradictions` and as evidence enrichment in `extract`. Do not use it as a primary search source.
- If none of the search categories resolved → **degraded mode**. Use `WebFetch` against `https://api.openalex.org/works?search=...` and announce "Search is running in degraded mode — no scholarly-search MCP detected. Connect Consensus, Scholar Gateway, PubMed, or Scite for better recall."

State home selection rule:

1. If `~~notebook publish` resolved → state home = a NotebookLM notebook (one per review). Notebook PDFs become native sources; markdown artifacts become text-source notes.
2. Else if `~~document store` resolved → state home = a folder. The folder mirrors the on-disk review layout (`scope.json`, `corpus.jsonl`, `evidence.jsonl`, `synthesis.md`, `contradictions.md`, `audit.jsonl`, `pdfs/`).
3. Else if `~~knowledge base` resolved → state home = a page tree. Each artifact becomes a child page.
4. Else → **session-only**. Tell the user: "Nothing will persist past this conversation. Connect a document store or notebook to keep your review."

The user may override the state-home choice at any time by saying *"put this review in Drive"* / *"use NotebookLM for this"* / *"keep it in Notion."*

### Manual override

If a probe pass missed a tool and the user knows the exact MCP tool name, accept it directly:

> User: "Use mcp__plugin_research_consensus__search as my claim search."
> Assistant: "Recorded — `~~claim search` now resolves to `mcp__plugin_research_consensus__search`. Continuing."

Manual overrides persist **across sessions** (R14, v0.4.0) — written to `scriptorium-config`'s `[scriptorium.connector_overrides]` block via the state adapter, and applied before Pass 1 fires on subsequent sessions. Each override appends an audit entry: `{phase: "connector-probe", action: "override", details: {category, tool_name, reason: "user-provided"}, ts, status: "success"}`.

If a saved override points to a tool that's no longer connected this session, fall back to probe and warn the user. Shape of the recovery audit entry: `{phase: "connector-probe", action: "override.stale", details: {category, saved_tool_name, fallback_to: "<probe-resolved-tool or none>"}, ts, status: "warning"}`.

## Persisted state-home preference

`state_home` may be set in `scriptorium-config` from a prior session (set by `setup`). On subsequent runs, if the persisted value matches a category that resolved during this session's probe, prefer it over the cascade default. If the persisted value points at a category that did NOT resolve (e.g., user wrote `notebooklm` but no NotebookLM tool is available this session), fall back to the cascade and tell the user: "Your saved state home (NotebookLM) isn't available this session — falling back to <next available>."

## State-adapter mapping

Every downstream skill reads/writes through this mapping. Skills never hardcode a tool name.

| Concept | NotebookLM | Document store | Knowledge base | Session-only |
|---|---|---|---|---|
| review root | one notebook | one folder | one parent page | in-conversation memory |
| `scope.json` | text-source note `scope` | `scope.json` file | child page `Scope` | local variable |
| `corpus.jsonl` | text-source note `corpus` | `corpus.jsonl` file | child page `Corpus` (one row per heading) | array |
| `evidence.jsonl` | text-source note `evidence` | `evidence.jsonl` file | child page `Evidence` | array |
| `audit.jsonl` + `audit.md` | notes `audit-jsonl` and `audit-md` | files | child pages `Audit log`, `Audit (human)` | array + rendered string |
| `synthesis.md` | text-source note `synthesis` | `synthesis.md` file | child page `Synthesis` | string |
| `contradictions.md` | text-source note `contradictions` | `contradictions.md` file | child page `Contradictions` | string |
| PDFs | native PDF sources | `pdfs/` subfolder | uploaded attachments | session-only |

## Unified JSON shapes

Both runtimes agree on these. Skills never invent variants.

- **Paper:** `{paper_id, source, title, authors[], year, doi, abstract, venue, open_access_url, metadata_resolution: "verified" | "partial" | "inferred"}`
  - `metadata_resolution` is set by `search` when the paper enters the corpus. `verified` = DOI/PMID resolves to a real publisher record OR title+authors+year exact-matches a single OpenAlex/Semantic Scholar record. `partial` = at least one of those resolves but other fields are gap-filled from a related record. `inferred` = any of `{title, authors, year, doi}` was constructed from prose context rather than a verified API response.
- **EvidenceEntry:** `{paper_id, locator, claim, quote, direction: positive|negative|neutral|mixed, concept, evidence_tier?: meta_analysis | systematic_review | experimental | observational | cross_sectional | qualitative | theoretical_or_review, scite_classification?: supporting|contrasting|mentioning, full_text_source?, metadata_resolution?}`
  - `evidence_tier` is captured during extraction (see `extract`). The synthesis layer uses it to modulate prose register — a meta-analysis row produces declarative prose; a cross-sectional row produces correlational prose. The tier name appears explicitly in synthesis prose ("a meta-analysis of fourteen trials shows…") so it survives the markdown→audio handoff to NotebookLM.
  - `metadata_resolution` mirrors the corresponding `Paper`'s value at extraction time; the cite-check uses it.
- **AuditEntry:** `{phase, action, details{}, ts, status}` where `status ∈ {success, warning, failure, partial, skipped}`. Synthesis-verify entries gain `n_metadata_verified / n_metadata_partial / n_metadata_inferred` in `details`. Contradiction-check entries gain `n_same_question / n_different_questions / n_uncertain` in `details` (see `contradictions`).

## When to fire which skill

| Phase | User says… | Skill to fire |
|---|---|---|
| Setup | "set up Scriptorium", first run, "what is this" | `setup` |
| Direction (fuzzy goal) | "I want to learn about X", "I have a topic but I'm not sure what I want from it", "grill me on this topic" | `grill-me` |
| Direction (need a question) | "I need to write a paper on X but don't have my question yet", "help me find the research question", "grill me on the question" | `grill-question` |
| Scope | "I want to do a lit review on X", "scope this review", "what should I search for" | `scope` |
| Search | "find papers on X", "search for…" | `search` |
| Screen | "filter by year/language/keyword", "apply inclusion criteria" | `screen` |
| Extract | "pull full text", "extract findings from this PDF" | `extract` |
| Synthesize | "write the literature review section", "draft a synthesis" | `synthesize` |
| Contradict | "where do papers disagree?", "find contradictions" | `contradictions` |
| Audit | "show the audit trail", "PRISMA flow" | `audit` |
| Publish | "make a podcast/slides/mind map of this" | `publish` |
| Orchestrate | "run a literature review on X (end-to-end)" | `review` |

Scoping (phase 1) and final writing (phases 7+) stay with the user — Scriptorium covers phases 2–6.

## First-turn checklist

1. Run the connector probe (Pass 1 + Pass 1.5 + Pass 2) silently. **Do not surface the skill name in chat** — the user sees results, not implementation. (R3, v0.4.0: removed announcement leak that contradicted NARRATION.md.)
2. Brief the user in one sentence using plain-language connector names from `NARRATION.md`'s vocabulary table: "I checked your tools — you've got [X], [Y], and [Z] connected." If anything didn't resolve that the user mentioned having, offer the retry / manual-override path before continuing.
3. If the user has not yet scoped the review, fire `scope`. Do not ask scoping questions yourself — `scope` owns that conversation.
4. Hand off to the phase-appropriate skill.

## Skip-ahead routes (R18, v0.4.0 — power-user fast-path)

If the user already has partial state from a prior session or external work, these phrases skip the linear pipeline:

| User says… | Route | Precondition check |
|---|---|---|
| "I have a corpus, just extract" / "extract from this corpus" | `extract` | corpus artifact exists at state home, OR user pastes a corpus.jsonl in chat |
| "Re-run the cite-check" / "verify the synthesis" | `synthesize` cite-check section only (skip drafting) | synthesis + corpus + evidence all present |
| "Just publish what I have" / "ship to NotebookLM" | `publish` | synthesis cite-check passed, contradictions ran |
| "Re-render the viewer" / "rebuild the click-to-source" | `render` | synthesis + corpus + evidence all present |
| "Show me the audit trail" / "PRISMA flow" | `audit` | audit log exists |
| "Add this PDF to my corpus" | `extract` (single-paper mode) | scope or corpus exists |

If the user invokes a fast-path but the precondition fails, surface the gap in plain language and offer the upstream phase: *"To extract, I need a corpus first. Want me to run a search, or do you have a corpus.jsonl to paste?"* Don't silently fall through.

## Cowork-specific honesty notes

- **No PostToolUse hooks.** Cite-checks and gate enforcement live entirely in skill prose. The discipline checkpoint at the end of `synthesize` is authoritative — do not skip it on the assumption that something downstream will catch a missing citation.
- **No local filesystem.** Every artifact lives in the state home you picked at the top of the session. There is no `cwd` to fall back to.
- **No bash.** This plugin does not invoke a CLI. Full-text retrieval that historically used a CLI in Claude Code (Unpaywall, arXiv) now runs via `WebFetch`; see `extract`. Network allowlist note: `WebFetch` requires the user's Cowork org to permit `api.unpaywall.org` and `export.arxiv.org`. If those hosts are blocked, the skill will fall through gracefully and tell the user.
- **Session-only is real degradation.** If the probe selected session-only, warn the user every time you write an artifact that it will not persist, and offer to export to a connector once one is added.

## User narration (added v0.2.1)

Follow `NARRATION.md`. This is the user's first contact with Scriptorium; the impression set here carries through.

**During the connector probe:**

Translate every `~~category` placeholder into plain language. Never surface raw `mcp__` tool names or `~~` syntax.

> I checked what tools you have connected. You've got a peer-reviewed
> paper search (Consensus), a scholarly search engine, and the medical
> research database. These will cover most research needs. I don't see
> NotebookLM connected — that's optional, only needed if you want a
> podcast or slide deck of your finished review.

**When you ask for a manual override**, translate the request into human terms:

> A few of the connected tools showed up under codes I couldn't auto-route
> (this happens). If any of these is your search engine — I see one called
> `mcp__abc123` — say "use that as my search" and I'll record it.

Internal `~~category` names appear only in the audit log, never in user-facing chat.
