# chromeos-kernel-linux-surface

linux-surface kernel for chromiumos.

- using linux-surface (https://github.com/linux-surface/linux-surface) patches

- patches actually used is here: [kitakar5525/linux-surface-patches](https://github.com/kitakar5525/linux-surface-patches)
- kernel trees actually used is here: [Releases · kitakar5525/linux-surface-kernel](https://github.com/kitakar5525/linux-surface-kernel/releases)



## How to build a kernel (using `make` command)

```bash
# first, generate config using one of the script located under
# scripts/0001-generate-kernel-config/

# then
bash scripts/0002-build-kernel-using-make.sh
# run with sudo or fakeroot to preserve ownership
fakeroot -- bash scripts/0003-package-kernel.sh
```



## How to install the module and vmlinuz

copy the module into `ROOT-A/lib/modules` and copy the vmlinuz to `EFI-SYSTEM/syslinux/vmlinuz.A`
