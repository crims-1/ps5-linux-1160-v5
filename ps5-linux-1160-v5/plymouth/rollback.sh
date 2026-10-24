#!/usr/bin/env bash
# Restore the Plymouth theme saved by install.sh. Does not edit cmdline.txt.
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo bash ${BASH_SOURCE[0]}"
  exit 1
fi
STATE_DIR="/var/backups/ps5-linux-ali/latest"
DEST="/usr/share/plymouth/themes/ps5-linux-ali"
ALT_LINK="/usr/share/plymouth/themes/default.plymouth"
if [[ ! -d "$STATE_DIR" || ! -f "$STATE_DIR/previous-default-theme.path" ]]; then
  echo "No backup found at ${STATE_DIR}; nothing changed."
  exit 1
fi
OLD_THEME="$(cat "$STATE_DIR/previous-default-theme.path")"
if [[ -n "$OLD_THEME" && -f "$OLD_THEME" ]]; then
  update-alternatives --install "$ALT_LINK" default.plymouth "$OLD_THEME" 100
  update-alternatives --set default.plymouth "$OLD_THEME"
else
  echo "Previous theme path is missing; listing available choices instead:"
  update-alternatives --config default.plymouth
fi
if [[ "$(cat "$STATE_DIR/theme-directory-existed" 2>/dev/null || echo no)" == "yes" && -d "$STATE_DIR/previous-theme-directory" ]]; then
  rm -rf "$DEST"
  cp -a "$STATE_DIR/previous-theme-directory" "$DEST"
else
  rm -rf "$DEST"
fi
update-initramfs -u -k all
echo "Plymouth theme rollback complete. The boot cmdline was not changed by this installer."
