#!/usr/bin/env bash
# Post-deployment smoke test for Qdrant on Azure Container Apps.
# Usage: ./scripts/test-qdrant.sh <qdrant_endpoint>
# Example: ./scripts/test-qdrant.sh https://qdrant.nicedesert-abc123.eastus2.azurecontainerapps.io
#
# Exit codes: 0 = all tests passed, 1 = one or more tests failed

set -euo pipefail

QDRANT_URL="${1:?Usage: $0 <qdrant_endpoint>}"
QDRANT_URL="${QDRANT_URL%/}"
TEST_COLLECTION="__smoke_test_$(date +%s)"
PASSED=0
FAILED=0

log()   { echo "[TEST] $*"; }
pass()  { log "PASS - $*"; PASSED=$((PASSED + 1)); }
fail()  { log "FAIL - $*"; FAILED=$((FAILED + 1)); }

cleanup() {
  log "Cleaning up test collection..."
  curl -sf -X DELETE "${QDRANT_URL}/collections/${TEST_COLLECTION}" > /dev/null 2>&1 || true
}
trap cleanup EXIT

# ---------- 1. Health check ----------
log "Checking /healthz..."
if curl -sf --max-time 10 "${QDRANT_URL}/healthz" > /dev/null; then
  pass "Health endpoint responded OK"
else
  fail "Health endpoint unreachable"
  echo "Qdrant is not reachable at ${QDRANT_URL}. Aborting."
  exit 1
fi

# ---------- 2. Readiness check ----------
log "Checking /readyz..."
if curl -sf --max-time 10 "${QDRANT_URL}/readyz" > /dev/null; then
  pass "Readiness endpoint responded OK"
else
  fail "Readiness check failed (Qdrant not ready)"
fi

# ---------- 3. Create test collection ----------
log "Creating test collection '${TEST_COLLECTION}'..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
  -X PUT "${QDRANT_URL}/collections/${TEST_COLLECTION}" \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 4,
      "distance": "Cosine"
    }
  }')

if [ "$HTTP_CODE" = "200" ]; then
  pass "Created collection (HTTP ${HTTP_CODE})"
else
  fail "Create collection returned HTTP ${HTTP_CODE}"
fi

# ---------- 4. Upsert test vectors ----------
log "Upserting test vectors..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
  -X PUT "${QDRANT_URL}/collections/${TEST_COLLECTION}/points" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [
      {"id": 1, "vector": [0.1, 0.2, 0.3, 0.4], "payload": {"label": "test-a"}},
      {"id": 2, "vector": [0.5, 0.6, 0.7, 0.8], "payload": {"label": "test-b"}}
    ]
  }')

if [ "$HTTP_CODE" = "200" ]; then
  pass "Upserted 2 vectors (HTTP ${HTTP_CODE})"
else
  fail "Upsert returned HTTP ${HTTP_CODE}"
fi

# ---------- 5. Search ----------
log "Searching for nearest vector..."
SEARCH_RESULT=$(curl -sf --max-time 15 \
  -X POST "${QDRANT_URL}/collections/${TEST_COLLECTION}/points/search" \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.5, 0.6, 0.7, 0.8],
    "limit": 1,
    "with_payload": true
  }' 2>&1) || true

if echo "$SEARCH_RESULT" | grep -q '"label":"test-b"'; then
  pass "Search returned correct nearest neighbor"
else
  fail "Search did not return expected result: ${SEARCH_RESULT}"
fi

# ---------- 6. Collection info (verify persistence) ----------
log "Verifying collection info..."
INFO_RESULT=$(curl -sf --max-time 10 \
  "${QDRANT_URL}/collections/${TEST_COLLECTION}" 2>&1) || true

if echo "$INFO_RESULT" | grep -q '"vectors_count"'; then
  pass "Collection info returned vector count"
else
  fail "Collection info unexpected: ${INFO_RESULT}"
fi

# ---------- Summary ----------
echo ""
echo "============================================"
echo "  Qdrant Smoke Test Results"
echo "  Endpoint: ${QDRANT_URL}"
echo "  Passed: ${PASSED}  Failed: ${FAILED}"
echo "============================================"

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
