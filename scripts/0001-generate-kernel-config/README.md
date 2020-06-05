Run the script on root of kernel tree. Merged config will be created as ".config" file.

#### config-minimal-surface

Using chromiumos-x86_64 config as a base. Merge linux-surface config and my changes using `scripts/kconfig/merge_config.sh` which is available in Linux kernel tree.

Try this one if you only need to run kernel on Surface devices.

Note_1: That said, this is tested only on SB1 and S3.
Note_2: for using with `cros_sdk`, it might be possible to generate splitconfig from config_minimal-surface-$kernver-fragment.

#### config-general-surface

Using Arch Linux config as a base. Merge linux-surface config, chromiumos-x86_64 config, and my changes using `scripts/kconfig/merge_config.sh` which is available in Linux kernel tree.

Try this one if you want to run kernel on devices other than Surface.
