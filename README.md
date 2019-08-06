# chromeos-kernel-linux-surface

linux-surface kernel for Chromium OS/Chrome OS based OSes.

- Intended for **Surface Book 1 (especially, with Performance Base)** and **Surface 3**, but all patches (or equivalent) from [jakeday repository](https://github.com/jakeday/linux-surface) are applied

- Patchset for chromeos is here: [kitakar5525/linux-surface-patches](https://github.com/kitakar5525/linux-surface-patches)



<!-- TOC -->

- [chromeos-kernel-linux-surface](#chromeos-kernel-linux-surface)
    - [How to build a kernel (using `cros_sdk`)](#how-to-build-a-kernel-using-cros_sdk)
        - [How to retrieve the built kernel and config to your (outside cros_sdk chroot) home directory?](#how-to-retrieve-the-built-kernel-and-config-to-your-outside-cros_sdk-chroot-home-directory)
        - [extra: build a stock kernel](#extra-build-a-stock-kernel)
    - [How to build a kernel (using `make` command)](#how-to-build-a-kernel-using-make-command)
    - [How to install the module and vmlinuz](#how-to-install-the-module-and-vmlinuz)
    - [kernel config](#kernel-config)
        - [misc configs from diff with Arch Linux kernel](#misc-configs-from-diff-with-arch-linux-kernel)
    - [memo](#memo)
        - [List of boards](#list-of-boards)
        - [Kernel build log location](#kernel-build-log-location)
        - [Kernel build cache location](#kernel-build-cache-location)
    - [Issues](#issues)
        - [FIXME: Who overrides the kernel config?](#fixme-who-overrides-the-kernel-config)
        - [FIXME: how to load the compressed modules?](#fixme-how-to-load-the-compressed-modules)
        - [FIXME: How to install kernel headers for building external modules? How to reduce the size?](#fixme-how-to-install-kernel-headers-for-building-external-modules-how-to-reduce-the-size)
        - [FIXME: Auto-rotation not working](#fixme-auto-rotation-not-working)
        - [FIXME: Auto mode change into tablet_mode not working](#fixme-auto-mode-change-into-tablet_mode-not-working)
        - [FIXME: Taking a screenshot using Pow+VolDown not working](#fixme-taking-a-screenshot-using-powvoldown-not-working)
        - [FIXME: Module load order for built-in modules](#fixme-module-load-order-for-built-in-modules)
    - [fixed](#fixed)
        - [fixed: Direct firmware load for *firmware file* failed with error -2](#fixed-direct-firmware-load-for-firmware-file-failed-with-error--2)
        - [fixed: Some HID devices stop working after suspend (s2idle) by default](#fixed-some-hid-devices-stop-working-after-suspend-s2idle-by-default)
        - [fixed: Tap to click not working by default](#fixed-tap-to-click-not-working-by-default)
        - [fixed: ~~FIXME: Sound not working on Surface 3~~ Managed to work: Sound not working on Surface 3 by default](#fixed-fixme-sound-not-working-on-surface-3-managed-to-work-sound-not-working-on-surface-3-by-default)
        - [fixed: Sound on Surface Book 1 may not working by default](#fixed-sound-on-surface-book-1-may-not-working-by-default)
    - [wontfix](#wontfix)
        - [wontfix: `make` error when `DRM_I915=m` and `INTEL_IPTS=y`](#wontfix-make-error-when-drm_i915m-and-intel_iptsy)
        - [wontfix: `make` error when `HID=m` and `SURFACE_ACPI=y`](#wontfix-make-error-when-hidm-and-surface_acpiy)

<!-- /TOC -->



## How to build a kernel (using `cros_sdk`)

you need to setup `cros_sdk` environment first:
- [Chromium OS Docs - Chromium OS Developer Guide](https://chromium.googlesource.com/chromiumos/docs/+/master/developer_guide.md)

```bash
# before entering chroot, I recommend to include your Linux distribution's firmware
# Especially, don't forget to add IPTS firmware
# sudo cp -r /lib/firmware/* $HOME/chromiumos/chroot/build/amd64-generic/lib/firmware/
# Or, clone it from kernel.org
cd ~
# git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
# sudo cp -r linux-firmware/* $HOME/chromiumos/chroot/build/amd64-generic/lib/firmware/
# Or, from arch
wget --trust-server-names https://www.archlinux.org/packages/core/any/linux-firmware/download/
mkdir linux-firmware-20190628.70e4394-1-any.pkg
tar -xf linux-firmware-20190628.70e4394-1-any.pkg.tar.xz -C linux-firmware-20190628.70e4394-1-any.pkg
# don't forget to add ipts firmware
cp -r ipts linux-firmware-20190628.70e4394-1-any.pkg/usr/lib/firmware/intel/
sudo cp -r linux-firmware-20190628.70e4394-1-any.pkg/usr/lib/firmware/* $HOME/chromiumos/chroot/build/amd64-generic/lib/firmware/

cros_sdk # (inside cros_sdk)
export BOARD=amd64-generic

### Edit this file:
#- `~/trunk/src/overlays/overlay-amd64-generic/profiles/base/make.defaults`
# chenge kernel version if it still uses 4_14
# kernel-4_14 to kernel-4_19
# add firmware[1]; something like this:
#-LINUX_FIRMWARE="iwlwifi-all"
#+LINUX_FIRMWARE="iwlwifi-all adsp_skl i915_skl ipu3_fw marvell-pcie8897"
# and commit your changes
git add make.defaults
git commit -m "Update board make profile"

# run this to workon the    build
cros_workon --board=${BOARD} start sys-kernel/chromeos-kernel-4_19



### apply changes to kernel
cd ~/trunk/src/third_party/kernel/v4.19
# make a new branch with `repo start` [2][3]:
export WORKING_BRANCH=chromeos-surface
repo start $WORKING_BRANCH .
### Apply patches
# Download latest patchset from repo:
# [kitakar5525/linux-surface-patches(https://github.com/kitakar5525/linux-surface-patches)
cd ../
git clone --depth 1 https://github.com/kitakar5525/linux-surface-patches
cd -
# apply lile this:
# for i in $(find ../linux-surface-patches/patch-chromeos-4.19 -name "*.patch" | sort); do echo "applying $i"; patch -Np1 -i $i; done
# Or, stop if patch command returns non-zero value
# for i in $(find ../linux-surface-patches/patch-chromeos-4.19/ -name *.patch | sort); do echo "applying $i"; patch -Np1 -i $i; if [ $? -ne 0 ]; then break; fi; done
# Or, use `git am`
for i in $(find ../linux-surface-patches/patch-chromeos-4.19 -name "*.patch" | sort); do git am $i; done

# commit your changes here if you used `patch` command instead of `git am`
#git add -A
#git commit -m "Apply Surface patch set"

### edit kernel config
# check what config file is needed
# grep CHROMEOS_KERNEL_SPLITCONFIG ~/trunk/src/overlays/overlay-amd64-generic/profiles/base/make.defaults
# edit a config[4] found above; in my case, chromiumsos-x86_64:
#chromeos/scripts/kernelconfig editconfig
# Or, use my config files
cp -r ../linux-surface-patches/patch-chromeos-4.19/configs/config-surface/config chromeos/
# If you use my config, make sure CONFIG_EXTRA_FIRMWARE_DIR='/build/amd64-generic/lib/firmware/'

# commit your changes
git add -A
git commit -m "Update configs for Surface devices"

# build the kernel!
make mrproper
FEATURES="noclean" cros_workon_make --board=${BOARD} chromeos-kernel-4_19 --install
```


### How to retrieve the built kernel and config to your (outside cros_sdk chroot) home directory?
```bash
### Copy the built kernel
exit # (outside cros_sdk)
export WORKING_BRANCH=chromeos-surface
cd /home/ubuntu/chromiumos/src/third_party/kernel/v4.19
kver=$(make kernelversion); echo $kver
export MODULE_EXPORT_DIR=~/modules-$kver
mkdir $MODULE_EXPORT_DIR

### extra: if you want, copy default configs
git checkout - # back to the branch where your branch derived
kver_default=$(git describe --tags | sed 's/-/.r/; s/-g/./')
mkdir $MODULE_EXPORT_DIR/configs-$kver_default-default
chromeos/scripts/prepareconfig chromiumos-x86_64 && make olddefconfig # generate default .config file
cp .config $MODULE_EXPORT_DIR/configs-$kver_default-default/config-$kver_default-default
cp -r chromeos/config $MODULE_EXPORT_DIR/configs-$kver_default-default/
make mrproper
git checkout $WORKING_BRANCH # back to your working branch

cd ~
cp -r $HOME/chromiumos/chroot/build/amd64-generic/boot $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/chroot/build/amd64-generic/lib/modules $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/src/third_party/kernel/v4.19/chromeos/config $MODULE_EXPORT_DIR
cd $MODULE_EXPORT_DIR
tar -czf modules.tar.gz modules
cd -
rm -rf $MODULE_EXPORT_DIR/modules
# tar -czf ${MODULE_EXPORT_DIR}.tar.gz $MODULE_EXPORT_DIR # compress the whole directory if you want
```



### extra: build a stock kernel
```bash
cros_sdk # (inside cros_sdk)
export BOARD=amd64-generic
cd ~/trunk/src/third_party/kernel/v4.19
git checkout - # back to the branch where your branch derived
make mrproper
cros_workon_make --board=${BOARD} chromeos-kernel-4_19 --install
### copy the built kernel
exit # (outside cros_sdk)
export WORKING_BRANCH=chromeos-surface
cd /home/ubuntu/chromiumos/src/third_party/kernel/v4.19
kver_default=$(git describe --tags | sed 's/-/.r/; s/-g/./')
export MODULE_EXPORT_DIR=~/modules-$kver_default-stock
mkdir $MODULE_EXPORT_DIR
make mrproper
cd ~
cp -r $HOME/chromiumos/chroot/build/amd64-generic/boot $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/chroot/build/amd64-generic/lib/modules $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/src/third_party/kernel/v4.19/chromeos/config $MODULE_EXPORT_DIR
cd $MODULE_EXPORT_DIR
tar -czf modules.tar.gz modules
cd -
rm -rf $MODULE_EXPORT_DIR/modules
# tar -czf ${MODULE_EXPORT_DIR}.tar.gz $MODULE_EXPORT_DIR
cd ~/trunk/src/third_party/kernel/v4.19
git checkout $WORKING_BRANCH # back to your working branch
```

- [1]: [List of available firmware - linux-firmware-9999.ebuild](https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/sys-kernel/linux-firmware/linux-firmware-9999.ebuild)
- [2]: [issues building amd64-generic with v4.14 kernel - Google Groups](https://groups.google.com/a/chromium.org/forum/#!searchin/chromium-os-dev/build$20kernel$20image|sort:date/chromium-os-dev/YSiV4HuFPeI/Z8S0TFCKAwAJ)
- [3]: [Chromium OS Docs - Chromium OS Developer Guide](https://chromium.googlesource.com/chromiumos/docs/+/master/developer_guide.md#create-a-branch-for-your-changes)
- [4]: [Kernel Configuration - The Chromium Projects](https://sites.google.com/a/chromium.org/dev/chromium-os/how-tos-and-troubleshooting/kernel-configuration)



## How to build a kernel (using `make` command)

```bash
# get the kernel source code
git clone --depth 1 https://chromium.googlesource.com/chromiumos/third_party/kernel chromeos-4.19 -b chromeos-4.19
# get the patchset
git clone --depth 1 https://github.com/kitakar5525/linux-surface-patches
cd chromeos-4.19
# make kernelversion # to check the kernel version



### apply the patchset
#for i in $(find ../linux-surface-patches/patch-chromeos-4.19 -name "*.patch" | sort); do echo "applying $i"; patch -Np1 -i $i; done
# commit the patch (locally) to avoid getting `-dirty` in the kernel version
#git add -A
#git commit -m "surface-patches"
# Or, just use `git am`
for i in $(find ../linux-surface-patches/patch-chromeos-4.19 -name "*.patch" | sort); do git am $i; done



### prepare the kernel config file

## FIXME
# If I understand correctly, this command gets the default chromiumos config:
# chromeos/scripts/prepareconfig chromiumos-x86_64
# However, this is different from the config file when I build using above way.
# See below section: "Who overwrote the kernel config?"
# So, let's use a config file which we can get from it.
# It is included in the patchset.
cp ../linux-surface-patches/patch-chromeos-4.19/configs/config-surface/config-4.19.* ./.config
make oldconfig
# Edit config here
# Especially, if you use my config, CONFIG_EXTRA_FIRMWARE_DIR='/lib/firmware'
# also, make sure IPTS firmware is in your `/lib/firmware/intel/ipts/`
# if not, copy firmware to it or remove them from `CONFIG_EXTRA_FIRMWARE`
make menuconfig



kernver="$(make -s kernelrelease)"
export INSTALL_MOD_PATH=../modules-$kernver
export INSTALL_MOD_STRIP=1 # to reduce the modules size (one example: 487M -> 35M)
modulesdir="$INSTALL_MOD_PATH/lib/modules/$kernver"

### build the kernel
make -j$(nproc --all) bzImage modules
# export the built modules
make modules_install # exported to $INSTALL_MOD_PATH
# remove build and source links
rm "$modulesdir"/{source,build}



### copy bzImage and config
cp arch/x86/boot/bzImage $INSTALL_MOD_PATH/vmlinuz-$kernver
cp .config $INSTALL_MOD_PATH/config-$kernver
```



## How to install the module and vmlinuz

copy the module into `ROOT-A/lib/modules` and copy the vmlinuz to `EFI-SYSTEM/syslinux/vmlinuz.A`










## kernel config

In addition to Surface related kernel configs (search by SURFACE in `make menuconfig`), you need to change a lot to use on Surface Book 1 / Surface 3.

```bash
Surface related kernel configs
- All items found by searching SURFACE
- SURFACE_ACPI_SSH dependency:
  - SERIAL_8250
  - SERIAL_8250_DW
  - SERIAL_DEV_CTRL_TTYPORT

Skylake related
#- search by SKYLAKE and SKL
#- SND_SOC_INTEL_SKYLAKE_SSP_CLK
#  - SND_SOC_INTEL_KBL_RT5663_MAX98927_MACH

Cherry Trail related
- All items found by searching CHERRY, Crystal
- All items found by searching CHT except SND related things
- CHT_DC_TI_PMIC_OPREGION dependency:
  - PMIC_OPREGION
  - INTEL_SOC_PMIC_CHTDC_TI
- CHT_WC_PMIC_OPREGION dependency:
  - INTEL_SOC_PMIC_CHTWC
- EXTCON_INTEL_CHT_WC dependency:
  - EXTCON
- INTEL_CHT_INT33FE dependency:
  - REGULATOR
  - CHARGER_BQ24190
- GPIO_CRYSTAL_COVE dependency:
  - INTEL_SOC_PMIC

Atom SoC sound related
- CONFIG_SND_SST_ATOM_HIFI2_PLATFORM [=m]
- CONFIG_SND_SST_ATOM_HIFI2_PLATFORM_PCI [=m]
#- CONFIG_SND_SST_ATOM_HIFI2_PLATFORM_ACPI [=m]

Sound on Surface 3
- CONFIG_SND_SOC_INTEL_CHT_BSW_RT5645_MACH
- CONFIG_HDMI_LPE_AUDIO # needed for HDMI sound

Backlight control on Surface 3
- CONFIG_PWM
  - CONFIG_PWM_LPSS_PLATFORM
  #- CONFIG_PWM_LPSS_PCI
- CONFIG_PWM_CRC
  - INTEL_SOC_PMIC
- DRM_I915=m
  - INTEL_IPTS=m # need to be as module or `make` will fail when `DRM_I915=m`

For IPTS on SB1 to work
- DRM_I915=m
- INTEL_MEI_ME [=M (?)]

Surface 3 S0ix
- INTEL_MEI_TXE
- CONFIG_INTEL_ATOMISP2_PM
- INTEL_INT0002_VGPIO (?)

SB1 S0ix
- MEDIA_CONTROLLER
  - VIDEO_V4L2_SUBDEV_API
    - CONFIG_VIDEO_IPU3_IMGU # need to be as module or embed the firmware to load the firmware
    - CONFIG_VIDEO_IPU3_CIO2
- CONFIG_INTEL_PCH_THERMAL

TPM (m if you want to use vTPM)
- CONFIG_TCG_TIS [=m]
- TCG_VTPM_PROXY [=m]
- CONFIG_TCG_CRB [=m]
- CONFIG_TCG_VIRTIO_VTPM [=m]

HID sensors
- HID_SENSOR_HUB
  - HID_SENSOR_IIO_COMMON
    - HID_SENSOR_ACCEL_3D
    - HID_SENSOR_ALS
    - HID_SENSOR_DEVICE_ROTATION
    - HID_SENSOR_GYRO_3D

Fix ACPI error on Surface 3
- SENSORS_CORETEMP [=m]

Embed firmware
#If you specify ipts firmwares here, remember to copy `/lib/firmware/intel/ipts` to your build machine.
#Or if you are in cros_sdk, `$HOME/chromiumos/chroot/build/amd64-generic/lib/firmware`.
- CONFIG_EXTRA_FIRMWARE='i915/skl_dmc_ver1_27.bin i915/skl_huc_ver01_07_1398.bin i915/skl_guc_ver9_33.bin intel/ipu3-fw.bin intel/ipts/config.bin intel/ipts/intel_desc.bin intel/ipts/vendor_desc.bin intel/ipts/vendor_kernel.bin intel/fw_sst_0f28.bin intel/fw_sst_0f28.bin-48kHz_i2s_master intel/fw_sst_0f28_ssp0.bin intel/fw_sst_22a8.bin'
# - CONFIG_EXTRA_FIRMWARE_DIR='/lib/firmware'
- CONFIG_EXTRA_FIRMWARE_DIR='/build/amd64-generic/lib/firmware/' # if you are in cros_sdk

Fix HID related errors after s2idle
- HID [=m] dependency:
  - I2C_HID [=m]
  - USB_HID [=m]
- CONFIG_SURFACE_ACPI [=m] # need to be as module when HID [=m] or build will fail

Testing
# Type Cover not working/prevents S0ix state after suspend (s2idle) on Surface 3
- CONFIG_SURFACE3_WMI [=m]
# Touchscreen sometimes not working after suspend (s2idle) on Surface 3
- TOUCHSCREEN_SURFACE3_SPI [=m]
- INTEL_PMC_IPC
# VirtualBox guest
    # [VirtualBox - Gentoo Wiki](https://wiki.gentoo.org/wiki/VirtualBox#Kernel_configuration)
    - CONFIG_X86_SYSFB
    - CONFIG_DRM_FBDEV_EMULATION
    - CONFIG_FIRMWARE_EDID
    - CONFIG_FB_SIMPLE
# Surface series camera?
- CONFIG_TPS68470_PMIC_OPREGION=y
- CONFIG_GPIO_TPS68470=y
- CONFIG_MFD_TPS68470=y

Personal memo
- #if you patched to include acpi_call, don't forget to set it y or m
```

### misc configs from diff with Arch Linux kernel

```bash

Useful?
- CONFIG_HOTPLUG_PCI_ACPI
    - CONFIG_HOTPLUG_PCI_ACPI_IBM
- CONFIG_PWM_LPSS_PCI # not related to Surface 3
- CONFIG_DRM_I915_ALPHA_SUPPORT
- INPUT_SOC_BUTTON_ARRAY
- DYNAMIC_DEBUG
- ACPI_EC_DEBUGFS
- INTEL_POWERCLAMP
- CONFIG_DRM_I915_GVT
  - INTEL_IOMMU
  - INTEL_IOMMU_DEFAULT_ON is not set # kernel param is `intel_iommu=on`
  - VFIO
  - VFIO_MDEV
  - VFIO_MDEV_DEVICE
  - KVM
    - DRM_I915_GVT_KVMGT
  - CONFIG_KVM_INTEL
  - CONFIG_VHOST_NET
  - VIRTIO_VSOCKETS
    - VHOST_VSOCK
    - VIRTIO_VSOCKETS_COMMON



Useful for some people?
- CONFIG_INTEL_MEI_WDT
- HID_SENSOR_HUMIDITY
- HID_SENSOR_INCLINOMETER_3D
- HID_SENSOR_MAGNETOMETER_3D
- HID_SENSOR_PRESS
- HID_SENSOR_PROX
- HID_SENSOR_TEMP
- MTD_CMDLINE_PARTS
- VT
  - FRAMEBUFFER_CONSOLE
  - FRAMEBUFFER_CONSOLE_DETECT_PRIMARY
  - CONFIG_FRAMEBUFFER_CONSOLE_ROTATION
  - CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER
  - DRM_FBDEV_EMULATION
  - DRM_KMS_FB_HELPER
- CRYPTO_CRC32C_INTEL
- CRYPTO_CRC32_PCLMUL
- CRYPTO_CRCT10DIF_PCLMUL
- CRYPTO_USER
- DPTF_POWER
- EDAC
- CRYPTO_GHASH_CLMUL_NI_INTEL
- MTD
- MTD_SPI_NOR
- SPI_INTEL_SPI_PCI
- SPI_INTEL_SPI_PLATFORM
- CONFIG_USB_ROLE_SWITCH
  - CONFIG_USB_ROLES_INTEL_XHCI
- CONFIG_MACINTOSH_DRIVERS
  - MAC_EMUMOUSEBTN
- CRYPTO_PCBC
- X86_PCC_CPUFREQ
- CONFIG_TRANSPARENT_HUGEPAGE
- CONFIG_USBIP_CORE
- CONFIG_USB_NET_CDC_MBIM
- CONFIG_VIDEO_VIVID
- CONFIG_VLAN_8021Q
- CONFIG_CIFS
- CONFIG_AUTOFS4_FS
- CONFIG_AUTOFS_FS
```










## memo

### List of boards

```bash
# (inside cros_sdk)
$ ls ~/trunk/src/overlays
# (outside cros_sdk)
$ ls chromiumos/src/overlays/overlay-amd64-generic
```

Especially, board `amd64-generic` is located at
- (inside cros_sdk) `~/trunk/src/overlays/overlay-amd64-generic`
- (outside cros_sdk) `chromiumos/src/overlays/overlay-amd64-generic`

### Kernel build log location

```bash
# (inside cros_sdk)
/build/amd64-generic/tmp/portage/logs/sys-kernel:chromeos-kernel-*
```

### Kernel build cache location

```bash
# (inside cros_sdk)
/build/amd64-generic/var/cache/portage/sys-kernel/
```










## Issues

### FIXME: Who overrides the kernel config?

When building using `cros_workon_make`, kernel config may be overritten by someone:
```
>>> Configuring source in /build/amd64-generic/tmp/portage/sys-kernel/chromeos-kernel-4_19-9999/work/chromeos-kernel-4_19-9999 ...
 * Using kernel config: chromiumos-x86_64
 *    - enabling Enable ACPI AC config
 *    - disabling framebuffer console config
 *    - enabling Support running virtual machines with KVM config
 *    - enabling CDC MBIM driver config
 *    - enabling TPM support config
 *    - enabling Transparent Hugepage Support config
 *    - enabling Virtual USB support config
 *    - enabling Virtual Video Test Driver config
 *    - enabling 802.1Q VLAN config
 *    - disabling VT console config
make -j8 O=/build/amd64-generic/var/cache/portage/sys-kernel/chromeos-kernel-4_19 LD=/usr/x86_64-pc-linux-gnu/x86_64-cros-linux-gnu/binutils-bin/2.27.0/ld 'CC=x86_64-cros-linux-gnu-clang -B/usr/x86_64-pc-linux-gnu/x86_64-cros-linux-gnu/binutils-bin/2.27.0' 'CXX=x86_64-cros-linux-gnu-clang++ -B/usr/x86_64-pc-linux-gnu/x86_64-cros-linux-gnu/binutils-bin/2.27.0' HOSTCC=x86_64-pc-linux-gnu-clang HOSTCXX=x86_64-pc-linux-gnu-clang++ olddefconfig 
make[1]: Entering directory '/build/amd64-generic/var/cache/portage/sys-kernel/chromeos-kernel-4_19'
  GEN     ./Makefile
scripts/kconfig/conf  --olddefconfig Kconfig
.config:5211:warning: override: reassigning to symbol ACPI_AC
.config:5214:warning: override: reassigning to symbol FRAMEBUFFER_CONSOLE
.config:5223:warning: override: reassigning to symbol KVM
.config:5230:warning: override: reassigning to symbol VSOCKETS
.config:5232:warning: override: reassigning to symbol VIRTUALIZATION
.config:5236:warning: override: reassigning to symbol USB_NET_CDC_MBIM
.config:5239:warning: override: reassigning to symbol TCG_TPM
.config:5240:warning: override: reassigning to symbol TCG_TIS
.config:5244:warning: override: reassigning to symbol TRANSPARENT_HUGEPAGE
.config:5248:warning: override: reassigning to symbol USBIP_CORE
.config:5252:warning: override: reassigning to symbol VIDEO_VIVID
.config:5256:warning: override: reassigning to symbol VLAN_8021Q
.config:5259:warning: override: reassigning to symbol VT
.config:5260:warning: override: reassigning to symbol VT_CONSOLE
#
# configuration written to .config
#
make[1]: Leaving directory '/build/amd64-generic/var/cache/portage/sys-kernel/chromeos-kernel-4_19'
>>> Source configured.
```

```
[ebuild  N     ] sys-kernel/chromeos-kernel-4_4-4.4.176-r1836::chromiumos to /build/eve/ USE="clang eve_bt_hacks eve_wifi_etsi fit_compression_kernel_lz4 kvm_host mbim tpm2 transparent_hugepage vlan -acpi_ac -allocator_slab -apex -apply_patches -asan -binder -blkdevram -boot_dts_device_tree -buildtest -builtin_fw_amdgpu -builtin_fw_t124_xusb -builtin_fw_t210_bpmp -builtin_fw_t210_nouveau -builtin_fw_t210_xusb -ca0132 -cec -cifs -criu -cros_ec_mec -cros_host -debug -debugobjects -devdebug -device_tree -diskswap -dm_snapshot -dmadebug -dp_cec -dwc2_dual_role -dyndebug -factory_netboot_ramfs -factory_shim_ramfs -fbconsole -firmware_install -fit_compression_kernel_lzma -gdmwimax -gobi -goldfish -highmem -i2cdev -iscsi -kasan -kcov -kexec_file -kgdb -kmemleak -kvm -lockdebug -lxc -memory_debug -module_sign -nfc -nfs -nowerror -pca954x -pcserial -plan9 -ppp -pvrdebug -qmi -realtekpstor -recovery_ramfs -samsung_serial -selinux_develop -socketmon -systemtap -test -tpm -ubsan -unibuild -usb_gadget -usb_gadget_acm -usb_gadget_audio -usb_gadget_ncm -usbip -vfat -virtio_balloon -vivid -vtconsole -wifi_diag -wifi_testbed_ap -wilco_ec -wireless318 -wireless34 -wireless38 -wireless42 -x32" BOARD_USE="eve -acorn -amd64-corei7 -amd64-generic -amd64-generic-cheets -amd64-generic-goofy -amd64-generic_embedded -amd64-generic_mobbuild -amd64-host -aplrvp -aries -arkham -arm-generic -arm64-generic -arm64-llvmpipe -asuka -atlas -auron -auron_paine -auron_pearlvalley -auron_yuna -banjo -banon -bayleybay -beaglebone -beaglebone_servo -beaglebone_vv1 -beltino -betty -betty-arc64 -betty-arcmaster -betty-arcnext -blackwall -bob -bobcat -bolt -bruteus -buddy -butterfly -bwtm2 -candy -capri -capri-zfpga -cardhu -caroline -caroline-arc64 -caroline-arcnext -caroline-ndktranslation -caroline-userdebug -cave -celes -celes-cheets -chell -chell-cheets -cheza -cheza-freedreno -cid -clapper -cmlrvp -cnlrvp -cobblepot -coral -cosmos -cranky -cyan -cyan-cheets -cyclone -daisy -daisy_embedded -daisy_skate -daisy_snow -daisy_spring -daisy_winter -dalmore -danger -danger_embedded -dragonegg -duck -edgar -elm -elm-cheets -enguarde -eve-arcnext -eve-arcvm -eve-campfire -eve-kvm -eve-swap -eve-userdebug -expresso -falco -falco_gles -falco_li -fb1 -fizz -fizz-accelerator -fizz-labstation -fizz-moblab -flapjack -foster -gale -gandof -glados -glados-cheets -glimmer -glimmer-cheets -glkrvp -gnawty -gonzo -gru -grunt -guado -guado-accelerator -guado-macrophage -guado_labstation -guado_moblab -hana -hatch -heli -hsb -iclrvp -ironhide -jadeite -jecht -kalista -kayle -kblrvp -kefka -kevin -kevin-arcnext -kevin-tpm2 -kevin64 -kidd -kip -klang -kukui -kunimitsu -lakitu -lakitu-gpu -lakitu-nc -lakitu-st -lakitu_mobbuild -lakitu_next -lars -laser -lasilla-ground -lassen -leon -link -littlejoe -loonix -lulu -lulu-cheets -lumpy -mappy -mappy_flashstation -marble -mccloud -meowth -metis -minnowboard -mipseb-n32-generic -mipseb-n64-generic -mipseb-o32-generic -mipsel-n32-generic -mipsel-n64-generic -mipsel-o32-generic -mistral -moblab-generic-vm -monroe -moose -nami -nautilus -nefario -ninja -nocturne -novato -novato-arc64 -novato-arcnext -nyan -nyan_big -nyan_blaze -nyan_kitty -oak -oak-cheets -octavius -octopus -orco -panda -panther -panther_embedded -panther_goofy -panther_moblab -parrot -parrot32 -parrot64 -parrot_ivb -pbody -peach -peach_kirby -peach_pi -peach_pit -peppy -plaso -poppy -ppcbe-32-generic -ppcbe-64-generic -ppcle-32-generic -ppcle-64-generic -puppy -purin -pyro -quawks -rainier -rambi -rammus -raspberrypi -reef -reks -relm -reptile -rikku -rizer -romer -rotor -rowan -rush -rush_ryu -sama5d3 -samus -samus-cheets -samus-kernelnext -sand -sarien -scarlet -scarlet-arcnext -sentry -setzer -shogun -sklrvp -slippy -smaug -smaug-cheets -smaug-kasan -snappy -sonic -soraka -squawks -stelvio -storm -storm_nand -stout -strago -stumpy -stumpy_moblab -stumpy_pico -sumo -swanky -tael -tails -tatl -tegra3-generic -terra -tidus -tricky -ultima -umaro -veyron -veyron_fievel -veyron_gus -veyron_jaq -veyron_jerry -veyron_mickey -veyron_mighty -veyron_minnie -veyron_minnie-cheets -veyron_nicky -veyron_pinky -veyron_remy -veyron_rialto -veyron_shark -veyron_speedy -veyron_speedy-cheets -veyron_thea -veyron_tiger -viking -whirlwind -whlrvp -winky -wizpig -wolf -wooten -wsb -x30evb -x32-generic -x86-agz -x86-alex -x86-alex32 -x86-alex32_he -x86-alex_he -x86-alex_hubble -x86-dogfood -x86-generic -x86-generic_embedded -x86-mario -x86-mario64 -x86-zgb -x86-zgb32 -x86-zgb32_he -x86-zgb_he -zako -zoombini" 475 KiB
```

### FIXME: how to load the compressed modules?
I can compress the modules:
```
CONFIG_MODULE_COMPRESS=y
CONFIG_MODULE_COMPRESS_GZIP=y
```
but chromiumos won't load the compressed modules.

### FIXME: How to install kernel headers for building external modules? How to reduce the size?

### FIXME: Auto-rotation not working
While auto rotation is not working, you can rotate your screen by:

If you are in tablet_mode:
    - Use this android app: [azw413/ChromeOSRotate: Android App to rotate orientation on Chrome Tablets](https://github.com/azw413/ChromeOSRotate)

If you are not in tablet_mode:
    - `Ctrl+Shift+Reload` (`Ctrl+Shift+Super(Win)+F3`)

### FIXME: Auto mode change into tablet_mode not working
While auto mode change is not working, you can manually change the mode by keyboard.

To do so, add a flag `--ash-debug-shortcuts` to your `/etc/chrome_dev.conf`,
then restart your ui `sudo restart ui`, after that, you can change the mode by `Ctrl+Alt+Shift+T`.

```bash
# mount root filesystem as writable
sudo mount / -o rw,remount
```

```bash
# Edit a file
sudo vim /etc/chrome_dev.conf
```

### FIXME: Taking a screenshot using Pow+VolDown not working

### FIXME: Module load order for built-in modules
To adjust the backlight on Surface 3, we need to build `i915` as not built-in but module.
Maybe the cause of this problem is that `i915` will be loaded too early when built as built-in.

For now, I have to build `DRM_I915` and modules which depend on it as module.

```
- DRM_I915
  - CONFIG_HDMI_LPE_AUDIO
  - INTEL_IPTS
```



## fixed

### fixed: Direct firmware load for *firmware file* failed with error -2

The message will appear when the driver is built as built-in maybe because the driver loads too early and root filesystem is not mounted yet.

Build the driver as module or use `CONFIG_EXTRA_FIRMWARE`



References
- [[SOLVED] LFS - direct firmware load failed error -2](https://www.linuxquestions.org/questions/linux-from-scratch-13/lfs-direct-firmware-load-failed-error-2-a-4175587686/#post5594478)

### fixed: Some HID devices stop working after suspend (s2idle) by default

You may see some logs after s2idle in `dmesg` like this:
```
i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
```

Then, build `HID` as module (`I2C_HID`=m is not sufficient (?) in my case)
and reload the module ``sudo modprobe -r i2c_hid && sudo modprobe i2c_hid`

### fixed: Tap to click not working by default

Edit `/etc/gesture/40-touchpad-cmt.conf`
```diff
Section "InputClass"
    Identifier      "touchpad"
[...]
+    # for Surface series touchpad tap to click
+    Option          "libinput Tapping Enabled" "1"
+    Option          "Tap Minimum Pressure" "0.1"
EndSection
```

then `sudo restart ui`

References:
- [Problem With alps touchpad ? Issue #128 ? arnoldthebat/chromiumos](https://github.com/arnoldthebat/chromiumos/issues/128)

### fixed: ~~FIXME: Sound not working on Surface 3~~ Managed to work: Sound not working on Surface 3 by default
`dmesg` says:
```
Audio Port: ASoC: no backend DAIs enabled for Audio Port
```

HDMI or USB audio is working.

---

I managed to make the sound working on Surface 3, not ideal result yet.
- Obtain UCM files for chtrt5645 from [UCM/chtrt5645 at master · plbossart/UCM](https://github.com/plbossart/UCM/tree/master/chtrt5645)
- Place these 2 .conf files into a directory named `chtrt5645`
- Copy the directory into `/usr/share/alsa/ucm/`

Then, reboot.

If it is still not working, you may manually switch Speaker or Headphones:
- `alsaucm -c chtrt5645 set _verb HiFi set _enadev Speaker`
- `alsaucm -c chtrt5645 set _verb HiFi set _enadev Headphones`

References:
[ALSA (chtrt5645/HdmiLpeAudio) no audio / Newbie Corner / Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=239674)

### fixed: Sound on Surface Book 1 may not working by default
You may need to comment out the line in a file `/etc/modprobe.d/alsa-skl.conf`
```
blacklist snd_hda_intel
```



## wontfix

### wontfix: `make` error when `DRM_I915=m` and `INTEL_IPTS=y`

```
ld: drivers/misc/ipts/ipts-gfx.o: in function `connect_gfx':
/tmp/mnt/nvme0n1/5525-build/chromeos-4.19/drivers/misc/ipts/ipts-gfx.c:54: undefined reference to `intel_ipts_connect'
ld: drivers/misc/ipts/ipts-gfx.o: in function `disconnect_gfx':
/tmp/mnt/nvme0n1/5525-build/chromeos-4.19/drivers/misc/ipts/ipts-gfx.c:67: undefined reference to `intel_ipts_disconnect'
make: *** [Makefile:1031: vmlinux] Error 1
```

Build `INTEL_IPTS` as module when you build `DRM_I915` as module.

### wontfix: `make` error when `HID=m` and `SURFACE_ACPI=y`

```
drivers/platform/x86/surface_acpi.o: In function `surfacegen5_vhf_create_hid_device':
/mnt/host/source/src/third_party/kernel/v4.19/drivers/platform/x86/surface_acpi.c:2689: undefined reference to `hid_allocate_device'
drivers/platform/x86/surface_acpi.o: In function `surfacegen5_acpi_vhf_probe':
/mnt/host/source/src/third_party/kernel/v4.19/drivers/platform/x86/surface_acpi.c:2759: undefined reference to `hid_add_device'
/mnt/host/source/src/third_party/kernel/v4.19/drivers/platform/x86/surface_acpi.c:2786: undefined reference to `hid_destroy_device'
drivers/platform/x86/surface_acpi.o: In function `surfacegen5_acpi_vhf_remove':
/mnt/host/source/src/third_party/kernel/v4.19/drivers/platform/x86/surface_acpi.c:2801: undefined reference to `hid_destroy_device'
drivers/platform/x86/surface_acpi.o: In function `surfacegen5_vhf_event_handler':
/mnt/host/source/src/third_party/kernel/v4.19/drivers/platform/x86/surface_acpi.c:2712: undefined reference to `hid_input_report'
drivers/platform/x86/surface_acpi.o: In function `vhf_hid_parse':
/mnt/host/source/src/third_party/kernel/v4.19/drivers/platform/x86/surface_acpi.c:2655: undefined reference to `hid_parse_report'
make[1]: *** [/mnt/host/source/src/third_party/kernel/v4.19/Makefile:1035: vmlinux] Error 1
make[1]: Target '_all' not remade because of errors.
make[1]: Leaving directory '/build/amd64-generic/var/cache/portage/sys-kernel/chromeos-kernel-4_19'
make: *** [Makefile:146: sub-make] Error 2
make: Target '_all' not remade because of errors.
```

Build `SURFACE_ACPI` as module when you build `HID` as module.
