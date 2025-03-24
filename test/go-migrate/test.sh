#!/usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
#    devcontainer features test \
#               --features go-migrate \
#               --base-image mcr.microsoft.com/devcontainers/go:latest .

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
check "migrate version" migrate --version

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
