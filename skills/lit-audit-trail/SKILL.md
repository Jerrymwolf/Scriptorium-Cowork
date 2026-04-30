---
name: lit-audit-trail
description: Use when the user asks for the audit trail, PRISMA flow, or a record of what happened during the review. Reads the append-only audit log from the state adapter and renders it as a PRISMA-flavored summary.
---

# Literature Audit Trail (Cowork)

The audit log is the single source of truth for reconstructing what happened. Every phase writes one entry per meaningful action; nothing is overwritten.

## Phases covered

- `scoping` — scope-approved event with the resolved dimensions
- `search` — every query against every source, with `n_results` and `n_after_dedupe`
- `screening` — every batch rule application, with kept/dropped counts
- `extraction` — every full-text resolution, with the cascade source that won and `n_evidence_rows`
- `synthesis` — verify runs, with unsupported/missing counts and mode
- `contradiction-check` — concept-level pair counts
- `publishing` — NotebookLM Studio artifact generations (from `lit-publishing`)

## Workflow

1. Read the `audit-jsonl` artifact via the state adapter (note `audit-jsonl`, file `audit.jsonl`, or page `Audit log`). The artifact contains one JSON line per action.
2. Parse each line into an `AuditEntry`: `{phase, action, details{}, ts, status}`.
3. Render the PRISMA-flavored summary below.

## PRISMA-flavored summary template

```
## PRISMA-style summary

1. Identification: <sum of n_results across all `search` actions> records returned across <list of sources>; <n_after_dedupe> after deduplication.
2. Screening:    <sum of `kept` across all `screening` actions> kept; <sum of `dropped`> dropped.
3. Eligibility:  <count of papers reaching `extraction` with full_text_source != "abstract_only"> papers with full text.
4. Included:     <count of papers with at least one row in evidence> papers contribute evidence.
5. Contradictions: <count of concepts with n_pairs ≥ 1> concepts with positive/negative disagreement.
```

This is the skeleton of a PRISMA 2020 flow diagram. Tell the user they can hand it to a reference manager or diagramming tool to produce the actual figure for their thesis.

## Reading raw entries

If the user asks "what happened in phase X" or "show the search queries," filter the parsed entries by `phase` and render them as a short table: `ts | action | status | details (one-line summary)`.

## Appending entries from other skills

Every lit-* skill appends its own entries; this skill is **read-focused**. If the user asks "log this," call the state adapter's audit-append helper directly: append a JSON line to the `audit-jsonl` artifact with the `AuditEntry` shape.

## Status enum interpretation

- `success` — the action completed as expected.
- `warning` — completed with caveats (e.g., synthesis cite-check in lenient mode flagged sentences).
- `failure` — the action was attempted and failed; details should explain.
- `partial` — the action completed for some inputs and not others.
- `skipped` — the user explicitly opted out of this action.

When summarizing, surface every `failure` and `warning` to the user before completing the report — these are the ones their committee will ask about.
