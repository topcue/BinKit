import re
import os
import sys
from packaging import version

TOOL_PATH = os.getenv('TOOL_PATH')
if not TOOL_PATH:
    print("env $TOOL_PATH should be defined first.")
    print("source scripts/env.sh")
    exit(1)

# setup crosstool-ng
CTNG_PATH = os.path.join(TOOL_PATH, "crosstool-ng")
CTNG_BIN = os.path.join(CTNG_PATH, "ct-ng")
CTNG_CONF = ".config"
CTNG_CONF_OUTPUT = os.path.join(CTNG_PATH, "output")

# architectures supported by ct-ng
CT_CONF = dict()
CT_CONF["arm_32"] = "arm-unknown-linux-gnueabi"
CT_CONF["arm_64"] = "aarch64-unknown-linux-gnu"
CT_CONF["x86_32"] = ""
CT_CONF["x86_64"] = "x86_64-unknown-linux-gnu"
CT_CONF["mips_32"] = "mipsel-unknown-linux-gnu"   # (MIPS 32-bit LE)
CT_CONF["mips_64"] = ""                           # (MIPS 64-bit LE)
CT_CONF["mipseb_32"] = "mips-unknown-linux-gnu"   # (MIPS 32-bit BE)
CT_CONF["mipseb_64"] = "mips64-unknown-linux-gnu" # (MIPS 64-bit BE)

def select_config(arch, config_file=CTNG_CONF):
    os.system(f"{CTNG_BIN} {arch}")

def patch_line(search_line, replace_line, conf_file=CTNG_CONF):
    with open(conf_file, 'r') as file:
        content = file.read()

    content = content.replace(search_line, replace_line)

    with open(conf_file, 'w') as file:
        file.write(content)

def patch_line_with_prefix(prefix, replace_line, match_new_line=False, conf_file=".config"):
    with open(conf_file, 'r') as file:
        content = file.read()

    if match_new_line:
        pattern = rf"^{re.escape(prefix)}.*\n"
    else:
        pattern = rf"^{re.escape(prefix)}.*"
    modified_content = re.sub(pattern, replace_line, content, flags=re.MULTILINE)

    with open(conf_file, 'w') as file:
        file.write(modified_content)

def apply_basic_binkit_patch():
    print("[*] Apply my patch file")

    # Set target vendor to ubuntu
    patch_line_with_prefix( 'CT_TARGET_VENDOR=',
                            'CT_TARGET_VENDOR=\"ubuntu\"', False, CTNG_CONF)

    # Set output paths
    patch_line_with_prefix( 'CT_LOCAL_TARBALLS_DIR=',
                            'CT_LOCAL_TARBALLS_DIR=\"${TOOL_PATH}/ctng_tarballs\"', False, CTNG_CONF)
    patch_line_with_prefix( 'CT_PREFIX_DIR=',
                            'CT_PREFIX_DIR="${CT_PREFIX:-${TOOL_PATH}}/${CT_HOST:+HOST-${CT_HOST}/}${CT_TARGET}-${CT_GCC_VERSION}"', False, CTNG_CONF)

    # Set log level to error
    patch_line( '# CT_LOG_ERROR is not set', \
                'CT_LOG_ERROR=y', CTNG_CONF)
    patch_line( 'CT_LOG_EXTRA=y', \
                '# CT_LOG_EXTRA is not set', CTNG_CONF)
    patch_line( 'CT_LOG_LEVEL_MAX="EXTRA"', \
                'CT_LOG_LEVEL_MAX="ERROR"', CTNG_CONF)

    # Do not use multilib
    patch_line( 'CT_MULTILIB=y', \
                '# CT_MULTILIB is not set', CTNG_CONF)
    patch_line_with_prefix( 'CT_CC_GCC_MULTILIB_LIST=',\
                            'CT_DEMULTILIB=y', False, CTNG_CONF)

    # Unset debug
    patch_line( 'CT_DEBUG_CT=y', \
                '# CT_DEBUG_CT is not set', CTNG_CONF)
    patch_line( 'CT_DEBUG_CT_SAVE_STEPS=y', \
                '# CT_DEBUG_CT_SAVE_STEPS is not set', CTNG_CONF)
    patch_line( 'CT_DEBUG_CT_SAVE_STEPS_GZIP=y', \
                '# CT_DEBUG_CT_SAVE_STEPS_GZIP is not set', CTNG_CONF)

    # Unset static compile
    patch_line( 'CT_STATIC_TOOLCHAIN=y', \
                '# CT_STATIC_TOOLCHAIN is not set', CTNG_CONF)

def patch_bits_64_to_32(conf_file=".config"):
    patch_line( "CT_ARCH_BITNESS=64", \
                "CT_ARCH_BITNESS=32")
    patch_line( "# CT_ARCH_32 is not set", \
                "CT_ARCH_32=y")
    patch_line( "CT_ARCH_64=y", \
                "# CT_ARCH_64 is not set")

def set_arch_for_x86_32(conf_file=".config"):
    patch_line( 'CT_ARCH_ARCH=\"\"', \
                'CT_ARCH_ARCH=\"i686\"')

def set_arch_for_mips_32(conf_file=".config"):
    patch_line( 'CT_ARCH_ARCH=\"mips1\"', \
                'CT_ARCH_ARCH=\"\"')

def patch_float_mode_soft_to_auto(conf_file=".config"):
    patch_line( '# CT_ARCH_FLOAT_AUTO is not set', \
                'CT_ARCH_FLOAT_AUTO=y')
    patch_line( 'CT_ARCH_FLOAT_SW=y', \
                '# CT_ARCH_FLOAT_SW is not set')
    patch_line( 'CT_ARCH_FLOAT=\"soft\"', \
                'CT_ARCH_FLOAT=\"auto\"')

def patch_float_mode_hard_to_auto(conf_file=".config"):
    patch_line( '# CT_ARCH_FLOAT_AUTO is not set', \
                'CT_ARCH_FLOAT_AUTO=y')
    patch_line( 'CT_ARCH_FLOAT_HW=y', \
                '# CT_ARCH_FLOAT_HW is not set')
    patch_line( 'CT_ARCH_FLOAT=\"hard\"', \
                'CT_ARCH_FLOAT=\"auto\"')

def patch_endian_be_to_le(conf_file=".config"):
    patch_line( 'CT_ARCH_BE=y', \
                '# CT_ARCH_BE is not set')
    patch_line( '# CT_ARCH_LE is not set', \
                'CT_ARCH_LE=y')
    patch_line( 'CT_ARCH_ENDIAN=\"big\"', \
                'CT_ARCH_ENDIAN=\"little\"')

def disable_mathvec(conf_file=".config"):
    patch_line( 'CT_GLIBC_EXTRA_CONFIG_ARRAY=\"\"', \
                'CT_GLIBC_EXTRA_CONFIG_ARRAY=\"--disable-mathvec\"')

def is_version_lower_than(target_version_str, conf_file=".config"):
    target_version = version.parse(target_version_str)

    with open(conf_file, 'r') as file:
        for line in file:
            if line.startswith("CT_GCC_VERSION="):
                gcc_version_str = line.split("=")[1].strip().strip('"')
                gcc_version = version.parse(gcc_version_str)

                return gcc_version < target_version

    print(f"[-] Error: The config file version cannot be determined.", file=sys.stderr)
    exit(1)

def generate_ctng_config(arch, conf_output_path=CTNG_CONF_OUTPUT):
    # Generating architecture-specific basic config files with ct-ng
    # Since ct-ng provides x86_32 only up to Ubuntu 16.04, apply patches based on x86_64
    if arch == "x86_32":
        select_config(CT_CONF["x86_64"], CTNG_CONF)
    # Since ct-ng does not provide MIPS 64-bit (LE), apply patches based on MIPS 64-bit (BE)
    elif arch == "mips_64":
        select_config(CT_CONF["mipseb_64"], CTNG_CONF)
    else:
        select_config(CT_CONF[arch], CTNG_CONF)

    # Select GCC's version or debug tools
    os.system(f"{CTNG_BIN} menuconfig")

    apply_basic_binkit_patch()

    # Apply patches based on architecture or version
    if arch == "arm_64" and is_version_lower_than("10.1.0", CTNG_CONF):
        disable_mathvec(CTNG_CONF)
    elif arch == "x86_32":
        patch_bits_64_to_32(CTNG_CONF)
        set_arch_for_x86_32(CTNG_CONF)
    elif arch in (("mips_32", "mipseb_32")):
        patch_float_mode_soft_to_auto(CTNG_CONF)
        set_arch_for_mips_32(CTNG_CONF)
    elif arch == "mips_64":
        patch_float_mode_hard_to_auto(CTNG_CONF)
        patch_endian_be_to_le(CTNG_CONF)
    elif arch == "mipseb_64":
        patch_float_mode_hard_to_auto(CTNG_CONF)

    # Final config file location: BinKit/tools/crosstool-ng/output
    os.system(f"mv {CTNG_CONF} {CTNG_CONF_OUTPUT}/{arch}.conf")

if __name__ == "__main__":
    # Make output directory
    os.system(f"mkdir -p {CTNG_CONF_OUTPUT}")

    arch_list = ["arm_32", "arm_64", "x86_32", "x86_64", "mips_32", "mips_64", "mipseb_32", "mipseb_64"]
    # Generate ct-ng config files
    for arch in arch_list:
        generate_ctng_config(arch, CTNG_CONF_OUTPUT)

# EOF
