#!/usr/bin/env bash
# Runtime test for runtime/cite-check.py against a fixture covering
# pmid (numeric), openalex (W-prefixed), and consensus (alphanumeric)
# paper_id shapes. Asserts exit 0 with 3 resolved citations.
set -euo pipefail
cd "$(dirname "$0")/.."

OUTPUT=$(python3 runtime/cite-check.py \
  --synthesis scripts/cite-check-test-fixture/synthesis-pmid.md \
  --evidence scripts/cite-check-test-fixture/evidence.jsonl \
  --corpus scripts/cite-check-test-fixture/corpus.jsonl \
  --mode strict --min-citations 3)

echo "$OUTPUT"
echo
if echo "$OUTPUT" | grep -q "Citations resolved to evidence:   3 / 3"; then
  echo "✓ R0 fixture passed: 3 citations resolved across pmid/openalex/consensus"
  exit 0
else
  echo "✗ R0 fixture FAILED: cite-check did not resolve 3/3"
  exit 1
fi
