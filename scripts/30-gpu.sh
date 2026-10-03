#!/usr/bin/env bash
# Phat hien GPU -> chon encoder phan cung tot nhat
source "$(dirname "$0")/00-common.sh"
say "Phat hien encoder"
DETECTED=software
if has_nvidia; then
  apt_q libnvidia-encode-535 2>/dev/null || true
  DETECTED=nvenc
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | sed 's/^/     GPU: /'
elif [ -e /dev/dri/renderD128 ]; then
  apt_q vainfo intel-media-va-driver-non-free mesa-va-drivers
  vainfo >/dev/null 2>&1 && DETECTED=vaapi
fi
[ "$ENCODER" = "auto" ] && ENCODER=$DETECTED
if [ "$CODEC" = "auto" ]; then
  case "$ENCODER" in nvenc|vaapi) CODEC=hevc ;; *) CODEC=h264 ;; esac
fi
echo "ENCODER=$ENCODER" >"$CCG_HOME/encoder.env"
echo "CODEC=$CODEC"   >>"$CCG_HOME/encoder.env"
ok "Encoder = $ENCODER | Codec = $CODEC"
[ "$ENCODER" = "software" ] && warn "Khong co GPU encode -> dung CPU, nen ha xuong 1280x720@60"
