#!/usr/bin/env bash
# © 2026, Cargo Robotics
# Jetson only: build and run zed-opencv-calibration in Docker (ZED SDK 5.1.x, L4T JP installer).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

L4T_MAJOR="${L4T_MAJOR:-35}"
L4T_MINOR="${L4T_MINOR:-4}"
L4T_PATCH="${L4T_PATCH:-1}"

DOCKERFILE="${SCRIPT_DIR}/Dockerfile.calibration"
IMAGE_NAME="${ZED_CALIBRATION_IMAGE:-cargo/zed-virtual-stereo-calibration:zed-5.1.0-l4t${L4T_MAJOR}.${L4T_MINOR}-aarch64}"

usage() {
  echo "Usage: $(basename "$0") <build|run|shell> [extra docker args...]"
  echo ""
  echo "  build       Build ${IMAGE_NAME} (context: ${SCRIPT_DIR})"
  echo "  run|shell   Run container (ZED X / Argus volumes; see docker-compose-deploy zed)"
  echo ""
  echo "L4T line for Stereolabs URL (defaults ${L4T_MAJOR}.${L4T_MINOR}.${L4T_PATCH}): set L4T_MAJOR, L4T_MINOR, L4T_PATCH"
  echo ""
  echo "Environment:"
  echo "  ZED_CALIBRATION_IMAGE          Override image tag"
  echo "  CALIBRATION_JETSON_BASE_IMAGE  Optional; passed as IMAGE_NAME to docker build"
  echo ""
  echo "Binaries on PATH in container: zed_stereo_calibration, zed_reprojection_viewer"
  echo "Ensure on host: systemctl is-active nvargus-daemon zed_x_daemon"
  exit 1
}

docker_build() {
  local build_args=(
    --build-arg "L4T_MAJOR=${L4T_MAJOR}"
    --build-arg "L4T_MINOR=${L4T_MINOR}"
    --build-arg "L4T_PATCH=${L4T_PATCH}"
  )
  if [[ -n "${CALIBRATION_JETSON_BASE_IMAGE:-}" ]]; then
    build_args+=(--build-arg "IMAGE_NAME=${CALIBRATION_JETSON_BASE_IMAGE}")
  fi
  docker build \
    -f "${DOCKERFILE}" \
    "${build_args[@]}" \
    -t "${IMAGE_NAME}" \
    "${SCRIPT_DIR}"
}

if [[ $# -lt 1 ]]; then
  usage
fi

cmd="$1"
shift

case "${cmd}" in
  build)
    docker_build
    ;;
  run | shell)
    docker_run_args=(
      docker run --rm -it
      --runtime=nvidia
      --privileged
      --network=host
      --ipc=host
      --pid=host
      -e NVIDIA_DRIVER_CAPABILITIES=all
      -e DISPLAY="${DISPLAY:-:0}"
      -v /dev:/dev
      -v /usr/local/zed/resources/:/usr/local/zed/resources/
      -v /usr/local/zed/settings/:/usr/local/zed/settings/
      -v /dev/shm:/dev/shm
      -v /tmp:/tmp
      -v /var/nvidia/nvcam/settings/:/var/nvidia/nvcam/settings/
      -v /etc/systemd/system/zed_x_daemon.service:/etc/systemd/system/zed_x_daemon.service
    )
    if [[ -d /usr/lib/aarch64-linux-gnu/tegra ]]; then
      docker_run_args+=(-v /usr/lib/aarch64-linux-gnu/tegra:/usr/lib/aarch64-linux-gnu/tegra)
    fi
    if [[ -d /usr/lib/aarch64-linux-gnu/tegra-egl ]]; then
      docker_run_args+=(-v /usr/lib/aarch64-linux-gnu/tegra-egl:/usr/lib/aarch64-linux-gnu/tegra-egl)
    fi
    if [[ -d /usr/lib/aarch64-linux-gnu/nvidia ]]; then
      docker_run_args+=(-v /usr/lib/aarch64-linux-gnu/nvidia:/usr/lib/aarch64-linux-gnu/nvidia)
    fi
    docker_run_args+=(
      -e "LD_LIBRARY_PATH=/usr/local/zed/lib:/usr/lib/aarch64-linux-gnu/tegra:/usr/lib/aarch64-linux-gnu/tegra-egl:/usr/lib/aarch64-linux-gnu/nvidia:/usr/local/cuda/lib64"
      "$@"
      "${IMAGE_NAME}"
      bash -l
    )
    exec "${docker_run_args[@]}"
    ;;
  -h | --help | help)
    usage
    ;;
  *)
    echo "Unknown command: ${cmd}" >&2
    usage
    ;;
esac
