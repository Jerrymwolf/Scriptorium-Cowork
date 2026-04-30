---
name: lit-extracting
description: Use when the user asks to pull full text of kept papers, extract methods/findings, or populate evidence from PDFs. Runs the Cowork-appropriate full-text cascade and writes locator-cited evidence rows.
---

# Literature Extracting (Cowork)

Input: kept papers in the `corpus` artifact. Output: full-text or abstract fallback per paper, plus structured `EvidenceEntry` rows in the `evidence` artifact. Every row carries `[paper_id:locator]` where `locator` is `page:N`, `sec:<name>`, `abstract`, or a line range — never a numbered citation.

## Cascade

Cowork has no Unpaywall, arXiv, or local PDF tooling. The cascade is:

**user_pdf → pmc (via `~~biomed search`) → abstract_only**

Earlier sources always win. Abstract-only is a valid terminal state — it is never an error, but it is flagged as lower-confidence and downstream cite-checks treat its claims accordingly.

## Workflow

For each kept paper:

1. **User PDF first.** If the user uploaded a PDF for this paper to the conversation:
   - If state home is NotebookLM: add it via `~~notebook publish` `source_add(source_type="file", file_path=...)`. NotebookLM becomes the full-text store and you query its content via `notebook_query` for evidence.
   - If state home is a document store: write the PDF to the `pdfs/` subfolder and read it inline.
   - If state home is session-only: read the PDF inline; it does not persist.
2. **PMC fallback.** If the paper has a PMCID in its corpus row and `~~biomed search` is connected, call `get_full_text_article(pmcid=…)` for NIH OA full text.
3. **Abstract-only.** Otherwise, stay with the abstract from the corpus row. Set `full_text_source: "abstract_only"` on the resulting evidence rows.
4. **Identify claims.** For each meaningful claim in the source, write one `EvidenceEntry` to the `evidence` artifact. Follow the unified shape: `{paper_id, locator, claim, quote, direction, concept, full_text_source}`.
5. **Audit.** Append one entry per paper: `{phase: "extraction", action: "fulltext.resolved", details: {paper_id, source, n_pages_or_chars, n_evidence_rows}, status}`.

## Locator grammar

- `page:N` — single PDF page (preferred for PDF-backed claims)
- `page:N-M` — page range
- `sec:<slug>` — section, e.g. `sec:Methods`, `sec:Discussion`
- `abstract` — the paper's abstract (used when only the abstract is available)
- `L<start>-L<end>` — line range inside an extracted plaintext

The synthesis layer reads these when verifying `[paper_id:locator]` tokens. Invent neither paper ids nor locators — the locator must map to something real.

## Direction + concept

- `direction`: `positive` (evidence supports the concept), `negative` (contradicts), `mixed` (both directions in same paper), `neutral` (relevant but not directional).
- `concept`: a short slug (`caffeine_wm_accuracy`, not "caffeine's effect on working memory accuracy in adults"). Downstream, `lit-contradiction-check` groups by concept.

## NotebookLM-specific note

When state home is NotebookLM, you have two options for evidence extraction:

- **Per-paper notebook (HIGH isolation).** Create a fresh notebook per paper, add only its PDF as a source, query for claims, write evidence rows back to the main review notebook, then delete the per-paper notebook. Cleanest, slowest.
- **Single review notebook (MEDIUM isolation).** Add all PDFs as sources to one notebook and query each in turn. Faster, but cross-paper context bleeds — query prompts must explicitly name the paper id.

Default to per-paper isolation unless the user is quota-pressed. Record the choice in the audit row's `details.isolation` field.

## Hand-off

After every kept paper is extracted, report "N papers extracted, M evidence rows written" and hand off to `lit-synthesizing`.
