---
name: synthesize
description: Use when the user asks to draft a literature review section, write a synthesis, or summarize the evidence. Produces synthesis.md with every claim backed by [paper_id:locator] tokens and runs a mandatory cite-check before committing.
---

# Literature Synthesizing (Cowork)

Input: `evidence` artifact (claims with paper+locator). Output: `synthesis` artifact where every sentence is one of four types: **factual**, **synthesis**, **argument**, or **meta** (heading, transition, scaffolding).

## Sentence-type contract (v1.0.0)

A literature review's value is the synthesis and argument layered over factual claims. Three tiers, each with its own anchor rule:

| Tier | Definition | Cite-check rule |
|---|---|---|
| **factual** | A claim about what a specific paper says, found, measured, or argued. | Must carry a single `[paper_id:locator]` token resolving to a verbatim quote in the evidence row. |
| **synthesis** | A claim that emerges from putting ≥2 papers next to each other (consensus, divergence, gap, comparison). | Must chain ≥2 `[paper_id:locator]` tokens, each resolving to a quote-anchored evidence row. The synthesis sentence itself need not be a quote — it's the system's bridge across cited facts. |
| **argument** | The author's interpretive position about what the synthesis means. Tagged in source markdown with `<arg>...</arg>` or rendered with an "interpretation" marker in HTML. | Must cite ≥1 synthesis or factual row, AND must be visibly tagged as interpretive. The argument layer is the **user's voice** by default — for `defending` intent, the system never commits to argument sentences without explicit user opt-in. |
| **meta** | Heading, transition, scaffolding. | No citation required. |

**Voice authorship policy** (A1, v0.5.0: voice is now keyed on `intent` directly, not `output_intent` — closes the v0.4.x incoherence where the disconfirmer gate (intent-keyed) and voice (output_intent-keyed) could disagree, e.g., `intent: defending + output_intent: memo` would fire the gate but write in building voice):

| `intent` | Voice | Behavior |
|---|---|---|
| `defending` | defending | system surfaces synthesis only; argument is the user's exclusive authorship |
| `building` | building | system *suggests* argument sentences as drafts the user can accept, edit, or reject |
| `curious` | curious | system may author argument sentences with an "interpretation" tag |

`intent` is set by `grill-question` Step 0 (R8) when the user picks explicitly. When `grill-question` doesn't fire (e.g., `grill-me` exits straight to `review` for memo / podcast / exploration / teaching / deck paths), intent is derived by `grill-me` per the default-intent table:

| `output_intent` | Default `intent` |
|---|---|
| chapter, brief | defending |
| memo, teaching, deck | building |
| podcast, exploration | curious |

The default-intent table preserves v0.4.1 behavior for users who never see the intent question — they still get the same voice as before. The change is that users who DO pick intent explicitly now have that pick honored, even when it's unusual for the artifact shape (e.g., `chapter + building`, `memo + defending`). `scope`'s soft-warning scan flags unusual combinations but never blocks.

**Why this matters:** the disconfirmer gate (R8) keys on `intent`. If voice keyed on `output_intent`, the two halves of the defending-position discipline could disagree — gate fires but voice doesn't. v0.5.0 puts both halves on `intent` so the discipline is internally coherent.

The cite-check (below) applies different rules per tier.

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
4. **Mandatory final step — cite-check before commit.** This skill verifies the current synthesis draft. In the end-to-end pipeline, `review` runs `contradictions` as the next phase and then re-runs this cite-check on the updated draft.

## Cite-check (HARD GATE — now mechanically enforced as of v0.3.0)

**Run `runtime/cite-check.py` after drafting.** This is the v0.3.0 mechanical-enforcement gate that prevents zero-citation synthesis from shipping.

```bash
python3 runtime/cite-check.py \
  --synthesis path/to/synthesis.md \
  --evidence path/to/evidence.jsonl \
  --corpus path/to/corpus.jsonl \
  --mode strict \
  --min-citations <N>
```

`<N>` is calibrated by `output_intent`: 10 for chapter, 6 for teaching/deck, 5 for brief, 3 for memo, 2 for podcast/exploration. The script exits non-zero on any failure. **If exit ≠ 0, do not ship.** Surface the script's output to the user verbatim, then either re-extract more evidence or revise the synthesis to drop unsupported claims.

### Two enforcement modes (R1 + R6, v0.4.0)

**Mechanical (script) mode — when shell is available.** `runtime/cite-check.py` walks sentences using substring `is_meta()` rules to identify headings/HRs/blockquotes/numbered-lists/empty lines as scaffolding (no cite required). This is fast, deterministic, and conservatively over-flags numbered-list-shaped empirical sentences (e.g. "1. 38% of participants showed…" — flagged as meta, then audited as a false positive). The trade is intentional: the script is the release gate, not the final word.

**The script does NOT enforce per-tier rules** (factual / synthesis / argument tier-specific citation requirements from the v1.0.0 sentence-type contract above). Per-tier enforcement requires Haiku-judged sentence classification and runs in inline mode only. The script's job is the floor: every cited token resolves, total citations meet the floor, no inferred metadata in strict mode. Per-tier discipline (e.g. "argument sentences must be `<arg>`-tagged AND carry ≥1 cite") is a v0.4.1 clarification — the script never claimed to enforce it; the prose now says so explicitly.

**Inline (Cowork-only) mode — when shell is NOT available.** Apply the algorithm below using Haiku judgment for borderline meta-vs-content cases (the script's substring rule's known weak spot). Synthesize uses Haiku for borderline meta-vs-content classification while the script uses substrings. Outputs are otherwise identical:

```
Cowork-only inline cite-check:

1. Read synthesis.md, evidence.jsonl, corpus.jsonl from state home.
2. Build evidence_keys = set of (paper_id, locator) tuples from evidence.
3. Build corpus_by_id = dict from corpus.
4. Split synthesis into sentences via regex
   r"(?<=[.!?])\s+(?=[A-Z\(\[\*])". For each sentence, classify
   meta vs. content:
   - Headings (^#+), HRs (^---), blockquotes (^>), bold-only
     (^\*\*.*\*\*$), and empty lines → meta (no cite needed).
   - Numbered/bulleted list-items: BORDERLINE — fire one Haiku
     call: "Is this sentence a heading/scaffolding line, or an
     empirical claim about a specific paper/finding? Reply 'meta'
     or 'content'."
5. For each content sentence, count matches of regex
   \[([a-zA-Z0-9][a-zA-Z0-9_\-]*:[a-zA-Z0-9_\-]+):
   (abstract|page:[0-9\-]+|sec:[a-zA-Z_\-]+|L[0-9]+-L[0-9]+)\]
   — same shape as the script.
6. For each match, check (paper_id, locator) ∈ evidence_keys;
   tally resolved/unresolved.
7. For each cited paper_id, look up corpus_by_id and tally
   metadata_resolution into verified/partial/inferred buckets.
8. Apply the same failure rules as the script:
   - n_total_cites < min_citations[output_intent] → failure
   - n_unresolved > 0 → failure
   - mode=strict AND inferred > 0 → failure
9. Emit the same report format as below. Append the same audit entry.
```

The inline mode produces the same outputs as `runtime/cite-check.py`. The substring/Haiku difference matters only for sentences that look like list-items but make empirical claims. Both modes catch the v0.2.2 zero-citation memo bug.

The minimum-citations floor is universal across all `output_intent` values.

## Cite-check (manual contract — runs alongside the script)

Cowork has no PostToolUse hook to enforce this for you. The skill itself is the discipline. The check has **two parts** — claim-to-evidence linkage AND citation metadata resolution. Both must pass.

**Part 1 — Claim linkage by tier.** Walk every sentence in the draft `synthesis`. Classify each as **factual**, **synthesis**, **argument**, or **meta** (use Haiku judgment via Cowork's `askClaude` shortcut, NOT substring rules — added v1.0.0). Apply the rule for that tier:

- **factual** sentence — must carry exactly one `[paper_id:locator]` token resolving to an evidence row. Missing or unresolved → strip (strict) or flag `[UNSUPPORTED]` (lenient).
- **synthesis** sentence — must carry ≥2 chained `[paper_id:locator]` tokens, each resolving. <2 cites or any unresolved → strip (strict) or flag (lenient).
- **argument** sentence — must (a) carry ≥1 cite to a factual or synthesis row, AND (b) be visibly tagged with `<arg>...</arg>` in source or "*interpretation*" in rendered output. Untagged argument or no underlying cite → strip (strict) or flag (lenient).
- **meta** sentence — no citation required. Pass.

The Haiku judgment replaces the v0.1.7 substring `is_meta()` rules. Prompt template (one call per uncited sentence):

> *"Classify this sentence into one of four types: factual (claims what a specific paper found/said/measured), synthesis (claims something emerging from comparing ≥2 papers), argument (the author's interpretive position about what the literature means), meta (heading, transition, scaffolding). Sentence: '...'. Reply with one word."*

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

## User narration (added v0.2.1)

Follow `NARRATION.md`. Synthesize has the second-worst silent period in the pipeline (long stretch between corpus and finished draft).

**Before drafting**, tell the user in plain language:

> Now I'm writing the draft. I'll group the findings by topic and weave
> them together, with every claim pointing back to a specific paper. This
> is one of the longer steps; I'll signal once the draft is ready.

**During drafting**, if you can emit progress (e.g., "halfway through the section on [topic]"), do. If not, at least signal you're still working periodically. The progress card in the sidebar (R5, v0.4.0) also shows the user where in the pipeline they are.

**Before the cite-check**, translate the gate into plain language:

> Draft is done. Now I'm double-checking that every claim in it points
> back to a real paper at a real spot — this is the discipline check we
> ran your spec through. Takes about a minute.

**After the cite-check passes**, summarize without internal vocabulary:

> All [N] claims trace back to a specific paper and quote. The draft is
> ready for you to read.

If the cite-check fails (any sentence won't resolve), explain in plain language what failed and what it means:

> Three sentences in the draft don't trace cleanly to a source — usually
> this means I synthesized too far from what the papers actually say. I'll
> show you exactly which ones and we can decide whether to soften, drop, or
> find a better citation.

**Never surface:** `[paper_id:locator]` tokens in user-facing chat, `metadata_resolution: inferred` jargon, three-tier sentence-typing terminology. The discipline operates underneath; the user sees its results in plain language.

## Hand-off

After the cite-check runs, report: "Synthesis written; N sentences, M citations, K unsupported (stripped/flagged)." If this skill was invoked by `review`, return control to `review` so it can run `contradictions` as the next phase. If the user invoked `synthesize` directly, ask whether they want to run `contradictions` next.
