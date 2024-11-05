import os
import re
import string, random

from subprocess import Popen, PIPE


RE_PATTERN = (
    "(.*)_"
    + "(gcc-[.0-9]+|clang-[.0-9]+|"
    + "clang-obfus-[-a-z2]+|"
    + "gcc|clang)_"
    + "((?:x86|arm|mips|mipseb|ppc)_(?:32|64))_"
    + "(O0|O1|O2|O3|Os|Ofast)_"
    + "(.*)"
)
RESTR = re.compile(RE_PATTERN)


def system(cmd):
    proc = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
    o = proc.communicate()[0].decode().strip()
    return o


def randstr(length):
    return "".join(random.choice(string.ascii_lowercase) for i in range(length))


def gettmpdir():
    tmpdir = os.path.join("/tmp", "parsfi_tmp", randstr(10))
    while os.path.exists(tmpdir):
        tmpdir = os.path.join("/tmp", "parsfi_tmp", randstr(10))
    os.makedirs(tmpdir)
    return tmpdir


def get_file_type(fname, use_str=False):
    BITS_32 = "ELF 32-bit"
    BITS_64 = "ELF 64-bit"
    ARCH_X86_32 = "Intel 80386"
    ARCH_X86_64 = "x86-64"
    ARCH_ARM = "ARM"
    ARCH_MIPS = "MIPS"
    ENDIAN_LSB = "LSB"
    ENDIAN_MSB = "MSB"

    if use_str:
        s = fname
    else:
        # TODO: detect file type by parsing ELF file structure
        fname = os.path.realpath(fname)
        s = system('file "{0}"'.format(fname))

    if BITS_32 in s:
        bits = "32"
    elif BITS_64 in s:
        bits = "64"
    else:
        raise NotImplemented

    if ARCH_X86_32 in s or ARCH_X86_64 in s:
        arch = "x86"
    elif ARCH_ARM in s:
        arch = "arm"
    elif ARCH_MIPS in s:
        arch = "mips"
    else:
        raise NotImplemented

    if ENDIAN_LSB in s:
        endian = ""
    elif ENDIAN_MSB in s:
        endian = "eb"
    else:
        raise NotImplemented

    return "{0}{1}_{2}".format(arch, endian, bits)


def get_dirs(base_dir, suffix=""):
    src_dir = os.path.join(base_dir, "sources")
    out_dir = os.path.join(base_dir, "output" + suffix)
    log_dir = os.path.join(base_dir, "logs" + suffix)

    return src_dir, out_dir, log_dir
