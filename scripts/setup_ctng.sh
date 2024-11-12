#!/bin/bash
if [ -z "$TOOL_PATH" ]; then
    echo "env \$TOOL_PATH should be defined first."
    echo "source scripts/env.sh"
    exit
fi

# setup crosstool-ng
CTNG_BIN="$TOOL_PATH/crosstool-ng/ct-ng"
CTNG_PATH="$TOOL_PATH/crosstool-ng"
if [ ! -f "$CTNG_BIN" ]; then
    if [ ! -d "$CTNG_PATH" ]; then
        wget -P /tmp https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-1.26.0/crosstool-ng-1.26.0.tar.xz
        tar -xf /tmp/crosstool-ng-1.26.0.tar.xz -C /tmp/
        mv /tmp/crosstool-ng-1.26.0 $CTNG_PATH
        rm -rf /tmp/crosstool-ng-1.26.0 /tmp/crosstool-ng-1.26.0.tar.xz
    fi
    cd "$CTNG_PATH"
    make distclean
    ./bootstrap
    ./configure --enable-local
    make -j "${NUM_JOBS}" -l "${MAX_JOBS}"
fi
export CTNG_BIN
export CTNG_PATH
