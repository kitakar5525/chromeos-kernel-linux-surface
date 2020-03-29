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
    - [Notes](#notes)
        - [Direct firmware load for *firmware file* failed with error -2](#direct-firmware-load-for-firmware-file-failed-with-error--2)

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
export KVER=4_19 # kernel version you want to build
export KVER_PERIOD=$(echo $KVER | sed s/_/./)

### Edit this file:
#- `~/trunk/src/overlays/overlay-amd64-generic/profiles/base/make.defaults`
# chenge kernel version if it still uses 4_14
# kernel-4_14 to kernel-$KVER
# add firmware[1]; something like this:
#-LINUX_FIRMWARE="iwlwifi-all"
#+LINUX_FIRMWARE="iwlwifi-all adsp_skl i915_skl ipu3_fw marvell-pcie8897"
# and commit your changes
git add make.defaults
git commit -m "Update board make profile"

# run this to workon the build
cros_workon --board=${BOARD} start sys-kernel/chromeos-kernel-$KVER



### apply changes to kernel
cd ~/trunk/src/third_party/kernel/v$KVER_PERIOD
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
# for i in $(find ../linux-surface-patches/patch-chromeos-$KVER_PERIOD -name "*.patch" | sort); do echo "applying $i"; patch -Np1 -i $i; done
# Or, stop if patch command returns non-zero value
# for i in $(find ../linux-surface-patches/patch-chromeos-$KVER_PERIOD/ -name *.patch | sort); do echo "applying $i"; patch -Np1 -i $i; if [ $? -ne 0 ]; then break; fi; done
# Or, use `git am`
for i in $(find ../linux-surface-patches/patch-chromeos-$KVER_PERIOD -name "*.patch" | sort); do git am -3 $i; done

# commit your changes here if you used `patch` command instead of `git am`
#git add -A
#git commit -m "Apply Surface patch set"

### edit kernel config
# check what config file is needed
# grep CHROMEOS_KERNEL_SPLITCONFIG ~/trunk/src/overlays/overlay-amd64-generic/profiles/base/make.defaults
# edit a config[4] found above; in my case, chromiumsos-x86_64:
#chromeos/scripts/kernelconfig editconfig
# Or, use my config files
cp -r ../linux-surface-patches/patch-chromeos-$KVER_PERIOD/configs/config-surface/config/base.config chromeos/config
cp -r ../linux-surface-patches/patch-chromeos-$KVER_PERIOD/configs/config-surface/config/x86_64/chromiumos-x86_64.flavour.config chromeos/config/x86_64
cp -r ../linux-surface-patches/patch-chromeos-$KVER_PERIOD/configs/config-surface/config/x86_64/common.config chromeos/config/x86_64
# If you use my config, make sure CONFIG_EXTRA_FIRMWARE_DIR='/build/amd64-generic/lib/firmware/'

# commit your changes
git add -A
git commit -m "Update configs for Surface devices"

# build the kernel!
make mrproper
# FEATURES="noclean" cros_workon_make --board=${BOARD} chromeos-kernel-$KVER --install
# you can change USE flags. See kitakar5525/chromeos-kernel-linux-surface#2
# remove `tpm` flag to avoid TCG_TIS=y in order to get chrome://flags/ page working on SB1
# untill we can use hardware tpm.
USE="${USE} -tpm" FEATURES="noclean" cros_workon_make --board=${BOARD} chromeos-kernel-$KVER --install
```


### How to retrieve the built kernel and config to your (outside cros_sdk chroot) home directory?

install dependencies first:
```bash
sudo apt install make gcc flex bison
```

```bash
### Copy the built kernel
exit # (outside cros_sdk)
export REPO_DIR=$(pwd)
export BOARD=amd64-generic
export WORKING_BRANCH=chromeos-surface
export KVER=4_19 # kernel version you want to build
export KVER_PERIOD=$(echo $KVER | sed s/_/./)

cd $REPO_DIR/src/third_party/kernel/v$KVER_PERIOD
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
cp -r $REPO_DIR/chroot/build/$BOARD/boot $MODULE_EXPORT_DIR
cp -r $REPO_DIR/chroot/build/$BOARD/lib/modules $MODULE_EXPORT_DIR
cp -r $REPO_DIR/src/third_party/kernel/v$KVER_PERIOD/chromeos/config $MODULE_EXPORT_DIR
# for external module building, retrieve Module.symvers
cp -r $REPO_DIR/chroot/build/$BOARD/var/cache/portage/sys-kernel/chromeos-kernel-$KVER/Module.symvers $MODULE_EXPORT_DIR/modules/$kver

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
export KVER=4_19 # kernel version you want to build
export KVER_PERIOD=$(echo $KVER | sed s/_/./)

cd ~/trunk/src/third_party/kernel/v$KVER_PERIOD
export STOCK_BRANCH=m/master
git checkout $STOCK_BRANCH # back to the branch where your branch derived
make mrproper
cros_workon_make --board=${BOARD} chromeos-kernel-$KVER --install

### copy the built kernel
exit # (outside cros_sdk)
export BOARD=amd64-generic
export KVER=4_19 # kernel version you want to build
export KVER_PERIOD=$(echo $KVER | sed s/_/./)

cd /home/ubuntu/chromiumos/src/third_party/kernel/v$KVER_PERIOD
kver_default=$(git describe --tags | sed 's/-/.r/; s/-g/./')
export MODULE_EXPORT_DIR=~/modules-$kver_default-stock
mkdir $MODULE_EXPORT_DIR
make mrproper
cd ~
cp -r $HOME/chromiumos/chroot/build/$BOARD/boot $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/chroot/build/$BOARD/lib/modules $MODULE_EXPORT_DIR
cp -r $HOME/chromiumos/src/third_party/kernel/v$KVER_PERIOD/chromeos/config $MODULE_EXPORT_DIR
cd $MODULE_EXPORT_DIR
tar -czf modules.tar.gz modules
cd -
rm -rf $MODULE_EXPORT_DIR/modules
# tar -czf ${MODULE_EXPORT_DIR}.tar.gz $MODULE_EXPORT_DIR
```

- [1]: [List of available firmware - linux-firmware-9999.ebuild](https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/sys-kernel/linux-firmware/linux-firmware-9999.ebuild)
- [2]: [issues building amd64-generic with v4.14 kernel - Google Groups](https://groups.google.com/a/chromium.org/forum/#!searchin/chromium-os-dev/build$20kernel$20image|sort:date/chromium-os-dev/YSiV4HuFPeI/Z8S0TFCKAwAJ)
- [3]: [Chromium OS Docs - Chromium OS Developer Guide](https://chromium.googlesource.com/chromiumos/docs/+/master/developer_guide.md#create-a-branch-for-your-changes)
- [4]: [Kernel Configuration - The Chromium Projects](https://sites.google.com/a/chromium.org/dev/chromium-os/how-tos-and-troubleshooting/kernel-configuration)



## How to build a kernel (using `make` command)

```bash
export KVER=4_19 # kernel version you want to build
export KVER_PERIOD=$(echo $KVER | sed s/_/./)

# get the kernel source code
git clone --depth 1 https://chromium.googlesource.com/chromiumos/third_party/kernel chromeos-$KVER_PERIOD -b chromeos-$KVER_PERIOD
# get the patchset
git clone --depth 1 https://github.com/kitakar5525/linux-surface-patches
cd chromeos-$KVER_PERIOD
# make kernelversion # to check the kernel version



### apply the patchset
#for i in $(find ../linux-surface-patches/patch-chromeos-$KVER_PERIOD -name "*.patch" | sort); do echo "applying $i"; patch -Np1 -i $i; done
# commit the patch (locally) to avoid getting `-dirty` in the kernel version
#git add -A
#git commit -m "surface-patches"
# Or, just use `git am`
for i in $(find ../linux-surface-patches/patch-chromeos-$KVER_PERIOD -name "*.patch" | sort); do git am -3 $i; done



### prepare the kernel config file

## FIXME
# If I understand correctly, this command gets the default chromiumos config:
# chromeos/scripts/prepareconfig chromiumos-x86_64
# However, this is different from the config file when I build using above way.
# See below section: "Who overwrote the kernel config?"
# So, let's use a config file which we can get from it.
# It is included in the patchset.
cp ../linux-surface-patches/patch-chromeos-$KVER_PERIOD/configs/config-surface/config-$KVER_PERIOD.* ./.config
make oldconfig
# Edit config here
# Especially, if you use my config, CONFIG_EXTRA_FIRMWARE_DIR='/lib/firmware'
# also, make sure IPTS firmware is in your `/lib/firmware/intel/ipts/`
# if not, copy firmware to it or remove them from `CONFIG_EXTRA_FIRMWARE`
make menuconfig



kernver="$(make -s kernelrelease)"
export INSTALL_MOD_PATH=../modules-$kernver
export INSTALL_PATH=../modules-$kernver
export INSTALL_MOD_STRIP=1 # to reduce the modules size (one example: 487M -> 35M)
modulesdir="$INSTALL_MOD_PATH/lib/modules/$kernver"

### build the kernel
make -j$(nproc --all) bzImage modules
# export the built modules
make modules_install # exported to $INSTALL_MOD_PATH
make install # exported to $INSTALL_PATH
# remove build and source links
rm "$modulesdir"/{source,build}

cp Module.symvers ../modules-$kernver # for external module building
```



## How to install the module and vmlinuz

copy the module into `ROOT-A/lib/modules` and copy the vmlinuz to `EFI-SYSTEM/syslinux/vmlinuz.A`










## Notes

### Direct firmware load for *firmware file* failed with error -2

The message will appear when the driver is built as built-in maybe because the driver loads too early and root filesystem is not mounted yet.

Build the driver as module or use `CONFIG_EXTRA_FIRMWARE`



References
- [[SOLVED] LFS - direct firmware load failed error -2](https://www.linuxquestions.org/questions/linux-from-scratch-13/lfs-direct-firmware-load-failed-error-2-a-4175587686/#post5594478)
