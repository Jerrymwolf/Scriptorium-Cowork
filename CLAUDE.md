# scriptorium-cowork — repo-level context

This is the **Claude Cowork edition** of Scriptorium, a literature-review plugin. It is a sibling of the Claude Code edition (https://github.com/Jerrymwolf/Scriptorium) and was extracted into its own repo for cleaner Cowork-marketplace identity.

## What this plugin enforces (three disciplines)

1. **Evidence-first claims.** Every empirical sentence in `synthesis` carries a `[paper_id:locator]` token that resolves to a row in `evidence`.
2. **PRISMA audit trail.** Every search, screen, extraction, synthesis, and publish action appends one entry to an append-only audit log.
3. **Contradiction surfacing.** Disagreement is named as camps, not averaged into bland consensus.

## What's different from the Claude Code edition

- **No CLI.** No `pipx install`, no `scriptorium` binary. Pure skills + MCP.
- **No hooks.** Cowork has no PostToolUse or SessionStart hook system; the cite-check is enforced by `synthesize`'s mandatory final step, and the discipline preamble is loaded from `skills/using-scriptorium/INJECTION.md`.
- **No slash commands.** Cowork dispatches via natural language; the README documents trigger phrases instead.
- **Connector-agnostic.** Skills reference tool *categories* (`~~claim search`, `~~document store`, `~~notebook publish`) rather than specific products. The runtime probe in `using-scriptorium` resolves placeholders to whichever MCPs the user has connected. See `CONNECTORS.md`.

## Repository layout

- `.claude-plugin/plugin.json` — plugin manifest
- `.claude-plugin/marketplace.json` — marketplace manifest for `/plugin marketplace add Jerrymwolf/Scriptorium-Cowork`
- `skills/` — fourteen SKILL.md files implementing the router, setup, grill flows, review pipeline, and rendering
- `runtime/` — runtime helper scripts shipped in the `.plugin` (cite-check.py, build-viewer.py). Skill prose references these (NOT `scripts/`). Added v0.4.0 to fix the v0.3.0 packaging bug where `scripts/*` was excluded from the build but skills referenced `scripts/cite-check.py`. Dev-only scripts (release.sh, validate-plugin.js, smoke-test.sh, fixtures) stay in `scripts/`.
- `CONNECTORS.md` — tool-category map and state-home cascade
- `README.md` — user-facing install + usage
- `CHANGELOG.md` — version history
- `LICENSE` — MIT

There are deliberately **no** `commands/`, `agents/`, or `hooks/` directories. Cowork doesn't render those surfaces.

## When working in this repo

- Skill prose is authoritative. Do not add Bash invocations, CLI flags, or filesystem paths assuming a local cwd — Cowork has none of those.
- Keep `~~category` placeholders intact in skill prose; the runtime probe resolves them. Hardcoding a specific MCP tool name (e.g., `mcp__claude_ai_Consensus__search`) is acceptable only inside `using-scriptorium/SKILL.md`'s probe table.
- When adding a new phase skill, fire `using-scriptorium` first in its body and read state through the adapter mapping. Do not invent a new state shape.
- The `.plugin` zip is built by `./scripts/release.sh <version>`, which excludes developer-only files (`scripts/`, `.github/`, marketplace metadata, git metadata, macOS metadata, prior `.plugin` artifacts). Do not hand-roll the zip command for release artifacts.
- Before every release, run `node scripts/validate-plugin.js`. The release script runs it automatically, but running it before version bumps catches stale docs earlier.

## Distribution paths

1. **Anthropic public Cowork plugin directory** — submit at `clau.de/plugin-directory-submission`. Highest-leverage discoverability.
2. **GitHub Release with `.plugin` attached** — canonical versioned download.
3. **Drag `.plugin` into Cowork chat** — simplest peer sharing; renders as rich preview with Accept button.

## Releasing v0.1.3 and onward (the lazy way)

After v0.1.2, releasing is one command. From the repo root after bumping `plugin.json`, `marketplace.json`, and `CHANGELOG.md`:

```bash
./scripts/release.sh 0.1.3
```

The script preflights (gh auth, clean tree, version match, release doesn't exist), commits any pending changes, builds the .plugin, tags, pushes, cuts the GitHub release, attaches the artifact, and prints the share line. It extracts release notes from the version's CHANGELOG section automatically.

(A tag-triggered GitHub Action used to live at `.github/workflows/release.yml` as a second path. It was removed because it raced `release.sh` on every tag push and failed. `release.sh` is now the only release path — do not re-add the Action.)

For the very first release on a fresh repo, see "First-time publish from Claude Code" below.

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
node scripts/validate-plugin.js
zip -r /tmp/scriptorium-cowork.plugin . \
  -x "*.git*" "*.DS_Store" "*.plugin" \
     "scripts/release.sh" "scripts/*" \
     ".github/*" \
     ".claude-plugin/marketplace.json"

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
# bump version in plugin.json, marketplace.json, and CHANGELOG.md
node scripts/validate-plugin.js
./scripts/release.sh X.Y.Z
```

## Sister repo

The Claude Code edition lives at `https://github.com/Jerrymwolf/Scriptorium`. Skill prose between the two should stay aligned in spirit; runtime-specific divergence is documented in CHANGELOG.md.
