Run the script on root of kernel tree. Merged config will be created as ".config" file.

Using chromiumos-x86_64 config as a base. Merge linux-surface config and my changes using `scripts/kconfig/merge_config.sh` which is available in Linux kernel tree.

Note: for using with `cros_sdk`, it might be possible to generate splitconfig from config_minimal-surface-$kernver-fragment.