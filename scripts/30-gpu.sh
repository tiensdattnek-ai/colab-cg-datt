#!/usr/bin/env bash
# Phat hien GPU -> chon encoder phan cung tot nhat
source "$(dirname "$0")/00-common.sh"
say "Phat hien encoder"
DETECTED=software
if has_nvidia; then
  # Thu viện NVENC thường đã có sẵn trên Colab; chỉ cài khi thiếu
  if ! ldconfig -p | grep -q libnvidia-encode; then
    DRV=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | cut -d. -f1)
    apt_q "libnvidia-encode-${DRV}" 2>/dev/null || apt_q libnvidia-encode-535 2>/dev/null || true
  fi
  if ldconfig -p | grep -q libnvidia-encode; then DETECTED=nvenc
  else warn "Co GPU nhung thieu libnvidia-encode -> dung software"; DETECTED=software; fi
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
mark ENCODER "$ENCODER"
ok "Encoder = $ENCODER | Codec = $CODEC"
[ "$ENCODER" = "software" ] && warn "Khong co GPU encode -> dung CPU, nen ha xuong 1280x720@60"
