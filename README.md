# chromeos-kernel-linux-surface

linux-surface kernel for Chromium OS/Chrome OS based OSes.

- Intended for **Surface Book 1 (especially, with Performance Base)** and **Surface 3**, but all patches (or equivalent) from [jakeday repository](https://github.com/jakeday/linux-surface) are applied

- Patches/config for chromeos kernel is here: [kitakar5525/linux-surface-patches](https://github.com/kitakar5525/linux-surface-patches)



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
    - [Notes](#notes)
        - [Direct firmware load for *firmware file* failed with error -2](#direct-firmware-load-for-firmware-file-failed-with-error--2)
        - [Some HID devices stop working after suspend (s2idle) by default](#some-hid-devices-stop-working-after-suspend-s2idle-by-default)
        - [Tap to click not working by default](#tap-to-click-not-working-by-default)
        - [~~FIXME: Sound not working on Surface 3~~ Managed to work: Sound not working on Surface 3 by default](#fixme-sound-not-working-on-surface-3-managed-to-work-sound-not-working-on-surface-3-by-default)
        - [Sound on Surface Book 1 may not working by default](#sound-on-surface-book-1-may-not-working-by-default)
        - [Auto-rotation not working (#5)](#auto-rotation-not-working-5)
        - [Auto mode change into tablet_mode not working (#6)](#auto-mode-change-into-tablet_mode-not-working-6)
        - [Taking a screenshot using Pow+VolDown not working (#7)](#taking-a-screenshot-using-powvoldown-not-working-7)

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

# run this to workon the build
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
cp -r ../linux-surface-patches/patch-chromeos-4.19/configs/config-surface/config/base.config chromeos/config
cp -r ../linux-surface-patches/patch-chromeos-4.19/configs/config-surface/config/x86_64/chromiumos-x86_64.flavour.config chromeos/config/x86_64
cp -r ../linux-surface-patches/patch-chromeos-4.19/configs/config-surface/config/x86_64/common.config chromeos/config/x86_64
# If you use my config, make sure CONFIG_EXTRA_FIRMWARE_DIR='/build/amd64-generic/lib/firmware/'

# commit your changes
git add -A
git commit -m "Update configs for Surface devices"

# build the kernel!
make mrproper
# FEATURES="noclean" cros_workon_make --board=${BOARD} chromeos-kernel-4_19 --install
# you can change USE flags. See kitakar5525/chromeos-kernel-linux-surface#2
# remove `tpm` flag to avoid TCG_TIS=y in order to get chrome://flags/ page working on SB1
# untill we can use hardware tpm.
USE="${USE} -tpm" FEATURES="noclean" cros_workon_make --board=${BOARD} chromeos-kernel-4_19 --install
```


### How to retrieve the built kernel and config to your (outside cros_sdk chroot) home directory?
```bash
### Copy the built kernel
exit # (outside cros_sdk)
export BOARD=amd64-generic
export WORKING_BRANCH=chromeos-surface
cd /home/ubuntu/chromiumos/src/third_party/kernel/v4.19
kver=$(make kernelversion); echo $kver
export MODULE_EXPORT_DIR=~/chromeos-kernel-linux-surface-$kver
mkdir $MODULE_EXPORT_DIR

### extra: if you want, copy default configs
export STOCK_BRANCH=m/master
git checkout $STOCK_BRANCH # back to the branch where your branch derived
kver_default=$(git describe --tags | sed 's/-/.r/; s/-g/./')
mkdir $MODULE_EXPORT_DIR/configs-$kver_default-default
chromeos/scripts/prepareconfig chromiumos-x86_64 && make olddefconfig # generate default .config file
cp .config $MODULE_EXPORT_DIR/configs-$kver_default-default/config-$kver_default-default
cp -r chromeos/config $MODULE_EXPORT_DIR/configs-$kver_default-default/
make mrproper
git checkout $WORKING_BRANCH # back to your working branch

cd ~
cp -r $HOME/chromiumos/chroot/build/$BOARD/boot $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/chroot/build/$BOARD/lib/modules $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/src/third_party/kernel/v4.19/chromeos/config $MODULE_EXPORT_DIR
# for external module building, retrieve Module.symvers
cp -r $HOME/chromiumos/chroot/build/$BOARD/var/cache/portage/sys-kernel/chromeos-kernel-4_19/Module.symvers $MODULE_EXPORT_DIR/modules/$kver

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
export STOCK_BRANCH=m/master
git checkout $STOCK_BRANCH # back to the branch where your branch derived
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
cp -r $HOME/chromiumos/chroot/build/$BOARD/boot $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/chroot/build/$BOARD/lib/modules $MODULE_EXPORT_DIR
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
#- CONFIG_EXTRA_FIRMWARE='i915/skl_dmc_ver1_27.bin i915/skl_huc_ver01_07_1398.bin i915/skl_guc_ver9_33.bin intel/ipu3-fw.bin intel/ipts/config.bin intel/ipts/intel_desc.bin intel/ipts/vendor_desc.bin intel/ipts/vendor_kernel.bin intel/fw_sst_0f28.bin intel/fw_sst_0f28.bin-48kHz_i2s_master intel/fw_sst_0f28_ssp0.bin intel/fw_sst_22a8.bin'
# stopped embedding firmware except intel/ipu3-fw.bin for now
CONFIG_EXTRA_FIRMWARE='intel/ipu3-fw.bin'
# - CONFIG_EXTRA_FIRMWARE_DIR='/lib/firmware'
- CONFIG_EXTRA_FIRMWARE_DIR='/build/amd64-generic/lib/firmware/' # if you are in cros_sdk

Fix HID related errors after s2idle (to reload module after suspend)
- I2C_HID [=m]
- USB_HID [=m]

Testing
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










## Notes

### Direct firmware load for *firmware file* failed with error -2

The message will appear when the driver is built as built-in maybe because the driver loads too early and root filesystem is not mounted yet.

Build the driver as module or use `CONFIG_EXTRA_FIRMWARE`



References
- [[SOLVED] LFS - direct firmware load failed error -2](https://www.linuxquestions.org/questions/linux-from-scratch-13/lfs-direct-firmware-load-failed-error-2-a-4175587686/#post5594478)

### Some HID devices stop working after suspend (s2idle) by default

You may see some logs after s2idle in `dmesg` like this:
```
i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
```

Then, build `HID` as module (`I2C_HID`=m is not sufficient (?) in my case)
and reload the module `sudo modprobe -r i2c_hid && sudo modprobe i2c_hid`

### Tap to click not working by default

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

### ~~FIXME: Sound not working on Surface 3~~ Managed to work: Sound not working on Surface 3 by default
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

### Sound on Surface Book 1 may not working by default
You may need to comment out the line in a file `/etc/modprobe.d/alsa-skl.conf`
```
blacklist snd_hda_intel
```

### Auto-rotation not working (#5)
While auto rotation is not working, you can rotate your screen by:

If you are in tablet_mode:
    - Use this android app: [azw413/ChromeOSRotate: Android App to rotate orientation on Chrome Tablets](https://github.com/azw413/ChromeOSRotate)

If you are not in tablet_mode:
    - `Ctrl+Shift+Reload` (`Ctrl+Shift+Super(Win)+F3`)

### Auto mode change into tablet_mode not working (#6)
While auto mode change is not working, you can manually change the mode by keyboard.

To do so, add a flag `--ash-debug-shortcuts` to your `/etc/chrome_dev.conf`,
then restart your ui `sudo restart ui`, after that, you can change the mode by `Ctrl+Alt+Shift+T`.

```bash
# mount root filesystem as writable
sudo mount / -o rw,remount
```

```bash
# Edit this file
sudo vim /etc/chrome_dev.conf
```

### Taking a screenshot using Pow+VolDown not working (#7)
While that function not working, you can take a screenshot without keyboard by
- Settings -> Device -> Stylus -> Show stylus tools in the shelf

and in the stylus tools, choose "Capture screen".
However, if you "Autohide shelf", the screenshot is taken before the shelf is completely hidden.
