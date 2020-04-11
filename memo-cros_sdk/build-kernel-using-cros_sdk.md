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
export REPO_DIR=~/chromiumos # change if not
export BOARD=amd64-generic
export WORKING_BRANCH=chromeos-surface
export KVER=4_19 # kernel version you want to build
export KVER_PERIOD=$(echo $KVER | sed s/_/./)

cd $REPO_DIR/src/third_party/kernel/v$KVER_PERIOD
git checkout $WORKING_BRANCH
kernver=$(make kernelversion); echo $kernver
export MODULE_EXPORT_DIR=~/chromeos-kernel-linux-surface-$kernver
modulesdir="$MODULE_EXPORT_DIR/lib/modules/$kernver"
mkdir $MODULE_EXPORT_DIR
mkdir $MODULE_EXPORT_DIR/lib

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

cd -
cp -r $REPO_DIR/chroot/build/$BOARD/boot $MODULE_EXPORT_DIR
cp -r $REPO_DIR/chroot/build/$BOARD/lib/modules $MODULE_EXPORT_DIR/lib
rm "$modulesdir"/{source,build} # remove build and source links
cp -r $REPO_DIR/src/third_party/kernel/v$KVER_PERIOD/chromeos/config $MODULE_EXPORT_DIR

mkdir "$modulesdir"/build
mkdir "$modulesdir"/build/chromeos
cp -r $REPO_DIR/chroot/build/$BOARD/var/cache/portage/sys-kernel/chromeos-kernel-$KVER/Module.symvers "$modulesdir"/build # for external module building, retrieve Module.symvers
cp $MODULE_EXPORT_DIR/boot/config-${kernver} "$modulesdir"/build/.config
cp $MODULE_EXPORT_DIR/boot/System.map-${kernver} "$modulesdir"/build/System.map
cp -r $MODULE_EXPORT_DIR/config "$modulesdir"/build/chromeos
cp -r $MODULE_EXPORT_DIR/configs-$kver_default-default "$modulesdir"/build/chromeos

# compress the whole directory
# using basename to remove path to home dir in archive
cd ~/
tar -czf ${MODULE_EXPORT_DIR}.tar.gz $(basename $MODULE_EXPORT_DIR) && rm -rf $MODULE_EXPORT_DIR
cd -
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