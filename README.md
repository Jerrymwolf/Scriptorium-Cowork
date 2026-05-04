# Scriptorium for Cowork

**From a half-formed research idea to a defensible direction — with the literature to back it up.**

Scriptorium is a research-direction and literature-review plugin for Claude Cowork. Built for graduate students, doctoral researchers, and anyone who has a topic but doesn't yet have a research question. It grills your idea into shape, helps you generate a defensible research question, runs the lit review with a PRISMA-style audit trail, names contradictions where the field actually disagrees, and ships a synthesis chapter you could put in front of a committee.

No CLI. No local shell. No hooks. Pure skills + the MCPs you've already connected.

> **New in v0.5.0** — voice-reconciliation release. Closes the v0.4.x incoherence where picking `intent: building` for a chapter had no effect on the rendered output (voice resolved to defending per the output_intent table, ignoring your pick). v0.5.0 keys voice on intent directly; the form widget now means what it says. Soft warnings flag unusual combinations (chapter+curious, memo+curious, etc.) without blocking. The disconfirmer gate and voice are now both on the same control — no more memo-with-defended-position-but-building-voice contradictions.
>
> **New in v0.4.1** — render-correctness patch. Closes the v0.4.0 bug where rendered memos showed raw audit-trail tokens like `[consensus:abc123:abstract]` to the user. Citation style is now APA 7th edition: `(Li et al., 2023)` inline, alphabetized references list, italicized journal names. Probe-gap fix for `"Semantic Scholar"` (with space) tools. Plus per-tier `<arg>` enforcement clarity in synthesize prose.
>
> **New in v0.4.0** — comprehensive UX & discipline patch. Closes the v0.3.0 gaps: the cite-check script now correctly resolves PMID-style citations (was P0-broken on biomed corpora); `output_intent` flows end-to-end so a memo intent gets a memo-shaped output, not a chapter-shaped one; a glanceable progress card updates in your Cowork sidebar at every phase; the disconfirmer gate finally has a real trigger (intent check Q0 in grill-question); failure-state narration follows a canonical template; the connector probe runs silently instead of leaking its skill name. See [CHANGELOG.md](./CHANGELOG.md) for the full list and migration notes.
>
> **New in v0.2.0** — three discipline gates: a disconfirmer requirement during grilling for users defending a position, three-tier sentence typing in the synthesis cite-check (factual / synthesis / argument), and a description-keyword fallback in the connector probe for UUID-named tools. Plus a click-to-source viewer artifact that opens in the Cowork sidebar and lets you click any citation in a synthesis to see the source paper, the supporting quote, and a one-click DOI link.

> **The canonical doctoral workflow:** You know what you're interested in — something about leadership and remote work, or caffeine and cognition, or whatever's been nagging at you. But *"I want to research X"* isn't a research question yet. Finding the question requires reading literature you haven't read, and reading the literature efficiently requires knowing what you're looking for. Classic chicken-and-egg. Scriptorium breaks the loop: grill the idea into shape, generate the question with you, run the lit review with full audit trail, surface contradictions, and ship a synthesis chapter you'd defend. *(And then, if you want a podcast for the commute, that's one more sentence.)*

---

## Where to start

**Most users should start by getting grilled.** Three openings, in order of how confident you are about what you want:

1. **`"Grill me on this topic"`** — *Recommended starting point.* Fires `grill-me`, a Pocock-style three-to-five-turn interview that surfaces purpose, audience, artifact, and depth, then routes you to the right tool. You might end up at a podcast, a paper, a strategy memo, a teaching module, or just clearer thinking. If you're not sure what you want from a topic, this is the door.
2. **`"I have a topic but no question yet — grill me"`** — Use when you know you're writing a research-paper-shaped artifact (paper, chapter, dissertation, EdD/DBA capstone) but the research question isn't pinned down. Fires `grill-question`. Detects practitioner-doctorate context (EdD/DBA/Penn CLO) and surfaces the practitioner-researcher position rather than treating it as bias.
3. **`"Run a lit review on X"`** — Use when you already have a clear research question and just need the literature. Fires the full pipeline; twelve minutes later you have a defensible synthesis with audit trail. Asks one question first (*"do you have a clear research question, or want to grill out your direction first?"*) so it can route you upward to the grill-me skills if it turns out you're not as ready as you thought.

If you're not sure which to pick, just say *"grill me on this topic."* The skills auto-redirect — if you start in `grill-me` but actually need `grill-question`, it forwards you in turn one. Same the other direction.

A short transcript with `grill-me`:

> **You:** I'm thinking about caffeine and working memory but I'm not sure what I want from it yet.
>
> **Scriptorium:** I see you're interested in caffeine and working memory. Let me help you figure out what you want to do with it. Most people who start with a topic like this are aiming at one of three things: getting up to speed for a meeting (commute podcast or briefing doc), writing something committee-readable (paper or chapter), or just personal curiosity. Which fits?
>
> **You:** Honestly the first one — I have a meeting Thursday.
>
> **Scriptorium:** Got it. So we're aiming at "fluent enough to hold a 30-minute conversation," not "expert enough to publish." That points at an audio overview by Thursday morning. Any specific population you care about — healthy adults, ADHD, kids, athletes?
>
> **You:** Healthy adults.
>
> **Scriptorium:** That's enough to start. Routing you to a focused lit review with a NotebookLM podcast as the deliverable. Want me to run it?

Three turns, one decision per turn, ends with a concrete next action. Same shape for `grill-question`, but the questions narrow toward phenomenon-of-interest, tradition, and operationalization rather than artifact and audience.

---

## What it produces

Once you have a research question (yours from the start, or one you grilled out together), the lit review runs in roughly twelve minutes and hands you four artifacts:

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
  "concept": "attention",
  "evidence_tier": "systematic_review",
  "metadata_resolution": "verified"
}
```

`evidence_tier` modulates how the synthesis layer renders the claim — meta-analyses produce declarative prose, RCTs produce qualified prose, cross-sectional studies produce correlational prose. The tier is named *explicitly in prose* so the signal survives the markdown→audio handoff to NotebookLM. `metadata_resolution` is verified / partial / inferred — strict mode blocks commit on any inferred citation.

A fragment of synthesis:

```markdown
A systematic review of caffeine's cognitive effects reports improvements in sustained
attention at 75–150mg doses [nehlig2010:page:4]. Effects on working memory are mixed:
in a randomized trial of 48 healthy adults, short-term recall improved [smith2018:page:7],
while a single cross-sectional study of complex span tasks found no benefit
[kennedy2017:page:12].
```

Every bracketed token resolves to a real row. Note the explicit tier framing — *"a systematic review"*, *"a randomized trial of 48 healthy adults"*, *"a single cross-sectional study"* — so a podcast listener hears the evidence-quality hierarchy even when the citation tokens are stripped.

---

## Then turn it into anything (the neat-function part)

Once the review passes its cite-check, say *"publish this as a podcast,"* *"make a deck for committee,"* or *"send this to NotebookLM."* Scriptorium uploads the entire corpus — synthesis, contradictions, evidence, every PDF — into a fresh NotebookLM notebook and triggers Studio artifact generation. Each artifact cites the actual papers. This is the part that gets people excited at conferences and is genuinely useful, but it's the *output* of the workflow, not the workflow itself. The defensible review is the substance; the podcast is the convenience.

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

> I'm working on a chapter about how organizational leaders maintain trust during remote work, but I haven't pinned down the research question yet. Grill me on this.

Scriptorium fires `grill-me` first. Three to five turns surface that you're heading toward a dissertation chapter, the audience is your committee, the depth is "mastery," and the tradition leans qualitative. The skill notices you're past the topic-only stage and routes you into `grill-question` to pin the actual question. A few more turns produce something defensible — say, *"How do remote-work managers in mid-sized SaaS companies sustain interpersonal trust across distributed teams over the first 90 days of onboarding?"* — with sub-questions and named boundaries.

Then the lit review runs: connector probe, scope confirmation, search → screen → extract → synthesize → contradiction-check → audit. Twelve minutes later it reports back:

```
Corpus:        137 returned, 92 deduped, 41 kept after screening
Full-text:     28/41 (68%)
Evidence rows: 86 total — 4 meta-analysis · 12 experimental · 38 observational ·
                          14 cross-sectional · 18 qualitative
Cite-check:    0 unsupported sentences · 132 verified · 8 partial · 0 inferred ✓
Contradictions: 2 same-question disagreements · 4 scope-variation findings · 1 uncertain

Outputs: synthesis, contradictions, audit-jsonl, references
```

Then: *"Want a podcast, deck, mind map, or video of this review, or are we done?"*

---

## Patterns that work

**1. Idea → question → chapter — the canonical doctoral workflow.** You're working on a dissertation chapter or capstone but the research question isn't yet pinned down. Say *"grill me on this topic"*. Three turns surface what you actually want from the work. Two more turns generate a defensible question with sub-questions, boundaries, and tradition. The lit review then fires and produces a synthesis chapter, locator-cited, with a PRISMA audit trail. The output is a chapter draft you'd defend. This is what Scriptorium is built for first.

**2. Get unstuck on a vague research interest.** You have a topic that's been nagging you but you can't articulate the question. Say *"grill me on this topic"* and let `grill-me` push you through the purpose / audience / artifact decisions you've been avoiding. Sometimes the answer is *"this is a strategy memo, not a paper."* Sometimes it's *"this is a real research question — let me grill it out."* Either way you exit knowing what you're doing and why.

**3. Hand a draft and a tape to your committee.** Synthesis as a markdown chapter, audit trail as proof of method, audio overview as a 12-minute *"here's what the literature says"* briefing your committee can listen to before the defense. Three artifacts that answer three different committee questions: *"What does the literature say?"*, *"How did you search?"*, *"Can you give me the gist on the way to my office hours?"*.

**And one more thing — get smart fast for a meeting.** Find-literature-then-make-a-podcast is its own neat flow, even outside doctoral work. Tonight: scope a quick review on a topic you don't own yet. Morning: ask for the audio overview. Commute: listen. You walk into the meeting with the actual literature in your head, not a hot take. Not the lead use case but a great one — works the same pipeline, just with a tighter scope and a heavier reliance on the publishing layer.

---

## Trigger phrases

Cowork dispatches via natural language. Common ones:

| If you say… | This fires |
|---|---|
| *"set up Scriptorium"* | first-run setup |
| *"I have a topic but don't know what I want from it"* / *"help me figure out what to do with this idea"* / `/grill [topic]` | `grill-me` — direction interview (recommended starting point) |
| *"I need a research question for this paper"* / *"grill me on the question"* | `grill-question` — RQ interview |
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

By default your corpus stays inside the connectors you chose. The single operation that moves it elsewhere is `publish`, which uploads to NotebookLM (Google). That operation always shows a privacy note before proceeding and logs every uploaded file to the audit trail. MIT-licensed, no telemetry, no phone-home.

---

## License & credits

MIT. See [LICENSE](./LICENSE).

Architected in the style of [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent — self-contained skill folders Claude loads on demand. The pattern is *Superpowers*; the application to literature review is *Scriptorium*. Sister project for Claude Code: [Jerrymwolf/Scriptorium](https://github.com/Jerrymwolf/Scriptorium).

---

**Try it:** drop the [`.plugin` file from the latest release](https://github.com/Jerrymwolf/Scriptorium-Cowork/releases/latest) into your Cowork chat, click Accept, and say *"run a lit review on a topic you've been meaning to read up on."* At v0.1.0, real feedback is the highest-leverage thing you can give — [file an issue](https://github.com/Jerrymwolf/Scriptorium-Cowork/issues) or DM with what worked or broke.
