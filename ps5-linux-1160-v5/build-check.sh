#!/usr/bin/env bash
# Build the original source and verify the output; does not deploy or run it.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
SDK_CLANG="/opt/ps5-payload-sdk/bin/prospero-clang"
if [[ ! -x "$SDK_CLANG" ]]; then
  echo "Prospero SDK compiler not found at ${SDK_CLANG}. Install/configure the SDK first."
  exit 2
fi
for tool in make file readelf; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Required tool missing: $tool"
    exit 2
  fi
done
make clean
make -j1
ELF="${ROOT}/bin/ps5-linux-loader.elf"
if [[ ! -s "$ELF" ]]; then
  echo "Build returned but expected ELF is missing: $ELF"
  exit 1
fi
echo "=== Output file ==="
file "$ELF"
echo "=== ELF header ==="
readelf -h "$ELF" | grep -E 'Class:|OS/ABI:|Type:|Machine:'
echo "Build completed. This does not test execution on a PS5."
