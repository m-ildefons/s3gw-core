#!/bin/sh

set -e

# https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html
# Release: Your typical release build with no debugging information and full optimization.
# MinSizeRel: A special Release build optimized for size rather than speed.
# RelWithDebInfo: Same as Release, but with debugging information.
# Debug: Usually a classic debug build including debugging information, no optimization etc.
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Debug"}

CEPH_DIR=$(realpath ${CEPH_DIR:-"/srv/ceph"})
CEPH_CMAKE_ARGS="-DENABLE_GIT_VERSION=ON -DWITH_PYTHON3=3 -DWITH_CCACHE=ON ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_TESTS=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_RADOSGW_AMQP_ENDPOINT=OFF -DWITH_RADOSGW_KAFKA_ENDPOINT=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_RADOSGW_SELECT_PARQUET=OFF -DWITH_RADOSGW_MOTR=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_RADOSGW_DBSTORE=ON -DWITH_RADOSGW_LUA_PACKAGES=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_MANPAGE=OFF -DWITH_OPENLDAP=OFF -DWITH_LTTNG=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_RDMA=OFF ${CEPH_CMAKE_ARGS}"
CEPH_CMAKE_ARGS="-DWITH_SYSTEM_BOOST=ON ${CEPH_CMAKE_ARGS}"
NPROC=${NPROC:-$(nproc --ignore=2)}

build_radosgw() {
  echo "Building radosgw ..."
  echo "CEPH_DIR=${CEPH_DIR}"
  echo "NPROC=${NPROC}"
  echo "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"

  export CCACHE_DIR="${CEPH_DIR}/build.ccache"
  if [ ! -d "${CCACHE_DIR}" ]; then
    mkdir "${CCACHE_DIR}"
    echo "Created by aquarist-labs/s3gw-core build-radosgw container" > \
      "${CCACHE_DIR}/README"
  fi

  cd ${CEPH_DIR}

  git config --global --add safe.directory "${CEPH_DIR}"

  ./install-deps.sh || true

  if [ -d "build" ]; then
      cd build/
      cmake -DBOOST_J=${NPROC} ${CEPH_CMAKE_ARGS} ..
  else
      ./do_cmake.sh ${CEPH_CMAKE_ARGS}
      cd build/
  fi

  ninja -j${NPROC} bin/radosgw
}

strip_radosgw() {
  [ "${CMAKE_BUILD_TYPE}" == "Debug" -o "${CMAKE_BUILD_TYPE}" == "RelWithDebInfo" ] && return 0

  echo "Stripping files ..."
  strip --strip-debug --strip-unneeded \
    --remove-section=.comment --remove-section=.note.* \
    ${CEPH_DIR}/build/bin/radosgw \
    ${CEPH_DIR}/build/lib/*.so
}

build_radosgw
strip_radosgw

exit 0
