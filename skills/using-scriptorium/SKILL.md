---
name: using-scriptorium
description: Use when the user mentions a literature review, asks to find/screen/synthesize/draft research, or starts a Scriptorium session. Probes which Cowork connectors are available, picks the state home, teaches the three disciplines, and dispatches to the phase-appropriate lit-* skill.
---

# Using Scriptorium (Cowork)

**Fire this first in every Scriptorium session.** It is the router. After the connector probe runs and the state home is selected, hand off to the skill that matches the user's current phase.

## The three disciplines (non-negotiable)

1. **Evidence-first claims.** Every sentence in `synthesis.md` either cites `[paper_id:locator]` that exists in the evidence store, or it is stripped/flagged. There is no rhetorical-but-uncited writing.
2. **PRISMA audit trail.** Every search, screen, extraction, and reasoning decision appends one entry to the audit trail. Entries never overwrite; the trail is reconstructable.
3. **Contradiction surfacing.** When evidence on the same concept points in different directions, name the disagreement explicitly. Do not average away conflict.

## Connector probe (run at session start)

Walk this list in order and record which categories resolved to which concrete MCP tool. Categories are documented in `CONNECTORS.md` at the plugin root.

| Category | Probe | What you get |
|---|---|---|
| `~~claim search` | look for `mcp__claude_ai_Consensus__search` or any tool whose name contains `consensus` | claim-framed search |
| `~~breadth search` | look for `mcp__claude_ai_Scholar_Gateway__semanticSearch`, `semantic_scholar`, or `openalex` | breadth across disciplines |
| `~~biomed search` | look for `mcp__claude_ai_PubMed__search_articles` or any `pubmed` tool | biomed + OA full text |
| `~~document store` | look for `mcp__claude_ai_Google_Drive__*`, `box`, or `onedrive` | folder of files |
| `~~knowledge base` | look for `mcp__claude_ai_Notion__*` or `confluence` | page-tree |
| `~~notebook publish` | look for `mcp__notebooklm-mcp__notebook_create` | NotebookLM Studio |

Search backend selection rule:

- If `~~claim search` resolved → prefer it for claim-framed questions.
- If `~~biomed search` resolved AND the topic is biomedical → use it for primary recall.
- If `~~breadth search` resolved → use it as the breadth pass alongside one of the above.
- If none resolved → **degraded mode**. Use `WebFetch` against `https://api.openalex.org/works?search=...` and announce "Search is running in degraded mode — no scholarly-search MCP detected. Connect Consensus, Scholar Gateway, or PubMed for better recall."

State home selection rule:

1. If `~~notebook publish` resolved → state home = a NotebookLM notebook (one per review). Notebook PDFs become native sources; markdown artifacts become text-source notes.
2. Else if `~~document store` resolved → state home = a folder. The folder mirrors the on-disk review layout (`scope.json`, `corpus.jsonl`, `evidence.jsonl`, `synthesis.md`, `contradictions.md`, `audit.jsonl`, `pdfs/`).
3. Else if `~~knowledge base` resolved → state home = a page tree. Each artifact becomes a child page.
4. Else → **session-only**. Tell the user: "Nothing will persist past this conversation. Connect a document store or notebook to keep your review."

The user may override the state-home choice at any time by saying *"put this review in Drive"* / *"use NotebookLM for this"* / *"keep it in Notion."*

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
- **EvidenceEntry:** `{paper_id, locator, claim, quote, direction: positive|negative|neutral|mixed, concept}`
- **AuditEntry:** `{phase, action, details{}, ts, status}` where `status ∈ {success, warning, failure, partial, skipped}`

## When to fire which skill

| Phase | User says… | Skill to fire |
|---|---|---|
| Setup | "set up Scriptorium", first run, "what is this" | `setting-up-scriptorium` |
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
2. Run the connector probe; record which categories resolved.
3. Brief the user in one sentence: "Connectors detected: <list>. State home: <choice>. Search backend: <choice>." If nothing resolved, announce degraded mode explicitly.
4. If the user has not yet scoped the review, fire `lit-scoping`. Do not ask scoping questions yourself — `lit-scoping` owns that conversation.
5. Hand off to the phase-appropriate skill.

## Cowork-specific honesty notes

- **No PostToolUse hooks.** Cite-checks and gate enforcement live entirely in skill prose. The discipline checkpoint at the end of `lit-synthesizing` is authoritative — do not skip it on the assumption that something downstream will catch a missing citation.
- **No local filesystem.** Every artifact lives in the state home you picked at the top of the session. There is no `cwd` to fall back to.
- **No bash.** This plugin does not invoke a CLI. If a user asks about the `scriptorium` CLI, point them to the Claude Code edition; this Cowork edition is a pure skill-and-MCP plugin.
- **Session-only is real degradation.** If the probe selected session-only, warn the user every time you write an artifact that it will not persist, and offer to export to a connector once one is added.
