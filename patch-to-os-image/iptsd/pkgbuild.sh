#!/bin/bash
#
# Recommend running with fakeroot like the following to preserve ownership:
# $ fakeroot -- bash pkgbuild.sh
# 
# ${pkgname}-${pkgver}-ROOT_A.tar.gz package will be created.
#

pkgname=iptsd
pkgdir_roota=${pkgname}-ROOT_A
pkgdir_rootc=${pkgname}-ROOT_C
# pkgver="" # to be added on prepare()

prepare() {
  echo ">>> prepare()"

  if [ ! -e ${pkgname}.git ]; then
    echo "performing git clone..."
    git clone https://github.com/linux-surface/iptsd ${pkgname}.git
  fi

  cd ${pkgname}.git

  # ensure that the git repo matches upstream
  git reset --hard origin/master

  echo "performing git pull..."
  git pull

  # configure pkgver
  pkgver=$(git describe --tags)
}

build() {
  echo ">>> build()"

  echo "performing go build..."
  go build
}

generate_init_script_roota() {
  mkdir -p ${pkgdir_roota}/etc/init/

  # daemon init file to be placed in ROOT_A/etc/init
  cat > ${pkgdir_roota}/etc/init/kitakar5525-iptsd.conf << 'INIT_CONF'
# referenced bluetoothd.conf and auditd.conf

description     "Start the ipts daemon"
author          "kitakar5525"

start on started system-services
stop on stopping system-services
respawn

exec /usr/bin/iptsd
INIT_CONF

  chmod 0644 ${pkgdir_roota}/etc/init/kitakar5525-iptsd.conf
}

generate_patch_file_brunch () {
  # patch file to install package (to be run by brunch)
  cat > ${pkgdir_rootc}/patches/55-kitakar5525-install-iptsd-onto-ROOT_A.sh << EXT_PACKAGE
ret=0

# install package onto ROOT
tar zxf /firmware/packages/kitakar5525-packages/iptsd/${pkgname}-${pkgver}-ROOT_A.tar.gz -C /system
if [ ! "$?" -eq 0 ]; then ret=$((ret + (2 ** 0))); fi

exit $ret
EXT_PACKAGE

  chmod 0744 ${pkgdir_rootc}/patches/55-kitakar5525-install-iptsd-onto-ROOT_A.sh
}

package_roota() {
  echo ">>> package_roota()"

  # Install iptsd binary
  install -Dpm 0755 "$pkgname" "${pkgdir_roota}/usr/bin/$pkgname"

  # Install iptsd service
  generate_init_script_roota

  # Install udev configuration
  install -Dpm 0644 etc/udev/50-ipts.rules \
    "${pkgdir_roota}/usr/lib/udev/rules.d/50-ipts.rules"

  # Install iptsd device configs
  install -dm 0755 "${pkgdir_roota}/usr/share/ipts"
  install -Dpm 0644 config/* "${pkgdir_roota}/usr/share/ipts"

  # generate tarball to be copied onto ROOT_A
  tar -C ${pkgdir_roota} -czf ${pkgname}-${pkgver}-ROOT_A.tar.gz .
}

package_rootc() {
  echo ">>> package_rootc()"

  # create ROOT_C dir structure
  mkdir -p ${pkgdir_rootc}/packages/kitakar5525-packages/iptsd ${pkgdir_rootc}/patches

  # package ROOT_A things
  install -Dpm 0644 ${pkgname}-${pkgver}-ROOT_A.tar.gz ${pkgdir_rootc}/packages/kitakar5525-packages/iptsd/

  generate_patch_file_brunch

  # generate tarball to be copied onto ROOT_C
  tar -C ${pkgdir_rootc} -czf ${pkgname}-${pkgver}-ROOT_C.tar.gz .
}

cleanup() {
  echo ">>> cleanup()"

  rm -rf ${pkgdir_roota}
  rm -rf ${pkgdir_rootc}
  rm ${pkgname}-${pkgver}-ROOT_A.tar.gz
}

prepare
build
package_roota
package_rootc
cleanup

# move built package out of build dir
mv ${pkgname}-${pkgver}-ROOT_C.tar.gz ../
