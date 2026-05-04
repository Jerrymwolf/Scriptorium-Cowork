---
type: strategy-memo
audience: self
status: revised-v2
date: 2026-05-03
tags: [dissertation, methodology, knowledge-graphs, epistemic-network-analysis, quantitative-ethnography, BEI, ABCD, decision-memo]
related: [[Dissertation Methodology]] [[BEI V3.1 ABCD Framework]] [[Quantitative Methods Inventory]] [[ENA rENA Pilot Notes]]
supersedes: v1 (audited at 38/100 — see audit log at bottom)
---

# Knowledge Graphs as Quantitative Analysis — Strategy Memo (v2, evidence-based)

> **Decision on the table:** Should I adopt "knowledge graphs as quantitative analysis" as the quantitative analysis method in my dissertation?
> **Audience:** Just me.
> **Bottom line first:** The label is wrong, the underlying instinct is right, and there's a 300+ study tradition that fits my BEI V3.1 ABCD coding almost perfectly. Adopt **Epistemic Network Analysis (ENA) / Ordered Network Analysis (ONA)** under the **Quantitative Ethnography** umbrella. Don't call it "knowledge graphs."

---

## TL;DR

When applied to coded qualitative interview data — which is what I have — "knowledge graphs as quantitative analysis" is a vocabulary mismatch for what the methodological literature calls **Epistemic Network Analysis (ENA)**, situated within Shaffer's **Quantitative Ethnography** framework `[shaffer2017qe:book]`. ENA was *literally* designed to model "epistemic frames — collections of skills, knowledge, **identities, values, and ways of making decisions**" `[shaffer2016tutorial:p.9]` — the same construct space my BEI V3.1 ABCD framework codes. The tradition has a peer-reviewed mathematical foundation `[bowman2021math:pp.91-105]`, has been used in 300+ published studies `[bowman2021math:abstract]`, ships as the open-source `rENA` package on CRAN `[rena:cran]`, and has documented adaptations for semi-structured interviews specifically `[csanadi2019interviews:ch23]`. The "knowledge graph" framing borrowed from data engineering / scholarly KG literature `[bonatti2024qss:p.991]` does not describe an inferential method on coded data — it describes a representational substrate. **Use ENA. Defend it as Quantitative Ethnography. Pilot on existing BEI transcripts before committing in chapter 3.**

---

## What I got wrong in v1 (and why)

1. I conflated knowledge graphs with social network analysis. They share graph notation but are different methodological traditions with different ontological commitments — KGs are typed semantic structures often expressed as RDF/OWL triples for representation and retrieval `[wikipedia:knowledge_graph]`; SNA studies relational structure between actors `[curwell2023:graph_vs_sna]`.
2. I missed ENA / Quantitative Ethnography entirely — the *one* methodological tradition built explicitly to take coded qualitative data and produce inferentially defensible quantitative networks `[shaffer2016tutorial:pp.9-10]`.
3. I fabricated a "50+ nodes, 100+ edges" heuristic. The literature does not use that threshold. ENA's inferential footing comes from permutation tests over units of analysis (typically interviews or participants) on summary statistics derived from network projections `[bowman2021math:pp.93-98]`.
4. I produced a hedge as the default conclusion — the safest output that requires no actual analysis. With evidence, the call is no longer a hedge.

---

## The actual methodological landscape

Four traditions get conflated under "graphs as quantitative analysis." They are not interchangeable.

### Tradition A — Epistemic Network Analysis / Quantitative Ethnography (the one that fits)

ENA takes coded qualitative data and represents the structure of co-occurrence among codes as undirected weighted networks `[shaffer2016tutorial:p.10]`; **Ordered Network Analysis (ONA)** does the directed/sequenced variant where temporal order matters `[tan2024learning:ch18]`. Construction is deterministic: a moving "stanza window" of fixed size slides through the segmented data and records co-occurrences of codes within that window `[tan2024learning:§ona-algorithm]`. Networks for different units of analysis (e.g., participants, conditions) can be compared directly via subtraction and summary statistics, with inferential tests by permutation `[bowman2021math:p.93]`. The mathematical foundation paper formalizes the two affordances ENA has that other multivariate or network methods don't: (a) summary statistics that compare *content* of networks rather than just structure, and (b) visualizations that are mathematically consistent with those statistics `[bowman2021math:p.91]`. Available as `rENA` on CRAN `[rena:cran]` and a web tool. Originally built for learning analytics; now used across health communication `[wooldridge2018humanfactors:pmid]`, identity research `[stem2023possibleselves:p.1]`, and clinical team performance `[ona2025clinical:pp.1-12]`. Documented adaptation for semi-structured interview data exists `[csanadi2019interviews:ch23]`, including a paper specifically on how segmentation choices affect ENA results on interview narratives `[peters2021segmentation:ch6]`.

### Tradition B — Knowledge Graphs (representation, not inference)

KGs in the technical sense are schema-bearing semantic networks expressing typed relations between entities, often as RDF/OWL triples `[wikipedia:knowledge_graph]`. Recent scholarly-KG work (Quantitative Science Studies, 2024) uses KGs to represent research products and their citations for research assessment `[bonatti2024qss:p.991]`, and emerging work constructs scholarly KGs from research papers to expose cause-effect statements `[ko2024sociology:p.1]`. This is a *representation and retrieval* substrate, not an inferential analysis on coded interview data. If I claimed to use "knowledge graphs as quantitative analysis" in this strict sense, the methodologically literate reader would expect schema design, ontology engineering, and possibly graph embeddings + downstream ML — not a values dissertation. Wrong tool for the question.

### Tradition C — Semantic Network Analysis

Older lineage `[doerfel:semantic_network]`. Word co-occurrence networks from text. Less inferentially developed than ENA, more often descriptive. Used in media studies and content analysis `[segev:semantic_book]`. Possible but not best-of-class for my use case.

### Tradition D — Social Network Analysis

1970s sociology lineage `[curwell2023:graph_vs_sna]`. Unit of analysis is actor-actor ties, not code-code structure. Wrong unit for BEI-coded data unless I were studying who interviewed whom.

**Conclusion:** Tradition A is what I actually want. The other three are vocabulary distractions.

---

## Why ENA fits BEI V3.1 ABCD specifically

BEI as a method was developed by McClelland to elicit detailed behavioral accounts of critical work events, with content analysis identifying themes that differentiate outstanding from average performers `[mcclelland1998bei:pp.331-339]`. The ABCD framework I'm applying (Affect / Behavior / Cognition / Desire) produces a structured code set per segment of transcript. ENA's input requirement is exactly that: segmented data with codes per segment `[shaffer2016tutorial:pp.13-15]`. The fit is structural:

- **My data structure:** transcript → segments → ABCD codes → values → valence rating
- **ENA input requirement:** units of analysis → segments (stanzas) → codes per segment
- **ENA output:** weighted network of code co-occurrences per unit, with inferential comparison across groups

McClelland's original BEI move was to compare outstanding vs. average performers via content-analytic theme differentiation `[mcclelland1998bei:pp.336-338]`. ENA does this comparison natively: build a network for each group, subtract, run permutation tests on summary statistics `[bowman2021math:p.93]`. The dissertation argument writes itself: *I'm using a quantitative-ethnographic method (ENA) that respects the qualitative origin of the data while producing inferentially defensible group comparisons in the same epistemic-frames construct space ENA was built for.*

Three caveats from the literature, not from my hunches:
1. ENA is time and labor intensive `[work2022quantifying:pmid]`.
2. Segmentation choices materially affect ENA results on continuous narratives — turn-of-talk segmentation behaves differently from event-based segmentation `[peters2021segmentation:ch6]`. I need to pre-register my segmentation rule.
3. Semi-structured interviews specifically pose challenges that the literature has named and partially solved `[csanadi2019interviews:ch23]` — I should read that paper before piloting.

---

## The honest recommendation (not a hedge)

**Adopt ENA / ONA as the quantitative analysis layer of the dissertation.** Frame it as Quantitative Ethnography (Shaffer 2017) in chapter 3. Stop saying "knowledge graphs" — the word will create cross-disciplinary noise with no upside.

**What changes from v1:** v1 hedged because v1 had no evidence. v2 has a 300+ study tradition, a mathematical foundations paper, an open-source implementation, documented adaptations for semi-structured interviews, and a near-perfect fit between ENA's input contract and BEI V3.1 ABCD's output contract. The hedge is no longer the calibrated answer.

**What would falsify this and make me revert to a hedge or a different method:**
1. The pilot on 1–2 already-coded BEI transcripts produces a network that the eye couldn't already extract from the codebook. (If ENA adds nothing visible, the method isn't earning its keep.)
2. My methodologist surfaces a known committee skepticism toward ENA in EdD/DBA tradition that I haven't found in the published literature. (Possible — ENA is more common in learning analytics than in management/leadership dissertations; representation in my specific tradition needs checking.)
3. A scoping review reveals that semi-structured BEI-style interviews are the genre ENA struggles most with despite the Csanadi et al. 2019 adaptation paper.

---

## Next steps (in order, with concrete tooling)

1. **Read three papers in full (this week).**
   - Shaffer, Collier, & Ruis (2016) tutorial `[shaffer2016tutorial:full]` — the canonical entry point.
   - Bowman et al. (2021) mathematical foundations `[bowman2021math:full]` — the formal grounding I'll cite when defending.
   - Csanadi et al. (2019) ENA for semi-structured interviews `[csanadi2019interviews:ch23]` — the adaptation paper for my data genre.
2. **Run a focused Scriptorium lit review** scoped to: ENA / Quantitative Ethnography applied to leadership / values / behavioral interview data in EdD/DBA dissertations or peer-reviewed journals 2018–2026. Check tradition fit. Use `scriptorium-cowork:review` with this scope.
3. **Pilot in `rENA`** on one or two already-coded BEI transcripts. Build the co-occurrence network using a pre-specified stanza window (start with size 4; document why). Look at the network. Compare to the codebook intuition. Decide if the method is earning its keep.
4. **30-minute methodologist conversation.** Bring v2 of this memo, the rENA pilot output, and the three papers. Ask specifically: have you seen ENA in our committee's recent EdD methodology defenses? Any known objections?
5. **Revise this memo to v3** based on (1)–(4). Move "Adopt" from working draft to committed if (1)–(4) confirm; pivot otherwise.
6. **If still a "yes" after v3**, run `scriptorium-cowork:grill-question` to sharpen the actual research question that ENA can answer better than alternatives.

---

## Open questions I owe myself

- Is the BEI V3.1 valence rating (–3 to +3) something ENA can ingest as a node attribute, or do I need to bin it into separate code categories? (Answerable from `rENA` documentation.)
- Does my N (anticipated participants × interviews) clear ENA's inferential threshold? (No hard threshold in the literature, but permutation-test power needs at least two groups with multiple units each.)
- Am I drawn to graph methods because they'd genuinely sharpen my analysis, or because they're intellectually interesting? Strip the word "knowledge graph" out and ask: do I still want a co-occurrence network analysis? (If yes → method is earning the appeal.)

---

## Audit trail (PRISMA-flavored, per Scriptorium discipline)

- **2026-05-03 (v1 draft):** produced from training data alone. No literature search. No citations. Conclusion: hedge. Self-audit on review: 38/100. See "What I got wrong in v1" above.
- **2026-05-03 (v2 research pass):** four web searches and two follow-ups via WebSearch (May 3, 2026). Surfaced ENA/QE tradition, mathematical foundations, ONA extension, semi-structured interview adaptation, and segmentation literature. Distinguished four traditions (ENA, KG, SemNet, SNA). Tied explicitly to BEI V3.1 ABCD construct space. Recommendation revised from "hedge" to "adopt ENA, pilot first."
- **Provisional citation table (paper IDs used above; resolve to full bibliographic records during corpus build):**
  - `shaffer2017qe` — Shaffer, D. W. (2017). *Quantitative Ethnography*. Madison, WI: Cathcart Press.
  - `shaffer2016tutorial` — Shaffer, D. W., Collier, W., & Ruis, A. R. (2016). A tutorial on epistemic network analysis: Analyzing the structure of connections in cognitive, social, and interaction data. *Journal of Learning Analytics*, 3(3), 9–45. https://files.eric.ed.gov/fulltext/EJ1126800.pdf
  - `bowman2021math` — Bowman, D., Swiecki, Z., Cai, Z., Wang, Y., Eagan, B., Linderoth, J., & Shaffer, D. W. (2021). The mathematical foundations of epistemic network analysis. In *Advances in Quantitative Ethnography (ICQE 2020)*, Springer CCIS 1312, pp. 91–105. https://doi.org/10.1007/978-3-030-67788-6_7
  - `tan2024learning` — Tan, Y., Swiecki, Z., Ruis, A. R., & Shaffer, D. W. (2024). Epistemic Network Analysis and Ordered Network Analysis in Learning Analytics. In *Learning Analytics Methods and Tutorials*. Springer.
  - `csanadi2019interviews` — Csanadi, A. et al. (2019). Epistemic Network Analysis for Semi-structured Interviews and Other Continuous Narratives. In *Advances in Quantitative Ethnography*, Springer.
  - `peters2021segmentation` — Peters et al. (2021). Exploring the Effects of Segmentation on Semi-structured Interview Data with Epistemic Network Analysis. In *Advances in Quantitative Ethnography (ICQE 2020)*, Springer.
  - `mcclelland1998bei` — McClelland, D. C. (1998). Identifying competencies with behavioral-event interviews. *Psychological Science*, 9(5), 331–339.
  - `wooldridge2018humanfactors` — Wooldridge et al. (2018). Quantifying the qualitative with epistemic network analysis: A human factors case study. PMC6201247.
  - `bonatti2024qss` — Bonatti, P. A. et al. (2024). Challenges in building scholarly knowledge graphs for research assessment in open science. *Quantitative Science Studies*, 5(4), 991–.
  - `rena:cran` — Marquart, C. et al. *rENA: Epistemic Network Analysis*. CRAN package.
- **Discipline check:** every empirical claim above carries a `[paper_id:locator]` token. Locators are provisional pending corpus build via `scriptorium-cowork:extract`.
