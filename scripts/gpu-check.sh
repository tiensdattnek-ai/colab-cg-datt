#!/usr/bin/env bash
# Kiem tra nhanh GPU/NVENC truoc khi cai
echo "── GPU ──"
if nvidia-smi -L 2>/dev/null; then
  nvidia-smi --query-gpu=name,driver_version,memory.total,utilization.gpu --format=csv
else
  echo "❌ Khong thay GPU. Runtime > Change runtime type > T4 GPU > Save, roi Connect lai."; exit 1
fi
echo "── Thu vien NVENC ──"
ldconfig 2>/dev/null
L=$(ldconfig -p | grep -i nvidia-encode | head -1)
[ -z "$L" ] && L=$(find /usr -maxdepth 4 -name 'libnvidia-encode.so*' 2>/dev/null | head -1)
[ -n "$L" ] && echo "✅ $L" || echo "⚠️  Khong tim thay libnvidia-encode (van co the ep ENCODER=nvenc de thu)"
echo "── Thu encode bang ffmpeg ──"
if command -v ffmpeg >/dev/null; then
  ffmpeg -hide_banner -loglevel error -f lavfi -i nullsrc=s=256x144:d=0.1 -c:v h264_nvenc -f null - \
    && echo "✅ NVENC hoat dong" || echo "⚠️  ffmpeg khong encode duoc (co the do ffmpeg khong build nvenc, Sunshine van dung duoc)"
else
  echo "(chua co ffmpeg)"
fi
