---
name: synthesize
description: Use when the user asks to draft a literature review section, write a synthesis, or summarize the evidence. Produces synthesis.md with every claim backed by [paper_id:locator] tokens and runs a mandatory cite-check before committing.
---

# Literature Synthesizing (Cowork)

Input: `evidence` artifact (claims with paper+locator). Output: `synthesis` artifact where every sentence is either evidence-backed or deliberately meta (headings, transitions).

## Citation grammar

All citations use the token `[paper_id:locator]`. The locator format is defined in `extract`: `page:N`, `page:N-M`, `sec:<name>`, `abstract`, `L<n>-L<m>`. **Never** write `[1]`, `[2]`, or numbered-citation style — those are claim-search MCP grammar and are stripped at search time. If a sentence needs multiple citations, chain the tokens: `[W1:page:4][W2:sec:Discussion]`.

## Workflow

1. **Group evidence by concept.** Read the `evidence` artifact via the state adapter; group rows by `concept`. For each concept, you have positive, negative, neutral, and mixed rows. Note each row's `evidence_tier`.
2. **Draft one paragraph per concept, modulating register by tier.** Each paragraph names the concept, states the consensus (or lack of it), and cites the specific evidence. If directions disagree on a concept, write that disagreement into the paragraph — do **not** average.

   Render prose register according to the highest tier present for that concept:

   - `meta_analysis` / `systematic_review` → declarative: *"X improves Y [paper:loc]."*
   - `experimental` (single study) → qualified: *"In a randomized trial of [N] [population], X was associated with improved Y [paper:loc]."*
   - `observational` / `cross_sectional` → correlational: *"X correlates with Y in [population] [paper:loc]; causal inference is not warranted."*
   - `qualitative` → interpretive: *"In interviews with [population], X was described as a contributor to Y [paper:loc]."*
   - `theoretical_or_review` → attributive: *"X has been argued to influence Y [paper:loc]."*

   When a concept has rows at multiple tiers, lead with the highest and **name the tier explicitly in prose** ("a meta-analysis of fourteen trials shows…", "a single cross-sectional survey of college students reports…"). The explicit naming is the only mechanism that survives the markdown→audio handoff to NotebookLM — the host model has no metadata channel; it reads the synthesis as text.
3. **Write transitions.** Transitions are allowed to be uncited (they don't make empirical claims). Keep them short.
4. **Run the contradiction check** (hand off to `contradictions`) before the final step; add its findings as a "Where authors disagree" subsection.
5. **Mandatory final step — cite-check before commit.**

## Cite-check (THIS IS A HARD GATE — DO NOT SKIP)

Cowork has no PostToolUse hook to enforce this for you. The skill itself is the discipline. The check has **two parts** — claim-to-evidence linkage AND citation metadata resolution. Both must pass.

**Part 1 — Claim linkage.** Walk every sentence in the draft `synthesis`:

- For every `[paper_id:locator]` token in a sentence, confirm a row in `evidence` matches that exact `paper_id` and `locator`.
- If no token is present in a sentence, ask: is this sentence empirical or meta (heading, transition, scaffolding)?
  - Empirical without a citation → it fails. Strip (strict) or flag `[UNSUPPORTED]` (lenient).
  - Meta → fine.
- If a token is present but doesn't resolve → strip (strict) or flag `[UNSUPPORTED]` (lenient).

**Part 2 — Metadata resolution.** For every cited evidence row, read its `metadata_resolution` value (inherited from the `Paper` shape via `search`). Count three buckets: `verified`, `partial`, `inferred`.

- **Strict mode** blocks commit (status `failure`) if **any** citation in the synthesis carries `metadata_resolution: "inferred"`. The README's promise is "synthesis you can defend" — a single inferred-title citation is the kind of thing a committee member spot-checks and uses to question the whole audit trail. The threshold is binary: none of the citations are guessed.
- **Lenient mode** emits a per-sentence warning list naming every inferred citation and the inferred field(s), so the user knows exactly which to verify by hand before submission.

**Strict mode** is the default for any user who mentioned dissertation, thesis, or systematic review during setup. **Lenient** is the default for exploratory drafts. Preference lives in `scriptorium-config`.

## Cite-check report format

Print exactly:

```
Synthesis verify — <strict | lenient> mode

Sentences total:                    <N>
Sentences with citations:           <N>
Citations resolved to evidence:     <N> / <N>   ✓
Citation metadata resolution:
  verified:    <N> (<%>)
  partial:     <N> (<%>)
  inferred:    <N> (<%>)            ⚠   (omit ⚠ when count is 0)

Unsupported sentences (no evidence row):  <N>   (in strict, "<N> stripped"; in lenient, "<N> flagged")
Inferred-metadata sentences:              <N>   (in strict and N>0, "BLOCKED — see audit row"; in lenient, "flagged for spot-check")

Status: <success | warning | failure>
```

After the cite-check, append one audit entry: `{phase: "synthesis", action: "verify", details: {n_sentences, n_citations, n_unsupported_stripped, n_unsupported_flagged, n_metadata_verified, n_metadata_partial, n_metadata_inferred, mode}, status}`. Status is `success` only if `n_unsupported_stripped == 0 AND n_metadata_inferred == 0`. Status is `warning` in lenient mode when either count is non-zero. Status is `failure` in strict mode when either is non-zero.

## What you must never do

- Do not invent paper ids or locators. "I think this is in Smith (2020)" is not a citation.
- Do not merge contradictory evidence into a single consensus sentence to look cleaner. Name the disagreement.
- Do not omit the cite-check. "I'll just scan visually" is how unsupported claims ship into dissertations. Cowork has no second line of defense — this skill IS the defense.

## Hand-off

After the cite-check passes, report: "Synthesis written; N sentences, M citations, K unsupported (stripped/flagged)." If contradictions have not yet been surfaced as a separate pass, fire `contradictions` next. Otherwise hand off to the user for review.
