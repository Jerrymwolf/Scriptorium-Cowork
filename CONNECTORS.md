# Connectors

Scriptorium for Cowork is **connector-agnostic**. Skill prose refers to tool *categories* (`~~scholarly search`, `~~document store`) rather than specific products, so the plugin works against whichever MCPs you have connected.

## How tool references work

Skill files use `~~category` as a placeholder for whatever tool the user connects in that category. The runtime probe in `using-scriptorium` resolves each placeholder to a concrete MCP tool name on session start by enumerating available MCPs and substring-matching against keyword sets (`consensus`, `scite`, `pubmed`, `notebooklm`, etc.). Naming variants like `mcp__claude_ai_*`, `mcp__plugin_*`, and `mcp__<vendor>-mcp__*` are all detected.

## Categories

| Category | Placeholder | What it does | Examples |
|---|---|---|---|
| Scholarly search (claim-first) | `~~claim search` | Question-framed search; surfaces claims with evidence | Consensus |
| Scholarly search (breadth) | `~~breadth search` | Broad academic discovery across disciplines | Scholar Gateway, Semantic Scholar, OpenAlex (via WebFetch) |
| Biomedical search | `~~biomed search` | PubMed/MeSH-aware biomedical discovery + OA full text | PubMed |
| Citation context | `~~citation context` | Given a paper or claim, surfaces supporting/contrasting/mentioning citations from across the literature | Scite |
| Document store | `~~document store` | Persistent file/folder storage for review artifacts | Google Drive, Box, OneDrive, SharePoint |
| Knowledge base | `~~knowledge base` | Page-tree storage for review artifacts (alternative to document store) | Notion, Confluence |
| Notebook publishing | `~~notebook publish` | Source-grounded notebook with Studio artifact generation | NotebookLM |

## Required vs. optional

- **Required:** at least one of `~~claim search` / `~~breadth search` / `~~biomed search`. Without one, the plugin runs in degraded mode (WebFetch against OpenAlex's public API) and tells you so.
- **Recommended for institutional researchers:** `~~citation context` (Scite). Used by `lit-contradiction-check` to enrich named-camp disagreement with cross-corpus citation signals. Optional but adds a lot of polish to the contradiction surfacing.
- **Recommended:** at least one of `~~document store` / `~~knowledge base` / `~~notebook publish`. Without persistent state, your review evaporates at session end.
- **Optional:** `~~notebook publish` is required only if you want to generate a podcast, slide deck, or mind map of the finished review.

## State home cascade (when multiple are connected)

When more than one persistent state connector is enabled, the plugin picks in this fixed order: **NotebookLM → Drive/Box/OneDrive → Notion/Confluence → session-only**. The user can override at any time by saying *"use Drive for this review"* or *"put this in Notion."*

## Full-text retrieval — beyond MCPs

Some retrieval routes don't go through MCPs at all:

- **Unpaywall and arXiv** are accessed via Cowork's `WebFetch` tool. They're free, public, no-auth APIs. Your Cowork org needs to allowlist `api.unpaywall.org` and `export.arxiv.org` for the cascade to use them.
- **University library access** (EZproxy / OpenAthens) is configured via the `library_proxy_base` setting in `scriptorium-config`. When the OA cascade misses, Scriptorium generates a proxied URL using your library's prefix and hands it to you; you click, authenticate in your own browser, download the PDF, and drag it back into the Cowork chat. The agent never authenticates as you to your library — only your browser holds the session cookie. Proxy URL examples for major institutions live in `setting-up-scriptorium`.

These two surfaces — public OA APIs and the library-proxy handoff — restore most of the full-text recall the Claude Code edition gets through its CLI.

## Adding a new connector category

If you connect an MCP that doesn't match any category above, add a row to this table and reference it in the skill that needs it. Skill descriptions remain category-named; only the runtime probe table in `using-scriptorium/SKILL.md` maps category → concrete tool name.
