#!/bin/bash
#
# Run this script on root of kernel tree. Merged config will be created
# as ".config" file.
#

#
# $1: config fragment file
#
# read config fragment file from $1 and overwrite $1.
#
cleanup_config_fragment ()
{
    # reduce output from merge_config.sh
    ## remove comments
    awk '
    {
        # first, remove starting "# " from the lines including "is not set"
        if (/CONFIG_.* is not set/) gsub("^# ","",$0)
        # then, remove all the lines starting with "#"
        gsub("#.*","",$0)
        # adding back "#" to lines end with "is not set"
        if (/CONFIG_.* is not set/) gsub("^CONFIG_","# CONFIG_",$0)
        # # delete both leading and trailing whitespaces from each line
        gsub(/^[ \t]+|[ \t]+$/, "")
        print
    }' $1 | \
    ## remove dups
    ### using "-o" and overwriting the original file
    sort -u -o $1
}



# arch-lts419 kernel config
wget "https://aur.archlinux.org/cgit/aur.git/plain/config?h=linux-lts419" \
     -q --show-progress -O config_archlinux-lts419

# linux-surface-lts419 kernel config fragment
wget https://raw.githubusercontent.com/linux-surface/linux-surface/master/configs/surface-4.19.config \
     -q --show-progress -O config_surface-lts419-fragment
cleanup_config_fragment config_surface-lts419-fragment

# generate chromeos-intel-pineview fragment
chromeos/scripts/prepareconfig chromeos-intel-pineview
mv .config config_chromeos-intel-pineview-prepareconfig

# my config changes. you can also place your changes here if you want.
cat << EOS > config_mychanges-fragment
# set a distinguishable kernel name
CONFIG_LOCALVERSION="-general-surface-k5"

#
# uapi version of ipts driver
# This config may not exist on surface config yet. So, add it.
#
# Note: depending on what ipts version is included on kernel tree, this
# config may not exist. In that case, CONFIG_TOUCHSCREEN_IPTS (singletouch
# version) or CONFIG_INTEL_IPTS (guc_submission version) will be used,
# which are defined in surface config.
#
CONFIG_MISC_IPTS=m

# acpi_call config that I added
CONFIG_5525_ACPI_CALL=m

# to reduce kernel size
# CONFIG_DEBUG_INFO is not set

# to debug ASPM things
CONFIG_PCIEASPM_DEBUG=y

# I may do something with overlayfs later...
CONFIG_OVERLAY_FS=y

# for debugging Surface 3 touchscreen input
CONFIG_SPI_PXA2XX=m
CONFIG_SPI_PXA2XX_PCI=m

# for further issue debugging, do not reboot automatically on kernel
# panic and oops
# CONFIG_PANIC_ON_OOPS is not set
CONFIG_PANIC_TIMEOUT=0

# Currently, LoadPin module doesn't support compressed modules.
# And compressing modules leads to unbootable kernel.
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/3
# CONFIG_MODULE_COMPRESS is not set

# for backlight controlling on Surface 3, need to be built as module
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/8
# build DRM_I915 as module, also because it uses firmware files
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/21
CONFIG_DRM_I915=m

# TPM (m if you want to use vTPM)
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/9
CONFIG_TCG_TPM=m
CONFIG_TCG_TIS_CORE=m
CONFIG_TCG_TIS=m
CONFIG_TCG_TIS_SPI=m
CONFIG_TCG_VTPM_PROXY=m
CONFIG_TCG_CRB=m
CONFIG_TCG_VIRTIO_VTPM=m
#
# it seems that, at least on v4.19-minimal config, TCG_CR50 stuff can't
# be built as module (?) compiler gives the following errors:
#     ERROR: "cr50_suspend" [drivers/char/tpm/cr50_spi.ko] undefined!
#     ERROR: "cr50_resume" [drivers/char/tpm/cr50_spi.ko] undefined!
#     ERROR: "cr50_resume" [drivers/char/tpm/cr50_i2c.ko] undefined!
#     ERROR: "cr50_suspend" [drivers/char/tpm/cr50_i2c.ko] undefined!
# for now, just unset them.
#
# CONFIG_TCG_CR50_I2C is not set
# CONFIG_TCG_CR50_SPI is not set

# built-in storage related config
CONFIG_MMC_BLOCK=y

# Enable kernel headers through /sys/kernel/kheaders.tar.xz
# CONFIG_IKHEADERS=m

# https://github.com/systemd/systemd/blob/master/README
CONFIG_EFIVAR_FS=y

# to match stock chromiumos config
CONFIG_KERNEL_GZIP=y
# CONFIG_KERNEL_XZ is not set

# resolve "Actual value" not changing to "Requested value"
# caused by "NETFILTER_XT_MATCH_OWNER is not set"
# not specified in chromeos-intel-pineview prepareconfig
# (arc continuously crashing without this change at least on 4.19)
# CONFIG_NETFILTER_XT_MATCH_OWNER is not set
CONFIG_NETFILTER_XT_MATCH_QTAGUID=y

#
# Intel PMC development
#
CONFIG_INTEL_PMC_CORE=m
CONFIG_PMC_ATOM=m

#
# enable acpidbg
#
CONFIG_ACPI_DEBUGGER=y
CONFIG_ACPI_DEBUGGER_USER=m

# v4.19 specific

# security options
# init: Unable to mount /sys/fs/selinux filesystem: No such file or directory
# then kernel panic (and reboot)
CONFIG_SECURITY_SELINUX_BOOTPARAM_VALUE=1
CONFIG_DEFAULT_SECURITY_SELINUX=y
# CONFIG_DEFAULT_SECURITY_DAC is not set
CONFIG_DEFAULT_SECURITY="selinux"

# enable imgu config here because I personally backported the driver,
## not available upstream.
CONFIG_VIDEO_IPU3_IMGU=m

EOS
cleanup_config_fragment config_mychanges-fragment

# memo
cat << EOS
# useful when you have to reload modules?
CONFIG_I2C_HID=m

EOS



# merge configs
# TODO: how to speed up?
## a lot of output for the first time. So, using `> /dev/null`
scripts/kconfig/merge_config.sh \
    config_archlinux-lts419 \
    config_chromeos-intel-pineview-prepareconfig \
    config_surface-lts419-fragment \
    config_mychanges-fragment \
    > /dev/null

## second time, check the generated config. So, not using `> /dev/null` here.
## you may be interested in "Requested value" vs "Actual value".
scripts/kconfig/merge_config.sh \
    .config \
    config_chromeos-intel-pineview-prepareconfig \
    config_surface-lts419-fragment \
    config_mychanges-fragment \

# clean up
rm config_archlinux-lts419
rm config_chromeos-intel-pineview-prepareconfig
rm config_surface-lts419-fragment
rm config_mychanges-fragment
