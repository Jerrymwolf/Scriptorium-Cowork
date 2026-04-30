# Scriptorium for Cowork

**Run a literature review you can defend — and turn it into a podcast on the way to your meeting.**

Scriptorium is a literature-review plugin for Claude Cowork. You give it a research question; it searches the literature, cites every claim to a paper and page, names contradictions instead of averaging them away, and logs every decision to a PRISMA-style audit trail. When the review is done, it pushes your corpus into NotebookLM and turns it into a podcast, video, slide deck, mind map, study guide, FAQ, timeline, or quiz — each artifact grounded in the papers you actually read.

No CLI. No local shell. No hooks. Pure skills + the MCPs you've already connected.

> **The single highest-leverage use:** It's 9 PM. Tomorrow morning you have a meeting on a topic you don't own yet. Tonight you say *"run a lit review on X"* in Cowork — twelve minutes later you have a defensible synthesis with full audit trail. You ask for an audio overview. During the commute, you listen to a host-style podcast walking through the literature, every claim cited. You walk into the meeting with the actual research in your head, not a hot take.

---

## Where to start

**Most users should start by getting grilled.** Three openings, in order of how confident you are about what you want:

1. **`"Grill me on this topic"`** — *Recommended starting point.* Fires `research-grill-me`, a Pocock-style three-to-five-turn interview that surfaces purpose, audience, artifact, and depth, then routes you to the right tool. You might end up at a podcast, a paper, a strategy memo, a teaching module, or just clearer thinking. If you're not sure what you want from a topic, this is the door.
2. **`"I have a topic but no question yet — grill me"`** — Use when you know you're writing a research-paper-shaped artifact (paper, chapter, dissertation, EdD/DBA capstone) but the research question isn't pinned down. Fires `research-questions-grill-me`. Detects practitioner-doctorate context (EdD/DBA/Penn CLO) and surfaces the practitioner-researcher position rather than treating it as bias.
3. **`"Run a lit review on X"`** — Use when you already have a clear research question and just need the literature. Fires the full pipeline; twelve minutes later you have a defensible synthesis with audit trail. Asks one question first (*"do you have a clear research question, or want to grill out your direction first?"*) so it can route you upward to the grill-me skills if it turns out you're not as ready as you thought.

If you're not sure which to pick, just say *"grill me on this topic."* The skills auto-redirect — if you start in `research-grill-me` but actually need `research-questions-grill-me`, it forwards you in turn one. Same the other direction.

A short transcript with `research-grill-me`:

> **You:** I want to read up on caffeine and working memory.
>
> **Scriptorium:** Most people who start there are aiming at one of three things: getting up to speed for a meeting (commute podcast or briefing doc), writing something committee-readable (paper or chapter), or just personal curiosity. Which fits?
>
> **You:** Honestly the first one — I have a meeting Thursday.
>
> **Scriptorium:** Got it. So we're aiming at "fluent enough to hold a 30-minute conversation," not "expert enough to publish." That points at an audio overview by Thursday morning. Any specific population you care about — healthy adults, ADHD, kids, athletes?
>
> **You:** Healthy adults.
>
> **Scriptorium:** That's enough to start. Routing you to a focused lit review with a NotebookLM podcast as the deliverable. Want me to run it?

Three turns, one decision per turn, ends with a concrete next action. Same shape for `research-questions-grill-me`, but the questions narrow toward phenomenon-of-interest, tradition, and operationalization rather than artifact and audience.

---

## What it produces

After roughly twelve minutes on a well-scoped question, Scriptorium hands you four artifacts:

- **`synthesis`** — your draft chapter. Every sentence carries a `[paper_id:locator]` token that resolves to a real paper and page. Sentences without evidence are stripped or flagged before commit. No hallucinated citations.
- **`evidence`** — one row per claim, structured: `{paper_id, locator, claim, quote, direction, concept}`. The synthesis layer reads this; you can re-query it however you want.
- **`contradictions`** — when papers disagree on the same concept, Scriptorium names the camps. *"Camp A (smith2018, chen2020) reports gains; Camp B (kennedy2017) reports null results. Methodological difference: span-task complexity."* Disagreement survives into the draft instead of getting smoothed into false consensus.
- **`audit-jsonl`** — every search query, screening decision, extraction call, synthesis verify, and publish event. Append-only, status-tagged. When your committee asks *"how did you search?"* you show them the file.

A row of evidence:

```json
{
  "paper_id": "nehlig2010",
  "locator": "page:4",
  "claim": "Caffeine at 75–150mg improves sustained attention in healthy adults",
  "quote": "Doses between 75 and 150 mg improve sustained attention and vigilance...",
  "direction": "positive",
  "concept": "attention"
}
```

A fragment of synthesis:

```markdown
Caffeine at 75–150mg doses reliably improves sustained attention [nehlig2010:page:4],
though effects on working memory are mixed: short-term recall shows gains in healthy
adults [smith2018:page:7], while complex span tasks show no benefit [kennedy2017:page:12].
```

Every bracketed token resolves to a real row. Unsupported citations fail the cite-check before the file commits.

---

## Then turn it into anything

Once the review passes its cite-check, say *"publish this as a podcast,"* *"make a deck for committee,"* or *"send this to NotebookLM."* Scriptorium uploads the entire corpus — synthesis, contradictions, evidence, every PDF — into a fresh NotebookLM notebook and triggers Studio artifact generation. Each artifact cites the actual papers.

| Artifact | What it's for |
|---|---|
| **Audio Overview (podcast)** | Host-style conversation walking through the literature. The commute-listen artifact. |
| **Video Overview** | Narrated visual walkthrough with on-screen highlights. |
| **Slide deck** | Committee-presentable summary, drops into Keynote or Google Slides. |
| **Mind map** | Visual concept layout showing how the papers cluster around themes. |
| **Briefing Doc** | Executive summary of the review. |
| **Study Guide** | Q&A learning aid — for getting fluent with literature you didn't grow up in. |
| **FAQ** | The questions a reviewer would ask, answered from the corpus. |
| **Timeline** | Chronological view of how the literature evolved. |
| **Quiz** | Practice questions with answers — prelim and qualifier prep. |
| **Chat with the corpus** | Ask any question; every answer cites source PDFs. |

The first five fire automatically through the NotebookLM MCP from inside Cowork. The rest live one click away in the NotebookLM web UI on the same notebook — no re-upload.

> **Privacy gate.** Publishing is the one operation in Scriptorium that intentionally moves your corpus off the connectors you chose. You see an explicit confirmation before any file leaves; the full source manifest — every file uploaded, the notebook ID, every artifact ID — gets logged to your audit trail. If you don't have a NotebookLM connector, Scriptorium walks you through the manual upload path (same notebook, five extra clicks).

---

## Why Scriptorium (and not just Elicit / Consensus / ResearchRabbit)

Scriptorium isn't a search engine. It's a workflow. Elicit answers questions. Consensus surfaces claims. ResearchRabbit maps citation networks. Scite checks whether a paper is supported or contradicted. **Scriptorium takes what those tools produce and turns it into a defensible chapter with an audit trail — and then a podcast.** Use it alongside them, not instead of them.

| | Scriptorium | Elicit | Consensus | ResearchRabbit | Scite |
|---|---|---|---|---|---|
| Primary job | Workflow + audit | Question answering | Claim search | Citation graph | Claim check |
| Locator-cited extraction | ✅ | Partial | ❌ | ❌ | ❌ |
| PRISMA audit log | ✅ | ❌ | ❌ | ❌ | ❌ |
| Names disagreement | ✅ | ❌ | Partial | ❌ | ✅ |
| Output is a draft | ✅ (`synthesis`) | Summary | Answer card | Graph | Badges |
| Studio artifacts (podcast/deck/etc.) | ✅ via NotebookLM | ❌ | ❌ | ❌ | ❌ |
| Your corpus stays under your control | ✅ | ❌ | ❌ | ❌ | ❌ |

If your review needs to **cite its sources, survive committee scrutiny, and become a podcast**, Scriptorium is the layer that ties the other tools' output together.

---

## The three disciplines

Three rules, enforced by skill prose:

1. **Evidence-first claims.** Every sentence in synthesis cites `[paper_id:locator]` or it gets stripped. There is no rhetorical-but-uncited writing.
2. **PRISMA audit trail.** Every search, screen, extraction, and reasoning decision appends one row to the audit log. Append-only. Reconstructable end-to-end.
3. **Contradiction surfacing.** When evidence disagrees on the same concept, named camps — not "some researchers find X while others find Y."

---

## Install

Three paths, ranked by friction:

**A. Drag the `.plugin` file into a Cowork chat.** Simplest of all. Cowork renders the file as a rich preview with an Accept button — one click and it's installed. Get the file from the [Releases page](https://github.com/Jerrymwolf/Scriptorium-Cowork/releases) or from anyone running it.

**B. Settings → Plugins → Upload.** Same `.plugin` file, through the admin UI. Useful when the chat-attach preview misbehaves (known bug on Cowork for Windows).

**C. Marketplace add.**

```
/plugin marketplace add Jerrymwolf/Scriptorium-Cowork
/plugin install scriptorium-cowork@Scriptorium-Cowork
```

After install, open any Cowork chat and say *"set up Scriptorium."*

---

## Connect at least one of each

Scriptorium for Cowork is **connector-agnostic** — it doesn't ship its own scholarly-search MCP. It uses whatever you've connected, falling back gracefully when something is missing. Full category map in [`CONNECTORS.md`](./CONNECTORS.md).

| Category | What it does | Examples |
|---|---|---|
| Scholarly search | Required for non-degraded search | Consensus (claim-first), Scholar Gateway (breadth), PubMed (biomed) |
| State home | Where the review lives | NotebookLM (best — native PDFs + Studio), Drive/Box/OneDrive (folder), Notion (page tree) |
| Publishing destination | Studio artifact generation | NotebookLM |

If nothing is connected, Scriptorium runs in degraded mode (WebFetch against OpenAlex's public API) and tells you so.

---

## What a session feels like

In any Cowork chat:

> Run a lit review on caffeine and working memory in healthy adults.

Scriptorium probes which connectors you have, asks 3–5 clarifying questions about scope (purpose, fields, year range, target corpus size), then runs **search → screen → extract → synthesize → contradiction-check → audit**. Twelve minutes later it reports back:

```
Corpus:        137 returned, 92 deduped, 41 kept after screening
Full-text:     28/41 (68%)
Evidence rows: 86
Cite-check:    0 unsupported sentences
Contradictions: 3 concepts with positive/negative pairs

Outputs: synthesis, contradictions, audit-jsonl, references
```

Then: *"Want a podcast, deck, mind map, or video of this review, or are we done?"*

---

## Three patterns that work

**Get smart fast on an unfamiliar topic.** Tonight: scope a review. Twelve minutes later: defensible synthesis. Morning: ask for the audio overview. Commute: listen. You walk into the meeting with the literature in your head.

**Stack reviews into meta-synthesis.** Run three targeted reviews (*caffeine and attention*, *caffeine and working memory*, *caffeine and executive function*). Publish all three corpora into one NotebookLM notebook. Ask the combined corpus questions you couldn't ask any single review.

**Hand a draft and a tape to your committee.** Synthesis as a markdown chapter, audit trail as proof of method, audio overview as a 12-minute "here's what the literature says" briefing your committee can listen to before the defense.

---

## Trigger phrases

Cowork dispatches via natural language. Common ones:

| If you say… | This fires |
|---|---|
| *"set up Scriptorium"* | first-run setup |
| *"grill me on this topic"* / *"I have a topic but don't know what I want from it"* | `research-grill-me` — direction interview (recommended starting point) |
| *"grill me on the question"* / *"I need a research question for this paper"* | `research-questions-grill-me` — RQ interview |
| *"run a lit review on X"* | full pipeline (asks if you want to be grilled first) |
| *"scope this review"* / *"help me plan a review on X"* | scoping only |
| *"find papers on X"* | search only |
| *"screen these papers"* | screening |
| *"draft the synthesis"* | synthesis (with cite-check) |
| *"where do papers disagree?"* | contradiction check |
| *"show the audit trail"* / *"PRISMA flow"* | audit summary |
| *"publish this as a podcast"* / *"send to NotebookLM"* | publishing |

Phrasing doesn't have to match exactly — anything close to these triggers the right skill.

---

## Privacy

By default your corpus stays inside the connectors you chose. The single operation that moves it elsewhere is `lit-publishing`, which uploads to NotebookLM (Google). That operation always shows a privacy note before proceeding and logs every uploaded file to the audit trail. MIT-licensed, no telemetry, no phone-home.

---

## License & credits

MIT. See [LICENSE](./LICENSE).

Architected in the style of [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent — self-contained skill folders Claude loads on demand. The pattern is *Superpowers*; the application to literature review is *Scriptorium*. Sister project for Claude Code: [Jerrymwolf/Scriptorium](https://github.com/Jerrymwolf/Scriptorium).

---

**Try it:** drop the [`.plugin` file from the latest release](https://github.com/Jerrymwolf/Scriptorium-Cowork/releases/latest) into your Cowork chat, click Accept, and say *"run a lit review on a topic you've been meaning to read up on."* At v0.1.0, real feedback is the highest-leverage thing you can give — [file an issue](https://github.com/Jerrymwolf/Scriptorium-Cowork/issues) or DM with what worked or broke.
