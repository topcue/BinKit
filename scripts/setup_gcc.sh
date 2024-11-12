#!/bin/bash
if [ -z "$CTNG_BIN" ]; then
    echo "env \$CTNG_BIN should be defined first."
    echo "source scripts/env.sh"
    exit
fi

tmp_list=$(find "$CTNG_CONF_PATH" -mindepth 1 -maxdepth 1 -type d)
mapfile -t VERSION_LIST <<< "${tmp_list}"

function doit()
{
    local DIRNAME=$1
    cd "$DIRNAME"

    # Build toolchain
    ${CTNG_BIN} -s -j ${NUM_JOBS} -l ${MAX_JOBS} build

    # Cleanup
    rm -rf "$DIRNAME/.build"
}

declare -a cmds
declare -i cmd_idx=0
for VER in "${VERSION_LIST[@]}"; do
    tmp_list=$(find "${VER}" -maxdepth 1 -mindepth 1 -type f -name "*.conf")
    mapfile -t CONF_LIST <<< "${tmp_list}"
    for CONF in "${CONF_LIST[@]}"; do
        DIRNAME=${CONF%.conf}
        mkdir -p "$DIRNAME"
        cp "$CONF" "$DIRNAME/.config"

        cmds[$cmd_idx]="$DIRNAME"
        let cmd_idx++
    done
done

export -f doit
echo "${#cmds[@]} builds to be processed ..."
time parallel -j 32 doit ::: "${cmds[@]}"
