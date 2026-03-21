#!/bin/bash
set -euo pipefail

# Setup script for GitHub Actions self-hosted runner in a container
# Usage: ./devtools/ci/setup-runner.sh <GITHUB_RUNNER_TOKEN>
#
# Get a runner token from:
#   https://github.com/hoanghai20021989/selena/settings/actions/runners/new

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

IMAGE_NAME="selena-ci"
CONTAINER_NAME="selena-runner"
REPO_URL="https://github.com/hoanghai20021989/selena"

# ---------------------------------------------------------------------------
# Detect container runtime (prefer docker, fall back to podman)
# ---------------------------------------------------------------------------
if command -v docker &>/dev/null && docker info &>/dev/null; then
    CTR=docker
elif command -v podman &>/dev/null; then
    CTR=podman
else
    echo "Error: neither docker nor podman found"
    exit 1
fi
echo "Using container runtime: ${CTR}"

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <GITHUB_RUNNER_TOKEN>"
    echo ""
    echo "Get a token from: ${REPO_URL}/settings/actions/runners/new"
    exit 1
fi

RUNNER_TOKEN="$1"

# ---------------------------------------------------------------------------
# Build the CI image
# ---------------------------------------------------------------------------
echo "Building CI container image..."
${CTR} build -t "${IMAGE_NAME}" -f "${SCRIPT_DIR}/Containerfile" "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Stop existing runner if any
# ---------------------------------------------------------------------------
echo "Removing existing runner container (if any)..."
${CTR} rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Configure and start the runner
# Runner config is persisted in a named volume so restarts don't re-register.
# On first run: config.sh + run.sh. On restart: just run.sh.
# ---------------------------------------------------------------------------
echo "Configuring runner..."
${CTR} run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -v selena-runner-config:/opt/actions-runner \
    -v selena-ccache:/home/runner/.cache/ccache \
    -v selena-conan:/home/runner/.conan2 \
    --entrypoint /bin/bash \
    "${IMAGE_NAME}" \
    -c "
        cd /opt/actions-runner
        if [ ! -f .runner ]; then
            ./config.sh --url ${REPO_URL} --token ${RUNNER_TOKEN} --name selena-local --labels self-hosted,linux --unattended --replace
        fi
        ./run.sh
    "

echo ""
echo "Runner is starting. Check status with:"
echo "  ${CTR} logs -f ${CONTAINER_NAME}"
echo ""
echo "To stop:"
echo "  ${CTR} stop ${CONTAINER_NAME}"
echo ""
echo "To restart:"
echo "  ${CTR} start ${CONTAINER_NAME}"
