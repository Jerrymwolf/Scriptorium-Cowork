# Narration contract

Every Scriptorium skill follows this contract for user-facing prose during long-running operations. The goal: a Scriptorium session reads like a person walking the user through what they're doing, not a build log.

The bar is the **Annie test**: would someone who's never used Scriptorium and doesn't know the word "corpus" or "evidence row" understand what just happened and why, in one read, without re-reading?

If a user-facing message fails the Annie test, rewrite it.

## The narration rhythm

For any operation lasting more than ~5 seconds:

1. **Before the operation** — write a plain-language paragraph (~3–5 sentences) saying:
   - What's about to happen (in the user's words, not yours)
   - Why it matters
   - **Relative duration**, NOT wall-clock minutes. See §Timing language below. (R15, v0.4.0: dropped "about 1–3 minutes" examples — Cowork latency varies and the estimates were aspirational.)

2. **During the operation** — emit at least one short user-facing sentence per ~30 seconds of compute. If the operation is a series of sub-steps (e.g., five search queries), emit one sentence per sub-step completion.

3. **After the operation** — write one human sentence summarizing what just happened, then transition to what's next.

## Timing language (added v0.4.0)

Don't promise minutes. Promise **narration**.

Acceptable phrasings:
- "I'll narrate as I go"
- "this takes a while; I'll mark each [search/paper/section] as it finishes"
- "this is the longest single step"
- "almost done — last step is fast"
- "I'll update the progress card in your sidebar after each phase"

Why: real Cowork pipeline latency varies by connector, corpus size, and model load. Hard estimates ("12–20 minutes", "about 2 minutes") set expectations the system can't reliably meet. The progress artifact (R5, v0.4.0) plus per-step narration carries the same reassurance without an over-claimed timer.

Smoke test grep verifies no minute-counts remain in skill prose.

## Cost budget

Narration adds, across an entire pipeline run, no more than ~800 words of user-facing prose. Per phase: one paragraph pre, one sentence per ~30 sec of compute, one sentence post. If a single skill exceeds budget, condense.

## What never appears in user-facing chat

- Raw tool-call syntax (`mcp__7f8b5613-...`, `__search`, etc.)
- Internal placeholders (`~~claim search`, `~~biomed search`, `~~document store`)
- Paper IDs (`consensus:abc123def`, `pmid:38920760`)
- Citation tokens (`[paper_id:locator]`)
- Phase IDs in audit-log shorthand (`phase: scoping, action: scope_approved`)
- Anything wrapped in `mcp__`, `__`, or backtick-fenced internal-API names

These appear in the audit log (machine-readable) and never in chat (human-readable). The audit log and the chat are describing the same events to different audiences.

## Vocabulary translation table

When a user-facing message needs to refer to one of these internal concepts, translate it on first use within a session. After first translation, the more precise internal term is fine.

| Internal | Plain-language first-use |
|---|---|
| corpus | "the papers I'm working with" |
| evidence row | "a quote from a paper that supports a specific claim" |
| locator | "where in the paper the quote came from" |
| cite-check | "double-checking that every claim points back to a real source" |
| audit trail | "a record of every step I took, so you can show your work later" |
| disconfirmer | "what evidence would change your mind" |
| scope | "the plan for what we're researching" |
| synthesis | "the draft" |
| dedup | "removing duplicates" |
| screen | "filter to keep only the relevant ones" |
| extract | "pull the key findings from each paper" |
| render | "turn this into a viewable document" |
| ~~claim search | "a peer-reviewed paper search" |
| ~~biomed search | "the medical research database" |
| ~~breadth search | "a scholarly search engine" |
| ~~citation context | "a tool that tracks how often findings have been replicated" |
| ~~notebook publish | "NotebookLM, for podcasts and decks" |
| ~~document store | "your file storage (Box, Drive, OneDrive)" |
| ~~knowledge base | "your knowledge base (Notion, Confluence)" |
| PRISMA | "a record of every search, screen, and decision — the kind a committee can audit" |
| metadata_resolution | (don't surface; this is internal) |
| three-tier sentence typing | (don't surface; this is internal) |

## Phase-aware glossary

Some terms shift meaning across phases. Pick the phase-appropriate noun:

| Term | Pre-screen | Post-screen | Post-extract |
|---|---|---|---|
| "papers" | "everything we found" (broad) | "the relevant ones" (filtered) | "the papers I pulled findings from" (narrower) |

## The Annie test (operationalized)

Before any release that changes user-facing prose, run a fresh Scriptorium pipeline on a topic and pause at each phase boundary. A non-Scriptorium user reading the chat should be able to answer all five:

1. What is Scriptorium doing right now?
2. Why is it doing that?
3. How long until the next visible update?
4. What just finished, in your own words?
5. What's coming next?

Pass criterion: ≥4 of 5 answered correctly per phase, with no requests for clarification on internal vocabulary. One failed phase = revise that skill's narration before ship.

## Interactive choice contract (added v0.2.2)

**Every multiple-choice question fires a form widget, never a bulleted text question.**

When a skill needs to ask the user to pick from options (purpose, audience, depth, intent, output format, etc.), it MUST use `mcp__visualize__show_widget` with the elicitation module — not write the question and options as prose for the user to type a reply to.

Why: typing answers to multiple-choice questions is friction. The user has already read the options; making them type one back is unnecessary work. Click is the right interaction; type is the escape hatch.

**The form must always include a "type something different" escape hatch** as the final option, using the elicitation `data-other` attribute. Never lock the user into the system's option set.

Pattern (per the elicitation module in `mcp__visualize__read_me`):

```html
<div class="elicit-pills" data-name="purpose" data-multi="false">
  <button type="button" class="elicit-pill" data-value="chapter">A chapter or paper</button>
  <button type="button" class="elicit-pill" data-value="memo">A strategy memo</button>
  <button type="button" class="elicit-pill" data-value="orientation">Orientation</button>
  <button type="button" class="elicit-pill" data-value="teaching">A teaching artifact</button>
  <button type="button" class="elicit-pill" data-value="thinking">Just clearer thinking</button>
  <button type="button" class="elicit-pill" data-value="other" data-other>Something different</button>
</div>
<input type="text" class="elicit-other" data-for="purpose" placeholder="Tell me more" hidden>
```

**When in doubt, fire a form.** Choice questions in chat (even short ones like "ready to proceed?") should be one-pill yes/no widgets, not "type yes to continue."

**When NOT to fire a form:**
- Open-ended questions ("what's the question you're trying to answer?") — those are textareas, which the form can also support
- Mid-narration confirmations that don't need a structured answer ("got it, moving on" — just keep going)
- Anything where the answer is genuinely free-text and pre-selected options would be misleading

**Skills that have at least one choice point:** `grill-me`, `grill-question`, `review`, `scope`, `publish`, `render`, `setup`. Each must mandate form widgets in its prose for those points.

## Failure-state narration (added v0.4.0 — R11)

When a phase emits `status: "failure"`, the user-facing message follows this template:

> I hit a snag during **[phase, in plain language]**. **[What happened, in plain language — one sentence].** **[What it means for your review — one sentence].** Want to retry, override and continue, or stop here?

Three filled examples:

> I hit a snag during **searching the literature**. **None of the queries returned papers** — usually this means the question is phrased in a way the databases aren't indexed for, or the year window is too narrow. **We can't synthesize without a corpus, so this needs to resolve.** Want to retry with broader queries, soften the year window, or stop here?

> I hit a snag during **the cite-check on the draft**. **Three sentences in the draft don't trace cleanly to a source** — most likely I synthesized too far from what the papers actually say. **A draft that doesn't pass the cite-check shouldn't ship as a defensible review.** Want me to soften those three sentences, drop them, or stop and we'll find better citations?

> I hit a snag during **pulling full text from a paper**. **Your university library proxy returned an auth error for one DOI** — the OA cascade also missed it. **We can still extract evidence from the abstract, but locator-precision drops.** Want to skip this paper, retry with a different proxy, or paste the PDF directly into chat?

**What this template enforces:**
- Plain-language phase name (per vocabulary table)
- One-sentence diagnosis, not a stack trace
- One-sentence consequence (so the user knows whether to care)
- Three explicit options (retry / override / stop), as form pills with `data-other` for "explain something else"

**Phase skills must reference this section** — never surface a raw error string. Smoke test verifies references in audit, contradictions, extract, search, synthesize.

## When narration and audit-log entries describe the same event

The audit log records what happened in machine-readable form for reproducibility. The narration tells the user what's happening in human-readable form for understanding. Both should fire for every meaningful event; they don't replace each other.

| Event | Audit log entry | User narration |
|---|---|---|
| Search query fires | `{phase: search, action: query, details: {tool, query, n_results}}` | "First search done — 20 papers about [topic]." |
| Cite-check passes | `{phase: synthesis, action: verify, status: success}` | "All your claims point back to real sources. Draft is ready." |
| Disconfirmer fires | `{phase: contradiction-check, action: disconfirmer.fired, details: {n_matches}}` | "I found three studies that push back on your view — they're called out in the section labeled 'Where the literature pushes back.'" |

Skill prose mandates both — write the audit entry AND the user sentence — for every meaningful event.
