---
name: review
description: Use when the user asks to run a lit review on a topic or research question end-to-end ("run a lit review on caffeine and working memory", "do a literature review for me on X"). Orchestrates the full pipeline — scope, search, screen, extract, synthesize, contradictions, audit, and optional publishing — by dispatching to the per-phase skills in order.
---

# Running a Literature Review (Cowork)

This skill runs the end-to-end review pipeline. It is the single entry point for a user who wants Scriptorium to do everything from a one-line prompt.

**Fire `using-scriptorium` first.** The connector probe must run before any phase begins, so downstream skills know which `~~category` resolves to which concrete tool.

## Output-intent dispatch (added v0.3.0)

`review` accepts an `output_intent` parameter (set by `grill-me` or by direct invocation) that calibrates every downstream phase. The pipeline is the same; the calibration changes.

| `output_intent` | Corpus target | Synthesis length | Voice | Final artifact |
|---|---|---|---|---|
| `chapter` | exhaustive (200+) | 4,000–8,000 words | peer-review register | dissertation chapter, click-to-source viewer |
| `memo` | scan (10–15 papers) | ~800 words | strategic-recommendation framing | 1-page decision brief, click-to-source viewer |
| `brief` | representative (30–50) | ~1,500 words | exec-summary register | 2–3 page brief, viewer |
| `podcast` | scan (10–15 papers) | narrative ~1,200 words | conversational, NPR-lite | NotebookLM-ready bundle, viewer |
| `teaching` | representative (20–30) | ~2,000 words | pedagogical, examples-rich | teaching artifact, viewer |
| `exploration` | scan (5–10 papers) | ~600 words | tentative, hypothesis-shaped | exploration note, viewer |
| `deck` | representative (20–40) | bullet-density per slide | speaker-notes register | NotebookLM deck, viewer |

**Default if not set:** `chapter` (the most rigorous calibration; safer to over-research than under-research).

**Pass `output_intent` to every downstream phase.** `search` uses it to size corpus_target. `synthesize` uses it for register, length, and voice authorship policy. `render` uses it to format the final artifact. **Every audit entry's `details` block includes `output_intent`** — no exceptions. Downstream consumers that walk the audit log can filter or aggregate by intent without re-parsing scope.

## Progress artifact (R5, v0.4.0)

`review` maintains a Cowork artifact named `scriptorium-progress-<review-slug>` updated **before each phase begins** (so the user sees "scope is starting" rather than after the fact). The artifact is a self-contained HTML page rendered in the Cowork sidebar — glanceable status independent of narration cadence.

**Lifecycle:**

1. On `review` start (after the connector probe), call `mcp__cowork__create_artifact` with `id = scriptorium-progress-<review-slug>` and the template below populated with all dots `pending`.
2. Before each phase fires, call `mcp__cowork__update_artifact`:
   - The dot for the current phase → `active`
   - The dot for the previous phase → `done`, with a one-line `summary` populated (e.g., "Found 73 papers across 5 angles")
3. On phase failure (any `status: "failure"` audit entry), update the artifact: failed dot → `errored`; populate `errored_phase` in meta footer; freeze `active` advancement until user resolves with retry / override / stop.
4. On pipeline complete, all dots `done`, footer shows "Done · {{output_intent}} ready in your sidebar."

**HTML template** (inline in the create_artifact call; no external assets):

```html
<!DOCTYPE html>
<meta charset="utf-8">
<style>
  body { font-family: ui-sans-serif, system-ui; padding: 16px; max-width: 600px; }
  h2 { font-weight: 600; margin-bottom: 4px; }
  .subhead { color: #64748b; font-size: 0.9em; margin-bottom: 16px; }
  .step { display: flex; align-items: flex-start; padding: 8px 0; }
  .dot { width: 14px; height: 14px; border-radius: 50%;
    margin-right: 12px; margin-top: 4px; flex-shrink: 0; }
  .dot.done { background: #16a34a; }
  .dot.active { background: #2563eb; box-shadow: 0 0 0 4px #2563eb33; }
  .dot.pending { background: #cbd5e1; }
  .dot.errored { background: #dc2626; }
  .label { font-weight: 500; }
  .summary { color: #64748b; font-size: 0.9em; margin-top: 2px; }
  .meta { color: #94a3b8; font-size: 0.8em; margin-top: 16px;
    padding-top: 12px; border-top: 1px solid #e2e8f0; }
  .errored-meta { color: #dc2626; font-weight: 500; }
</style>
<h2>Literature review — {{topic}}</h2>
<div class="subhead">{{output_intent_plain_language}}</div>
<div id="steps">
  <!-- 7 step rows; each rendered with appropriate dot class -->
  <div class="step"><div class="dot {{s1}}"></div>
    <div><div class="label">Sharpening your question</div>
    <div class="summary">{{s1_summary}}</div></div></div>
  <div class="step"><div class="dot {{s2}}"></div>
    <div><div class="label">Searching the literature</div>
    <div class="summary">{{s2_summary}}</div></div></div>
  <div class="step"><div class="dot {{s3}}"></div>
    <div><div class="label">Filtering to what's relevant</div>
    <div class="summary">{{s3_summary}}</div></div></div>
  <div class="step"><div class="dot {{s4}}"></div>
    <div><div class="label">Pulling key findings from each paper</div>
    <div class="summary">{{s4_summary}}</div></div></div>
  <div class="step"><div class="dot {{s5}}"></div>
    <div><div class="label">Writing the draft</div>
    <div class="summary">{{s5_summary}}</div></div></div>
  <div class="step"><div class="dot {{s6}}"></div>
    <div><div class="label">Where the literature pushes back</div>
    <div class="summary">{{s6_summary}}</div></div></div>
  <div class="step"><div class="dot {{s7}}"></div>
    <div><div class="label">Assembling your viewable document</div>
    <div class="summary">{{s7_summary}}</div></div></div>
</div>
<div class="meta">
  Updated {{ts}} · Output: {{output_intent}}
  {{#if errored}}<span class="errored-meta"> · ⚠ Stopped at: {{errored_phase}}</span>{{/if}}
</div>
```

Phase labels are user-language (no "extract", "screen" jargon) per `NARRATION.md`'s vocabulary table.

## Phase sequence (authoritative)

0. **Direction check** — after the connector probe and before scoping, ask one question:

   > "Quick check before we dive in: do you already have a clear research question, or would you like to grill out your direction first?"

   Three responses route differently:

   - *"Clear question, just need the literature"* → continue to Step 1 (`scope`).
   - *"Clear topic but need the question"* → fire `grill-question`. When it returns with `{research_question, sub_questions, tradition, boundaries}`, continue to Step 1 with that state pre-populated.
   - *"I'm not even sure what I want yet"* / *"grill me first"* → fire `grill-me`. It may route to `grill-question` along the way; eventually returns with handoff state. Then continue to Step 1.

   Skip Step 0 entirely when (a) the user's initial prompt already contains a research question (a sentence ending with `?` that passes a basic So-What check), OR (b) the user explicitly says they have it scoped, OR **(c) `grill-me` or `grill-question` just handed off — their handoff state contains the direction signal Step 0 was about to ask for** (R4, v0.4.0: closes the v0.3.0 redundancy bug where review re-asked direction even after grill flows resolved it).

1. **Scope** — fire `scope`. Produces a user-approved scope artifact. Every downstream phase reads it. If grill-me handoff state is present, scoping uses it as pre-resolved fields and only asks about gaps.
2. **Search** — fire `search`. Runs queries across the connected scholarly-search MCPs. Writes to `corpus`. Appends an audit entry.
3. **Screen** — fire `screen`. Applies inclusion/exclusion criteria. Updates `corpus` row statuses. Appends an audit entry.
4. **Extract** — fire `extract`. For each kept paper, resolves full text via the cascade and writes evidence rows. Appends an audit entry per paper.
5. **Synthesize** — fire `synthesize`. Writes the initial synthesis and runs the mandatory cite-check. Do not ask `synthesize` to run `contradictions`; contradiction surfacing is the next phase.
6. **Contradictions** — fire `contradictions` as a separate pass after the initial synthesis cite-check. Group evidence by concept; surface positive/negative disagreement as named camps, scope variation, or uncertain cases; insert the relevant disagreement sections into the synthesis; re-run `synthesize`'s cite-check on the updated draft.
7. **Audit** — `audit` writes every phase transition. By the end, the trail contains entries for each phase.
8. **Publishing (optional)** — if the user asked for derivative artifacts (podcast / slides / mind map / video), fire `publish`. Preconditions: synthesis cite-check passed and contradiction-check has been run. If the user did not ask, skip this phase and offer it as a question at the end of the report-back.

## Report-back template (final turn)

When the pipeline exits, tell the user exactly:

- **Corpus size**: N returned, M deduped, K kept after screening.
- **Full-text rate**: `fetched / kept` (e.g. 28/42).
- **Evidence rows**: total rows in `evidence`, with tier breakdown (e.g., 86 rows: 4 meta-analysis · 12 experimental · 38 observational · 14 cross-sectional · 18 qualitative).
- **Cite-check**: unsupported sentences (0 is the goal); citation metadata resolution (verified / partial / inferred). In strict mode, any inferred ⇒ failure.
- **Contradictions**: three-bucket breakdown — N same-question disagreements · M scope-variation findings · K uncertain.
- **Outputs**: paths or note titles for `synthesis`, `contradictions`, `audit-md`, `references` (if exported), and any NotebookLM Studio artifacts.

End with a single question, **adapted to `output_intent`** (R12, v0.4.0 — closes the v0.3.0 chapter-shaped-closing-for-everyone bug):

| `output_intent` | Closing question |
|---|---|
| `chapter` | "Want a podcast version, slides, or are we good?" |
| `brief` | "Want a slide-ready version, or are we done?" |
| `memo` | "Want this in Slack-ready format, a one-pager, or are we done?" |
| `podcast` | "Want me to ship this to NotebookLM, or are we done?" |
| `teaching` | "Want a slide deck, a handout, or are we done?" |
| `deck` | "Want me to ship to NotebookLM Studio, or are we done?" |
| `exploration` | "Want me to deepen any of this into a longer piece, or are we done?" |

If `output_intent` is unset (legacy v0.3.0 sessions), default to the chapter closing.

## What you must never do

- Run a phase out of order. Synthesis-before-extract is silent plagiarism risk.
- Smooth over contradictions during synthesis. That is `contradictions`'s job.
- Skip the audit trail for any phase. The whole point of PRISMA is reconstructability.
- Re-implement search / screen / verify / extract logic inside this skill. Route to the per-phase skills every time.
- Accept a synthesis that did not pass the cite-check.
- Auto-publish without explicit user consent. The publishing privacy note in `publish` is mandatory.

## When a phase fails

If any phase emits an audit entry with `status: "failure"`, stop the pipeline. Surface the failure to the user with the full audit details. Offer two options: (a) retry the phase after addressing the cause, or (b) mark the failure acknowledged and continue (recorded as a `phase.override` audit entry — your committee will ask about overrides).

## User narration (added v0.2.1)

Follow `NARRATION.md`. Review is the orchestrator; it sets the tone for the whole session.

**At session start**, give the user the whole road map up front. (R15, v0.4.0: dropped hard minute estimates — they were aspirational and Cowork latency varies. Replaced with relative phrases per `NARRATION.md` §Timing language.)

> Here's the plan for your review:
> 1. First, I'll make sure your question is sharp (a few rounds of
>    back-and-forth)
> 2. Then I'll search the literature
> 3. Filter to what's relevant (fast)
> 4. Pull key findings from each paper (this is the longest single step)
> 5. Write the draft and double-check every claim
> 6. Surface where the literature pushes back
> 7. Hand you a viewable document
>
> I'll narrate as I go and update a progress card in your sidebar so you can see where we are.

**Between phases**, tell the user the previous phase finished and the next phase is starting in plain language. Don't just say "moving to phase 4"; say "now I'm pulling the key findings from each paper."

**At session end**, recap what the user has and what they can do with it:

> Done. Here's what you have:
> - A draft chapter, every claim cited
> - A click-to-source viewer where you can hover any citation and see
>   the source quote
> - A record of every search and decision (the audit trail) in case
>   your advisor or committee asks
>
> Want a podcast version, slides, or are we good?

## Interactive choices (added v0.2.2)

Every multi-choice question in this skill fires a form widget per `NARRATION.md` §Interactive choice contract.

**Direction check (Step 0)**: pills for the three responses (clear question / clear topic but need question / not even sure) plus `data-other`.

**End-of-pipeline question**: pills for derivative artifacts (podcast / slide deck / mind map / video / done) plus `data-other`.

**Failure-handling question** ("retry the phase or override?"): pills for retry / override + textarea for explanation.

Always include `data-other`. Never lock the user into the option set.
