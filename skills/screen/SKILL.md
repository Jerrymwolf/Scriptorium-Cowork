---
name: screen
description: Use after search when the user wants to apply inclusion/exclusion criteria (year range, language, must-include/exclude keywords) to the corpus. Marks papers kept or dropped with a reason and records the decision in the audit trail.
---

# Literature Screening (Cowork)

Input: `corpus` artifact with every row at status `candidate`. Output: same artifact with each row at `kept` or `dropped`, plus a `reason` field. The audit trail captures the batch decision.

## Criteria vocabulary

All five criteria are optional. Any present criterion that fails for a given paper drops it.

- `year_min` — int; drops `year < year_min`
- `year_max` — int; drops `year > year_max`
- `languages` — list of ISO codes; drops papers whose `raw.language` is not in the list
- `must_include` — list of keywords (case-insensitive); drops papers whose title+abstract do not contain ALL listed keywords
- `must_exclude` — list of keywords; drops papers whose title+abstract contain ANY listed keyword

Order of evaluation is fixed: year → language → must_include → must_exclude. The first failing criterion sets `reason`.

## Workflow

1. Read the scope artifact and pre-fill criteria from it: `year_min` and `year_max` from `year_range`, `languages` from the user's config, `must_include` from key terms in `research_question`. Show the user the inferred criteria and ask for additions.
2. Confirm the criteria with the user; print the JSON they imply.
3. Read the `corpus` artifact from the state adapter.
4. For each row, evaluate the criteria in-prose (you are the screener). Update `status` ("kept"/"dropped") and `reason` inline.
5. Write the updated corpus back to the adapter.
6. Append one audit entry: `{phase: "screening", action: "rule.apply", details: {year_min, year_max, languages, must_include, must_exclude, kept, dropped}, status: "success"}`.
7. Report `{kept: N, dropped: M}` to the user.

## Edge cases

- **Missing year** → fails `year_min`/`year_max` if those criteria are set. Record `reason = "year missing"`.
- **Missing abstract** → only title is searched for keywords. If `must_include` is set and title alone doesn't contain it, the paper drops. Flag this in audit details so the user can revisit.
- **Duplicate papers** (same DOI) are already deduped in search; don't re-dedupe here.

## Reversibility

Screening is reversible — set a row's `status` back to `candidate` and clear `reason` to restore it. If the user wants to re-screen with different criteria, drop them all back to `candidate` first, then re-run.

## Hand-off

After reporting kept/dropped counts, ask: "Proceed to full-text extraction on the N kept papers?" Hand off to `extract`.

## User narration (added v0.2.1)

Follow `NARRATION.md`. Screen is a quieter phase but still unannounced today.

**Before applying criteria:**

> Now I'm filtering the papers we found to keep only the ones that match
> what you're researching — by year, language, and topic. About 30 seconds.

**After:**

> [N] papers kept, [M] dropped because [reason in plain language —
> e.g., "they were about education, not workplace"]. Moving to pulling
> the key findings from each paper next.

Translate "kept/dropped" status into plain language; never surface raw rule names like `must_include` or `must_exclude`.
