Run the script on root of kernel tree. Merged config will be created as ".config" file.

#### config-minimal-surface

chromiumos-x86_64+linux-surface

Using chromiumos-x86_64 config as a base. Merge linux-surface config and my changes using `scripts/kconfig/merge_config.sh` which is available in Linux kernel tree.

Try this one if you only need to run kernel on Surface devices.

Note_1: That said, this is tested only on SB1 and S3.
Note_2: for using with `cros_sdk`, it might be possible to generate splitconfig from config_minimal-surface-$kernver-fragment.

#### config-general-surface

Arch Linux+chromiumos-x86_64+linux-surface

Using Arch Linux config as a base. Merge chromiumos-x86_64 config, linux-surface config, and my changes using `scripts/kconfig/merge_config.sh` which is available in Linux kernel tree.

Try this one if you prefer more general config (closer to regular Linux distros).
