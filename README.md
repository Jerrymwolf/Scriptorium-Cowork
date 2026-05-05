# Scriptorium for Cowork

**Turn a half-formed research idea into a real literature review — with every claim traceable to a source, and a podcast at the end if you want one.**

[![Download .plugin (latest)](https://img.shields.io/github/v/release/Jerrymwolf/Scriptorium-Cowork?label=Download%20.plugin&style=for-the-badge&color=2563eb)](https://github.com/Jerrymwolf/Scriptorium-Cowork/releases/latest)

After downloading: drag the `.plugin` file into any Cowork chat, click Accept, then say *"set up Scriptorium."* Takes about a minute total.

Scriptorium is a Claude Cowork plugin for graduate students, doctoral researchers, and anyone wrestling with a research idea that hasn't quite become a question yet. You tell it what you're working on. It asks you a few questions to figure out what you actually want. Then it searches the literature, pulls the key findings out of each paper, drafts a synthesis where every claim points back to a real paper at a real page, and notes where the evidence disagrees. About fifteen minutes start to finish.

When the draft is done, you can keep it as a chapter, turn it into a one-page memo, or send the whole thing to NotebookLM for a podcast version of the literature.

> **What's new in v0.5.1:** README rewrite — the prior version read like internal release notes. This version is meant for someone who's never used the plugin. Plugin behavior is unchanged from v0.5.0.
>
> **What's new in v0.5.0:** Your answer to *"what are you trying to do?"* now actually changes how the draft sounds. Pick *"exploring an idea"* and the system will suggest interpretations for you to react to. Pick *"defending a position"* and it sticks to the evidence so you can write the interpretive sentences yourself. Before, the pick on the form had no visible effect on the writing — now it does.
>
> See [CHANGELOG.md](./CHANGELOG.md) for the full version history.

---

## What problem this solves

You have an idea. Something about leadership and remote work, or caffeine and cognition, or whatever's been on your mind. Saying *"I want to research X"* isn't a research question yet — but to find the question, you'd need to read a bunch of literature, and to read that literature efficiently, you'd need to know what you're looking for. Classic chicken-and-egg.

Scriptorium breaks the loop. It walks you through *"what do you actually want from this?"*, helps you sharpen the question, then runs the review with a paper trail your committee can audit. At the end you have a draft you'd defend, with sources you can click through to verify.

---

## If the download button above didn't work

Two fallbacks:

- **Settings → Plugins → Upload.** Same `.plugin` file, through the menu. Useful when drag-attach previews misbehave (known issue on Cowork for Windows).
- **Marketplace command.** In any Cowork chat:
  ```
  /plugin marketplace add Jerrymwolf/Scriptorium-Cowork
  /plugin install scriptorium-cowork@Scriptorium-Cowork
  ```

Both end at the same place: drag-into-chat works for almost everyone, but these two are there if it doesn't.

---

## What you connect

Scriptorium doesn't have its own search engine — it uses whatever scholarly tools you've already connected to Cowork. You only need one to start. More options means better results.

**For finding papers**, any one of:
- Consensus (best for "does X cause Y?" questions)
- A scholarly search engine like Scholar Gateway or Semantic Scholar (best for general research)
- PubMed (required for medical or biological topics)

**For storing your work** (optional but recommended):
- NotebookLM — best choice if you want podcast/video output
- Google Drive, Box, OneDrive, or SharePoint — saves your work as files
- Notion or Confluence — saves your work as pages

If nothing is connected, Scriptorium still runs in a degraded mode using OpenAlex's public API, and tells you so. Your work then lives only in the chat.

---

## How a session feels

Open a Cowork chat and just describe your situation in plain English.

> **You:** I'm thinking about caffeine and working memory but I'm not sure what I want from it yet.
>
> **Scriptorium:** Got it. Most people who start with a topic like this want one of three things — to get up to speed for a meeting, to write something committee-ready, or just to satisfy curiosity. Which fits?
>
> **You:** Honestly the first one — I have a meeting Thursday.
>
> **Scriptorium:** So we're aiming at "fluent enough for a 30-minute conversation," not "expert enough to publish." That points to a focused review you could turn into a podcast for the commute. Any specific population you care about — healthy adults, kids, athletes?
>
> **You:** Healthy adults.
>
> **Scriptorium:** Enough to start. Running the review now — I'll narrate as I go and update a progress card in your sidebar.

Three turns, one question per turn, ends with the system actually doing something. From there it works in the background — searching, filtering, pulling findings, writing the draft, double-checking every claim, surfacing where the literature disagrees — and reports back when it's done.

---

## What you get

After the review runs, you have a draft and a paper trail.

**The draft** is a markdown document with every empirical claim followed by a citation in standard APA format like *(Smith et al., 2023)*. Click any citation in the click-to-source viewer (which opens in your sidebar) and you'll see the paper title, the actual quote that supports the claim, and a one-click link to the source.

**The paper trail** is a record of every search the system ran, every paper it kept or rejected, every key finding it pulled, and every check it ran on the draft. If your committee asks *"how did you find these sources?"* you can show them the file. The format is the kind a methods chapter accepts.

**The contradictions section** names disagreements explicitly. Instead of bland *"researchers find mixed results"* prose, you get *"Camp A (Smith 2018, Chen 2020) reports gains; Camp B (Kennedy 2017) reports null results — the difference is task complexity."* Disagreement survives into the draft.

A short example of what the synthesis looks like:

> A systematic review of caffeine's cognitive effects reports improvements in sustained attention at 75–150mg doses (Nehlig, 2010). Effects on working memory are mixed: in a randomized trial of 48 healthy adults, short-term recall improved (Smith et al., 2018), while a single cross-sectional study of complex span tasks found no benefit (Kennedy & Park, 2017).

Notice the prose explicitly names the *kind* of evidence — "a systematic review", "a randomized trial of 48 healthy adults", "a single cross-sectional study". The reader gets the evidence-quality hierarchy without needing to know technical terms.

---

## Then turn it into a podcast (or a deck, or a mind map)

Once the draft passes its quality checks, you can say *"publish this as a podcast"* or *"make a deck for committee"* or *"send this to NotebookLM."* Scriptorium uploads the whole review to a fresh NotebookLM notebook and produces:

- **Audio overview (podcast)** — a host-style conversation walking through the literature. Good for the commute.
- **Video overview** — a narrated walkthrough with on-screen highlights.
- **Slide deck** — committee-presentable, drops into Keynote or Google Slides.
- **Mind map** — visual layout showing how the papers cluster around themes.
- **Briefing doc, FAQ, study guide, timeline, quiz** — and a chat-with-the-corpus interface where you can ask questions and get cited answers.

The first few fire automatically through NotebookLM. The rest are one click away in the same notebook.

**Privacy note:** Publishing is the one operation in Scriptorium that intentionally moves your work to a third party (Google, since NotebookLM is theirs). You'll see an explicit confirmation before anything leaves, and every uploaded file is logged to your paper trail. If you'd rather not, just don't ask for the publishing step.

---

## What this isn't

Scriptorium isn't a search engine. It's a workflow that uses whichever search tools you have.

If you want question-answering, use Elicit. If you want claim search, use Consensus. If you want a citation graph, use ResearchRabbit. If you want to know whether a paper is supported or contradicted, use Scite.

What Scriptorium does is take what those tools produce and turn it into a defensible chapter with sources you can audit — and then a podcast. **Use it alongside the others, not instead of them.**

|  | Scriptorium | Elicit | Consensus | ResearchRabbit | Scite |
|---|---|---|---|---|---|
| Outputs a draft you can defend | ✅ | Summaries only | Answer cards | Graphs | Badges |
| Every claim traceable to a source quote | ✅ | Partial | ❌ | ❌ | ❌ |
| Paper trail for your committee | ✅ | ❌ | ❌ | ❌ | ❌ |
| Names disagreements as camps | ✅ | ❌ | Partial | ❌ | ✅ |
| Generates a podcast version | ✅ via NotebookLM | ❌ | ❌ | ❌ | ❌ |
| Your sources stay where you put them | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## The three rules Scriptorium enforces

These are the rules behind the curtain that make the output defensible:

1. **Every empirical claim cites a real source.** If a sentence in the draft doesn't point back to a paper and a page, the system either flags it for you to fix, or strips it. There is no "the literature suggests" without a citation.
2. **Every step is logged.** Searches, screening decisions, what got extracted from each paper, what passed the quality check on the draft — all of it goes into a record your committee can read. Append-only, so nothing gets quietly rewritten.
3. **Disagreement is named, not averaged.** When papers disagree, the draft says so explicitly with the camps named. No false consensus.

These rules are why the output is something you'd actually put in front of a committee.

---

## Common things to say

You can talk to Scriptorium in plain English. Some phrases that work:

- *"Set up Scriptorium"* — first-run setup
- *"I have a topic but I'm not sure what I want from it"* — starts the direction interview
- *"I need a research question for this paper"* — starts the research-question interview
- *"Run a lit review on [topic]"* — runs the whole pipeline
- *"Find papers on [topic]"* — just the search
- *"Where do these papers disagree?"* — the contradictions check
- *"Show me the audit trail"* — the paper trail your committee would want
- *"Publish this as a podcast"* — sends to NotebookLM

Phrasing doesn't have to match exactly. Anything close works.

---

## Common patterns

**1. Idea → question → chapter.** You're working on a dissertation chapter but the question isn't pinned. Say *"grill me on this topic"* and walk through three to five turns. End with a defensible research question and a literature review that backs it up. This is the canonical use case.

**2. Get unstuck on a vague research interest.** Sometimes the right answer is *"this is a strategy memo, not a paper"* — and the interview surfaces that. Either way you exit knowing what you're doing.

**3. Get smart fast for a meeting.** Tonight: scope a quick review. Tomorrow morning: ask for the podcast version. Walk into the meeting with the actual literature in your head, not a hot take.

**4. Hand a draft and a tape to your committee.** A markdown chapter draft, the audit trail as proof of method, and a 12-minute audio overview your committee can listen to before the defense. Three artifacts answering three different committee questions: *"What does the literature say?"*, *"How did you search?"*, and *"Can you give me the gist?"*

---

## Privacy

Your work stays inside the tools you've connected. The only operation that moves it elsewhere is the publishing step, which sends to NotebookLM (Google) and always asks first. MIT-licensed, no telemetry, no phone-home.

---

## License & credits

MIT. See [LICENSE](./LICENSE).

Architected in the style of [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent — small skill folders that Claude loads on demand. Scriptorium is what happens when you apply that pattern to literature review. Sister project for Claude Code users: [Jerrymwolf/Scriptorium](https://github.com/Jerrymwolf/Scriptorium).

---

**Try it.** Drop the [`.plugin` file from the latest release](https://github.com/Jerrymwolf/Scriptorium-Cowork/releases/latest) into a Cowork chat, click Accept, and say *"run a lit review on something I've been meaning to read up on."* If something breaks or feels weird, [file an issue](https://github.com/Jerrymwolf/Scriptorium-Cowork/issues) — at this stage, real feedback is the most valuable thing you can give.
