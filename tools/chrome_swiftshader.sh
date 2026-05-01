#!/usr/bin/env bash
set -euo pipefail

exec google-chrome \
  --use-gl=swiftshader \
  --enable-webgl \
  --ignore-gpu-blocklist \
  --enable-unsafe-swiftshader \
  "$@"
