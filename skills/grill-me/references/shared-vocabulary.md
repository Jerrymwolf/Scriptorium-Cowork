# Shared vocabulary

Canonical file is at `../../grill-question/references/shared-vocabulary.md`.

This file is intentionally a pointer to avoid drift between the two grill skills. Both `grill-me` and `grill-question` reference the same vocabulary. Edits go in the canonical file.

If the Cowork skill loader doesn't follow this cross-reference at runtime, see `scripts/validate-plugin.js` — it allowlists this byte pair and warns on drift.
