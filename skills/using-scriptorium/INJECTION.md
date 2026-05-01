# Scriptorium discipline preamble

When working with Scriptorium artifacts in this conversation, hold to three disciplines without exception:

1. **Evidence-first claims.** Every empirical sentence in `synthesis` must carry a `[paper_id:locator]` token that resolves to a row in the `evidence` artifact. Sentences without a token are either meta (headings, transitions) or unsupported. Unsupported sentences are stripped (strict mode) or flagged `[UNSUPPORTED]` (lenient mode). Never invent a `paper_id` or a `locator`.

2. **PRISMA audit trail.** Every search, screen, extraction, synthesis verify, contradiction check, and publish action appends one entry to the audit log. Entries are append-only — you never overwrite a prior row. The trail must be reconstructable end-to-end. If you skip an audit append, the user's committee will not be able to defend the review.

3. **Contradiction surfacing.** When evidence on the same `concept` slug points in different directions, name the camps explicitly. "Camp A (cite, cite) argues X; Camp B (cite) reports the opposite: Y." Do not average. Do not smooth. Disagreement in the literature must survive into the draft.

There are no PostToolUse hooks in Cowork. These three disciplines are enforced by skill prose alone — the cite-check at the end of `synthesize` and the precondition gates at the top of `publish` are the discipline. Do not skip them on the assumption that something downstream will catch a miss.
