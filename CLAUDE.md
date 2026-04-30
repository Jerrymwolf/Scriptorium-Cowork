# scriptorium-cowork — repo-level context

Scriptorium is a literature-review plugin for Claude Cowork. It runs through skills and MCPs only — no CLI, no hooks, no shell.

## What this plugin enforces (three disciplines)

1. **Evidence-first claims.** Every empirical sentence in `synthesis` carries a `[paper_id:locator]` token that resolves to a row in `evidence`.
2. **PRISMA audit trail.** Every search, screen, extraction, synthesis, and publish action appends one entry to an append-only audit log.
3. **Contradiction surfacing.** Disagreement is named as camps, not averaged into bland consensus.

## How it works

- **No CLI.** Pure skills + MCP.
- **No hooks.** Cowork has no PostToolUse or SessionStart hook system; the cite-check is enforced by `lit-synthesizing`'s mandatory final step, and the discipline preamble is loaded from `skills/using-scriptorium/INJECTION.md`.
- **No slash commands.** Cowork dispatches via natural language; the README documents trigger phrases instead.
- **Connector-agnostic.** Skills reference tool *categories* (`~~claim search`, `~~document store`, `~~notebook publish`) rather than specific products. The runtime probe in `using-scriptorium` resolves placeholders to whichever MCPs the user has connected. See `CONNECTORS.md`.

## Repository layout

- `.claude-plugin/plugin.json` — plugin manifest
- `.claude-plugin/marketplace.json` — marketplace manifest for `/plugin marketplace add Jerrymwolf/Scriptorium-Cowork`
- `skills/` — eleven SKILL.md files implementing the pipeline
- `CONNECTORS.md` — tool-category map and state-home cascade
- `README.md` — user-facing install + usage
- `CHANGELOG.md` — version history
- `LICENSE` — MIT

There are deliberately **no** `commands/`, `agents/`, or `hooks/` directories. Cowork doesn't render those surfaces.

## When working in this repo

- Skill prose is authoritative. Do not add Bash invocations, CLI flags, or filesystem paths assuming a local cwd — Cowork has none of those.
- Keep `~~category` placeholders intact in skill prose; the runtime probe resolves them. Hardcoding a specific MCP tool name (e.g., `mcp__claude_ai_Consensus__search`) is acceptable only inside `using-scriptorium/SKILL.md`'s probe table.
- When adding a new phase skill, fire `using-scriptorium` first in its body and read state through the adapter mapping. Do not invent a new state shape.
- The `.plugin` zip is built from this repo root (`zip -r /tmp/scriptorium-cowork.plugin . -x "*.git*" "*.DS_Store"`). The build artifact is gitignored — only ship via GitHub Release.

## Distribution paths

1. **Anthropic public Cowork plugin directory** — submit at `clau.de/plugin-directory-submission`. Highest-leverage discoverability.
2. **GitHub Release with `.plugin` attached** — canonical versioned download.
3. **Drag `.plugin` into Cowork chat** — simplest peer sharing; renders as rich preview with Accept button.

## First-time publish from Claude Code

Run this in Claude Code with `gh` authenticated to `Jerrymwolf`:

```bash
# 1. Move out of the parent Scriptorium repo into a sibling location
cp -R ~/Desktop/Projects/APPs/Scriptorium/cowork-plugin ~/Desktop/Projects/APPs/Scriptorium-Cowork
cd ~/Desktop/Projects/APPs/Scriptorium-Cowork

# 2. Init local git
git init -b main
git add .
git commit -m "Initial release: Scriptorium for Cowork v0.1.0"

# 3. Create the GitHub repo and push
gh repo create Jerrymwolf/Scriptorium-Cowork \
  --public \
  --description "Evidence-first, PRISMA-audited literature review for Claude Cowork. No CLI required." \
  --source . --remote origin --push

# 4. Build the .plugin artifact (gitignored — only ships via Release)
zip -r /tmp/scriptorium-cowork.plugin . -x "*.git*" "*.DS_Store" "*.plugin"

# 5. Tag and create the v0.1.0 release with the .plugin file attached
git tag -a v0.1.0 -m "v0.1.0 — initial Cowork-native release"
git push origin v0.1.0
gh release create v0.1.0 \
  --title "Scriptorium for Cowork v0.1.0" \
  --notes-file CHANGELOG.md \
  /tmp/scriptorium-cowork.plugin
```

After step 5, verify by opening `https://github.com/Jerrymwolf/Scriptorium-Cowork/releases/tag/v0.1.0` and confirming the `.plugin` file is attached as a release asset.

## Subsequent releases

```bash
# bump version in plugin.json, marketplace.json, CHANGELOG.md
git commit -am "Release vX.Y.Z"
git push
zip -r /tmp/scriptorium-cowork.plugin . -x "*.git*" "*.DS_Store" "*.plugin"
git tag -a vX.Y.Z -m "vX.Y.Z — <one-line summary>"
git push origin vX.Y.Z
gh release create vX.Y.Z \
  --title "Scriptorium for Cowork vX.Y.Z" \
  --notes-file CHANGELOG.md \
  /tmp/scriptorium-cowork.plugin
```

