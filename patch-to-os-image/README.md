This directory will contain the following stuff compatible with brunch:
- binary build script and generated binary packages
- patch files

### Installation

#### Brunch

You can just extract archives onto ROOT-C like the following:
```bash
package_name="iptsd"
ROOT_C_archive=$1 # archive location

ROOT_C_MOUNT_DIR=/tmp/mnt/ROOT-C

# 1. mount ROOT-C
if [ ! -d $ROOT_C_MOUNT_DIR ]; then
    mkdir -p $ROOT_C_MOUNT_DIR
fi
mount /dev/disk/by-label/ROOT-C $ROOT_C_MOUNT_DIR

# 2. remove existing package archive
rm $ROOT_C_MOUNT_DIR/packages/kitakar5525-packages/${package_name}/*

# 3. extract archive onto ROOT-C
tar -xf ${ROOT_C_archive} -C $ROOT_C_MOUNT_DIR
sync; sync; sync
echo "done."

# 4. cleanup
## unmount ROOT-C
umount $ROOT_C_MOUNT_DIR
```

#### chromiumos

First, extract ROOT_C package into somewhere. Then, extract ROOT_A package
existing under packages/ onto ROOT-A.
