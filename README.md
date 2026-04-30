# Scriptorium for Cowork

**A literature review workflow you can defend — entirely inside Claude Cowork.**

Scriptorium runs entirely inside Claude Cowork — through skills and the MCPs you've already connected. No CLI required, no local shell access, no hook system.

## What it does

Scriptorium turns the middle third of a literature review — search through synthesis — into a disciplined, auditable workflow. It produces:

- **A defensible synthesis.** Every sentence carries a `[paper_id:locator]` token that resolves to a row in your evidence store. Unsupported sentences are stripped or flagged before commit.
- **A committee-ready audit trail.** Every query, screening decision, extraction, and synthesis verify is timestamped and stored in append-only `audit.jsonl`. Your methods chapter has a receipt.
- **Named contradictions.** When two papers disagree on the same concept, Scriptorium names the camps. Disagreement survives into your draft instead of getting smoothed into false consensus.
- **Publishing-ready artifacts.** Push the finished review into NotebookLM and turn it into a podcast, video, slide deck, mind map, briefing doc, study guide, FAQ, timeline, or quiz — or chat the literature directly. See [Publish to NotebookLM](#publish-to-notebooklm).

## Why Scriptorium

Scriptorium isn't a search engine. It's a workflow. Elicit answers questions. Consensus surfaces claims. ResearchRabbit maps citation networks. Scite checks whether a paper is supported or contradicted. **Scriptorium takes what those tools produce and turns it into a defensible chapter with an audit trail.** Use it alongside them, not instead of them.

|                          | Scriptorium       | Elicit             | Consensus       | ResearchRabbit   | Scite           |
|--------------------------|-------------------|--------------------|-----------------|------------------|-----------------|
| Primary job              | Workflow + audit  | Question answering | Claim search    | Citation graph   | Claim check     |
| Locator-cited extraction | ✅                | Partial            | ❌              | ❌               | ❌              |
| PRISMA-style audit log   | ✅                | ❌                 | ❌              | ❌               | ❌              |
| Names disagreement       | ✅                | ❌                 | Partial         | ❌               | ✅              |
| Output is a draft        | ✅ (`synthesis.md`) | Summary          | Answer card     | Graph            | Badges          |
| Your corpus stays local  | ✅                | ❌                 | ❌              | ❌               | ❌              |

If your review needs to **cite its sources and survive committee scrutiny**, Scriptorium is the layer that turns the other tools' output into a chapter.

## Install

Three paths, in order of friction:

**A. Drag the `.plugin` file into a Cowork chat.** Simplest of all. Cowork renders the file as a rich preview with an Accept button — one click and it's installed. Get the file from the [Releases page](https://github.com/Jerrymwolf/Scriptorium-Cowork/releases) or from anyone who's already running it.

**B. Settings → Plugins → Upload.** Same `.plugin` file, but go through the admin UI. Useful when the chat-attach preview misbehaves (known bug on Cowork for Windows).

**C. Marketplace add (Claude Code style).**

```
/plugin marketplace add Jerrymwolf/Scriptorium-Cowork
/plugin install scriptorium-cowork@Scriptorium-Cowork
```

After install, open any Cowork chat and say *"set up Scriptorium."*

## Connectors

Scriptorium for Cowork is **connector-agnostic** — it doesn't ship its own scholarly-search MCP. Instead, it uses whatever you've connected, falling back gracefully when something is missing. See [`CONNECTORS.md`](./CONNECTORS.md) for the full category map.

Recommended:

- **Scholarly search:** Consensus (claim-first), Scholar Gateway (breadth), or PubMed (biomed). At least one is required for non-degraded search.
- **State home:** NotebookLM (best — native PDF sources + Studio publishing), Google Drive / Box / OneDrive (folder-based), or Notion (page-tree). Without one, your review is session-only and won't persist past the conversation.
- **Publishing destination:** NotebookLM, if you want podcast / slide deck / mind map / video output.

If nothing is connected, the plugin runs in degraded mode (WebFetch against OpenAlex's public API) and tells you so.

## Use

In any Cowork chat, say:

> Run a lit review on caffeine and working memory in healthy adults.

Scriptorium fires `using-scriptorium` first to probe your connectors, then `lit-scoping` to ask 3–5 clarifying questions, then walks you through search → screen → extract → synthesize → contradiction-check → audit. The whole pipeline typically takes 8–15 minutes for a well-scoped question and produces:

- `corpus` — every paper found, deduped, with `kept`/`dropped` status
- `evidence` — locator-cited claims (one row per claim)
- `synthesis` — every sentence cite-grounded
- `contradictions` — named-camp disagreements
- `audit-jsonl` — every action, timestamped, status-tagged

These artifacts live in whichever state home you picked at the start. Export them whenever you want, or feed them into NotebookLM for the full publishing menu below.

## Publish to NotebookLM

When the review passes its cite-check, `lit-publishing` uploads the entire corpus — `synthesis`, `contradictions`, `evidence`, plus every PDF you ingested — into a fresh NotebookLM notebook and triggers Studio artifact generation. Say *"publish this as a podcast"*, *"make a deck for committee"*, or *"send this to NotebookLM"* and it fires.

**What you can generate from a finished review:**

| Artifact | What it's good for |
|---|---|
| **Audio Overview (podcast)** | Host-style conversation walking through the literature. Listen on the commute the morning of your meeting. |
| **Video Overview** | Narrated visual walkthrough with on-screen highlights. |
| **Slide deck** | Committee-presentable summary, ready to drop into Keynote or Google Slides. |
| **Mind map / infographic** | Visual concept layout showing how the papers cluster around themes. |
| **Briefing Doc** | Executive summary of the review, generated in NotebookLM Studio. |
| **Study Guide** | Q&A learning aid — useful for getting fluent with a literature you didn't grow up in. |
| **FAQ** | The questions a reviewer would ask, answered from the corpus. |
| **Timeline** | Chronological view of how the literature evolved. |
| **Quiz** | Practice questions with answers — prelim / qualifier prep. |
| **Chat with the corpus** | Once the notebook exists, ask any question; every answer cites the source PDFs. |

The first four are triggered automatically through the NotebookLM MCP. The rest are reachable inside the NotebookLM web UI from the same notebook — no re-upload needed.

**Privacy gate.** Publishing is the one operation in Scriptorium that intentionally moves your corpus off your connected stores. Before any file leaves, you see an explicit privacy prompt and confirm. The full source manifest — every file uploaded, the notebook ID, every artifact ID — gets logged to your audit trail.

If `~~notebook publish` isn't connected, `lit-publishing` walks you through the manual upload path. Same notebook, five extra clicks.

## The three disciplines

These are non-negotiable, enforced by skill prose:

1. **Evidence-first claims.** Every sentence in synthesis cites `[paper_id:locator]` or it doesn't ship.
2. **PRISMA audit trail.** Every decision is logged, append-only, status-tagged.
3. **Contradiction surfacing.** Named camps, not bland consensus.

A discipline preamble is loaded into every session via `skills/using-scriptorium/INJECTION.md`.

## Trigger phrases

| If you say… | This skill fires |
|---|---|
| "set up Scriptorium" / first-run | `setting-up-scriptorium` |
| "run a lit review on X" | `running-lit-review` (full pipeline) |
| "scope a review on X" | `lit-scoping` |
| "find papers on X" | `lit-searching` |
| "screen these papers" / "apply criteria" | `lit-screening` |
| "extract findings from these PDFs" | `lit-extracting` |
| "draft the synthesis" | `lit-synthesizing` |
| "where do papers disagree?" | `lit-contradiction-check` |
| "show the audit trail" / "PRISMA flow" | `lit-audit-trail` |
| "publish this to NotebookLM" / "make a podcast" / "make a deck" / "make a video" / "make a quiz" | `lit-publishing` |

## Privacy

By default, your corpus stays inside the connectors you chose. The one operation that intentionally moves it elsewhere is `lit-publishing`, which uploads to NotebookLM (Google). That operation always shows a privacy note before proceeding and logs every uploaded file to `audit-jsonl`.

## License

MIT. See [LICENSE](./LICENSE).

## Credits

Scriptorium is architected in the style of [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent — self-contained skill folders that Claude loads on demand. The pattern is *Superpowers*; the application to literature review is *Scriptorium*.
