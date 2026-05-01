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

## Step 0 — Grill-me handoff state check

If `review` fired one of the grill-me skills before invoking this one, handoff state is in conversation context:

- From `grill-me`: `{purpose, audience, artifact, depth, tradition?, topic}`
- From `grill-question`: `{research_question, sub_questions, tradition, boundaries}`

Treat any present field as **resolved** in the inference pass (Step 2). Skip Tier 1+2 questions that already have answers. Go directly to Step 5 (recap and approval) with a one-line acknowledgment: *"You've already worked through purpose and question with the grill-me skill — let me confirm the scope and we'll search."*

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

## Step 5 — Recap and approval

Render exactly:

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

- Vague prompt → approval in ≤ 12 user messages (2–3 minutes).
- Semi-specified → ≤ 6 messages (45–90 seconds).
- Precise → ≤ 2 messages (< 30 seconds).

## What you must never do

- Never proceed to search without an approved scope.
- Never silently fill a resolved dimension the user did not confirm.
- Never treat soft warnings as blockers — surface them, let the user decide.
- Never skip the audit append on approval.
