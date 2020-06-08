#!/bin/bash

is_debian () {
  cat /etc/os-release | grep debian
  if [[ $? == 0 ]]; then true; else false; fi
}



which dpkg > /dev/null
if [[ ! $? == 0 ]]; then
  echo "$0: this script depends on dpkg but not available, aborting"
  exit -1
fi

# HACK: if distro is not dpkg-based, add `no-check-builddeps`
cat /etc/dpkg/buildpackage.conf | grep "no-check-builddeps" > /dev/null
if [[ ! $? == 0 ]] && ! is_debian; then
  if [ ! -f /etc/dpkg/buildpackage.conf ]; then 
    sudo touch /etc/dpkg/buildpackage.conf
  fi
  cat << 'EOS' | sudo tee -a /etc/dpkg/buildpackage.conf

# HACK: ignore deps for non-dpkg based distros
"no-check-builddeps"
EOS
fi

make -j$(nproc) bindeb-pkg

# collect generated files into one dir
## TODO: better way to do so?
KERN_VER="$(make kernelrelease)"
cd ..
LIST_GENERATED=$(ls *$KERN_VER*)
mkdir $KERN_VER
mv $(echo $LIST_GENERATED) $KERN_VER/
