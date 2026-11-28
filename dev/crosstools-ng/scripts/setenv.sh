#!/bin/sh

#export PATH=/usr/local/bin:${PATH}
export PATH=/usr/local/bin:/usr/bin:/bin
export CT_PREFIX=${HOME}/crosstool-ng
export CT_LOCAL_TARBALLS_DIR=${CT_PREFIX}/src
mkdir -p ${CT_LOCAL_TARBALLS_DIR}

echo "PATH ${PATH}"
echo "CT_PREFIX ${CT_PREFIX}"
echo "CT_LOCAL_TARBALLS_DIR ${CT_LOCAL_TARBALLS_DIR}"

ulimit -Sn 2048
