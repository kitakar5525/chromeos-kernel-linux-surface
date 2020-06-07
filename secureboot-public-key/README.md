Releases after 2020-06-08, the kernel is signed with secureboot key.

Copy `MOK_kitakar5525.cer` to location where MokManager can read (e.g. EFI partition). Then, enroll the key using MokManager.
If other Linux system is available (both via chroot or dual-booting), you can also use `mokutil` to enroll the public key.

The linux-surface repo has a good wiki page about secureboot signing: https://github.com/linux-surface/linux-surface/wiki/Secure-Boot