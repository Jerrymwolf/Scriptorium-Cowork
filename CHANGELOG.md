# Changelog

All notable changes to scriptorium-cowork are documented here.

## 0.1.0 — 2026-04-29

Initial Cowork-native release of Scriptorium.

### Added
- Eleven skills covering the full lit-review pipeline (using-scriptorium, setting-up-scriptorium, lit-scoping, lit-searching, lit-screening, lit-extracting, lit-synthesizing, lit-contradiction-check, lit-audit-trail, lit-publishing, running-lit-review).
- INJECTION.md discipline preamble loaded by `using-scriptorium` to replace the missing Claude Code SessionStart hook.
- CONNECTORS.md documenting six tool categories (`~~claim search`, `~~breadth search`, `~~biomed search`, `~~document store`, `~~knowledge base`, `~~notebook publish`) with a state-home cascade rule.
- State-adapter mapping: NotebookLM > document store (Drive/Box/OneDrive) > knowledge base (Notion/Confluence) > session-only.
- Hard-gate cite-check at the end of `lit-synthesizing` (replaces the CC PostToolUse hook).
- Privacy gate in `lit-publishing` requiring explicit user consent before any upload to NotebookLM.

### Known limitations
- Connector probe in `using-scriptorium` uses prefix matching on MCP tool names; non-standard MCP server names may need a manual override.
- Reviewer-branch agents (`lit-cite-reviewer`, `lit-contradiction-reviewer`) are not yet implemented — synthesis-exit cite-check runs inline.
- On Cowork for Windows, the in-chat `.plugin` rich preview can fail (issue #50041 in claude-code repo); fall back to Settings → Plugins → Upload.
