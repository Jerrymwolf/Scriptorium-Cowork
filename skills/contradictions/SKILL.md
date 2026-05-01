---
name: contradictions
description: Use when the user asks where papers disagree, wants to surface contradictions, or is preparing a "limits of the evidence" section. Groups evidence by concept, then runs a two-stage same-question check before deciding whether direction-mismatch is theoretical conflict or scope variation. Reports three buckets — same-question disagreements, scope-variation findings, and uncertain cases for human review.
---

# Literature Contradiction Check (Cowork)

Scriptorium refuses to average contradictory findings into bland consensus. But it also refuses to call something a contradiction when two studies are actually answering different questions in different populations or timeframes — that misframes scope variation as theoretical conflict and erodes the audit trail's defensibility. This skill runs a **two-stage check**.

## Stage 1 — gather candidate pairs

Read the `evidence` artifact. Group by `concept`. For each concept, find every pair where one row has `direction: positive` and another has `direction: negative`. These are *candidates*, not contradictions yet.

## Stage 2 — same-question judgment

For each candidate pair, ask the model: *"Are these two evidence rows answering the same question, or different questions on the same topic? 'Same question' requires matching: construct measured, population, timeframe of measurement, operationalization. If you're not sure, answer 'uncertain' rather than guessing."*

Provide both rows' full `claim` and `quote` text plus their `evidence_tier` so the judge has the methods context. Three-way output:

- `same_question` — both rows measure the same construct in the same population over the same timeframe with comparable operationalization. This is **theoretical conflict** — name the camps.
- `different_questions` — the rows differ on at least one of construct, population, timeframe, or operationalization. This is **scope variation** — they could both be true simultaneously.
- `uncertain` — the judge can't confidently distinguish. Better to flag for human review than to mis-frame.

The judgment is a slug-fragility safety valve: rather than relying on `concept`-slug equality (which a model wrote informally), the skill re-reads the prose at decision time. The `uncertain` bucket is the load-bearing piece — when the judge punts, the artifact says so rather than picking.

## Rendering — three templates

### Same-question disagreement (theoretical conflict)

> **<concept, in one noun phrase>.** Camp A (`[paper:loc]`, `[paper:loc]`) argues <positive direction claim>. Camp B (`[paper:loc]`) reports the opposite: <negative direction claim>. <One sentence on what distinguishes the camps — methods, sample, dose, year — drawn from the evidence rows themselves.> *Tier asymmetry note (if present): a meta-analysis [paper:loc] supports Camp A; the Camp B claim comes from a single cross-sectional study [paper:loc] — this is asymmetric weight.*

### Different-questions findings (scope variation)

> **<concept>.** Findings differ across <which dimension(s) varied — population, timeframe, operationalization>. Direction-positive in <population A / timeframe A / operationalization A> [paper:loc][paper:loc]; direction-negative in <population B / timeframe B / operationalization B> [paper:loc]. These are likely answering different questions rather than disagreeing on the same one. *Integration (if in evidence): <paper:loc> reconciles these as <e.g., "an acute-buffer-versus-chronic-depletion distinction">.*

### Uncertain (human review)

> **<concept>.** Two studies report opposite directions but I couldn't determine whether they're answering the same question or different ones — the methods, populations, or timeframes weren't comparable enough to call. `[paper:loc]` reports <positive>; `[paper:loc]` reports <negative>. Worth a human read before deciding which framing applies.

If Scite (`~~citation context`) resolved during the connector probe, optionally add a citation-context line to same-question disagreements: *"Across the wider literature Scite shows <N> supporting and <M> contrasting citations for these papers' core claims."*

## Audit

Append one entry per concept with at least one candidate pair: `{phase: "contradiction-check", action: "pairs.judged", details: {concept, n_candidates, n_same_question, n_different_questions, n_uncertain}, status: "success"}`. The triple counts are how a user (or their committee) can audit how the skill made the framing call — and how often it punted to `uncertain`.

## What you must never do

- Do not skip Stage 2 and render every candidate pair as a contradiction. That's the v0.1.2 bug.
- Do not silently pick `same_question` or `different_questions` when the methods context is thin — `uncertain` is a valid, honest answer.
- Do not invent a "winning" camp. Both camps are reported with their citations; the reader decides.
- Do not skip if there are zero candidates. Write a one-line `contradictions` artifact: *"No positive/negative pairs found across N concepts in the evidence."* Append a corresponding audit entry with `status: "success"` and `details.n_candidates: 0`.

## Hand-off

Insert rendered sections into `synthesis` under up to three separate headings: *"Where authors disagree on the same question"* (same-question), *"Where findings vary across populations / timeframes / operationalizations"* (different-questions), *"Disagreements I couldn't classify"* (uncertain). **Skip any heading whose bucket is empty** — never insert an empty section. If all three buckets are empty (no candidate pairs at all), insert a single one-liner under *"Notes on disagreement"*: *"No direction-mismatch pairs found across N concepts in the evidence."* Re-run `synthesize` Step 5 (cite-check) on the updated draft — the cite-check is mandatory after any synthesis edit.
