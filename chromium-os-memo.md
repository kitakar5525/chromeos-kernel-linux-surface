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