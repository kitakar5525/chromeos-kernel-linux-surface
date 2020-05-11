## generating generic kernel config (for use with generic x86 PCs including Surface devices)

Using Arch Linux config as a base. Merge linux-surface config, chromiumos-x86_64 config and my changes using `scripts/kconfig/merge_config.sh` which is available in Linux kernel tree.

```bash
# arch-lts419 kernel config
wget "https://aur.archlinux.org/cgit/aur.git/plain/config?h=linux-lts419" -q --show-progress -O config_archlinux-lts419

# linux-surface 4.19 kernel config fragment
wget https://raw.githubusercontent.com/linux-surface/linux-surface/master/configs/surface-4.19.config -q --show-progress -O config_surface-4.19-fragment

# generate chromiumos-x86_64 fragment
chromeos/scripts/prepareconfig chromiumos-x86_64
mv .config config_chromiumos-x86_64-prepareconfig

# my config changes. you can also place your changes here if you want.
cat << EOS > config_mychanges-fragment
CONFIG_5525_ACPI_CALL=m
# CONFIG_DEBUG_INFO is not set
CONFIG_VIDEO_IPU3_IMGU=m
CONFIG_PCIEASPM_DEBUG=y

# for debugging Surface 3 touchscreen input
CONFIG_SPI_PXA2XX=m
CONFIG_SPI_PXA2XX_PCI=m

# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/3
# CONFIG_MODULE_COMPRESS is not set

# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/8
# and https://github.com/kitakar5525/chromeos-kernel-linux-surface#direct-firmware-load-for-firmware-file-failed-with-error--2
CONFIG_DRM_I915=m

# https://github.com/kitakar5525/chromeos-kernel-linux-surface/issues/9
CONFIG_TCG_TIS_CORE=m
CONFIG_TCG_TIS=m
CONFIG_TCG_VIRTIO_VTPM=m

# built-in storage related config
CONFIG_MMC_BLOCK=y

# init: Unable to mount /sys/fs/selinux filesystem: No such file or directory
# then kernel panic (and reboot)
CONFIG_SECURITY_SELINUX_BOOTPARAM_VALUE=1
CONFIG_DEFAULT_SECURITY_SELINUX=y
# CONFIG_DEFAULT_SECURITY_DAC is not set
CONFIG_DEFAULT_SECURITY="selinux"

# Enable kernel headers through /sys/kernel/kheaders.tar.xz
CONFIG_IKHEADERS=m

# https://github.com/systemd/systemd/blob/master/README
CONFIG_EFIVAR_FS=y

# to match stock chromiumos config
CONFIG_KERNEL_GZIP=y
# CONFIG_KERNEL_XZ is not set

# resolve "Actual value" not changing to "Requested value"
# caused by "NETFILTER_XT_MATCH_OWNER is not set"
# not specified in chromiumos-x86_64 prepareconfig
# (arc continuously crashing without this change)
# CONFIG_NETFILTER_XT_MATCH_OWNER is not set
CONFIG_NETFILTER_XT_MATCH_QTAGUID=y
EOS

# a lot of output for the first time. So, using `> /dev/null`
# arch419 + chromiumos-x86_64 + surface419 + mychanges
scripts/kconfig/merge_config.sh config_archlinux-lts419 \
config_chromiumos-x86_64-prepareconfig \
config_surface-4.19-fragment \
config_mychanges-fragment > /dev/null
cp .config config_arch419+chromiumos-x86_64+surface419+mychanges

# second time, check the generated config. So, not using `> /dev/null` here.
# you may be interested in "Requested value" vs "Actual value".
scripts/kconfig/merge_config.sh .config \
config_chromiumos-x86_64-prepareconfig \
config_surface-4.19-fragment \
config_mychanges-fragment
cp .config config_arch419+chromiumos-x86_64+surface419+mychanges

# memo
cat << EOS
# useful when you have to reload modules?
CONFIG_I2C_HID=m
EOS
```