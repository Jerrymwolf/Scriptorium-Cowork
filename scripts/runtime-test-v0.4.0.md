# v0.4.0 runtime tests

These tests verify behavior the static contract smoke test can't see — form widgets firing, progress artifact rendering, override persistence, fast-path routing. Run in a fresh Cowork session after dragging in the v0.4.0 .plugin.

The static smoke test passes 86/86 contract checks; this is the runtime layer.

## Test 1 — R0 cite-check fixture (already automated)

Run `bash scripts/cite-check-test.sh` from the repo. Should exit 0 with "3 citations resolved across pmid/openalex/consensus."

This is the P0 fix from v0.3.0; if it ever regresses, biomed corpora silently drop every PMID citation.

## Test 2 — R5 progress artifact

1. Fire `/scriptorium` with chapter-intent prompt: *"I need to write my dissertation chapter on caffeine and working memory."*
2. Confirm `scriptorium-progress-<slug>` artifact appears in the Cowork sidebar before scope starts.
3. Confirm dot transitions: pending → active → done at each phase boundary.
4. Confirm phase summaries populate as each phase finishes ("Found 73 papers across 5 angles", etc.).
5. Test errored state: kill connector mid-search (or use a topic that returns zero results); confirm dot turns red and footer shows "⚠ Stopped at: searching the literature."

Pass criterion: at any moment during the pipeline, glancing at the sidebar tells you exactly where in the 7 steps you are, without re-reading the chat.

## Test 3 — R2 output_intent end-to-end (memo trace)

This is the v0.2.2 strategy-memo failure case retested.

1. Fire `/scriptorium` with: *"Help me think through whether to add knowledge graphs to our quant analysis program."*
2. Confirm `grill-me` lands on `output_intent: memo`.
3. Confirm `review` skips Step 0 (R4) — no "do you have a clear question?" re-ask.
4. Confirm `scope` recap is the 4-line condensed shape (R10), NOT the full dissertation table.
5. Confirm `synthesize` voice is `building` (system suggests argument sentences for accept/edit/reject), NOT `defending`.
6. Confirm cite-check uses `--min-citations 3` floor.
7. Confirm closing question is the memo variant: *"Want this in Slack-ready format, a one-pager, or are we done?"* — NOT the chapter variant.
8. Confirm `render` produces 1-page Markdown + viewer (R19), NOT a chapter-shaped HTML viewer.

Pass criterion: a memo intent never produces chapter-shaped output. The v0.2.2 zero-citation-memo bug is structurally impossible.

## Test 4 — Chapter trace + disconfirmer gate

1. Fire `/scriptorium` with: *"I need to write my dissertation chapter on caffeine and working memory."*
2. `grill-me` redirects to `grill-question` (wrong-skill redirect — already in v0.3.0).
3. **Confirm `grill-question` Step 0 fires Intent check** (R8). Either reads from grill-me handoff or asks form widget with curious / building / defending pills.
4. **Confirm disconfirmer Q5 form has four example-shape pills + data-other** (R9). Pills should be:
   - "A specific finding pattern (e.g., a longitudinal study showing X correlates with Y, not −Y)"
   - "A specific published critic or rebuttal"
   - "A specific methodological challenge (e.g., a failed registered replication)"
   - "A specific population or context where my view shouldn't hold"
5. Click a pill; confirm a pre-framed textarea reveals.
6. Confirm cite-check uses `--min-citations 10` floor (chapter intent).
7. Confirm `render` produces full HTML viewer.

Pass criterion: the disconfirmer gate has a real trigger and the form models specificity instead of asking for it cold.

## Test 5 — PMID resolution (the P0 case in a real session)

1. Fire `/scriptorium` with a biomed-only question: *"What does the literature say about HIIT for cognitive function in older adults?"*
2. Confirm search routes to PubMed (biomed).
3. Confirm corpus rows have `paper_id: "pmid:NNNNNNN"` shape.
4. Run the synthesis pipeline.
5. Open `runtime/cite-check.py` audit entry; confirm `n_resolved == n_total_cites` (i.e., zero PMID-style citations went unresolved).

Pass criterion: every PMID citation resolves cleanly. In v0.3.0, this case silently dropped every citation and reported PASSED.

## Test 6 — R14 connector override persistence

1. Fire `/scriptorium`. Manually override claim_search to a custom MCP tool name.
2. End the session.
3. Start a new session, fire `/scriptorium`.
4. Confirm probe applies the override before Pass 1; surfaces "(remembered from last session)" or equivalent.
5. Disconnect the override target; start a third session.
6. Confirm the system falls back to probe and emits a `connector.override.stale` audit entry with `status: warning`.

Pass criterion: overrides survive across sessions; stale overrides degrade gracefully with audit trail.

## Test 7 — R18 fast-path routes

1. Drop a `corpus.jsonl` file into chat.
2. Type: *"I have a corpus, just extract."*
3. Confirm router skips `scope` / `search` / `screen` and fires `extract` directly.
4. Test other phrases:
   - *"Re-run the cite-check"* → fires synthesize cite-check section only
   - *"Just publish what I have"* → fires `publish` (after precondition check)
   - *"Re-render the viewer"* → fires `render`
   - *"Show me the audit trail"* → fires `audit`
5. Test precondition fail: type *"I have a corpus, just extract"* with no corpus pasted and no state at home. Confirm system surfaces gap in plain language and offers upstream phase.

Pass criterion: power users skip the linear pipeline. Preconditions checked, gaps surfaced honestly.

## Test 8 — R16 query review (opt-in)

1. With `preview_queries = false` (default): fire a search, confirm queries fire silently with narration.
2. Set `preview_queries = true` in scriptorium-config.
3. Fire a new search, confirm Step 2.5 form appears with each query as a pill.
4. Test approve all / regenerate / edit individual / data-other paths.

Pass criterion (for hypothesis evaluation): does Annie say the queries-shown step felt like load-bearing transparency, or like another form to click through? The flag is opt-in until Jerry decides post-Annie-test whether to default it on.

## Test 9 — R3 + narration honesty

1. Fire `/scriptorium`. Watch the first turn.
2. Confirm "Using `using-scriptorium` to route this session" does NOT appear (R3).
3. Confirm probe runs silently and only surfaces results in plain language.
4. Watch the search phase: confirm narration emits between queries (per `NARRATION.md`).
5. Confirm no minute-counts in narration ("12–20 minutes", "about 2 minutes" should be absent).

Pass criterion: Annie test passes — a fresh user can answer all 5 NARRATION questions per phase without internal vocabulary.

## Test 10 — R11 failure-state narration

1. Force a failure (network block, zero-result search, or bad disconfirmer).
2. Confirm message follows the template:
   > "I hit a snag during **[phase]**. **[what happened]**. **[what it means]**. Want to retry, override and continue, or stop here?"
3. Confirm three pills (retry / override / stop) + data-other for "explain something else."

Pass criterion: no raw error strings; user understands what happened and has clear options.

## Reporting

After running these, record results in `scripts/runtime-test-results-v0.4.0.md` (gitignored or committed as evidence). For any test that fails, file an issue with the trace and the exact prompt that produced it.

If 8+/10 tests pass on first try, ship to public marketplace directory.
If 6–7/10 pass, hold for v0.4.1.
If <6/10 pass, this is more like an alpha; consider rollback to v0.3.0 with cite-check regex hot-fix.
