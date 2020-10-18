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



# linux-surface-lts419 kernel config fragment
wget https://raw.githubusercontent.com/linux-surface/linux-surface/master/configs/surface-4.19.config \
     -q --show-progress -O config_surface-lts419-fragment
cleanup_config_fragment config_surface-lts419-fragment

# generate chromeos-intel-pineview fragment
chromeos/scripts/prepareconfig chromeos-intel-pineview
mv .config config_chromeos-intel-pineview-prepareconfig

# When building with cros_sdk, it sets some configs dynamically.
# https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/eclass/cros-kernel2.eclass
# Set some of them here manually.
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/2
## download raw cros-kernel2.eclass file then source the file
source <(curl -s "https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/eclass/cros-kernel2.eclass?format=TEXT" | \
base64 --decode) 2>/dev/null

cat << EOS > config_minimal-surface-419-fragment
# config referenced: Arch Linux aur/linux-lts419 (https://aur.archlinux.org/cgit/aur.git/plain/config?h=linux-lts419&id=5ec5fd684818c2c1fe4f345329f32aa5cce88eaf)

# Surface related kernel configs
# Note_1: add here that is supported upstream; linux-surface specific configs
# is handled by linux-surface config fragment
# Note_2: build as module for debugging
CONFIG_TOUCHSCREEN_SURFACE3_SPI=m
CONFIG_SURFACE3_WMI=m
CONFIG_SURFACE_PRO3_BUTTON=m
CONFIG_SURFACE_3_BUTTON=m
# SURFACE_SAM_SSH dependency:
    CONFIG_SERIAL_8250=y
    CONFIG_SERIAL_8250_DW=y
    CONFIG_SERIAL_DEV_BUS=y
    CONFIG_SERIAL_DEV_CTRL_TTYPORT=y

# Cherry Trail related
# TODO: may contain configs not needed for Surface 3
## items found by searching CHERRY
    CONFIG_PINCTRL_CHERRYVIEW=y
## items found by searching CRYSTAL
    CONFIG_GPIO_CRYSTAL_COVE=y
        # GPIO_CRYSTAL_COVE dependency:
        CONFIG_INTEL_SOC_PMIC=y
## items found by searching CHT
    CONFIG_CHT_WC_PMIC_OPREGION=y
    CONFIG_CHT_DC_TI_PMIC_OPREGION=y
        # CHT_DC_TI_PMIC_OPREGION and CHT_WC_PMIC_OPREGION deps:
        CONFIG_PMIC_OPREGION=y
    CONFIG_I2C_CHT_WC=y
    CONFIG_INTEL_SOC_PMIC_CHTWC=y
    CONFIG_INTEL_SOC_PMIC_CHTDC_TI=y
    # Note: SND may use firmware files, so build as module
    CONFIG_SND_SOC_INTEL_CHT_BSW_RT5672_MACH=m
    CONFIG_SND_SOC_INTEL_CHT_BSW_RT5645_MACH=m # for Surface 3 internal sound
    CONFIG_SND_SOC_INTEL_CHT_BSW_MAX98090_TI_MACH=m
    CONFIG_SND_SOC_INTEL_CHT_BSW_NAU8824_MACH=m
    CONFIG_SND_SOC_INTEL_BYT_CHT_DA7213_MACH=m
    CONFIG_SND_SOC_INTEL_BYT_CHT_ES8316_MACH=m
    # CONFIG_SND_SOC_INTEL_BYT_CHT_NOCODEC_MACH is not set
    CONFIG_INTEL_CHT_INT33FE=y
        # INTEL_CHT_INT33FE dependency:
        CONFIG_REGULATOR=y
        CONFIG_EXTCON=y
        CONFIG_CHARGER_BQ24190=y
        CONFIG_USB_ROLE_SWITCH=y
        CONFIG_USB_ROLES_INTEL_XHCI=y
        CONFIG_TYPEC_MUX_PI3USB30532=y
    CONFIG_INTEL_CHTDC_TI_PWRBTN=y
    CONFIG_EXTCON_INTEL_CHT_WC=y
## items found by searching ATOM
    # CONFIG_MATOM is not set
    CONFIG_SND_SST_ATOM_HIFI2_PLATFORM=m
    CONFIG_SND_SST_ATOM_HIFI2_PLATFORM_PCI=m
    CONFIG_SND_SST_ATOM_HIFI2_PLATFORM_ACPI=m
    CONFIG_SND_SOC_SOF_INTEL_ATOM_HIFI_EP=m
        # SND_SOC_SOF_INTEL_ATOM_HIFI_EP deps:
        CONFIG_SND_SOC_SOF_MERRIFIELD_SUPPORT=y
        CONFIG_SND_SOC_SOF_MERRIFIELD=m
    CONFIG_INTEL_ATOMISP2_PM=y
    CONFIG_PMC_ATOM=y
    CONFIG_PUNIT_ATOM_DEBUG=y

# HDMI sound
CONFIG_HDMI_LPE_AUDIO=y

# internal sound on Surface 3
# Note: SND may use firmware files, so build as module
CONFIG_SND_SOC_INTEL_CHT_BSW_RT5645_MACH=m

# Backlight control on Surface 3
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/8
CONFIG_PWM=y
CONFIG_PWM_LPSS_PLATFORM=y
CONFIG_PWM_CRC=y
CONFIG_INTEL_SOC_PMIC=y
# build DRM_I915 as module, also because it uses firmware files
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/21
CONFIG_DRM_I915=m

# IPTS
# CONFIG_INTEL_MEI=m # (?)
CONFIG_INTEL_MEI_ME=m # (?)

# Surface 3 S0ix
CONFIG_INTEL_MEI_TXE=y
CONFIG_INTEL_ATOMISP2_PM=y
CONFIG_INTEL_INT0002_VGPIO=y # (?)
# According to commit https://chromium.googlesource.com/chromiumos/third_party/kernel/+/b9fd280765020857a93d8f45b76f37f020193cc4
# ("FROMGIT: BACKPORT: platform/x86: intel_pmc_ipc: Convert to MFD"),
# this is related to Intel Broxton and Apollo Lake and not seems to be
# related to CHT, so not enabling.
    # CONFIG_INTEL_PMC_IPC=y # (?)
# according to https://github.com/torvalds/linux/commit/ed852cde25a12ea3b6fcc3afc746f773154d0bc5
# ("ACPI / PMIC: Add byt prefix to Crystal Cove PMIC OpRegion driver"),
# CRC_PMIC_OPREGION is related only to BYT boards
    # CONFIG_CRC_PMIC_OPREGION=y

# SB1 S0ix
CONFIG_VIDEO_IPU3_IMGU=m # need to be as module or embed the firmware to load the firmware
CONFIG_VIDEO_IPU3_CIO2=m # let's build as module if imgu is as module
    # VIDEO_IPU3_IMGU and VIDEO_IPU3_IMGU deps:
    CONFIG_MEDIA_CONTROLLER=y
    CONFIG_VIDEO_V4L2_SUBDEV_API=y
    # The patch to add imgu driver I'm now using is not depend on STAGING_MEDIA=y,
    # but does depend on upstream version. So, adding this config for a good.
        CONFIG_STAGING_MEDIA=y
CONFIG_INTEL_PCH_THERMAL=y

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

# HID sensors
CONFIG_HID_SENSOR_HUB=y
CONFIG_HID_SENSOR_IIO_COMMON=y
CONFIG_HID_SENSOR_ACCEL_3D=y
CONFIG_HID_SENSOR_ALS=y
CONFIG_HID_SENSOR_DEVICE_ROTATION=y
CONFIG_HID_SENSOR_GYRO_3D=y

# Fix ACPI error on Surface 3
# this was needed before but not needed anymore
# CONFIG_SENSORS_CORETEMP=m

# Embedding firmware files
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/21
# If built-in drivers use firmware file, you may need to specify the file here.
# That said, I recommend just building the driver as module... I think it's simpler.
# add required firmware here:
# CONFIG_EXTRA_FIRMWARE =''
# CONFIG_EXTRA_FIRMWARE_DIR ='/lib/firmware'
# CONFIG_EXTRA_FIRMWARE_DIR ='/build/amd64-generic/lib/firmware/' # if you are in cros_sdk

# you may want to reload the following drivers after suspend;
# sometimes those drivers not working after suspend
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/11
CONFIG_I2C_HID=m
CONFIG_USB_HID=m

# load the kernel as an EFI executable
# for secure boot signing
# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/18
CONFIG_EFI_STUB=y

# for brunch initramfs console output
## TODO: may contain unnecessary config
## https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/16
CONFIG_VT=y
CONFIG_FRAMEBUFFER_CONSOLE=y
# actually, those are enabled if not disabling explicitly (e.g. via vtconsole_config_disable)
# keep explicitly enabling to be sure.

# print configs from cros-kernel2.eclass
## maybe needed for ARC, especially VSOCKETS and VHOST
    $kvm_host_config
$transparent_hugepage_config
$vlan_config
$mbim_config
# do not apply "vtconsole_config_disable", so not printing
$vivid_config

# Testing
## Surface series camera?
CONFIG_MFD_TPS68470=y
CONFIG_TPS68470_PMIC_OPREGION=y
CONFIG_GPIO_TPS68470=y
## VirtualBox guest
## [VirtualBox - Gentoo Wiki](https://wiki.gentoo.org/wiki/VirtualBox#Kernel_configuration)
CONFIG_X86_SYSFB=y
CONFIG_DRM_FBDEV_EMULATION=y
CONFIG_FIRMWARE_EDID=y
CONFIG_FB_SIMPLE=y
## some other stuff
CONFIG_ACPI_DEBUG=y
CONFIG_ACPI_PCI_SLOT=y

# misc configs from diff with Arch Linux kernel
## Useful?
CONFIG_HOTPLUG_PCI_ACPI=y
CONFIG_HOTPLUG_PCI_ACPI_IBM=m # (m is enough; not all PC need this)
CONFIG_PWM_LPSS_PCI=y # not needed to Surface 3
CONFIG_DRM_I915_ALPHA_SUPPORT=y
CONFIG_INPUT_SOC_BUTTON_ARRAY=y
CONFIG_DYNAMIC_DEBUG=y
CONFIG_ACPI_EC_DEBUGFS=y
CONFIG_INTEL_POWERCLAMP=y
CONFIG_DRM_I915_GVT=y
CONFIG_INTEL_IOMMU=y
# CONFIG_INTEL_IOMMU_DEFAULT_ON is not set # kernel param to enable is `intel_iommu=on`
CONFIG_VFIO=y
CONFIG_VFIO_MDEV=y
CONFIG_VFIO_MDEV_DEVICE=y
CONFIG_DRM_I915_GVT_KVMGT=y
CONFIG_INTEL_MEI_WDT=y
CONFIG_DPTF_POWER=y
EOS
cleanup_config_fragment config_minimal-surface-419-fragment

cat << EOS
# memo
## misc configs from diff with Arch Linux kernel
### Useful for some people?
# CONFIG_HID_SENSOR_HUMIDITY
# CONFIG_HID_SENSOR_INCLINOMETER_3D
# CONFIG_HID_SENSOR_MAGNETOMETER_3D
# CONFIG_HID_SENSOR_PRESS
# CONFIG_HID_SENSOR_PROX
# CONFIG_HID_SENSOR_TEMP
# CONFIG_MTD_CMDLINE_PARTS
# CONFIG_DRM_KMS_FB_HELPER
# CONFIG_CRYPTO_CRC32C_INTEL
# CONFIG_CRYPTO_CRC32_PCLMUL
# CONFIG_CRYPTO_CRCT10DIF_PCLMUL
# CONFIG_CRYPTO_USER
# CONFIG_EDAC
# CONFIG_CRYPTO_GHASH_CLMUL_NI_INTEL
# CONFIG_MTD
# CONFIG_MTD_SPI_NOR
# CONFIG_SPI_INTEL_SPI_PCI
# CONFIG_SPI_INTEL_SPI_PLATFORM
# CONFIG_MACINTOSH_DRIVERS
# CONFIG_MAC_EMUMOUSEBTN
# CONFIG_CRYPTO_PCBC
# CONFIG_X86_PCC_CPUFREQ
# CONFIG_USBIP_CORE
# CONFIG_CIFS
# CONFIG_AUTOFS4_FS
# CONFIG_AUTOFS_FS

EOS

# my config changes. you can also place your changes here if you want.
cat << EOS > config_mychanges-fragment
# set a distinguishable kernel name
CONFIG_LOCALVERSION="-minimal-surface-k5"

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
CONFIG_5525_ACPI_CALL=y

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

#
# enable acpidbg
#
CONFIG_ACPI_DEBUGGER=y
CONFIG_ACPI_DEBUGGER_USER=m
EOS
cleanup_config_fragment config_mychanges-fragment



# you may be interested in "Requested value" vs "Actual value".
scripts/kconfig/merge_config.sh \
    config_chromeos-intel-pineview-prepareconfig \
    config_surface-lts419-fragment \
    config_minimal-surface-419-fragment \
    config_mychanges-fragment \

# clean up
rm config_chromeos-intel-pineview-prepareconfig
rm config_surface-lts419-fragment
rm config_minimal-surface-419-fragment
rm config_mychanges-fragment
