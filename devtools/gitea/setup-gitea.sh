#!/bin/bash
set -euo pipefail

# Setup script for self-hosted Gitea with CI runner
# Usage: ./devtools/gitea/setup-gitea.sh [--admin-password <password>]
#
# Deploys Gitea + act_runner on the local machine via Docker Compose.
# Default admin: selena / selena (change with --admin-password)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITEA_URL="http://localhost:3000"
ADMIN_USER="selena"
ADMIN_PASSWORD="selena"
ADMIN_EMAIL="admin@selena.local"

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --admin-password) ADMIN_PASSWORD="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Start Gitea (without runner — need token first)
# ---------------------------------------------------------------------------
echo "Starting Gitea..."
cd "${SCRIPT_DIR}"
docker compose up -d gitea

echo "Waiting for Gitea to be healthy..."
for i in $(seq 1 30); do
    if curl -sf "${GITEA_URL}/api/v1/version" >/dev/null 2>&1; then
        echo "Gitea is up."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "Timed out waiting for Gitea."
        exit 1
    fi
    sleep 2
done

# ---------------------------------------------------------------------------
# Create admin user
# ---------------------------------------------------------------------------
echo "Creating admin user..."
docker exec gitea gitea admin user create \
    --username "${ADMIN_USER}" \
    --password "${ADMIN_PASSWORD}" \
    --email "${ADMIN_EMAIL}" \
    --admin \
    --must-change-password=false 2>/dev/null || echo "Admin user already exists."

# ---------------------------------------------------------------------------
# Create API token
# ---------------------------------------------------------------------------
echo "Creating API token..."
TOKEN_RESPONSE=$(curl -sf -X POST "${GITEA_URL}/api/v1/users/${ADMIN_USER}/tokens" \
    -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{"name":"setup-token","scopes":["all"]}' 2>/dev/null || true)

if [ -z "${TOKEN_RESPONSE}" ]; then
    # Token may already exist, delete and recreate
    curl -sf -X DELETE "${GITEA_URL}/api/v1/users/${ADMIN_USER}/tokens/setup-token" \
        -u "${ADMIN_USER}:${ADMIN_PASSWORD}" >/dev/null 2>&1 || true
    TOKEN_RESPONSE=$(curl -sf -X POST "${GITEA_URL}/api/v1/users/${ADMIN_USER}/tokens" \
        -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" \
        -d '{"name":"setup-token","scopes":["all"]}')
fi

API_TOKEN=$(echo "${TOKEN_RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin)['sha1'])" 2>/dev/null || \
            echo "${TOKEN_RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null || true)

if [ -z "${API_TOKEN}" ]; then
    echo "Failed to get API token. Using basic auth."
    API_AUTH="-u ${ADMIN_USER}:${ADMIN_PASSWORD}"
else
    API_AUTH="-H 'Authorization: token ${API_TOKEN}'"
fi

# ---------------------------------------------------------------------------
# Create selena repo
# ---------------------------------------------------------------------------
echo "Creating selena repository..."
eval curl -sf -X POST "${GITEA_URL}/api/v1/user/repos" \
    ${API_AUTH} \
    -H "Content-Type: application/json" \
    -d '{"name":"selena","description":"Selena trading engine","default_branch":"main","auto_init":false}' \
    >/dev/null 2>&1 || echo "Repository may already exist."

# ---------------------------------------------------------------------------
# Get runner registration token and start runner
# ---------------------------------------------------------------------------
echo "Getting runner registration token..."
RUNNER_TOKEN=$(eval curl -sf -X GET "${GITEA_URL}/api/v1/repos/${ADMIN_USER}/selena/actions/runners/registration-token" \
    ${API_AUTH} | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "Starting runner..."
RUNNER_TOKEN="${RUNNER_TOKEN}" docker compose up -d runner

echo "Waiting for runner to register..."
sleep 5
docker logs gitea-runner 2>&1 | tail -5

# ---------------------------------------------------------------------------
# Set up branch protection
# ---------------------------------------------------------------------------
echo "Setting up branch protection on main..."
eval curl -sf -X POST "${GITEA_URL}/api/v1/repos/${ADMIN_USER}/selena/branch_protections" \
    ${API_AUTH} \
    -H "Content-Type: application/json" \
    -d '{
        "branch_name": "main",
        "enable_push": false,
        "enable_merge_whitelist": true,
        "enable_status_check": true,
        "status_check_contexts": ["build-and-test"]
    }' >/dev/null 2>&1 || echo "Branch protection may already exist."

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo " Gitea is ready!"
echo "============================================"
echo ""
echo " Web UI:  ${GITEA_URL}"
echo " Login:   ${ADMIN_USER} / ${ADMIN_PASSWORD}"
echo " SSH:     ssh://git@100.85.32.4:2222/${ADMIN_USER}/selena.git"
echo " HTTP:    ${GITEA_URL}/${ADMIN_USER}/selena.git"
echo ""
echo " To push your repo:"
echo "   git remote add gitea ssh://git@100.85.32.4:2222/${ADMIN_USER}/selena.git"
echo "   git push gitea main"
echo ""
