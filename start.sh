#!/usr/bin/env bash
set -euo pipefail

OLD_MSYS_NO_PATHCONV="${MSYS_NO_PATHCONV-}"
cleanup(){ if [[ -n "${OLD_MSYS_NO_PATHCONV}" ]]; then export MSYS_NO_PATHCONV="$OLD_MSYS_NO_PATHCONV"; else unset MSYS_NO_PATHCONV; fi; }
trap cleanup EXIT
export MSYS_NO_PATHCONV=1

# Images you built
IMAGE_FULL="vllm-pixtral-full"
IMAGE_QUANT="vllm-pixtral-quant"

# Defaults (override with env vars)
PORT="${2:-8000}"
MAX_LEN="${MAX_LEN:-50000}"
GPU_UTIL="${GPU_UTIL:-0.90}"
MM_CACHE_GB="${MM_CACHE_GB:-2}"
IMG_DIR="${IMG_DIR:-}"   # optional: mount folder for file:// images

# Common docker args
DOCKER_ARGS=(--gpus all --ipc=host -p "${PORT}:${PORT}" -e "HF_TOKEN=${HF_TOKEN:-}")

# Optional images mount (so you can use file:///images/foo.png)
ALLOW_ARGS=()
if [[ -n "${IMG_DIR}" ]]; then
  DOCKER_ARGS+=(-v "${IMG_DIR}:/images:ro")
  ALLOW_ARGS=(--allowed-local-media-path /images)
fi

# Always use the template baked inside the image
CHAT_ARGS=(--chat-template /templates/openai_mm.jinja --chat-template-content-format openai --interleave-mm-strings)

case "${1:-}" in
  full)
    docker run "${DOCKER_ARGS[@]}" \
      "${IMAGE_FULL}" \
      --model mistralai/Pixtral-12B-2409 \
      --served-model-name mistralai/Pixtral-12B-2409 pixtral-12b \
      --host 0.0.0.0 --port "${PORT}" \
      --dtype bfloat16 \
      --max-model-len "${MAX_LEN}" \
      "${CHAT_ARGS[@]}" \
      "${ALLOW_ARGS[@]}" \
      --mm-processor-cache-gb "${MM_CACHE_GB}" \
      --gpu-memory-utilization "${GPU_UTIL}"
    ;;
  quant)
    docker run "${DOCKER_ARGS[@]}" \
      "${IMAGE_QUANT}" \
      --model nintwentydo/pixtral-12b-2409-W4A16-G128 \
      --served-model-name nintwentydo/pixtral-12b-2409-W4A16-G128 mistralai/Pixtral-12B-2409 pixtral-12b \
      --host 0.0.0.0 --port "${PORT}" \
      --dtype auto \
      --max-model-len "${MAX_LEN}" \
      "${CHAT_ARGS[@]}" \
      "${ALLOW_ARGS[@]}" \
      --mm-processor-cache-gb "${MM_CACHE_GB}" \
      --gpu-memory-utilization "${GPU_UTIL}"
    ;;
  local)
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 local /abs/path/to/model-dir [PORT]"
      exit 1
    fi
    LOCAL_PATH="$2"
    PORT="${3:-8000}"
    docker run "${DOCKER_ARGS[@]}" \
      -v "${LOCAL_PATH}:/models/custom:ro" \
      "${IMAGE_QUANT}" \
      --model /models/custom \
      --host 0.0.0.0 --port "${PORT}" \
      --dtype auto \
      --max-model-len "${MAX_LEN}" \
      "${CHAT_ARGS[@]}" \
      "${ALLOW_ARGS[@]}" \
      --mm-processor-cache-gb "${MM_CACHE_GB}" \
      --gpu-memory-utilization "${GPU_UTIL}"
    ;;
  *)
    echo "Usage:"
    echo "  $0 full [PORT]                  # run full-precision image"
    echo "  $0 quant [PORT]                 # run quantized image"
    echo "  $0 local /abs/path/model [PORT] # run a local model dir (quant image)"
    echo ""
    echo "Env vars:"
    echo "  HF_TOKEN=...                 # HF token (if needed)"
    echo "  IMG_DIR=/abs/path/images     # mount as /images for file:// URLs"
    echo "  MAX_LEN=32768                # context window"
    echo "  GPU_UTIL=0.90                # GPU memory fraction"
    echo "  MM_CACHE_GB=2                # vision preproc cache"
    exit 1
    ;;
esac

# Restore MSYS_NO_PATHCONV
if [[ -n "${OLD_MSYS_NO_PATHCONV}" ]]; then
  export MSYS_NO_PATHCONV="$OLD_MSYS_NO_PATHCONV"
else
  unset MSYS_NO_PATHCONV
fi
