# Connectors

Scriptorium for Cowork is **connector-agnostic**. Skill prose refers to tool *categories* (`~~scholarly search`, `~~document store`) rather than specific products, so the plugin works against whichever MCPs you have connected.

## How tool references work

Skill files use `~~category` as a placeholder for whatever tool the user connects in that category. The runtime probe in `using-scriptorium` resolves each placeholder to a concrete MCP tool name on session start.

## Categories

| Category | Placeholder | What it does | Examples |
|---|---|---|---|
| Scholarly search (claim-first) | `~~claim search` | Question-framed search; surfaces claims with evidence | Consensus |
| Scholarly search (breadth) | `~~breadth search` | Broad academic discovery across disciplines | Scholar Gateway, OpenAlex (via WebFetch) |
| Biomedical search | `~~biomed search` | PubMed/MeSH-aware biomedical discovery + OA full text | PubMed |
| Document store | `~~document store` | Persistent file/folder storage for the review artifacts | Google Drive, Box, OneDrive |
| Knowledge base | `~~knowledge base` | Page-tree storage for review artifacts (alternative to document store) | Notion, Confluence |
| Notebook publishing | `~~notebook publish` | Source-grounded notebook with Studio artifact generation | NotebookLM |

## Required vs. optional

- **Required:** at least one of `~~claim search` / `~~breadth search` / `~~biomed search`. Without one, the plugin runs in degraded mode (WebFetch against OpenAlex's public API) and tells you so.
- **Recommended:** at least one of `~~document store` / `~~knowledge base` / `~~notebook publish`. Without persistent state, your review evaporates at session end.
- **Optional:** `~~notebook publish` is only required if you want to generate a podcast, slide deck, or mind map of the finished review.

## State home cascade (when multiple are connected)

When more than one persistent state connector is enabled, the plugin picks in this fixed order: **NotebookLM → Drive/Box/OneDrive → Notion/Confluence → session-only**. The user can override at any time by saying *"use Drive for this review"* or *"put this in Notion."*

## Adding a new connector category

If you connect an MCP that doesn't match any category above, add a row to this table and reference it in the skill that needs it. Skill descriptions remain category-named; only the runtime probe table in `using-scriptorium/SKILL.md` maps category → concrete tool name.
