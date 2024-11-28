#!/bin/bash

if [ -z "$EXTRA_DEP_PATH" ]; then
    EXTRA_DEP_PATH="$TOOL_PATH/extra_dep"
    export EXTRA_DEP_PATH
fi

mkdir -p $EXTRA_DEP_PATH
mkdir -p $EXTRA_DEP_PATH/sources

CONFIGSUB=$(<$PROJ_ROOT/patches/config.sub)

function download_if_not_exists() {
    local URL=$1
    local FILE_NAME=$(basename "$URL")

    if [ -f "$FILE_NAME" ]; then
        echo "[DEBUG] File '$FILE_NAME' already exists."
    else
        echo "[DEBUG] File '$FILE_NAME' not found. Downloading..."
        wget "$URL" -O "$FILE_NAME"
    fi
}

function get_root_dir_name_from_tar() {
    local TAR_FILE_NAME=$1
    DIR_NAME=$(tar -tf "$TAR_FILE_NAME" | head -n1)
    echo $DIR_NAME
}


function cleanup_and_unzip() {
    local TAR_FILE_NAME=$1
    DIR_NAME=$(get_root_dir_name_from_tar $TAR_FILE_NAME)
    rm -rf $DIR_NAME
    tar -xf $TAR_FILE_NAME
}

function gen_conf() {
    local PKG_NAME=$1
    local ARCH=$2

    subfile=`find . -name "config.sub" 2>/dev/null`
    mapfile -t subfiles <<< "${subfile}"
    for sub in "${subfiles[@]}"; do
        if [[ -f "${sub}" ]]; then
            chmod 755 ${sub}
            echo "${CONFIGSUB}" > ${sub}
        fi
    done

    ARCH_X86="i686-ubuntu-linux-gnu"
    ARCH_X8664="x86_64-ubuntu-linux-gnu"
    ARCH_ARM="arm-ubuntu-linux-gnueabi"
    ARCH_ARM64="aarch64-ubuntu-linux-gnu"
    ARCH_MIPS="mipsel-ubuntu-linux-gnu"
    ARCH_MIPS64="mips64el-ubuntu-linux-gnu"
    ARCH_MIPSEB="mips-ubuntu-linux-gnu"
    ARCH_MIPSEB64="mips64-ubuntu-linux-gnu"

    local OPTIONS=""


    COMPILER="gcc-13.2.0"
    COMPVER=${COMPILER#"gcc-"}

    if [[ $ARCH =~ "eb_" ]]; then
        OPTIONS="${OPTIONS} -EB"
    fi

    # ========= x86 =============
    if [ $ARCH == "x86_32" ]; then
        ARCH_PREFIX=$ARCH_X86
        OPTIONS="${OPTIONS} -m32"
        ELFTYPE="ELF 32-bit LSB"
        ARCHTYPE="Intel 80386"

    elif [ $ARCH == "x86_64" ]; then
        ARCH_PREFIX=$ARCH_X8664
        ELFTYPE="ELF 64-bit LSB"
        ARCHTYPE="x86-64"

        # ========= arm =============
    elif [ $ARCH == "arm_32" ]; then
        ARCH_PREFIX=$ARCH_ARM
        ELFTYPE="ELF 32-bit LSB"
        ARCHTYPE="ARM, EABI5"

    elif [ $ARCH == "arm_64" ]; then
        ARCH_PREFIX=$ARCH_ARM64
        ELFTYPE="ELF 64-bit LSB"
        ARCHTYPE="ARM aarch64"

        # ========= mips =============
    elif [ $ARCH == "mips_32" ]; then
        ARCH_PREFIX=$ARCH_MIPS
        OPTIONS="${OPTIONS} -mips32r2"
        ELFTYPE="ELF 32-bit LSB"
        #ARCHTYPE="MIPS, MIPS32 rel2"
        ARCHTYPE="MIPS, MIPS32"

    elif [ $ARCH == "mips_64" ]; then
        ARCH_PREFIX=$ARCH_MIPS64
        OPTIONS="${OPTIONS} -mips64r2"
        ELFTYPE="ELF 64-bit LSB"
        #ARCHTYPE="MIPS, MIPS64 rel2"
        ARCHTYPE="MIPS, MIPS64"

        # ========= mipseb =============
    elif [ $ARCH == "mipseb_32" ]; then
        ARCH_PREFIX=$ARCH_MIPSEB
        OPTIONS="${OPTIONS} -mips32r2"
        ELFTYPE="ELF 32-bit MSB"
        #ARCHTYPE="MIPS, MIPS32 rel2"
        ARCHTYPE="MIPS, MIPS32"

    elif [ $ARCH == "mipseb_64" ]; then
        ARCH_PREFIX=$ARCH_MIPSEB64
        OPTIONS="${OPTIONS} -mips64r2"
        ELFTYPE="ELF 64-bit MSB"
        #ARCHTYPE="MIPS, MIPS64 rel2"
        ARCHTYPE="MIPS, MIPS64"
    fi

    TMP_PATH="${TOOL_PATH}/${ARCH_PREFIX}-${COMPVER}/bin:${PATH}"
    LIB_PATH="${TOOL_PATH}/${ARCH_PREFIX}-${COMPVER}/${ARCH_PREFIX}/lib"
    SYSROOT="${TOOL_PATH}/${ARCH_PREFIX}-${COMPVER}/${ARCH_PREFIX}/sysroot"
    SYSTEM="${TOOL_PATH}/${ARCH_PREFIX}-${COMPVER}/${ARCH_PREFIX}/sysroot/usr/include"

    ##! TODO: Fix me (path)
    EXTRA_LDFLAGS=""
    if [[ $PKG_NAME =~ "libpng" ]]; then
        OPTIONS="${OPTIONS} -L${LIB_PATH} -lc -I${EXTRA_DEP_PATH}/${ARCH}/zlib/include"
        EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L${$EXTRA_DEP_PATH}/${ARCH}/zlib/lib"
    elif [[ $PKG_NAME == "libxmi" ]]; then
        OPTIONS="${OPTIONS} -L${LIB_PATH} -lc"
    elif [[ $PKG_NAME == "libacl" ]]; then
        OPTIONS="${OPTIONS} -L${LIB_PATH} -lc -I${EXTRA_DEP_PATH}/${ARCH}/attr/include"
        EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L${EXTRA_DEP_PATH}/${ARCH}/attr/lib"
    elif [[ $PKG_NAME == "libgc" ]]; then
        LIBATOMIC_PATH="${EXTRA_DEP_PATH}/${ARCH}/libatomic"
        EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L${LIBATOMIC_PATH}/lib"
        OPTIONS="${OPTIONS} -L${LIB_PATH} -I${LIBATOMIC_PATH}/include"
    else
        OPTIONS="${OPTIONS} -L${LIB_PATH}"
    fi

    #! GCC config from do_compile_utils.sh
    CMD=""
    CMD="--host=\"${ARCH_PREFIX}\""
    CMD="${CMD} CFLAGS=\""
    CMD="${CMD} -isysroot ${SYSROOT} -isystem ${SYSTEM} -I${SYSTEM}"
    CMD="${CMD} ${OPTIONS}\""
    CMD="${CMD} LDFLAGS=\"${OPTIONS} ${EXTRA_LDFLAGS}\""
    CMD="${CMD} AR=\"${ARCH_PREFIX}-gcc-ar\""
    CMD="${CMD} RANLIB=\"${ARCH_PREFIX}-gcc-ranlib\""
    CMD="${CMD} NM=\"${ARCH_PREFIX}-gcc-nm\""
    CMD="${CMD} LIBS=\"-lc\""

    if [[ $PKG_NAME =~ "libpng" ]]; then
        CMD="${CMD} CPPFLAGS=-I/home/user/BinKit/tools/extra_dep/x86_64/zlib/include"
    fi
}

function install_pkg() {
    PKG_NAME=$1
    ARCH=$2
    URL=$3
    PREFIX="$EXTRA_DEP_PATH/${ARCH}/${PKG_NAME}"
    rm -rf $PREFIX
    mkdir -p $PREFIX

    cd $EXTRA_DEP_PATH/sources

    #! download
    download_if_not_exists $URL

    TAR_FILE_NAME=$(basename "$URL")
    DIR_NAME=$(get_root_dir_name_from_tar $TAR_FILE_NAME)
    echo "[DEBUG] TAR_FILE_NAME: $TAR_FILE_NAME"
    echo "[DEBUG] DIR_NAME: $DIR_NAME"

    #! unzip
    cleanup_and_unzip $TAR_FILE_NAME
    cd $DIR_NAME
    
    #! configure and make
    gen_conf $PKG_NAME $ARCH
    if [[ $PKG_NAME == "zlib" ]]; then
        CONF="./configure --prefix=\"${PREFIX}\""
    elif [[ $PKG_NAME =~ "libpng" ]]; then
        CONF="./configure --prefix=\"${PREFIX}\" --build=x86_64-linux-gnu ${CMD} --with-zlib-prefix=${EXTRA_DEP_PATH}/x86_64/zlib/lib"
    else
        CONF="./configure --prefix=\"${PREFIX}\" --build=x86_64-linux-gnu ${CMD}"
    fi

    echo "[DEBUG] CONF: $CONF"
    echo "[DEBUG] PATH: $PATH"
    echo "[DEBUG] TMP_PATH: $TMP_PATH"

    local original_path="$PATH"
    export PATH=$TMP_PATH
    echo "[DEBUG] PATH: $PATH"

    # CONF="${CONF} 1>/dev/null"
    # MAKE="make -j ${NUM_JOBS} 1>/dev/null"
    # INSTALL="make install 1>/dev/null"

    CONF="${CONF}"
    MAKE="make -j ${NUM_JOBS}"
    INSTALL="make install"

    eval $CONF
    # exit 0
    eval $MAKE
    eval $INSTALL
    # make check
    #! cleanup
    cd ..
    rm -rf $DIR_NAME

    #! revert PATH
    export PATH="$original_path"
    echo "[DEBUG] Restored PATH: $PATH"
}

URL_GMP="https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz"
URL_LIBPNG="https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.44.tar.gz"
URL_LIBPNG_12="https://github.com/pnggroup/libpng/archive/refs/tags/v1.2.59.tar.gz"
URL_LIBPNG_14="https://github.com/pnggroup/libpng/archive/refs/tags/v1.4.22.tar.gz"
URL_LIBPNG_15="https://github.com/pnggroup/libpng/archive/refs/tags/v1.5.30.tar.gz"
URL_ZLIB="https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz"
URL_LIBXMI="https://ftp.gnu.org/gnu/libxmi/libxmi-1.2.tar.gz"

URL_LIBUUID="https://sourceforge.net/projects/libuuid/files/libuuid-1.0.3.tar.gz/download"

# install_pkg "gmp" "x86_32" $URL_GMP
# install_pkg "gmp" "x86_64" $URL_GMP
# install_pkg "gmp" "arm_32" $URL_GMP
# install_pkg "gmp" "arm_64" $URL_GMP
# install_pkg "gmp" "mips_32" $URL_GMP
# install_pkg "gmp" "mips_64" $URL_GMP
# install_pkg "gmp" "mipseb_32" $URL_GMP
# install_pkg "gmp" "mipseb_64" $URL_GMP

# install_pkg "zlib" "x86_64" $URL_ZLIB

# install_pkg "libpng" "x86_64" $URL_LIBPNG

# install_pkg "libxmi" "x86_64" $URL_LIBXMI


# architectures=("x86_32" "x86_64" "arm_32" "arm_64" "mips_32" "mips_64" "mipseb_32" "mipseb_64")
# for ARCH in "${architectures[@]}"; do
#     install_pkg "libuuid" "$ARCH" $URL_LIBUUID
# done

# URL_ATTR="http://repo.jing.rocks/nongnu/attr/attr-2.5.2.tar.gz"
# install_pkg "attr" "x86_64" $URL_ATTR

# URL_LIBACL="https://download.savannah.nongnu.org/releases/acl/acl-2.3.2.tar.gz"
# install_pkg "libacl" "x86_64" $URL_LIBACL

# URL_LIBPAPER="https://github.com/rrthomas/libpaper/releases/download/v2.2.5/libpaper-2.2.5.tar.gz"
# architectures=("x86_32" "x86_64" "arm_32" "arm_64" "mips_32" "mips_64" "mipseb_32" "mipseb_64")
# for ARCH in "${architectures[@]}"; do
#     install_pkg "libpaper" "$ARCH" $URL_LIBPAPER
# done

# URL_LIBATOMIC="https://github.com/ivmai/libatomic_ops/releases/download/v7.8.2/libatomic_ops-7.8.2.tar.gz"
# architectures=("x86_32" "x86_64" "arm_32" "arm_64" "mips_32" "mips_64" "mipseb_32" "mipseb_64")
# for ARCH in "${architectures[@]}"; do
#     install_pkg "libatomic" "$ARCH" $URL_LIBATOMIC
# done

# URL_LIBGC="https://github.com/ivmai/bdwgc/releases/download/v8.2.8/gc-8.2.8.tar.gz"
# architectures=("x86_32" "x86_64" "arm_32" "arm_64" "mips_32" "mips_64" "mipseb_32" "mipseb_64")
# for ARCH in "${architectures[@]}"; do
#     install_pkg "libgc" "$ARCH" $URL_LIBGC
# done


# EOF
