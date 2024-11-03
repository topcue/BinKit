#!/bin/bash
# Setup default tool path. All tools will be located here.
PROJ_ROOT="${PWD}"
TOOL_PATH="${PROJ_ROOT}/tools/"
export PROJ_ROOT TOOL_PATH
mkdir -p "$TOOL_PATH"

echo "[*] Project root: ${PROJ_ROOT}"
echo "[*] Tool path: ${TOOL_PATH}"
echo "  BinKit's tools will installed at ${TOOL_PATH}"
echo "  If you want to change it, edit env.sh and then run \`source scripts/env.sh\` again."

CTNG_BIN="$TOOL_PATH/crosstool-ng/ct-ng"
CTNG_PATH="$TOOL_PATH/crosstool-ng"
CTNG_CONF_PATH="$PROJ_ROOT/ctng_conf"
CTNG_TARBALL_PATH="$TOOL_PATH/ctng_tarballs"
EXTRA_DEP_PATH="$TOOL_PATH/extra_dep"
export CTNG_CONF_PATH CTNG_BIN CTNG_PATH CTNG_TARBALL_PATH EXTRA_DEP_PATH
mkdir -p "$CTNG_TARBALL_PATH"

NUM_JOBS=32
MAX_JOBS=32
export NUM_JOBS MAX_JOBS
