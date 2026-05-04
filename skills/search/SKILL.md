---
name: search
description: Use when the user asks to find/search/discover papers on a topic, wants candidate sources, or is populating/extending the corpus. Reads the approved scope, runs queries against whichever scholarly-search MCPs are connected, dedupes the results, and writes them to the corpus via the state adapter.
---

# Literature Searching (Cowork)

## Precondition — scope is required

Read the `scope` artifact from the state home (note `scope`, file `scope.json`, or page `Scope`). If it does not exist, STOP and invoke `scope` first. Do not ask the user for query, year range, or criteria yourself — those values come from the scope artifact.

Fields consumed:

- `research_question` — seed for query construction
- `fields` — source selection (medicine → `~~biomed search`; psychology → `~~breadth search` or `~~claim search`)
- `methodology` — filter after retrieval
- `year_range` — applied to every source query
- `corpus_target` — governs per-source limits
- `publication_types` — source enablement
- `anchor_papers` — resolve first; they seed related-work expansion

The goal is a **deduped corpus** of candidate papers saved to the `corpus` artifact via the state adapter. Every paper carries a stable `paper_id`, canonical metadata, and an initial status of `candidate`.

## Source selection rule

Read what the connector probe (in `using-scriptorium`) resolved. Pick at least two sources for breadth.

- For biomed questions, always include `~~biomed search` if connected.
- For claim-framed questions ("does X cause Y?"), prefer `~~claim search` first.
- For exploratory or interdisciplinary questions, prefer `~~breadth search`.
- If the user uploaded PDFs to the conversation, ingest them first so they dominate dedupe.
- If nothing connected, run **degraded mode**: `WebFetch` against `https://api.openalex.org/works?search=<query>&per_page=50` and announce the degradation.

## Claim-search output-fencing rule (MANDATORY)

Some claim-search MCPs (Consensus is the canonical example) hard-require numbered `[1][2]` inline citations and a verbatim sign-up line in their output. That contract is for *answering questions*, not for *corpus building*. Fence the output:

> From `~~claim search` results, extract ONLY `{title, authors, year, doi, url}` into the corpus. NEVER propagate numbered `[1]`/`[2]` tokens into evidence or synthesis — our grammar is `[paper_id:locator]`. Any sign-up line only appears on a user-facing turn that ends directly on claim-search output; corpus-building turns never do.

Corpus-building turns are tool-to-tool: read the search result, write to the state adapter, do not emit a user-facing natural-language summary.

## Workflow

1. Load the scope artifact.
2. Construct the initial query from `research_question` and `fields`. Apply `year_range` and `publication_types` as filters. Set per-source `limit` from `corpus_target` (target / number-of-sources, with a floor of 25).
2.5. **Show queries before firing (R16, v0.4.0 — hypothesis, opt-in).** If `scriptorium-config` has `preview_queries = true`, render a form widget with each constructed query as a labeled pill (e.g., "Consensus: 'caffeine working memory healthy adults 2015-2024'"). Pills: `approve all` / `regenerate` / `edit individual queries` (reveals one textarea per query) / `data-other`. Default flag value is `false` — feature is hypothesis-only until Annie-test feedback validates it (per Risk register in v0.4.0 spec). If the flag is unset or `false`, skip Step 2.5 and proceed directly to Step 3.

3. For each enabled source category:
   - `~~claim search` — call the Consensus-style search tool; apply the fencing rule above.
   - `~~breadth search` — call Scholar Gateway / OpenAlex via its MCP.
   - `~~biomed search` — call PubMed `search_articles`, then `get_article_metadata` per PMID for DOIs and abstracts.
4. Normalize every result to the unified `Paper` shape: `{paper_id, source, title, authors[], year, doi, abstract, venue, open_access_url, metadata_resolution}`. The `paper_id` is the source's native identifier (OpenAlex `W…`, PubMed PMID, Consensus internal id) — invent nothing. Set `metadata_resolution`:
   - `verified` — DOI or PMID resolves via API; OR title+authors+year exact-matches a single record.
   - `partial` — one of those resolves but other fields are gap-filled from a related record (e.g., DOI resolves but the abstract had to be pulled from a different snapshot).
   - `inferred` — any of `{title, authors, year, doi}` was constructed from prose context rather than a verified API response. **Mark this honestly.** A title you reconstructed from a partial Consensus snippet is `inferred`, not `verified`. The cite-check downstream treats inferred metadata as a hard block in strict mode — silent over-claiming here breaks the audit trail's promise.
5. Dedupe in-memory by DOI → `(source, paper_id)` → normalized title. The strongest key is DOI; if two rows share a DOI, keep the one with the richer record (non-empty abstract, venue, authors). Last-resort fallback for normalized title: `re.sub(r"[^a-z0-9]+", " ", title.lower()).strip()`.
6. Write the deduped corpus to the `corpus` artifact via the state adapter. Format depends on state home — see the mapping in `using-scriptorium`.
7. Append one audit entry per source query: `{phase: "search", action: "<source>.query", details: {query, n_results, n_after_dedupe}, status}`.
8. Tell the user the count and top 5 titles. Hand off to `screen` when they're ready.

## When to stop searching

Stop when (a) the user is satisfied with the count, or (b) the last 20 new results contain fewer than 3 novel titles after dedupe — diminishing returns. Record both the stopping condition and the final count in an audit entry.

## Hand-off

Report `{n_returned, n_deduped, n_kept_for_screening}`. Hand off to `screen`.

## User narration (added v0.2.1)

Follow `NARRATION.md`. Search has the worst silent-period in the pipeline; treat narration as load-bearing here.

**Before any query fires**, write a plain-language paragraph naming:
- What you're searching for, in the user's words (not search keywords)
- Which databases, translated (Consensus → "a database covering most peer-reviewed papers"; PubMed → "the medical research database"; Scholar Gateway → "a scholarly search engine")
- How many queries total, framed as relative duration ("this takes a while; I'll mark each search as it finishes" — R15, v0.4.0: no hard minute estimate)

Example opening:

> I'm going to search the published literature now. Five different angles
> to cover the question — workplace contexts, the values angle, meaning,
> moral identity, and a check on what could prove you wrong. Two databases:
> Consensus, which covers most peer-reviewed papers, and a scholarly search
> engine. I'll narrate each search as it finishes — feel free to step away.

**Between queries**, emit one human sentence per query completion. Translate counts and topics into plain language:

> First search done — found 20 papers about how the theory applies in
> workplaces. Starting the values angle now.

**After all queries**, summarize and transition:

> All five searches done across both databases. After removing duplicates,
> I have 73 unique papers. Next I'll filter these to keep only the ones
> that match your scope — about 30 seconds.

**Never surface in chat:** raw tool names (`mcp__...`), `~~category` placeholders, paper IDs, JSON dumps, search-syntax keywords. Tool calls happen silently; the user sees only the human-readable summary.

If a search returns zero results, narrate that honestly ("Nothing came back on this angle — that itself is informative; I'll note it in the gap analysis"), don't silently move on.
