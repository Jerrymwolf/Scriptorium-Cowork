---
name: lit-contradiction-check
description: Use when the user asks where papers disagree, wants to surface contradictions, or is preparing a "limits of the evidence" section. Groups evidence by concept and reports positive vs negative camps explicitly instead of averaging.
---

# Literature Contradiction Check (Cowork)

Scriptorium refuses to average contradictory findings into a bland consensus sentence. When evidence on the same `concept` points in different directions, name the disagreement — **named camps**, not "some researchers find X while others find Y."

## Workflow

1. Read the `evidence` artifact via the state adapter.
2. Group entries by `concept`.
3. For each concept, list positive rows and negative rows. If both sides are non-empty, that concept is a contradiction.
4. **(Optional Scite enrichment.)** If `~~citation context` (Scite) resolved during the connector probe, for each contradiction look up the central claim with Scite and capture the supporting / contrasting / mentioning counts across the broader literature. This adds a "broader citation context" line per camp.
5. For each contradiction, write a paragraph following the named-camps template.
6. Write the assembled paragraphs to the `contradictions` artifact via the state adapter.
7. Append one audit entry per contradiction: `{phase: "contradiction-check", action: "pairs.found", details: {concept, n_pairs, scite_enriched: bool, scite_supporting?: int, scite_contrasting?: int}, status: "success"}`.
8. Insert the named-camps paragraphs into the `synthesis` artifact under a "Where authors disagree" heading; re-run `lit-synthesizing` Step 5 (cite-check) on the updated synthesis.

## Named-camps template (without Scite)

> **<Concept, in one noun phrase>.** Camp A (`[<paper_id_1>:<locator_1>]`, `[<paper_id_2>:<locator_2>]`) argues <positive direction claim>. Camp B (`[<paper_id_3>:<locator_3>]`) reports the opposite: <negative direction claim>. <One sentence on what distinguishes the two camps — methods, sample, dose, year — if the evidence supports it.>

## Named-camps template (with Scite enrichment)

When Scite is available, append one extra line per camp showing the broader citation pattern:

> **<Concept, in one noun phrase>.** Camp A (`[<paper_id_1>:<locator_1>]`, `[<paper_id_2>:<locator_2>]`) argues <positive direction claim>. Across the wider literature Scite shows <N> supporting and <M> contrasting citations for these papers' core claims. Camp B (`[<paper_id_3>:<locator_3>]`) reports the opposite: <negative direction claim>. Scite shows <P> supporting and <Q> contrasting citations for Camp B's claims. <One sentence on what distinguishes the two camps.>

This turns "two papers disagree" into "two papers disagree, and here's how the broader field has responded to each side." It is enrichment — never a substitute for the in-corpus evidence.

Mixed-direction rows are treated as a third camp only if there are at least two of them; otherwise fold them into the closer camp with a note.

## What counts as a contradiction

- Same `concept` slug
- At least one `direction: positive` row AND at least one `direction: negative` row
- Concepts with only neutral/mixed rows are **not** contradictions — they are noisy findings

## What this skill does NOT do

- Does not modify direction or concept fields in the evidence artifact.
- Does not invent a "winning" camp. Both camps are reported with their citations; the reader decides.
- Does not replace in-corpus citations with Scite citations. Scite enrichment is an additional line; the canonical evidence still comes from `evidence`.
- Does not skip if there are zero contradictions. Write a one-line `contradictions` artifact: "No positive/negative pairs found across N concepts in the evidence." Append a corresponding audit entry with `status: "success"` and `details.n_pairs: 0`.

## Hand-off

After insertion into synthesis, hand back to `lit-synthesizing` for the cite-check (Step 5) on the updated draft. The cite-check is mandatory after any synthesis edit.
