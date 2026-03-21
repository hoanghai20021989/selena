#!/bin/bash
set -euo pipefail

# Setup script for GitHub Actions self-hosted runner in a Podman container
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
podman build -t "${IMAGE_NAME}" -f "${SCRIPT_DIR}/Containerfile" "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Stop existing runner if any
# ---------------------------------------------------------------------------
if podman container exists "${CONTAINER_NAME}" 2>/dev/null; then
    echo "Stopping existing runner..."
    podman stop "${CONTAINER_NAME}" 2>/dev/null || true
    podman rm "${CONTAINER_NAME}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Configure and start the runner
# ---------------------------------------------------------------------------
echo "Configuring runner..."
podman run -d \
    --name "${CONTAINER_NAME}" \
    --replace \
    -v "${HOME}/.cache/ccache:/home/runner/.cache/ccache:Z" \
    -v "${HOME}/.conan2:/home/runner/.conan2:Z" \
    --entrypoint /bin/bash \
    "${IMAGE_NAME}" \
    -c "
        cd /opt/actions-runner
        ./config.sh --url ${REPO_URL} --token ${RUNNER_TOKEN} --name selena-local --labels self-hosted,linux --unattended --replace
        ./run.sh
    "

echo ""
echo "Runner is starting. Check status with:"
echo "  podman logs -f ${CONTAINER_NAME}"
echo ""
echo "To stop:"
echo "  podman stop ${CONTAINER_NAME}"
echo ""
echo "To restart:"
echo "  podman start ${CONTAINER_NAME}"
