#!/bin/sh

set -e

IMAGE_NAME=${IMAGE_NAME:-"s3gw-ui"}
S3GW_UI_DIR=$(realpath ${S3GW_UI_DIR:-"../../s3gw-ui/"})
S3GW_UI_DIST_DIR=${S3GW_UI_DIST_DIR:-"${S3GW_UI_DIR}/dist/s3gw-ui/"}

force=false
registry=
registry_args=

usage() {
  cat << EOF
usage: $0 [args...]

options
  --registry URL     The URL of the registry.
  --no-registry-tls  Disable TLS when pushing to registry.
  --help             Show this message

EOF
}

info() {
  echo "[INFO] $*" >/dev/stdout
}

error() {
  echo "[ERROR] $*" >/dev/stderr
}

build_app_image() {
  if [ ! -e "${S3GW_UI_DIST_DIR}" ]; then
    error "Application dist folder '${S3GW_UI_DIST_DIR}' does not exist. Please run the 'app' command first." && exit 1
  fi

  info "Building ${IMAGE_NAME} image ..."
  podman build -v "$S3GW_UI_DIR:/srv/app" -f Dockerfile -t ${IMAGE_NAME}:latest .

  if [ -n "${registry}" ]; then
    info "Pushing ${IMAGE_NAME} image to registry ..."
    podman push ${registry_args} localhost/${IMAGE_NAME} \
      ${registry}/${IMAGE_NAME}
  fi
}


while [ $# -ge 1 ]; do
  case ${1} in
    --force)
      force=true
      ;;
    --registry)
      registry=$2
      shift
      ;;
    --no-registry-tls)
      registry_args="--tls-verify=false"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown argument '${1}'"
      exit 1
      ;;
  esac
  shift
done

build_app_image || exit 1
exit 0
