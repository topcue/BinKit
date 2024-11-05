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

    # "4.0.0"
    # "5.0.2"
    # "6.0.1"
    # "7.0.1"
    # "8.0.0"
    # "9.0.1"
    # "10.0.1"
    # "11.0.1"
    # "12.0.1"
    # "13.0.0"

    # llvm versions from git tags (e.g. llvmorg-13.0.1)
    # 4.0.1
    # 5.0.2
    # 6.0.1
    # 7.1.0
    # 8.0.1
    # 9.0.1
    # 10.0.1
    # 11.1.0
    # 12.0.1
    # 13.0.1
    14.0.6
    # 15.0.7
    # 16.0.6
    # 17.0.6
    # 18.1.8
    # 19.1.3
)

CLANG_ROOT="$TOOL_PATH/clang"
LLVM_PROJECT_ROOT="$TOOL_PATH/llvm-project"
LOG_PATH="$CLANG_ROOT/logs"

mkdir -p "$CLANG_ROOT"
mkdir -p $LOG_PATH

if [ ! -d "$LLVM_PROJECT_ROOT" ] || [ -z "$(ls -A "$LLVM_PROJECT_ROOT" 2>/dev/null)" ]; then
    echo "Cloning llvm-project..."
    git clone https://github.com/llvm/llvm-project.git $LLVM_PROJECT_ROOT
fi

for VER in "${VERSIONS[@]}"; do
    echo "Setting clang-${VER} =========="
    GIT_TAG="llvmorg-"${VER}
    CLANG_PATH=$CLANG_ROOT/clang-${VER}


    GIT_CHECKOUT="cd $LLVM_PROJECT_ROOT && git checkout ${GIT_TAG}"
    CLEAN_UP_BUILD_DIR="rm -rf $LLVM_PROJECT_ROOT/build && mkdir -p build && cd build"
    CMAKE_CMD="cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${CLANG_PATH} -G \"Unix Makefiles\" ../llvm"
    MAKE="make -j ${NUM_JOBS}"
    MAKE_INSTALL="make install"

    eval $GIT_CHECKOUT
    eval $CLEAN_UP_BUILD_DIR
    eval $CMAKE_CMD # > $LOG_PATH/clang-${VER}_config.log 2> $LOG_PATH/clang-${VER}_config.error
    eval $MAKE # > $LOG_PATH/clang-${VER}_make.log 2> $LOG_PATH/clang-${VER}_make.error
    eval $MAKE_INSTALL # > $LOG_PATH/clang-${VER}_install.log 2> $LOG_PATH/clang-${VER}_install.error


    # CLANG_URL="http://releases.llvm.org/${VER}/clang+llvm-${VER}-"
    # CLANG_TAR="${CLANG_ROOT}/clang-${VER}.tar.xz"
    # CLANG_PATH="${CLANG_ROOT}/clang-${VER%.*}"
    # if [[ "${VER%%\.*}" -gt 8 ]]; then
	# CLANG_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${VER}/clang+llvm-${VER}-"
    # fi

    # if [[ ! -d "$CLANG_PATH" ]]; then
    #     # If the compilation fails, check if the href contains a correct SYSNAME.
    #     # For example, the link of 5.0.0 or 5.0.1 contains a SYSNAME,
    #     # "linux-x86_64-ubuntu16.04" instead of "x86_64-linux-gnu-ubuntu-16.04".
    #     if [[ ! -f "$CLANG_TAR" ]]; then
    #         wget "${CLANG_URL}${SYSNAME}.tar.xz" -O "$CLANG_TAR"
    #     fi

    #     CLANG_VER_DIR=$(tar tf ${CLANG_TAR} | head -n 1)
    #     tar xf "${CLANG_TAR}"
    #     mv "$CLANG_VER_DIR" "$CLANG_PATH"
    # fi
done
