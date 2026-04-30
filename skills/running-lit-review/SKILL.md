---
name: running-lit-review
description: Use when the user asks to run a lit review on a topic or research question end-to-end ("run a lit review on caffeine and working memory", "do a literature review for me on X"). Orchestrates the full pipeline — scope, search, screen, extract, synthesize, contradiction-check, audit, and optional publishing — by dispatching to the per-phase lit-* skills in order.
---

# Running a Literature Review (Cowork)

This skill runs the end-to-end review pipeline. It is the single entry point for a user who wants Scriptorium to do everything from a one-line prompt.

**Fire `using-scriptorium` first.** The connector probe must run before any phase begins, so downstream skills know which `~~category` resolves to which concrete tool.

## Phase sequence (authoritative)

0. **Direction check** — after the connector probe and before scoping, ask one question:

   > "Quick check before we dive in: do you already have a clear research question, or would you like to grill out your direction first?"

   Three responses route differently:

   - *"Clear question, just need the literature"* → continue to Step 1 (`lit-scoping`).
   - *"Clear topic but need the question"* → fire `research-questions-grill-me`. When it returns with `{research_question, sub_questions, tradition, boundaries}`, continue to Step 1 with that state pre-populated.
   - *"I'm not even sure what I want yet"* / *"grill me first"* → fire `research-grill-me`. It may route to `research-questions-grill-me` along the way; eventually returns with handoff state. Then continue to Step 1.

   Skip Step 0 entirely when (a) the user's initial prompt already contains a research question (a sentence ending with `?` that passes a basic So-What check), or (b) the user explicitly says they have it scoped.

1. **Scope** — fire `lit-scoping`. Produces a user-approved scope artifact. Every downstream phase reads it. If grill-me handoff state is present, scoping uses it as pre-resolved fields and only asks about gaps.
2. **Search** — fire `lit-searching`. Runs queries across the connected scholarly-search MCPs. Writes to `corpus`. Appends an audit entry.
3. **Screen** — fire `lit-screening`. Applies inclusion/exclusion criteria. Updates `corpus` row statuses. Appends an audit entry.
4. **Extract** — fire `lit-extracting`. For each kept paper, resolves full text via the cascade and writes evidence rows. Appends an audit entry per paper.
5. **Synthesize** — fire `lit-synthesizing`. Writes the synthesis. **The skill's mandatory final cite-check is the discipline checkpoint.** Do not skip.
6. **Contradiction-check** — fire `lit-contradiction-check` as a **separate pass** after synthesis, never inside it. Group evidence by concept; surface positive/negative disagreement as named camps; insert a "Where authors disagree" subsection into the synthesis; re-run the cite-check.
7. **Audit** — `lit-audit-trail` writes every phase transition. By the end, the trail contains entries for each phase.
8. **Publishing (optional)** — if the user asked for derivative artifacts (podcast / slides / mind map / video), fire `lit-publishing`. Preconditions: synthesis cite-check passed and contradiction-check has been run. If the user did not ask, skip this phase and offer it as a question at the end of the report-back.

## Report-back template (final turn)

When the pipeline exits, tell the user exactly:

- **Corpus size**: N returned, M deduped, K kept after screening.
- **Full-text rate**: `fetched / kept` (e.g. 28/42).
- **Evidence rows**: total rows in `evidence`, with tier breakdown (e.g., 86 rows: 4 meta-analysis · 12 experimental · 38 observational · 14 cross-sectional · 18 qualitative).
- **Cite-check**: unsupported sentences (0 is the goal); citation metadata resolution (verified / partial / inferred). In strict mode, any inferred ⇒ failure.
- **Contradictions**: three-bucket breakdown — N same-question disagreements · M scope-variation findings · K uncertain.
- **Outputs**: paths or note titles for `synthesis`, `contradictions`, `audit-md`, `references` (if exported), and any NotebookLM Studio artifacts.

End with a single question: "Do you want a podcast / slide deck / mind map / video of this review, or are we done?"

## What you must never do

- Run a phase out of order. Synthesis-before-extract is silent plagiarism risk.
- Smooth over contradictions during synthesis. That is `lit-contradiction-check`'s job.
- Skip the audit trail for any phase. The whole point of PRISMA is reconstructability.
- Re-implement search / screen / verify / extract logic inside this skill. Route to the per-phase skills every time.
- Accept a synthesis that did not pass the cite-check.
- Auto-publish without explicit user consent. The publishing privacy note in `lit-publishing` is mandatory.

## When a phase fails

If any phase emits an audit entry with `status: "failure"`, stop the pipeline. Surface the failure to the user with the full audit details. Offer two options: (a) retry the phase after addressing the cause, or (b) mark the failure acknowledged and continue (recorded as a `phase.override` audit entry — your committee will ask about overrides).
