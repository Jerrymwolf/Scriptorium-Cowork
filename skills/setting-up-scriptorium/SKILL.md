---
name: setting-up-scriptorium
description: Use on first run, when the user asks "set up Scriptorium", "what does this plugin do", or "configure Scriptorium". Walks the user through a 60-second onboarding — connector check, state-home selection, basic preferences — without requiring any CLI install.
---

# Setting Up Scriptorium (Cowork)

This is the on-ramp. It runs once per user, takes about a minute, and ends with the user ready to scope their first review.

There is **no CLI to install**. This Cowork edition is pure skills and MCP. If the user expected to run `pipx install scriptorium-cli`, tell them that's the Claude Code edition; this Cowork plugin works without it.

## Step 1 — Fire `using-scriptorium`

It runs the connector probe and tells you which scholarly-search MCPs and which state-home options resolved. Do not duplicate the probe here.

## Step 2 — Recap the connector landscape to the user

In one short paragraph, name what was detected and what is missing:

> Connectors detected: **Consensus** (claim-first search), **PubMed** (biomed), **Scite** (citation context). State home: **NotebookLM** is available — I'll use that as the default. Missing: **Scholar Gateway** for breadth across non-biomed disciplines, **Drive** as a fallback state home if NotebookLM is unavailable. You can add either later in your Cowork connector settings.

If a category did not resolve, ask the user explicitly: *"You said you have Consensus connected — I didn't detect it during the probe. Want to retry, or tell me the exact MCP tool name and I'll use it directly?"* Do not silently move to a degraded path when the user's setup contradicts what was probed.

If nothing resolved, say so plainly: "No scholarly-search MCPs detected. I can run a degraded search via WebFetch against OpenAlex's public API, but recall will be lower. To upgrade, connect Consensus, Scholar Gateway, PubMed, or Scite in Cowork settings."

## Step 3 — Confirm state home

Use AskUserQuestion to confirm. Options follow the cascade in `using-scriptorium` — NotebookLM > document store (Drive/Box/OneDrive) > knowledge base (Notion/Confluence) > session-only. Show only the options that actually resolved, plus "session-only" as the implicit fallback.

If only one resolved, skip the question and announce the choice: *"I'll use Drive as the state home for this review."*

## Step 4 — Collect minimal preferences

Ask one question at a time, in this order. Skip any obvious from the conversation so far.

1. **Contact email for OpenAlex / Unpaywall politeness.** Required if the user wants Unpaywall full-text retrieval (which is most of the value of the cascade). The Unpaywall API requires a contact email per its ToS — no account creation, just a real email for rate-limit tracking. Phrase it: *"What email should I attach to scholarly-search requests? Unpaywall and OpenAlex use it for rate-limit politeness."*

2. **University library proxy URL.** Optional but recommended for institutional researchers. Phrase it: *"Do you have access to a university library? If yes, paste your library's EZproxy URL prefix and I'll route paywalled DOIs through it when the open-access cascade misses."* Common patterns:

   | Institution | Proxy base |
   |---|---|
   | UPenn (Franklin) | `https://proxy.library.upenn.edu/login?url=` |
   | Harvard | `https://login.ezp-prod1.hul.harvard.edu/login?url=` |
   | Stanford | `https://login.stanford.idm.oclc.org/login?url=` |
   | Yale | `https://yale.idm.oclc.org/login?url=` |
   | Columbia | `https://login.ezproxy.cul.columbia.edu/login?url=` |
   | UC Berkeley | `https://login.libproxy.berkeley.edu/login?url=` |
   | MIT | `https://libproxy.mit.edu/login?url=` |

   If the user doesn't recognize their institution's pattern, suggest they check their library's website for "off-campus access" or "EZproxy" instructions, or try `<institution>.idm.oclc.org/login?url=` (OCLC hosts proxies for many universities). The agent does not authenticate to the proxy — it generates proxied URLs that the user clicks in their own browser, then drags the resulting PDF back into the chat.

3. **Default cite-check mode.** Strict (strip unsupported sentences) or lenient (flag with `[UNSUPPORTED]`). Default to **strict** for any user who mentions dissertation, thesis, or systematic review; **lenient** for exploratory drafts.

4. **Languages.** Default `["en"]`. Ask if the user is non-English-primary.

Persist answers as a Cowork user-memory note named `scriptorium-config`, TOML-shaped:

```toml
[scriptorium]
unpaywall_email = "you@university.edu"
library_proxy_base = "https://proxy.library.upenn.edu/login?url="
cite_check_mode = "strict"
languages = ["en"]
state_home = "notebooklm"
```

Any of these fields may be empty. The cascade falls through gracefully when a field is missing.

If user-memory is unavailable, store in conversation memory and warn: "These will not persist beyond this session — re-confirm next time."

## Step 5 — Network allowlist note

If the user's Cowork org enforces an outbound-network allowlist (the default for many enterprise deployments), Unpaywall and arXiv will be blocked by `WebFetch`. Mention this only if the org clearly has a restrictive policy or the user asks why the cascade can't reach external hosts. Hosts to add:

- `api.unpaywall.org` — Unpaywall API
- `export.arxiv.org` — arXiv full-text and metadata
- The user's library proxy host (e.g., `proxy.library.upenn.edu`) — only required if `WebFetch` is being used to *test* the proxy URL; the actual fetch happens in the user's browser

The user asks their Cowork admin to add these hosts, or — for personal accounts — adds them in Settings → Capabilities.

## Step 6 — Hand off

Close with: *"Setup is complete. To start your first review, tell me the research question — for example, 'I want to do a lit review on caffeine and working memory in healthy adults.'"*

Do not auto-fire `lit-scoping` here. Let the user initiate the next turn so they have a clean entry point.

## What this skill does NOT do

- Does not install anything.
- Does not write to the filesystem (Cowork has none).
- Does not validate any account credentials — it just records what the user said.
- Does not authenticate to the user's library proxy. Library access happens through the user's browser; the agent only generates the proxied URL.
- Does not pre-fetch any papers. Search starts in `lit-searching`, not here.
