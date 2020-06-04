# chromeos-kernel-linux-surface

linux-surface kernel for Chromium OS/Chrome OS based OSes.

- Intended for **Surface Book 1 (especially, with Performance Base)** and **Surface 3**, but all patches (or equivalent) from [jakeday repository](https://github.com/jakeday/linux-surface) are applied

- Patches/config for chromeos kernel is here: [kitakar5525/linux-surface-patches](https://github.com/kitakar5525/linux-surface-patches)



<!-- TOC -->

- [chromeos-kernel-linux-surface](#chromeos-kernel-linux-surface)
    - [How to build a kernel (using `make` command)](#how-to-build-a-kernel-using-make-command)
    - [How to install the module and vmlinuz](#how-to-install-the-module-and-vmlinuz)

<!-- /TOC -->



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
export INSTALL_MOD_PATH=../chromeos-kernel-linux-surface-$kernver # modules will be exported to $INSTALL_MOD_PATH/lib/modules/$kernver
export INSTALL_PATH=../chromeos-kernel-linux-surface-$kernver/boot; mkdir -p $INSTALL_PATH 
export INSTALL_MOD_STRIP=1 # to reduce the modules size (one example: 487M -> 35M)
modulesdir="$INSTALL_MOD_PATH/lib/modules/$kernver"

### build the kernel
make -j$(nproc --all) bzImage modules

# do not continue if error occurred on make
if [[ $? -ne 0  ]]; then
  exit
fi

# export the built modules
make modules_install # exported to $INSTALL_MOD_PATH
# remove build and source links
rm "$modulesdir"/{source,build}

# copy vmlinuz, System.map, and config
# not using `make install` because it seems that depending on distros
# used to build the kernel, config may not be installed.
# Filename may also vary. So, explicitly copy them manually...
cp arch/x86_64/boot/bzImage $INSTALL_PATH/vmlinuz-${kernver}
cp System.map* $INSTALL_PATH/System.map-${kernver}
cp .config $INSTALL_PATH/config-${kernver}

# copy files to build/ for external module building
mkdir "$modulesdir"/build
cp Module.symvers "$modulesdir"/build
cp $INSTALL_PATH/config-${kernver} "$modulesdir"/build/.config
cp $INSTALL_PATH/System.map-${kernver} "$modulesdir"/build/System.map

# compress lib dir
tar -C $INSTALL_MOD_PATH -czf $INSTALL_MOD_PATH/lib.tar.gz lib && rm -rf $INSTALL_MOD_PATH/lib
# compress the whole dir if you want
tar -czf ${INSTALL_MOD_PATH}.tar.gz $INSTALL_MOD_PATH && rm -rf $INSTALL_MOD_PATH
```



## How to install the module and vmlinuz

copy the module into `ROOT-A/lib/modules` and copy the vmlinuz to `EFI-SYSTEM/syslinux/vmlinuz.A`
