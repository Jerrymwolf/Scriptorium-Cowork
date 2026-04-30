# Shared Vocabulary

The two skills (Research Grill Me, Research Questions Grill Me) share a small lexicon. Both skills' SKILL.md files reference this file so terms stay aligned. New terms introduced in either memo are added here.

**purpose** — The user's reason for engaging with a topic. One of: entertainment / personal orientation / instruction / production / inquiry / strategic decision-support. Resolved by *Research Grill Me*. Carried as handoff state to *Research Questions Grill Me*.

**artifact** — The tangible (or deliberately intangible) output the engagement produces. Examples: commute podcast, slide deck, teaching module, strategy memo, journal article, dissertation chapter, "I just wanted to think it through." Resolved by *Research Grill Me*. Treated as constraint by *Research Questions Grill Me* (a journal article tolerates a different question shape than a chapter).

**depth** — How deeply the user intends to engage. Four bands: orientation (gist, who-said-what), fluency (active vocabulary, can teach a peer), mastery (can argue with the field), novel contribution (publishable). Resolved by *Research Grill Me*. Constrains tradition selection and operationalization in *Research Questions Grill Me*.

**tradition** — The methodological lineage a research question is asked from. Quant, qual, mixed, action, design-based. Surfaces in *Research Grill Me* only as a pre-commitment hint when the user already knows; resolved by *Research Questions Grill Me* when applicable.

**boundaries** — The line between in-scope and out-of-scope phenomena. Largely a *Research Questions Grill Me* concept (Booth/Colomb/Williams "boundary work"), but *Research Grill Me* sets a coarse boundary upstream via artifact (a podcast can't cover what a chapter can; a chapter can't cover what a multi-paper program can).

**stopping state** — A named exit condition for the interview. Each skill has multiple stopping states keyed to where the user is heading next. Different from "stopping criterion," which is the test the model applies. *Research Grill Me* has five stopping states; *Research Questions Grill Me* has one stopping state with five criteria.

**handoff state** — The set of resolved fields one skill passes to another when the user transitions. Canonical shape from *Research Grill Me* → *Research Questions Grill Me*: `{purpose, audience, artifact, depth, tradition?, topic}`. Canonical shape from *Research Questions Grill Me* → Scriptorium: `{research_question, sub_questions, tradition, boundaries}`.

**discovery escape hatch** — Inherited from Pocock's Grill Me pattern. At any point, if the user signals genuine uncertainty ("I don't know yet"), the skill suggests an exploration mode rather than forcing commitment. Both skills inherit; the prose only needs to permit it.
