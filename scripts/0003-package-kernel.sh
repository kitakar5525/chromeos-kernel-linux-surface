#!/bin/bash

package_root_a () {
  mkdir ${KERN_VER}-ROOT_A
  for p in $(echo $LIST_DEB2TARGZ); do
    # extract the tar archives into ROOT_A dir
    tar -xf $p -C ${KERN_VER}-ROOT_A
  done

  cd ${KERN_VER}-ROOT_A
  rm -rf etc #remove unnecessary files

  cd ..
  # generate tarball to be copied onto ROOT_A
  tar -C ${KERN_VER}-ROOT_A -czf ${KERN_VER}-ROOT_A.tar.gz .
}

generate_patch_file_brunch () {
  # patch file to install kernel (to be run by brunch)
  cat > patches/zz-kitakar5525-extract-kernel-package-onto-ROOT_A.sh << 'EXT_KERNEL'
# HACK: prefix this patch file with "zz" to always run this patch last.
# On brunch release "brunch_r83_k4.19_testing_20200528", the brunch patch
# "99-kernel_headers.sh" replaces kernel headers. To use headers with
# the kernel I provide, at least this patch needs to be run after that
# brunch patch.

ret=0

# remove existing kernel files first
rm -rf /system/lib/modules/*
rm -rf /system/lib/headers
rm -rf /system/usr/src/linux-headers-*

# install external kernel onto ROOT
tar zxf /firmware/packages/kitakar5525-kernel/$(cat /proc/version |  cut -d' ' -f3)-ROOT_A.tar.gz -C /system
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 0))); fi

exit $ret
EXT_KERNEL
  chmod 0744 patches/zz-kitakar5525-extract-kernel-package-onto-ROOT_A.sh
}

package_root_c () {
  # create ROOT_C dir structure
  mkdir ${KERN_VER}-ROOT_C
  cd ${KERN_VER}-ROOT_C
  mkdir -p packages/kitakar5525-kernel patches

  # package ROOT_A things
  mv ../${KERN_VER}-ROOT_A.tar.gz packages/kitakar5525-kernel
  cp ../${KERN_VER}-ROOT_A/boot/vmlinuz-$KERN_VER kernel

  generate_patch_file_brunch

  cd ..
  # generate tarball to be copied onto ROOT_C
  tar -C ${KERN_VER}-ROOT_C -czf ${KERN_VER}-ROOT_C.tar.gz .
}

cleanup () {
  rm -rf ${KERN_VER}-ROOT_A
  rm -rf ${KERN_VER}-ROOT_C
  for p in $(echo $LIST_DEB2TARGZ); do
    rm $p
  done
}



which deb2targz > /dev/null
if [[ ! $? == 0 ]]; then
  echo "$0: this script depends on deb2targz but not available, aborting"
  exit -1
fi

KERN_VER="$(make kernelrelease)"
cd ..

# extract deb packages into tar archives
deb2targz *.deb
LIST_DEB2TARGZ=$(ls *$KERN_VER*.tar.*) # file names list of the tar archives

package_root_a
package_root_c
cleanup
