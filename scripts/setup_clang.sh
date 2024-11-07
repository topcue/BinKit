#!/bin/bash -eu
if [ -z "$TOOL_PATH" ]; then
    echo "env \$TOOL_PATH should be defined first."
    echo "source scripts/env.sh"
    exit
fi

declare -a VERSIONS=(
    # Below versions are used in the paper.
    # "4.0.0"
    # "5.0.0"
    # "6.0.0"
    # "7.0.0"
    # "8.0.0"
    # "9.0.0"

    4.0.1
    5.0.2
    6.0.1
    7.1.0
    8.0.1
    9.0.1
    10.0.1
    11.1.0
    12.0.1
    13.0.1
    14.0.6
    15.0.7
    16.0.6
    17.0.6
    18.1.8
    19.1.3
)

CLANG_ROOT="$TOOL_PATH/clang"
LLVM_PROJECT_ROOT="$TOOL_PATH/llvm-project"
LOG_PATH="$CLANG_ROOT/logs"
PATCH_CLANG="$PROJ_ROOT/patches/setup_clang"

mkdir -p "$CLANG_ROOT"
mkdir -p "$LOG_PATH"

if [ ! -d "$LLVM_PROJECT_ROOT" ] || [ -z "$(ls -A "$LLVM_PROJECT_ROOT" 2>/dev/null)" ]; then
    echo "Cloning llvm-project..."
    git clone https://github.com/llvm/llvm-project.git $LLVM_PROJECT_ROOT
fi

apply_patch() {
    local PATCH_FILE="$1"

    cd $LLVM_PROJECT_ROOT
    if git apply --check "$PATCH_FILE" 2>/dev/null; then
        echo "[+] Applying patch"
        git apply "$PATCH_FILE"
    else
        echo "[*] Already patched"
    fi
    cd build
}

for VER in "${VERSIONS[@]}"; do
    echo "Setting clang-${VER} =========="
    GIT_TAG="llvmorg-"${VER}
    CLANG_PATH=$CLANG_ROOT/clang-${VER}

    GIT_CHECKOUT="cd $LLVM_PROJECT_ROOT && git reset --hard && git clean -fd && git checkout ${GIT_TAG}"
    CLEAN_UP_BUILD_DIR="rm -rf $LLVM_PROJECT_ROOT/build && mkdir -p build && cd build"
    CMAKE_CMD="cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${CLANG_PATH} -G \"Unix Makefiles\" ../llvm"
    MAKE="make -j ${NUM_JOBS}"
    MAKE_INSTALL="make install"

    eval $GIT_CHECKOUT
    eval $CLEAN_UP_BUILD_DIR

    #! setup_clang_bug1.patch
    case "$VER" in
        "4.0.1"|"5.0.2"|"8.0.1"|"9.0.1"|"10.0.1"|"11.1.0")
            PATCH_FILE="$PATCH_CLANG/clang-${VER}.patch"
            apply_patch $PATCH_FILE
    esac

    eval $CMAKE_CMD    > >(tee $LOG_PATH/clang-${VER}_config.log)  2> >(tee $LOG_PATH/clang-${VER}_config.error >&2)
    eval $MAKE         > >(tee $LOG_PATH/clang-${VER}_make.log)    2> >(tee $LOG_PATH/clang-${VER}_make.error >&2)
    eval $MAKE_INSTALL > >(tee $LOG_PATH/clang-${VER}_install.log) 2> >(tee $LOG_PATH/clang-${VER}_install.error >&2)

    cd $LLVM_PROJECT_ROOT
    git reset --hard
    git clean -fd

done
