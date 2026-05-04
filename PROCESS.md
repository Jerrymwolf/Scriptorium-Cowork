# Process for Scriptorium-Cowork contributions

This file documents the contribution contract for Scriptorium-Cowork — human or AI. It exists because misreads of "approved scope" have shipped unintended changes.

## Plan-mode is the default

Any non-trivial task — workflow fix, skill prose change, schema edit, release prep — starts in PLAN-MODE. Plan-mode produces:

- A plan document with Files / Problem / Fix / Verify per task
- Decision points marked "DECISION REQUIRED:" with options and a default
- Acceptance criteria stated as observable behavior, not file presence
- A rollback path

Plan-mode does not touch files.

## Execute-mode requires explicit approval

**Approval phrases that move from plan to execute:**
- "go" / "go ahead" / "execute the plan"
- "ship it"
- "approved — execute"

**Approval phrases that DO NOT authorize execution:**
- "approved scope" (means: we agree on what should happen)
- "looks good" (means: I've read it; not necessarily go)
- silence (means: keep refining the plan)

## Deviation surfacing

If the plan as written conflicts with actual codebase state, do not silently adapt. Surface the conflict immediately:

> *"Spec'd change [X] would break [Y] because [Z]. Three options: A1, A2, A3. Recommend A1. Awaiting your choice."*

Then wait. Do not pick a default unless the user explicitly says "use your recommendation."

## Plan format

Match the v0.1.8 / v0.2.0 spec template:

1. Goal (one paragraph)
2. Decision points (table with defaults)
3. Order of operations (numbered)
4. Tasks (Files / Problem / Fix / Verify each)
5. Risk register
6. Acceptance criteria (behavior-level)
7. What this plan does NOT include
8. Out of scope but tracked (lands in TODO.md)

## Format-of-execution

When approved, execute in declared order. After each task, surface a diff-preview before committing. Do not run `release.sh` until smoke tests have passed AND the user has explicitly authorized the release.

## Version-number discipline

The version number is a promise about scope, not a milestone vanity number.

- **0.1.x** — bug fixes, prose tightenings, validator additions; no new user-visible behaviors
- **0.x.0** — new discipline gates, new skills, schema changes; user-visible but additive
- **1.0.0** — the loop-mode release. Reserved for when `/scriptorium` opens an interactive session with full refinement primitives. Do not ship as 1.0.0 if loop-mode is not in.

If a release feels like 1.0 because of marketing pull but is actually scope-staged below loop-mode, ship it as 0.x.0 and write the headline accurately.

## Smoke-test discipline

Releases that change runtime behavior require a hand-run smoke test before tagging. The smoke test runs the changed skill in a real Cowork session against a tiny reproducible corpus (e.g., 5–10 papers) and confirms expected user-visible behavior.

Smoke tests are documented in the release plan. Skipping them is a release blocker, not a soft warning.

## Repo layout: `scripts/` vs. `runtime/` (added v0.4.0)

Two top-level script directories with different shipping shapes:

- **`scripts/`** — developer-only. Excluded from the `.plugin` zip via the `scripts/*` exclusion in `release.sh`. Contains: `release.sh`, `validate-plugin.js`, `smoke-test.sh`, fixture data, runtime-test runbooks. Anything skill prose references at runtime DOES NOT belong here.
- **`runtime/`** — runtime helper scripts. Shipped in the `.plugin` zip. Contains: `cite-check.py`, `build-viewer.py`. Skill prose references these via `runtime/<script>.py`.

The split exists because v0.3.0 had a packaging bug: skills referenced `scripts/cite-check.py`, but `scripts/*` was excluded from the build, so the script the cite-check discipline gate depended on was never in the shipped plugin.

`validate-plugin.js` asserts both `runtime/cite-check.py` and `runtime/build-viewer.py` are present in the built plugin. If you add a new runtime script, add a corresponding assertion.

## Commit hygiene

Releases that touch multiple semantic concerns get split into commits per concern. Example for v0.2.0:

```
fix(workflow): separate synthesize and contradictions phases
ci: add release-time plugin validator
feat(grill): add disconfirmer gate for defending intent
feat(synthesize): three-tier sentence typing
feat(probe): description-keyword fallback for UUID tools
docs: v0.2.0 changelog and migration guide
```

`release.sh` auto-commits the working tree as one "Release vX.Y.Z" if you let it. Stage the semantic commits manually first; let `release.sh` only do the tag-and-publish.
