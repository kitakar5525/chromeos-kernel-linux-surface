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

### Uninstall packages from build chroot

It seems that you can't install both 4.19 and 5.4 kernels into build chroot at the same time.

```bash
$ emerge-$BOARD -C chromeos-kernel-4_19
 * This action can remove important packages! In order to be safer, use
 * `emerge -pv --depclean <atom>` to check for reverse dependencies before
 * removing packages.

>>> Using system located in ROOT tree /build/amd64-generic/

 sys-kernel/chromeos-kernel-4_19
    selected: 9999 
   protected: none 
     omitted: none 

All selected packages: =sys-kernel/chromeos-kernel-4_19-9999

>>> 'Selected' packages are slated for removal.
>>> 'Protected' and 'omitted' packages will not be removed.

>>> Waiting 5 seconds before starting...
>>> (Control-C to abort)...
>>> Unmerging in: 5 4 3 2 1
>>> Unmerging (1 of 1) sys-kernel/chromeos-kernel-4_19-9999...
 * 
 * Directory symlink(s) may need protection:
 * 
 * 	/build/amd64-generic/lib/modules/4.19.91/build
 * 	/build/amd64-generic/lib/modules/4.19.91/source
 * 	/build/amd64-generic/usr/src/linux
 * 
 * Use the UNINSTALL_IGNORE variable to exempt specific symlinks
 * from the following search (see the make.conf man page).
 * 
 * Searching all installed packages for files installed via above symlink(s)...
 * 
 * The above directory symlink(s) are all safe to remove. Removing them now...
 * 

 * Messages for package sys-kernel/chromeos-kernel-4_19-9999 merged to /build/amd64-generic/:
 * Log file: /build/amd64-generic/tmp/portage/logs/sys-kernel:chromeos-kernel-4_19-9999:20200106-123041.log

 * 
 * Directory symlink(s) may need protection:
 * 
 * 	/build/amd64-generic/lib/modules/4.19.91/build
 * 	/build/amd64-generic/lib/modules/4.19.91/source
 * 	/build/amd64-generic/usr/src/linux
 * 
 * Use the UNINSTALL_IGNORE variable to exempt specific symlinks
 * from the following search (see the make.conf man page).
 * 
 * Searching all installed packages for files installed via above symlink(s)...
 * 
 * The above directory symlink(s) are all safe to remove. Removing them now...
 * 
```