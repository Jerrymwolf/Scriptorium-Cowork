---
name: lit-synthesizing
description: Use when the user asks to draft a literature review section, write a synthesis, or summarize the evidence. Produces synthesis.md with every claim backed by [paper_id:locator] tokens and runs a mandatory cite-check before committing.
---

# Literature Synthesizing (Cowork)

Input: `evidence` artifact (claims with paper+locator). Output: `synthesis` artifact where every sentence is either evidence-backed or deliberately meta (headings, transitions).

## Citation grammar

All citations use the token `[paper_id:locator]`. The locator format is defined in `lit-extracting`: `page:N`, `page:N-M`, `sec:<name>`, `abstract`, `L<n>-L<m>`. **Never** write `[1]`, `[2]`, or numbered-citation style — those are claim-search MCP grammar and are stripped at search time. If a sentence needs multiple citations, chain the tokens: `[W1:page:4][W2:sec:Discussion]`.

## Workflow

1. **Group evidence by concept.** Read the `evidence` artifact via the state adapter; group rows by `concept`. For each concept, you have positive, negative, neutral, and mixed rows.
2. **Draft one paragraph per concept.** Each paragraph names the concept, states the consensus (or lack of it), and cites the specific evidence. If directions disagree on a concept, write that disagreement into the paragraph — do **not** average.
3. **Write transitions.** Transitions are allowed to be uncited (they don't make empirical claims). Keep them short.
4. **Run the contradiction check** (hand off to `lit-contradiction-check`) before the final step; add its findings as a "Where authors disagree" subsection.
5. **Mandatory final step — cite-check before commit.**

## Cite-check (THIS IS A HARD GATE — DO NOT SKIP)

Cowork has no PostToolUse hook to enforce this for you. The skill itself is the discipline. Walk every sentence in the draft `synthesis`:

- For every `[paper_id:locator]` token in a sentence, confirm a row in `evidence` matches that exact `paper_id` and `locator`.
- If no token is present in a sentence, ask: is this sentence empirical (a claim about the literature) or meta (heading, transition, scaffolding)?
  - Empirical without a citation → it fails. Strip (strict) or flag `[UNSUPPORTED]` (lenient).
  - Meta → fine.
- If a token is present but does not resolve → strip (strict) or flag `[UNSUPPORTED]` (lenient).

**Strict mode default** for dissertation/systematic-review work; **lenient mode** for exploratory drafts. The user's preference is in the `scriptorium-config` user-memory note (set in `setting-up-scriptorium`).

After the cite-check, append one audit entry: `{phase: "synthesis", action: "verify", details: {n_sentences, n_citations, n_unsupported_stripped, n_unsupported_flagged, mode}, status}`. Status is `success` only if `n_unsupported_stripped == 0 OR mode == "strict"`. If the user is in lenient mode and there are flagged sentences, status is `warning`.

## What you must never do

- Do not invent paper ids or locators. "I think this is in Smith (2020)" is not a citation.
- Do not merge contradictory evidence into a single consensus sentence to look cleaner. Name the disagreement.
- Do not omit the cite-check. "I'll just scan visually" is how unsupported claims ship into dissertations. Cowork has no second line of defense — this skill IS the defense.

## Hand-off

After the cite-check passes, report: "Synthesis written; N sentences, M citations, K unsupported (stripped/flagged)." If contradictions have not yet been surfaced as a separate pass, fire `lit-contradiction-check` next. Otherwise hand off to the user for review.
