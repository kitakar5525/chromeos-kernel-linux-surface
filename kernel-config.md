## kernel config

In addition to Surface related kernel configs (search by SURFACE in `make menuconfig`), you need to change a lot to use on Surface Book 1 / Surface 3.

```bash
Surface related kernel configs
- All items found by searching SURFACE
- SURFACE_ACPI_SSH dependency:
  - SERIAL_8250
  - SERIAL_8250_DW
  - SERIAL_DEV_CTRL_TTYPORT

Cherry Trail related
- All items found by searching CHERRY, Crystal
- All items found by searching CHT except SND related things
- CHT_DC_TI_PMIC_OPREGION dependency:
  - PMIC_OPREGION
  - INTEL_SOC_PMIC_CHTDC_TI
- CHT_WC_PMIC_OPREGION dependency:
  - INTEL_SOC_PMIC_CHTWC
- EXTCON_INTEL_CHT_WC dependency:
  - EXTCON
- INTEL_CHT_INT33FE dependency:
  - REGULATOR
  - CHARGER_BQ24190
- GPIO_CRYSTAL_COVE dependency:
  - INTEL_SOC_PMIC

Atom SoC sound related
- CONFIG_SND_SST_ATOM_HIFI2_PLATFORM [=m]
- CONFIG_SND_SST_ATOM_HIFI2_PLATFORM_PCI [=m]

Sound on Surface 3
- CONFIG_SND_SOC_INTEL_CHT_BSW_RT5645_MACH
- CONFIG_HDMI_LPE_AUDIO # needed for HDMI sound

Backlight control on Surface 3
- CONFIG_PWM
  - CONFIG_PWM_LPSS_PLATFORM
  #- CONFIG_PWM_LPSS_PCI
- CONFIG_PWM_CRC
  - INTEL_SOC_PMIC
- DRM_I915=m
  - INTEL_IPTS=m

For IPTS on SB1 to work
- DRM_I915=m
- INTEL_MEI_ME [=M (?)]

Surface 3 S0ix
- INTEL_MEI_TXE
- CONFIG_INTEL_ATOMISP2_PM
- INTEL_INT0002_VGPIO (?)

SB1 S0ix
- MEDIA_CONTROLLER
  - VIDEO_V4L2_SUBDEV_API
    - CONFIG_VIDEO_IPU3_IMGU # need to be as module or embed the firmware to load the firmware
    - CONFIG_VIDEO_IPU3_CIO2
- CONFIG_INTEL_PCH_THERMAL

TPM (m if you want to use vTPM)
- CONFIG_TCG_TIS [=m]
- TCG_VTPM_PROXY [=m]
- CONFIG_TCG_CRB [=m]
- CONFIG_TCG_VIRTIO_VTPM [=m]

HID sensors
- HID_SENSOR_HUB
  - HID_SENSOR_IIO_COMMON
    - HID_SENSOR_ACCEL_3D
    - HID_SENSOR_ALS
    - HID_SENSOR_DEVICE_ROTATION
    - HID_SENSOR_GYRO_3D

Fix ACPI error on Surface 3
- SENSORS_CORETEMP [=m]

Embed firmware
#If you specify ipts firmwares here, remember to copy `/lib/firmware/intel/ipts` to your build machine.
#Or if you are in cros_sdk, `$HOME/chromiumos/chroot/build/amd64-generic/lib/firmware`.
#- CONFIG_EXTRA_FIRMWARE='i915/skl_dmc_ver1_27.bin i915/skl_huc_ver01_07_1398.bin i915/skl_guc_ver9_33.bin intel/ipu3-fw.bin intel/ipts/config.bin intel/ipts/intel_desc.bin intel/ipts/vendor_desc.bin intel/ipts/vendor_kernel.bin intel/fw_sst_0f28.bin intel/fw_sst_0f28.bin-48kHz_i2s_master intel/fw_sst_0f28_ssp0.bin intel/fw_sst_22a8.bin'
# stopped embedding firmware except intel/ipu3-fw.bin for now
CONFIG_EXTRA_FIRMWARE='intel/ipu3-fw.bin'
# - CONFIG_EXTRA_FIRMWARE_DIR='/lib/firmware'
- CONFIG_EXTRA_FIRMWARE_DIR='/build/amd64-generic/lib/firmware/' # if you are in cros_sdk

Fix HID related errors after s2idle (to reload module after suspend)
- I2C_HID [=m]
- USB_HID [=m]

Testing
- INTEL_PMC_IPC
# VirtualBox guest
    # [VirtualBox - Gentoo Wiki](https://wiki.gentoo.org/wiki/VirtualBox#Kernel_configuration)
    - CONFIG_X86_SYSFB
    - CONFIG_DRM_FBDEV_EMULATION
    - CONFIG_FIRMWARE_EDID
    - CONFIG_FB_SIMPLE
# Surface series camera?
- CONFIG_TPS68470_PMIC_OPREGION=y
- CONFIG_GPIO_TPS68470=y
- CONFIG_MFD_TPS68470=y

Personal memo
- #if you patched to include acpi_call, don't forget to set it y or m
```

### misc configs from diff with Arch Linux kernel

```bash

Useful?
- CONFIG_HOTPLUG_PCI_ACPI
    - CONFIG_HOTPLUG_PCI_ACPI_IBM
- CONFIG_PWM_LPSS_PCI # not related to Surface 3
- CONFIG_DRM_I915_ALPHA_SUPPORT
- INPUT_SOC_BUTTON_ARRAY
- DYNAMIC_DEBUG
- ACPI_EC_DEBUGFS
- INTEL_POWERCLAMP
- CONFIG_DRM_I915_GVT
  - INTEL_IOMMU
  - INTEL_IOMMU_DEFAULT_ON is not set # kernel param is `intel_iommu=on`
  - VFIO
  - VFIO_MDEV
  - VFIO_MDEV_DEVICE
  - KVM
    - DRM_I915_GVT_KVMGT
  - CONFIG_KVM_INTEL
  - CONFIG_VHOST_NET
  - VIRTIO_VSOCKETS
    - VHOST_VSOCK
    - VIRTIO_VSOCKETS_COMMON



Useful for some people?
- CONFIG_INTEL_MEI_WDT
- HID_SENSOR_HUMIDITY
- HID_SENSOR_INCLINOMETER_3D
- HID_SENSOR_MAGNETOMETER_3D
- HID_SENSOR_PRESS
- HID_SENSOR_PROX
- HID_SENSOR_TEMP
- MTD_CMDLINE_PARTS
- VT
  - FRAMEBUFFER_CONSOLE
  - FRAMEBUFFER_CONSOLE_DETECT_PRIMARY
  - CONFIG_FRAMEBUFFER_CONSOLE_ROTATION
  - CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER
  - DRM_FBDEV_EMULATION
  - DRM_KMS_FB_HELPER
- CRYPTO_CRC32C_INTEL
- CRYPTO_CRC32_PCLMUL
- CRYPTO_CRCT10DIF_PCLMUL
- CRYPTO_USER
- DPTF_POWER
- EDAC
- CRYPTO_GHASH_CLMUL_NI_INTEL
- MTD
- MTD_SPI_NOR
- SPI_INTEL_SPI_PCI
- SPI_INTEL_SPI_PLATFORM
- CONFIG_USB_ROLE_SWITCH
  - CONFIG_USB_ROLES_INTEL_XHCI
- CONFIG_MACINTOSH_DRIVERS
  - MAC_EMUMOUSEBTN
- CRYPTO_PCBC
- X86_PCC_CPUFREQ
- CONFIG_TRANSPARENT_HUGEPAGE
- CONFIG_USBIP_CORE
- CONFIG_USB_NET_CDC_MBIM
- CONFIG_VIDEO_VIVID
- CONFIG_VLAN_8021Q
- CONFIG_CIFS
- CONFIG_AUTOFS4_FS
- CONFIG_AUTOFS_FS
```