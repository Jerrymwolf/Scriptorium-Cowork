---
name: using-scriptorium
description: Use when the user mentions a literature review, asks to find/screen/synthesize/draft research, or starts a Scriptorium session. Probes which Cowork connectors are available, picks the state home, teaches the three disciplines, and dispatches to the phase-appropriate lit-* skill.
---

# Using Scriptorium (Cowork)

**Fire this first in every Scriptorium session.** It is the router. After the connector probe runs and the state home is selected, hand off to the skill that matches the user's current phase.

## The three disciplines (non-negotiable)

1. **Evidence-first claims.** Every sentence in `synthesis` either cites `[paper_id:locator]` that exists in the evidence store, or it is stripped/flagged. There is no rhetorical-but-uncited writing.
2. **PRISMA audit trail.** Every search, screen, extraction, and reasoning decision appends one entry to the audit trail. Entries never overwrite; the trail is reconstructable.
3. **Contradiction surfacing.** When evidence on the same concept points in different directions, name the disagreement explicitly. Do not average away conflict.

## Connector probe (run at session start)

The probe runs in two passes. Pass 1 enumerates every available MCP tool and matches it against keyword sets. Pass 2 resolves each Scriptorium category to whatever Pass 1 found. If a category the user expects is missing, ask before falling through to a degraded path.

### Pass 1 — enumerate and match

List every tool whose name starts with `mcp__`. For each, lowercase the name and check substring matches against these keyword sets:

| Keyword set (case-insensitive substring) | Resolves to |
|---|---|
| `consensus` | `~~claim search` |
| `scholar_gateway`, `scholar-gateway`, `scholargateway`, `semantic_scholar`, `semantic-scholar`, `semanticscholar`, `openalex` | `~~breadth search` |
| `pubmed`, `pmc` | `~~biomed search` |
| `scite` | `~~citation context` |
| `notebooklm`, `notebook_lm` | `~~notebook publish` |
| `google_drive`, `google-drive`, `gdrive`, `box`, `onedrive`, `sharepoint` | `~~document store` |
| `notion`, `confluence` | `~~knowledge base` |

Naming variants Cowork uses today: `mcp__claude_ai_<service>__*` (older), `mcp__plugin_<category>_<service>__*` (current plugin-style), `mcp__<service>-mcp__*` (vendor-named). Match all of them.

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
- If `~~citation context` resolved → reserve it for `lit-contradiction-check` and as evidence enrichment in `lit-extracting`. Do not use it as a primary search source.
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

Manual overrides persist for the session and are written to the audit trail as a `connector.override` entry. Shape: `{phase: "connector-probe", action: "override", details: {category, tool_name, reason: "user-provided"}, ts, status: "success"}`.

## Persisted state-home preference

`state_home` may be set in `scriptorium-config` from a prior session (set by `setting-up-scriptorium`). On subsequent runs, if the persisted value matches a category that resolved during this session's probe, prefer it over the cascade default. If the persisted value points at a category that did NOT resolve (e.g., user wrote `notebooklm` but no NotebookLM tool is available this session), fall back to the cascade and tell the user: "Your saved state home (NotebookLM) isn't available this session — falling back to <next available>."

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

- **Paper:** `{paper_id, source, title, authors[], year, doi, abstract, venue, open_access_url}`
- **EvidenceEntry:** `{paper_id, locator, claim, quote, direction: positive|negative|neutral|mixed, concept, scite_classification?: supporting|contrasting|mentioning}`
- **AuditEntry:** `{phase, action, details{}, ts, status}` where `status ∈ {success, warning, failure, partial, skipped}`

## When to fire which skill

| Phase | User says… | Skill to fire |
|---|---|---|
| Setup | "set up Scriptorium", first run, "what is this" | `setting-up-scriptorium` |
| Direction (fuzzy goal) | "I want to learn about X", "I have a topic but I'm not sure what I want from it", "grill me on this topic" | `research-grill-me` |
| Direction (need a question) | "I need to write a paper on X but don't have my question yet", "help me find the research question", "grill me on the question" | `research-questions-grill-me` |
| Scope | "I want to do a lit review on X", "scope this review", "what should I search for" | `lit-scoping` |
| Search | "find papers on X", "search for…" | `lit-searching` |
| Screen | "filter by year/language/keyword", "apply inclusion criteria" | `lit-screening` |
| Extract | "pull full text", "extract findings from this PDF" | `lit-extracting` |
| Synthesize | "write the literature review section", "draft a synthesis" | `lit-synthesizing` |
| Contradict | "where do papers disagree?", "find contradictions" | `lit-contradiction-check` |
| Audit | "show the audit trail", "PRISMA flow" | `lit-audit-trail` |
| Publish | "make a podcast/slides/mind map of this" | `lit-publishing` |
| Orchestrate | "run a literature review on X (end-to-end)" | `running-lit-review` |

Scoping (phase 1) and final writing (phases 7+) stay with the user — Scriptorium covers phases 2–6.

## First-turn checklist

1. Announce: "Using `using-scriptorium` to route this session."
2. Run the probe (Pass 1 + Pass 2). Show the user what resolved.
3. Brief the user in one sentence: "Connectors detected: <list>. State home: <choice>. Search backend: <choice>." If anything didn't resolve that the user mentioned having, offer the retry / manual-override path before continuing.
4. If the user has not yet scoped the review, fire `lit-scoping`. Do not ask scoping questions yourself — `lit-scoping` owns that conversation.
5. Hand off to the phase-appropriate skill.

## Cowork-specific honesty notes

- **No PostToolUse hooks.** Cite-checks and gate enforcement live entirely in skill prose. The discipline checkpoint at the end of `lit-synthesizing` is authoritative — do not skip it on the assumption that something downstream will catch a missing citation.
- **No local filesystem.** Every artifact lives in the state home you picked at the top of the session. There is no `cwd` to fall back to.
- **No bash.** This plugin does not invoke a CLI. Full-text retrieval that historically used a CLI in Claude Code (Unpaywall, arXiv) now runs via `WebFetch`; see `lit-extracting`. Network allowlist note: `WebFetch` requires the user's Cowork org to permit `api.unpaywall.org` and `export.arxiv.org`. If those hosts are blocked, the skill will fall through gracefully and tell the user.
- **Session-only is real degradation.** If the probe selected session-only, warn the user every time you write an artifact that it will not persist, and offer to export to a connector once one is added.
