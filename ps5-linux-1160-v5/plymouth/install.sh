#!/usr/bin/env bash
# Install the Ali Plymouth splash into the currently booted Ubuntu/Debian system.
# Does not edit cmdline.txt, firmware offsets, kernel code, or payload source.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="ps5-linux-ali"
DEST="/usr/share/plymouth/themes/${THEME_NAME}"
ALT_LINK="/usr/share/plymouth/themes/default.plymouth"
STATE_ROOT="/var/backups/ps5-linux-ali"
STAMP="$(date +%Y%m%d-%H%M%S)"
STATE_DIR="${STATE_ROOT}/${STAMP}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run inside the target Linux system with: sudo bash ${BASH_SOURCE[0]}"
  exit 1
fi
for cmd in update-alternatives update-initramfs; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command '$cmd' was not found. This installer is for Ubuntu/Debian systems using initramfs-tools."
    exit 1
  fi
done
for f in background.png ps5-linux-ali.plymouth ps5-linux-ali.script; do
  if [[ ! -f "${SCRIPT_DIR}/${f}" ]]; then
    echo "Missing theme file: ${SCRIPT_DIR}/${f}"
    exit 1
  fi
done

cat <<'NOTICE'
PS5 Linux — Ali Edition boot theme
This changes the Plymouth theme of the currently running Linux installation
and rebuilds its initramfs. It does NOT modify the PS5 payload or cmdline.txt.
NOTICE
read -r -p "Install the theme on THIS Linux system and create a backup first? [y/N] " answer
case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled; no changes made."; exit 0;; esac

mkdir -p "$STATE_DIR" "$STATE_ROOT"
OLD_THEME="$(readlink -f /etc/alternatives/default.plymouth 2>/dev/null || true)"
printf '%s\n' "$OLD_THEME" > "${STATE_DIR}/previous-default-theme.path"
if [[ -d "$DEST" ]]; then
  cp -a "$DEST" "${STATE_DIR}/previous-theme-directory"
  echo "yes" > "${STATE_DIR}/theme-directory-existed"
else
  echo "no" > "${STATE_DIR}/theme-directory-existed"
fi
ln -sfn "$STATE_DIR" "${STATE_ROOT}/latest"

mkdir -p "$DEST"
install -m 0644 "${SCRIPT_DIR}/background.png" "$DEST/background.png"
install -m 0644 "${SCRIPT_DIR}/ps5-linux-ali.plymouth" "$DEST/ps5-linux-ali.plymouth"
install -m 0644 "${SCRIPT_DIR}/ps5-linux-ali.script" "$DEST/ps5-linux-ali.script"

update-alternatives --install "$ALT_LINK" default.plymouth "${DEST}/ps5-linux-ali.plymouth" 200
update-alternatives --set default.plymouth "${DEST}/ps5-linux-ali.plymouth"
update-initramfs -u -k all

echo
echo "Installed. Backup: ${STATE_DIR}"
echo "If the splash does not appear, verify that 'splash' is present in the boot partition's cmdline.txt."
echo "This installer deliberately did not edit cmdline.txt."
echo "Rollback: sudo bash ${SCRIPT_DIR}/rollback.sh"
