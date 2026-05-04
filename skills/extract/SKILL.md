---
name: extract
description: Use when the user asks to pull full text of kept papers, extract methods/findings, or populate evidence from PDFs. Runs the Cowork-appropriate full-text cascade and writes locator-cited evidence rows.
---

# Literature Extracting (Cowork)

Input: kept papers in the `corpus` artifact. Output: full-text or abstract fallback per paper, plus structured `EvidenceEntry` rows in the `evidence` artifact. Every row carries `[paper_id:locator]` where `locator` is `page:N`, `sec:<name>`, `abstract`, or a line range — never a numbered citation.

## Cascade

Earlier sources always win. Abstract-only is a valid terminal state — never an error, but flagged as lower-confidence so downstream cite-checks can treat its claims accordingly.

**user_pdf → unpaywall → arxiv → pmc → library_proxy (manual handoff) → abstract_only**

| Step | How (Cowork) | Notes |
|---|---|---|
| `user_pdf` | If state home is NotebookLM, add via `~~notebook publish` `source_add(source_type="file")`. Otherwise read inline or save to `pdfs/`. | Top priority. User-supplied PDFs always win the cascade. |
| `unpaywall` | `WebFetch GET https://api.unpaywall.org/v2/{doi}?email={unpaywall_email}` → JSON; if `best_oa_location.url_for_pdf` is non-null, fetch that URL via `WebFetch`. | Free OA copies, ~50% recall on recent papers. Requires `unpaywall_email` from setup and `api.unpaywall.org` on the user's Cowork allowlist. |
| `arxiv` | `WebFetch GET http://export.arxiv.org/api/query?search_query=ti:"{title}"+AND+au:"{author}"&max_results=3` → Atom XML; parse for `<link rel="alternate" type="application/pdf">`. | Preprints. Requires `export.arxiv.org` on the allowlist. |
| `pmc` | If `~~biomed search` is connected and the corpus row has a PMCID, call `~~biomed search` `get_full_text_article(pmcid=…)`. | NIH OA full text — biomedical papers only. |
| `library_proxy` | If `library_proxy_base` is set in `scriptorium-config`, generate the proxied URL: `{library_proxy_base}{quoted(paper.doi_url)}`. Hand the URL to the user with: *"I couldn't pull this through OA channels. Click this proxied URL to fetch through your library, then drag the PDF back here when downloaded."* Wait for upload before continuing on this paper. | Cowork's `WebFetch` cannot authenticate as the user to their library — only their browser can. This is a manual handoff, not a silent fetch. |
| `abstract_only` | Use the abstract from the corpus row. Set `full_text_source: "abstract_only"` on resulting evidence rows. | Terminal fallback. Cite-check treats these claims as lower-confidence. |

## Workflow

For each kept paper:

1. **Try `user_pdf`** if the user uploaded a PDF.
2. **Try `unpaywall`** if `unpaywall_email` is configured. Skip if `WebFetch` returns a host-not-allowlisted error and tell the user once per session: "Unpaywall is blocked by your Cowork network policy. Add `api.unpaywall.org` to your org's allowlist to enable it." Then continue with the cascade.
3. **Try `arxiv`** for preprints, especially if the venue field looks like an arXiv ID or the DOI is a `10.48550/arxiv.*` pattern.
4. **Try `pmc`** for biomedical papers with a PMCID.
5. **Try `library_proxy` handoff** if the user has it configured. Generate the proxied URL, present it, and pause this paper's extraction until the user uploads or says *"skip."* Move to the next paper while waiting if the user prefers; pick up the proxied paper later when the upload appears.
6. **Fall through to `abstract_only`.**

For each step that succeeds, ingest the source content (PDF or abstract), identify meaningful claims, and write one `EvidenceEntry` per claim to the `evidence` artifact. Follow the unified shape: `{paper_id, locator, claim, quote, direction, concept, evidence_tier, full_text_source, metadata_resolution}`. Inherit `metadata_resolution` from the corpus row's `Paper`.

## Tagging the design tier

Set `evidence_tier` for each row based on the paper's study design (read methods or abstract):

- `meta_analysis` — pooled effect-size estimate across multiple primary studies
- `systematic_review` — structured synthesis without effect-size pooling
- `experimental` — manipulation of an independent variable, with or without random assignment (RCT, quasi-experimental, single-case design all fold here)
- `observational` — longitudinal or cohort design without manipulation
- `cross_sectional` — single-timepoint survey, correlational
- `qualitative` — interviews, ethnography, phenomenology, grounded theory, content analysis
- `theoretical_or_review` — narrative review, conceptual paper, position piece, expert commentary

When the design is ambiguous (e.g., a paper mixing ethnographic interviews with a cross-sectional survey), pick the tier that best describes the methods supporting the **specific claim** you're extracting — not the paper as a whole. Different rows from the same paper may carry different tiers.

A complete `EvidenceEntry` example:

```json
{
  "paper_id": "smith2018",
  "locator": "page:7",
  "claim": "Caffeine at 200mg improves digit-span recall in healthy adults",
  "quote": "Recall accuracy was significantly higher in the 200mg group (M=8.2, SD=1.3) than placebo (M=7.4, SD=1.5), t(46)=2.1, p=.04.",
  "direction": "positive",
  "concept": "caffeine_wm_recall",
  "evidence_tier": "experimental",
  "full_text_source": "unpaywall",
  "metadata_resolution": "verified"
}
```

Append one audit entry per paper: `{phase: "extraction", action: "fulltext.resolved", details: {paper_id, source: <cascade step that won>, n_evidence_rows, isolation?: "per-paper-notebook"|"shared-notebook"}, status}`.

## Locator grammar

- `page:N` — single PDF page (preferred for PDF-backed claims)
- `page:N-M` — page range
- `sec:<slug>` — section, e.g. `sec:Methods`, `sec:Discussion`
- `abstract` — the paper's abstract (used when only the abstract is available)
- `L<start>-L<end>` — line range inside an extracted plaintext

The synthesis layer reads these when verifying `[paper_id:locator]` tokens. Invent neither paper ids nor locators — the locator must map to something real.

## Direction + concept

- `direction`: `positive` (evidence supports the concept), `negative` (contradicts), `mixed` (both directions in same paper), `neutral` (relevant but not directional).
- `concept`: a short slug (`caffeine_wm_accuracy`, not "caffeine's effect on working memory accuracy in adults"). Downstream, `contradictions` groups by concept.

## Optional Scite enrichment

If `~~citation context` (Scite) resolved during the connector probe, after writing each evidence row, optionally call `~~citation context` for the paper's DOI or claim and capture Scite's classification (`supporting` / `contrasting` / `mentioning`) into the row's `scite_classification` field. This is enrichment — it does not replace the human-readable `direction` field, which is read directly from the source. Scite's classification is most useful in `contradictions`.

## NotebookLM-specific note

When state home is NotebookLM, choose isolation:

- **Per-paper notebook (HIGH isolation).** Create a fresh notebook per paper, add only its PDF as a source, query for claims, write evidence rows back to the main review notebook, then delete the per-paper notebook. Cleanest, slowest.
- **Single review notebook (MEDIUM isolation).** Add all PDFs as sources to one notebook and query each in turn. Faster, but cross-paper context bleeds — query prompts must explicitly name the paper id.

Default to per-paper isolation unless the user is quota-pressed. Record the choice in the audit row's `details.isolation` field.

## Hand-off

After every kept paper is extracted (or terminally marked abstract_only), report "N papers extracted, M evidence rows written, K papers fell through to abstract-only" and hand off to `synthesize`.

## User narration (added v0.2.1)

Follow `NARRATION.md`. Extract is the first phase that touches paper content; users often expect this to be slow.

**Before:**

> Pulling the key findings from each of the [N] papers — the specific
> claims and quotes that will go into your draft. This part takes the
> longest, usually two to four minutes.

**During** (for full-text cascade, narrate cascade outcomes per paper or in batches):

> Got full text on [N] papers; the rest are coming through abstract-only
> because they're behind paywalls. I'll mark which is which so you can see
> the difference.

**After:**

> [N] specific quotes pulled across the [M] papers — these are what your
> draft will be built from. Now I'll write the draft.

Translate "evidence rows" → "specific quotes that support a claim". Never surface `[paper_id:locator]` tokens in chat.
