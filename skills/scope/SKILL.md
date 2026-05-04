---
name: scope
description: Use when the user asks to scope, frame, or plan a literature review before searching begins, OR when invoked by review, OR when search finds no scope object. Produces a user-approved scope object that drives every downstream phase. Adaptive — vague prompts get many questions, precise prompts skip straight to a recap.
---

# Literature Scoping (Cowork)

The goal of this skill is a single artifact: a **user-approved scope object** that every downstream skill reads. Running this skill is the only legitimate way to produce that artifact.

**Fire `using-scriptorium` first.** The connector probe must have run before you continue — scope persistence depends on the state home it picked.

## The three disciplines

1. **Adaptive depth** — ask only what the initial prompt has not already resolved.
2. **Recap + approval gate** — never proceed to search without an explicit user approval of a structured recap.
3. **Audit trail** — on approval, append one `scope_approved` entry to the audit log via the state adapter.

## Step 0 — Grill-me handoff state check (extended v0.4.0 — R2)

If `review` fired one of the grill-me skills before invoking this one, handoff state is in conversation context:

- From `grill-me`: `{purpose, audience, artifact, depth, tradition?, topic, output_intent}`
- From `grill-question`: `{research_question, sub_questions, tradition, boundaries, intent, disconfirmer, output_intent}`
- From `review` direct: `{output_intent, depth}` (if user came in with a clear question)

Treat any present field as **resolved** in the inference pass (Step 2). Skip Tier 1+2 questions that already have answers. Go directly to Step 5 (recap and approval) with a one-line acknowledgment: *"You've already worked through purpose and question with the grill-me skill — let me confirm the scope and we'll search."*

### Output_intent calibration table (R2, v0.4.0)

If `output_intent` is present in handoff, auto-resolve these dimensions from the calibration table below. Explicit user overrides always win — calibration only fills unresolved gaps.

| `output_intent` | corpus_target | year_range | publication_types | depth |
|---|---|---|---|---|
| `chapter` | exhaustive | 1985+ | peer-reviewed | exhaustive |
| `memo` | 12 | last 10y | peer-reviewed + grey | representative |
| `brief` | 35 | last 10y | peer-reviewed | representative |
| `podcast` | 12 | no restriction | any | representative |
| `teaching` | 25 | no restriction | peer-reviewed | representative |
| `exploration` | 8 | no restriction | any | scan |
| `deck` | 30 | last 10y | peer-reviewed | representative |

Skip Tier 1+2 questions for any dimension auto-resolved by this table. If the user explicitly contradicts a calibration value (e.g., output_intent=memo but they ask for 50 papers), the explicit value wins.

## Step 1 — Existing-scope check

If a `scope` artifact already exists at the state home (note titled `scope`, file `scope.json`, or page `Scope`), present:

```
An existing scope was found (created <ts>).
  1. Resume with this scope and proceed to search
  2. Review and edit this scope
  3. Discard and start fresh
```

- Option 1: load the scope, skip to Step 5.
- Option 2: load the scope, treat all present fields as resolved, jump to Step 4.
- Option 3: delete the scope artifact, continue.

## Step 2 — Inference pass

Parse the user's initial prompt. For each dimension below, mark it **resolved** only if the signal is unambiguous. When in doubt, leave it unresolved.

| Dimension | Signal |
|---|---|
| research_question | interrogative or declarative topic statement |
| purpose | dissertation, grant, chapter, systematic, scoping, overview |
| fields | named disciplines |
| population | PICO-style noun phrases ("adolescents", "remote workers") |
| methodology | "RCTs", "qualitative", "ethnographies", "mixed methods" |
| year_range | explicit years or relative phrases ("last 5 years") |
| corpus_target | numbers + "papers"/"studies" |
| publication_types | "peer-reviewed", "preprints", "grey literature", "dissertations" |
| depth | "systematic", "exhaustive", "representative", "canonical" |
| anchor_papers | DOIs, author-year citations |

## Step 3 — Tiered questioning

Count resolved Tier 1+2 dimensions. **<4 resolved**: ask all unresolved Tier 1+2. **4–8**: ask only gaps. **9+**: skip to Step 4.

Tier 1 (always, for unresolved):
- "What specific question are you trying to answer?"
- "What is this review for? Dissertation chapter, grant proposal, narrative overview, systematic review, or scoping review?"
- "Which fields should the search cover?"

Tier 2 (when prompt is vague):
- Population, methodology, year range, corpus target, publication types, depth.

Ask one question at a time. Never batch.

Tier 3 (always offered as a single menu after 1+2):
```
Want to go deeper? I can also ask about:
  A. Conceptual frame — the theories or constructs you're working within
  B. Prior anchors — papers/authors you already trust
  C. Output intent — what you're producing (chapter, podcast, deck, export)
  D. Known gaps — are you trying to surface thin or absent areas?

Type letters to add questions, or 'skip'.
```

## Step 4 — Soft-warning scan

Before rendering the recap, check for these. Warnings go into the recap under "Soft warnings"; they are **not blocking**.

| Condition | Warning |
|---|---|
| `purpose=systematic` AND `depth=representative` | "Systematic reviews typically require exhaustive retrieval — confirm or revise depth." |
| `purpose=systematic` AND `corpus_target` < 25 | "Systematic reviews typically retrieve all eligible papers — a hard cap may not be appropriate." |
| `methodology=RCT` AND no medicine/psychology/education in fields | "RCTs are uncommon outside medicine/psych/education — confirm or broaden." |
| `publication_types=[preprints]` only AND `purpose=dissertation` | "Dissertations usually require peer-reviewed sources — confirm or broaden." |
| `depth=exhaustive` AND numeric `corpus_target` | "Exhaustive retrieval and a numeric target can conflict — clarify which governs." |

### Intent × output_intent unusual-combination warnings (A1, v0.5.0)

Added v0.5.0 alongside the voice authorship policy fix. When the user explicitly picks an `intent` (via `grill-question` Step 0) that's unusual for the chosen `output_intent`, surface a soft warning so they can confirm or revise. Never blocks.

| Condition | Warning |
|---|---|
| `output_intent=chapter` AND `intent=curious` | "Chapters usually defend a position. Confirm `curious` intent — system will author argument sentences with interpretation tags." |
| `output_intent=memo` AND `intent=curious` | "Memos usually carry a recommendation. Want exploration mode instead?" |
| `output_intent=exploration` AND `intent=defending` | "Exploration is for thinking out loud, not staking a position. Want chapter or brief instead?" |
| `output_intent=exploration` AND `intent=building` | "Exploration is for thinking out loud, not building an argument. Want memo or brief instead?" |
| `output_intent=podcast` AND `intent=defending` | "Defended-position podcasts exist (op-ed style) but are rare — confirm intent." |
| `output_intent=deck` AND `intent=curious` | "Decks usually carry a recommendation or instruction. Want exploration mode instead?" |
| `output_intent=deck` AND `intent=defending` | "Defended-position decks exist (board-deck style) but are rare — confirm intent." |

The warning triggers when `intent` is **explicitly user-set** (came from `grill-question` Step 0 with cold-start path), NOT when `intent` was derived from the default-intent table in `synthesize/SKILL.md` (which means the user didn't see the question). Distinguish the two via the `intent_source: "user" | "derived"` field in handoff state.

## Step 5 — Recap and approval (adapted to output_intent — R10, v0.4.0)

Pick one of two recap shapes based on `output_intent`:

### Full recap — for `chapter` / `brief` / `teaching` / `deck`

These intents need every dimension visible because the final artifact will be defended (chapter, brief) or distributed (teaching, deck) and dimensions like methodology and publication_types matter.

```
📋 Scoping recap — please review

Research question: <value>
Purpose:           <value>
Field(s):          <comma-joined>
Population:        <value or "not specified">
Methodology:       <value>
Year range:        <YYYY–YYYY or "no restriction">
Corpus target:     <value>
Publication types: <comma-joined>
Depth:             <exhaustive | representative>

Tier 3 (advanced):
<only resolved Tier 3 dims>

⚠ Soft warnings:
<one per line, or "None.">

Approve and proceed to search? (approve / revise <dimension> / start over)
```

### Condensed recap — for `memo` / `podcast` / `exploration`

These intents are time-sensitive and the user doesn't need (or want) a dissertation-style table for a Slack-ready memo or a 5-minute exploration.

```
📋 Plan check

Question:         <value>
Aiming for:       <output_intent rendered plain — "1-page strategy memo" / "podcast bundle" / "exploration note">
Audience:         <value>
How deep:         <scan | representative>
Disconfirmer:     <value, only if defending intent>

⚠ Soft warnings:
<one per line, or "None.">

Look right? (approve / adjust)
```

The condensed recap drops year_range, methodology, publication_types, and corpus_target — they're auto-resolved from the calibration table in Step 0 and the user doesn't need to confirm dissertation-style fields for a memo.

Both forms support the same response handling below.

Handle responses:
- **approve** → Step 6.
- **revise <dim>** → re-ask that dimension only, re-render.
- **start over** → clear resolved state, go to Step 2.

If 3 revision cycles pass without approval, proactively offer "Want to start over with a fresh prompt?"

## Step 6 — Persist and hand off

1. Build the scope object: `{scope_version: 1, research_question, purpose, fields, population, methodology, year_range, corpus_target, publication_types, depth, tier3, soft_warnings, anchor_papers, approved_at}`.
2. Write it to the state home via the adapter. If state home is session-only, hold it in conversation memory and warn the user: "Scope will not persist beyond this session — export before closing."
3. Append one audit entry: `{phase: "scoping", action: "scope_approved", details: {dimensions_resolved_via_inference: [...], dimensions_resolved_via_question: [...], tier3_dimensions_selected: [...], soft_warnings_acknowledged: [...], revision_cycles: <n>}, status: "success"}`.
4. Tell the user: "Scope approved and saved. Handing off to `search`."

## Performance targets

- Vague prompt → approval in ≤ 12 user messages.
- Semi-specified → ≤ 6 messages.
- Precise → ≤ 2 messages.

(R15, v0.4.0: dropped wall-clock estimates; message-count budgets are a more honest performance contract.)

## What you must never do

- Never proceed to search without an approved scope.
- Never silently fill a resolved dimension the user did not confirm.
- Never treat soft warnings as blockers — surface them, let the user decide.
- Never skip the audit append on approval.

## User narration (added v0.2.1)

Follow `NARRATION.md`. Scope is mostly inference + brief gap-filling; the visible surface is the recap.

**When showing the scoping recap:**

Render the recap in plain language — not as a JSON dump or a config table. The recap is the user's last chance to course-correct before the pipeline runs.

> Here's the plan I'm going to run with:
> - Question: [in the user's words]
> - Aiming for: [chapter / brief / podcast / etc.]
> - Audience: [who]
> - How deep: [scan / standard / exhaustive — translated]
> - Year window: [years or "no restriction"]
> - What would change your mind: [the disconfirmer]
>
> Look right? Say "go" or tell me what to adjust.

Never surface `scope_version`, `tier3`, `soft_warnings`, or other field-name jargon.

## Interactive choices (added v0.2.2)

Every multi-choice question in this skill fires a form widget per `NARRATION.md` §Interactive choice contract.

**Recap approval**: pills for `approve` / `revise <dimension>` / `start over` plus `data-other` for arbitrary edits.

**Per-dimension revision questions** (purpose, fields, methodology, depth, etc.): pills with the inferred default highlighted, plus `data-other`.

**Year range**: pills for common windows (last 5y / last 10y / 1985+ / no restriction) plus `data-other` for custom dates.

Always include `data-other`.
