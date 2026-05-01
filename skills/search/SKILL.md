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
