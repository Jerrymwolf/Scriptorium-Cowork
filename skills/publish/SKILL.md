---
name: publish
description: Use when the user asks for a podcast, slide deck, mind map, or video of a finished review. Publishes the review's artifacts to a NotebookLM notebook (or guides the user through the manual upload path if NotebookLM is not connected) and triggers Studio artifact generation.
---

# Literature Publishing (Cowork)

This skill is the bridge from a finished review to a downstream artifact (audio, deck, mindmap, video). It is **the one operation that intentionally moves your corpus off the user's connected stores into Google's NotebookLM.** Every publish is logged.

## Preconditions (HARD GATE)

Do not fire this skill until ALL of the following are true:

- `synthesis` artifact exists and its most recent cite-check entry has `status: "success"` (strict mode) OR `status: "warning"` with explicit user acknowledgment (lenient mode).
- `contradictions` artifact exists (even if empty — `contradictions` writes a one-liner when there are no candidates).
- `evidence` artifact exists.
- The audit log's most recent `synthesis.verify` entry has `n_unsupported_stripped == 0` AND `n_metadata_inferred == 0` for strict mode. In lenient mode, surface both counts to the user before proceeding and require explicit confirmation: *"Your most recent cite-check flagged N inferred citations and M unsupported sentences. Publishing will upload them as-is. Proceed?"*

If any precondition fails, refuse to publish and say which one. Hand back to the appropriate skill (usually `synthesize` for re-running the cite-check).

## Workflow — `~~notebook publish` connected

1. Confirm the user wants to publish, what they want to generate (audio, deck, mindmap, video, or all), and the notebook title.
2. Create a fresh NotebookLM notebook via `~~notebook publish` `notebook_create(title)`.
3. Upload sources in this fixed order, waiting briefly between each:
   - `synthesis` (as a text source named `synthesis`)
   - `contradictions` (as a text source named `contradictions`)
   - `evidence` (as a text source named `evidence`)
   - All PDFs in the review's `pdfs/` folder, alphabetical order, as native PDF sources
4. Trigger the requested Studio artifact via `studio_create(artifact_type=…)`. Poll `studio_status` until ready.
5. Append one audit entry per artifact: `{phase: "publishing", action: "studio.create", details: {notebook_id, notebook_url, artifact_type, artifact_id, sources_uploaded: [...], sources_skipped: [...]}, status}`.
6. Tell the user the notebook URL and the artifact URL.

## Workflow — no `~~notebook publish` connected

There is no Cowork-native fallback that produces a podcast or slide deck from raw markdown. Tell the user, then offer the manual path:

1. Open https://notebooklm.google.com and create a notebook.
2. Upload the synthesis, contradictions, evidence artifacts, and the PDFs from your review's state home.
3. Use the Studio panel to generate the artifact you want.

Append an audit entry: `{phase: "publishing", action: "manual.guidance", details: {reason: "no notebook publisher connected", artifact_requested}, status: "skipped"}`. The user's record stays consistent whether they used the automated path or the manual one.

## Privacy note (always show)

Before publishing automatically, tell the user verbatim:

> Publishing uploads your review's artifacts and PDFs to a third-party service (NotebookLM, run by Google). This is the one operation in Scriptorium that intentionally moves your corpus off the connectors you've chosen. Every upload is logged to your audit trail. Do you want to proceed?

Wait for explicit confirmation. Do not assume "publish" itself implies consent for which files leave.

## What you must never do

- Publish without the cite-check having passed first.
- Skip the audit entry. The publishing audit is the single most important row in the trail — it's what your committee asks about when they ask "where did the corpus go?"
- Try to recover from a Studio quota error by retrying silently. Surface the raw error to the user; let them decide.
