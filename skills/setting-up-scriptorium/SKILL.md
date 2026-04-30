---
name: setting-up-scriptorium
description: Use on first run, when the user asks "set up Scriptorium", "what does this plugin do", or "configure Scriptorium". Walks the user through a 60-second onboarding — connector check, state-home selection, basic preferences — without requiring any CLI install.
---

# Setting Up Scriptorium (Cowork)

This is the on-ramp. It runs once per user, takes about a minute, and ends with the user ready to scope their first review.

There is **no CLI to install**. Scriptorium runs as pure skills and MCP. If the user asks about a `scriptorium` binary, tell them this plugin works without it.

## Step 1 — Fire `using-scriptorium`

It runs the connector probe and tells you which scholarly-search MCPs and which state-home options resolved. Do not duplicate the probe here.

## Step 2 — Recap the connector landscape to the user

In one short paragraph, name what was detected and what is missing:

> Connectors detected: **Consensus** (claim-first search), **PubMed** (biomed). State home: **NotebookLM** is available — I'll use that as the default. Missing: **Scholar Gateway** for breadth across non-biomed disciplines, **Drive** as a fallback state home if NotebookLM is unavailable. You can add either later by going to your Cowork connector settings.

If nothing resolved, say so plainly: "No scholarly-search MCPs detected. I can still run a degraded search via WebFetch against OpenAlex's public API, but recall will be lower. To upgrade, connect Consensus, Scholar Gateway, or PubMed in Cowork settings."

## Step 3 — Confirm state home

Use AskUserQuestion to confirm. Options follow the cascade in `using-scriptorium` — NotebookLM > Document store > Knowledge base > session-only. Show only the options that actually resolved, plus "session-only" as the implicit fallback.

If only one resolved, skip the question and announce the choice: "I'll use Drive as the state home for this review."

## Step 4 — Collect minimal preferences

Ask one question at a time, in this order. Skip any that are obvious from the conversation so far.

1. **Contact email for OpenAlex / Unpaywall politeness.** Required if the user wants better rate limits and full-text resolution beyond what the search MCPs return. Optional otherwise. Phrase it: "What email should I attach to scholarly-search requests? (Used for politeness/rate limits — not for any account creation.)"
2. **Default cite-check mode.** Strict (strip unsupported sentences) or lenient (flag with `[UNSUPPORTED]`). Default to **strict** for any user who mentions dissertation, thesis, or systematic review; **lenient** for exploratory drafts.
3. **Languages.** Default `["en"]`. Ask if the user is non-English-primary.

Persist answers as a Cowork user-memory note named `scriptorium-config`, TOML-shaped:

```toml
[scriptorium]
unpaywall_email = "you@university.edu"
cite_check_mode = "strict"
languages = ["en"]
state_home = "notebooklm"
```

If user-memory is unavailable, store in conversation memory and warn: "These will not persist beyond this session — re-confirm next time."

## Step 5 — Hand off

Close with: "Setup is complete. To start your first review, tell me the research question — for example, *'I want to do a lit review on caffeine and working memory in healthy adults.'*"

Do not auto-fire `lit-scoping` here. Let the user initiate the next turn so they have a clean entry point.

## What this skill does NOT do

- Does not install anything.
- Does not write to the filesystem (Cowork has none).
- Does not validate any account credentials — it just records what the user said.
- Does not pre-fetch any papers. Search starts in `lit-searching`, not here.
